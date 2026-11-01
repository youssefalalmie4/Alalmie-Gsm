import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "apikey, authorization, x-client-info, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Content-Type": "application/json; charset=utf-8",
};

const invalidCredentials = () => Response.json(
  { error: "اسم المستخدم أو كلمة المرور غير صحيحة" },
  { status: 401, headers: corsHeaders },
);

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (request.method !== "POST") {
    return Response.json({ error: "Method not allowed" }, { status: 405, headers: corsHeaders });
  }

  const projectUrl = Deno.env.get("SUPABASE_URL");
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!projectUrl || !anonKey || !serviceRoleKey) {
    return Response.json({ error: "Username login is not configured" }, { status: 500, headers: corsHeaders });
  }

  try {
    const body = await request.json();
    const username = String(body?.username || "").trim().toLowerCase();
    const password = String(body?.password || "");
    if (!/^[a-z0-9][a-z0-9._-]{2,23}$/.test(username) || !password) {
      return invalidCredentials();
    }

    const admin = createClient(projectUrl, serviceRoleKey, {
      auth: { autoRefreshToken: false, persistSession: false },
    });
    const { data: mapping, error: mappingError } = await admin
      .from("smp_usernames")
      .select("user_id")
      .eq("username", username)
      .maybeSingle();
    if (mappingError || !mapping?.user_id) return invalidCredentials();

    const { data: userResult, error: userError } = await admin.auth.admin.getUserById(mapping.user_id);
    const email = userResult?.user?.email;
    if (userError || !email) return invalidCredentials();

    const response = await fetch(`${projectUrl}/auth/v1/token?grant_type=password`, {
      method: "POST",
      headers: { apikey: anonKey, Authorization: `Bearer ${anonKey}`, "Content-Type": "application/json" },
      body: JSON.stringify({ email, password }),
    });
    const payload = await response.json().catch(() => ({}));
    if (!response.ok) return invalidCredentials();
    return Response.json(payload, { headers: corsHeaders });
  } catch {
    return invalidCredentials();
  }
});
