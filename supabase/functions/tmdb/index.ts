// Relais TMDB : ajoute le jeton (secret TMDB_TOKEN) et n'accepte que les membres connectés de la watchlist.
const ALLOWED = (Deno.env.get("ALLOWED_EMAILS") || "").toLowerCase().split(",").map((s) => s.trim()).filter(Boolean);
const PATHS = /^\/(search\/(multi|movie|tv|collection|person)|movie\/\d+|tv\/\d+|collection\/\d+|movie\/\d+\/[a-z_]+|tv\/\d+\/[a-z_]+)$/;
const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, apikey, content-type, x-client-info",
  "Access-Control-Allow-Methods": "GET, OPTIONS",
};
function claims(req: Request) {
  const t = (req.headers.get("authorization") || "").replace(/^Bearer\s+/i, "");
  try { return JSON.parse(atob(t.split(".")[1].replace(/-/g, "+").replace(/_/g, "/"))); } catch { return null; }
}
Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  const c = claims(req); // signature déjà vérifiée par la passerelle (verify_jwt)
  if (!c || c.role !== "authenticated" || !ALLOWED.includes(String(c.email || "").toLowerCase()))
    return new Response(JSON.stringify({ error: "non autorisé" }), { status: 401, headers: { ...cors, "content-type": "application/json" } });
  const u = new URL(req.url);
  const path = u.searchParams.get("path") || "";
  if (!PATHS.test(path)) return new Response(JSON.stringify({ error: "chemin refusé" }), { status: 400, headers: { ...cors, "content-type": "application/json" } });
  const q = new URLSearchParams(u.searchParams); q.delete("path");
  if (!q.has("language")) q.set("language", "fr-FR");
  const r = await fetch(`https://api.themoviedb.org/3${path}?${q}`, { headers: { Authorization: `Bearer ${Deno.env.get("TMDB_TOKEN")}`, accept: "application/json" } });
  return new Response(await r.text(), { status: r.status, headers: { ...cors, "content-type": "application/json", "cache-control": "private, max-age=3600" } });
});
