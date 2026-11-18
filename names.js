/* Prénoms : rangés dans la base (lists, id « config »), visibles seulement une fois connecté.
   Les éléments [data-nm="s"], [data-nm="w"] et [data-nm="duo"] sont remplis après la connexion. */
window.NAMES = { s: '', w: '' };
window.duoNames = () => (NAMES.s && NAMES.w) ? NAMES.s + ' & ' + NAMES.w : '';
window.applyNames = () => {
  document.querySelectorAll('[data-nm]').forEach(el => {
    const k = el.dataset.nm, v = k === 'duo' ? duoNames() : NAMES[k];
    if (v) { if (el.dataset.nmAttr) el.setAttribute(el.dataset.nmAttr, v); else el.textContent = v; }
  });
  const base = document.documentElement.dataset.title;
  if (base) document.title = duoNames() ? base + ' · ' + duoNames() : base;
};
window.loadNames = async (client) => {
  try {
    const { data } = await client.from('lists').select('state').eq('id', 'config').maybeSingle();
    if (data && data.state) { NAMES.s = data.state.s || ''; NAMES.w = data.state.w || ''; }
  } catch (e) {}
  applyNames();
  document.dispatchEvent(new Event('names'));
  return NAMES;
};
