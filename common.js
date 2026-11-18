/* Commun à toutes les pages : connexion Supabase partagée */
window.SB_URL = 'https://tyzbletpcxdcrzseffyn.supabase.co';
window.SB_KEY = 'sb_publishable_pyhRVcvG17njHvw3IJ-Obg_2yWfQpPJ';
window.sb = window.supabase ? window.supabase.createClient(window.SB_URL, window.SB_KEY) : null;
/* Renvoie la session, ou redirige vers l'accueil pour se connecter */
window.needAuth = async function(){
  if (!window.sb) throw new Error('supabase');
  const { data: { session } } = await window.sb.auth.getSession();
  if (!session) { location.replace('./?next=' + encodeURIComponent(location.pathname.split('/').pop() || '')); throw new Error('auth'); }
  return session;
};
