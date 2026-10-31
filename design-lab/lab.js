/* GungeonMate design lab — view toolbar.
   Injects a fixed toolbar above every view page:
     [width presets] [text-scale] [back to hub]
   Phone widths model the app's ScreenProfile breakpoints:
     320/360/390/430 = compact (<600) · 768 = medium (600-839)
   Text scale ≈ MediaQuery textScaler (accessibility test = 1.3x). */

(function () {
  const SIZES = [
    { w: 320, h: 640, label: '320' },
    { w: 360, h: 720, label: '360' },
    { w: 390, h: 844, label: '390' },
    { w: 430, h: 932, label: '430' },
    { w: 768, h: 1024, label: '768' },
  ];
  const SCALES = [1, 1.3];

  const store = {
    get w() { return +(localStorage.getItem('gm-lab-w') || 390); },
    set w(v) { localStorage.setItem('gm-lab-w', v); },
    get ts() { return +(localStorage.getItem('gm-lab-ts') || 1); },
    set ts(v) { localStorage.setItem('gm-lab-ts', v); },
  };

  function apply() {
    const frame = document.querySelector('.phone-frame');
    const size = SIZES.find((s) => s.w === store.w) || SIZES[2];
    document.querySelectorAll('.phone-frame').forEach((f) => {
      f.style.width = size.w + 'px';
      f.style.height = size.h + 'px';
      const tag = f.querySelector('.frame-tag');
      if (tag) tag.textContent = size.label + 'dp';
    });
    document.documentElement.style.setProperty('--text-scale', store.ts);
    document.querySelectorAll('[data-w]').forEach((b) =>
      b.classList.toggle('on', +b.dataset.w === store.w)
    );
    document.querySelectorAll('[data-ts]').forEach((b) =>
      b.classList.toggle('on', +b.dataset.ts === store.ts)
    );
    void frame;
  }

  function build() {
    const bar = document.createElement('div');
    bar.className = 'lab-toolbar';
    bar.innerHTML =
      '<a href="../index.html">&larr; LAB</a>' +
      '<span class="lbl">width</span>' +
      SIZES.map((s) => `<button data-w="${s.w}">${s.label}</button>`).join('') +
      '<span class="lbl">text</span>' +
      SCALES.map((s) => `<button data-ts="${s}">${s}&times;</button>`).join('') +
      '<span class="sep"></span>' +
      '<a href="../tokens.html">tokens</a>';
    document.body.prepend(bar);
    bar.addEventListener('click', (e) => {
      const b = e.target.closest('button');
      if (!b) return;
      if (b.dataset.w) store.w = +b.dataset.w;
      if (b.dataset.ts) store.ts = +b.dataset.ts;
      apply();
    });
    apply();
  }

  document.readyState === 'loading'
    ? document.addEventListener('DOMContentLoaded', build)
    : build();
})();
