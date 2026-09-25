(() => {
  const root = document.documentElement;
  const saved = localStorage.getItem('popsicle-theme');
  if (saved) root.dataset.theme = saved;
  else if (matchMedia('(prefers-color-scheme: dark)').matches) root.dataset.theme = 'dark';

  const themeBtn = document.querySelector('[data-theme-toggle]');
  if (themeBtn) themeBtn.addEventListener('click', () => {
    const next = root.dataset.theme === 'dark' ? 'light' : 'dark';
    root.dataset.theme = next; localStorage.setItem('popsicle-theme', next);
  });
  const menu = document.querySelector('[data-menu]');
  if (menu) menu.addEventListener('click', () => document.body.classList.toggle('sidebar-open'));
  document.querySelectorAll('.nav-link').forEach(a => a.addEventListener('click', () => document.body.classList.remove('sidebar-open')));

  document.querySelectorAll('pre').forEach(pre => {
    if (pre.querySelector('.copy-btn')) return;
    const b = document.createElement('button'); b.className='copy-btn'; b.type='button'; b.textContent='Copy';
    b.addEventListener('click', async () => {
      const code = pre.querySelector('code')?.innerText || pre.innerText;
      try { await navigator.clipboard.writeText(code); b.textContent='Copied'; setTimeout(()=>b.textContent='Copy',1200); } catch (_) {}
    }); pre.appendChild(b);
  });

  const overlay = document.querySelector('.search-overlay');
  const input = document.querySelector('.search-input');
  const results = document.querySelector('.search-results');
  let index = [];
  fetch('assets/search-index.json').then(r=>r.json()).then(v=>index=v).catch(()=>{});
  function openSearch(){ if(!overlay)return; overlay.classList.add('open'); setTimeout(()=>input?.focus(),0); }
  function closeSearch(){ overlay?.classList.remove('open'); if(input)input.value=''; if(results)results.innerHTML=''; }
  document.querySelectorAll('[data-search]').forEach(b=>b.addEventListener('click',openSearch));
  overlay?.addEventListener('click',e=>{if(e.target===overlay)closeSearch()});
  document.addEventListener('keydown',e=>{
    if((e.metaKey||e.ctrlKey)&&e.key.toLowerCase()==='k'){e.preventDefault();openSearch()}
    if(e.key==='Escape') closeSearch();
  });
  input?.addEventListener('input', () => {
    const q=input.value.trim().toLowerCase();
    if(!q){results.innerHTML='<div class="search-empty">Type to search the Popsicle docs.</div>';return}
    const words=q.split(/\s+/);
    const ranked=index.map(item=>{
      const hay=(item.title+' '+item.description+' '+item.text+' '+item.keywords).toLowerCase();
      let score=0; words.forEach(w=>{if(item.title.toLowerCase().includes(w))score+=8;if(item.keywords.toLowerCase().includes(w))score+=5;if(hay.includes(w))score+=1});
      return {...item,score};
    }).filter(x=>x.score>0).sort((a,b)=>b.score-a.score).slice(0,9);
    results.innerHTML=ranked.length?ranked.map(x=>`<a class="result" href="${x.url}"><strong>${x.title}</strong><span>${x.description}</span></a>`).join(''):'<div class="search-empty">No matching documentation.</div>';
  });
})();