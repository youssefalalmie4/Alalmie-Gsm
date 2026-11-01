const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "GET, OPTIONS",
  "Content-Type": "application/json; charset=utf-8",
};

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (request.method !== "GET") {
    return Response.json({ error: "Method not allowed" }, { status: 405, headers: corsHeaders });
  }

  const projectUrl = Deno.env.get("SUPABASE_URL");
  const publicKey = Deno.env.get("SUPABASE_ANON_KEY");
  if (!projectUrl || !publicKey) {
    return Response.json({ error: "Supabase server configuration is incomplete" }, { status: 500, headers: corsHeaders });
  }

  const url = new URL("/rest/v1/protector_groups", projectUrl);
  url.searchParams.set("select", "group_code,brand,family,joker,source_snapshot");
  url.searchParams.set("order", "group_code.asc");

  try {
    const response = await fetch(url, {
      headers: { apikey: publicKey, Authorization: "Bearer " + publicKey },
    });
    if (!response.ok) {
      return Response.json({ error: "Catalog query failed" }, { status: 502, headers: corsHeaders });
    }
    const rows = await response.json();
    const groups = rows.map((row: { group_code: string; brand: string; family: string; joker: string }) => ({
      group: row.group_code,
      brand: row.brand,
      family: row.family,
      joker: row.joker,
    }));
    return Response.json({
      groups,
      sourceSnapshot: "2026-11-01",
      source: "Joker screen protector catalog",
    }, { headers: corsHeaders });
  } catch {
    return Response.json({ error: "Unable to reach the catalog database" }, { status: 502, headers: corsHeaders });
  }
});
