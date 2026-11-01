import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "apikey, authorization, x-client-info, content-type",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
  "Content-Type": "application/json; charset=utf-8",
};

const json = (body: unknown, status = 200) => Response.json(body, { status, headers: corsHeaders });

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (request.method !== "GET" && request.method !== "POST") return json({ error: "Method not allowed" }, 405);

  const projectUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!projectUrl || !serviceRoleKey) return json({ error: "Subscription service is not configured" }, 500);

  const bearer = request.headers.get("Authorization") || "";
  const token = bearer.replace(/^Bearer\s+/i, "");
  if (!token) return json({ error: "Sign in is required" }, 401);

  const admin = createClient(projectUrl, serviceRoleKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
  const { data: authData, error: authError } = await admin.auth.getUser(token);
  const user = authData?.user;
  if (authError || !user) return json({ error: "Session is invalid; sign in again" }, 401);

  const { data: adminAccess, error: adminError } = await admin
    .from("smp_subscription_admins")
    .select("user_id,username")
    .eq("user_id", user.id)
    .maybeSingle();
  if (adminError) return json({ error: "Could not verify administrator access" }, 500);
  const isAdmin = !!adminAccess;

  if (request.method === "GET") {
    let { data: subscription, error } = await admin
      .from("smp_subscriptions")
      .select("user_id,status,requested_at,starts_at,expires_at,decided_at")
      .eq("user_id", user.id)
      .maybeSingle();
    if (error) return json({ error: "Could not load subscription" }, 500);
    if (!subscription) {
      const created = await admin.from("smp_subscriptions")
        .insert({ user_id: user.id, status: "pending" })
        .select("user_id,status,requested_at,starts_at,expires_at,decided_at")
        .single();
      if (created.error) return json({ error: "Could not create subscription request" }, 500);
      subscription = created.data;
    }

    if (!isAdmin) return json({ is_admin: false, subscription });

    const { data: rows, error: rowsError } = await admin
      .from("smp_subscriptions")
      .select("user_id,status,requested_at,starts_at,expires_at,decided_at")
      .order("requested_at", { ascending: false })
      .limit(200);
    if (rowsError) return json({ error: "Could not load subscribers" }, 500);

    const subscribers = await Promise.all((rows || []).map(async (row) => {
      const { data } = await admin.auth.admin.getUserById(row.user_id);
      return {
        ...row,
        email: data?.user?.email || "",
        username: String(data?.user?.user_metadata?.username || ""),
      };
    }));
    return json({ is_admin: true, subscription, subscribers });
  }

  if (!isAdmin) return json({ error: "Administrator access is required" }, 403);
  let body: Record<string, unknown>;
  try {
    body = await request.json();
  } catch {
    return json({ error: "Invalid request body" }, 400);
  }

  const targetUserId = String(body.user_id || "");
  const action = String(body.action || "");
  if (!/^[0-9a-f-]{36}$/i.test(targetUserId) || targetUserId === user.id) {
    return json({ error: "Invalid subscriber" }, 400);
  }
  if (action !== "approve" && action !== "reject") return json({ error: "Invalid action" }, 400);

  const { data: target, error: targetError } = await admin
    .from("smp_subscriptions")
    .select("user_id,status,expires_at")
    .eq("user_id", targetUserId)
    .maybeSingle();
  if (targetError || !target) return json({ error: "Subscriber not found" }, 404);

  const now = new Date();
  let update: Record<string, unknown>;
  if (action === "approve") {
    const days = Number(body.days);
    if (!Number.isInteger(days) || days < 1 || days > 3650) return json({ error: "Choose a duration from 1 to 3650 days" }, 400);
    const oldEnd = target.status === "approved" && target.expires_at ? Date.parse(target.expires_at) : NaN;
    const startsAt = Number.isFinite(oldEnd) && oldEnd > now.getTime() ? oldEnd : now.getTime();
    update = {
      status: "approved",
      starts_at: new Date(startsAt).toISOString(),
      expires_at: new Date(startsAt + days * 86400000).toISOString(),
      decided_by: user.id,
      decided_at: now.toISOString(),
      updated_at: now.toISOString(),
    };
  } else {
    update = {
      status: "rejected",
      starts_at: null,
      expires_at: null,
      decided_by: user.id,
      decided_at: now.toISOString(),
      updated_at: now.toISOString(),
    };
  }

  const { data: updated, error: updateError } = await admin
    .from("smp_subscriptions")
    .update(update)
    .eq("user_id", targetUserId)
    .select("user_id,status,requested_at,starts_at,expires_at,decided_at")
    .single();
  if (updateError) return json({ error: "Could not update subscription" }, 500);
  return json({ ok: true, subscription: updated });
});
