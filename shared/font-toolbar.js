/**
 * font-toolbar.js — PoEMM shared font/size/fill/stroke toolbar
 *
 * Classic script (no build step). Exposes window.FontToolbar = { buildFontToolbar, syncFontToolbar }.
 *
 * Usage:
 *   <script src="../shared/font-toolbar.js"></script>
 *   FontToolbar.buildFontToolbar({ container, P, fonts, ensureFont, onChange });
 *   FontToolbar.syncFontToolbar(P);
 *
 * P must have: font, size, fillOn, fillColor, strokeOn, strokeColor, strokeWidth
 * onChange() is called after any P field is written — host syncs glyph, etc.
 */

(function () {
  'use strict';

  // ── CSS (injected once) ────────────────────────────────────────────────────
  const CSS = `
.tb-sep   { width:1px; height:22px; background:#2a2a2a; margin:0 8px; flex-shrink:0; }
.tb-group { display:flex; align-items:center; gap:5px; flex-shrink:0; }
.tb-T     { font-size:18px; font-style:italic; font-family:Georgia,serif;
            color:#7af; padding:0 2px; user-select:none; }
.tb-icon  { font-size:13px; font-style:italic; font-weight:700; color:#555;
            cursor:pointer; padding:2px 4px; border-radius:3px; user-select:none;
            transition:color 0.15s; }
.tb-icon.on { color:#f80; }
.tb-font-btn {
  background:#1a1a1a; color:#ccc; border:1px solid #2a2a2a; border-radius:3px;
  font-size:11px; padding:2px 20px 2px 6px; height:24px; cursor:pointer;
  width:140px; flex-shrink:0; white-space:nowrap; overflow:hidden; text-overflow:ellipsis;
  position:relative;
}
.tb-font-btn::after {
  content:'▾'; position:absolute; right:5px; top:50%; transform:translateY(-50%);
  font-size:10px; pointer-events:none;
}
.tb-font-dropdown {
  display:none; position:fixed; background:#1a1a1a; border:1px solid #444;
  border-radius:4px; z-index:1000; max-height:260px; overflow-y:auto;
  min-width:160px; box-shadow:0 4px 12px rgba(0,0,0,0.6);
}
.tb-font-dropdown.open { display:block; }
.tb-font-option {
  padding:4px 10px; font-size:12px; color:#ccc; cursor:pointer; white-space:nowrap;
}
.tb-font-option:hover, .tb-font-option.active { background:#333; color:#fff; }
.tb-font-option.selected { color:#7af; }
.tb-num {
  background:#1a1a1a; color:#7af; border:1px solid #2a2a2a; border-radius:3px;
  font-size:11px; padding:2px 4px; height:24px; text-align:right;
}
.tb-size-num   { width:50px; }
.tb-weight-num { width:44px; }
.tb-range {
  -webkit-appearance:none; appearance:none;
  background:transparent; flex-shrink:0; cursor:pointer;
}
.tb-range::-webkit-slider-runnable-track {
  height:4px; background:#2a2a2a; border-radius:2px;
}
.tb-range::-webkit-slider-thumb {
  -webkit-appearance:none;
  width:13px; height:13px; border-radius:50%;
  background:#7af; border:none; margin-top:-4.5px;
  transition:background 0.1s;
}
.tb-range:active::-webkit-slider-thumb { background:#3a7fcc; }
.tb-range::-moz-range-track { height:4px; background:#2a2a2a; border-radius:2px; }
.tb-range::-moz-range-thumb { width:13px; height:13px; border-radius:50%; background:#7af; border:none; }
.tb-range:active::-moz-range-thumb { background:#3a7fcc; }
.tb-size-range   { width:72px; }
.tb-weight-range { width:72px; }
.tb-color {
  width:22px; height:22px; padding:1px 2px;
  border:1px solid #2a2a2a; background:#1a1a1a; border-radius:3px; cursor:pointer;
}
`;

  function injectCSS() {
    if (document.getElementById('font-toolbar-css')) return;
    const style = document.createElement('style');
    style.id = 'font-toolbar-css';
    style.textContent = CSS;
    document.head.appendChild(style);
  }

  // ── buildFontToolbar ───────────────────────────────────────────────────────
  /**
   * @param {object} opts
   * @param {HTMLElement} opts.container  - Element to populate (#toolbar div)
   * @param {object}      opts.P          - Params: font, size, fillOn, fillColor,
   *                                        strokeOn, strokeColor, strokeWidth
   * @param {string[]}    opts.fonts      - Available font names
   * @param {function}    opts.ensureFont - (name) => void  load font async
   * @param {function}    opts.onChange   - () => void  called after any P write
   */
  function buildFontToolbar({ container, P, fonts, ensureFont, onChange }) {
    injectCSS();

    container.innerHTML = '';

    function sep() {
      const s = document.createElement('div');
      s.className = 'tb-sep';
      container.appendChild(s);
    }
    function group(...els) {
      const g = document.createElement('div');
      g.className = 'tb-group';
      els.forEach(e => g.appendChild(e));
      container.appendChild(g);
    }

    // ── T icon ──
    const tIcon = document.createElement('span');
    tIcon.className = 'tb-T'; tIcon.textContent = 'T';
    group(tIcon);

    sep();

    // ── Font (custom dropdown for live hover preview) ──
    const fontBtn = document.createElement('button');
    fontBtn.id = 'tb-font'; fontBtn.className = 'tb-font-btn';
    fontBtn.type = 'button'; fontBtn.textContent = P.font;

    const fontDropdown = document.createElement('div');
    fontDropdown.className = 'tb-font-dropdown';

    const fontSample = document.createElement('span');
    fontSample.id = 'tb-font-sample';
    fontSample.textContent = 'Sample';
    fontSample.style.cssText = [
      `font-family:"${P.font}",serif`,
      'font-size:14px', 'color:#ccc', 'white-space:nowrap',
      'pointer-events:none', 'display:inline-block',
      'width:72px', 'height:20px', 'line-height:20px',
      'overflow:hidden', 'text-overflow:ellipsis',
      'vertical-align:middle', 'flex-shrink:0',
    ].join(';');

    fonts.forEach(f => {
      const item = document.createElement('div');
      item.className = 'tb-font-option' + (f === P.font ? ' selected' : '');
      item.dataset.font = f;
      item.textContent = f;
      // Live preview on hover
      item.addEventListener('mouseenter', () => {
        ensureFont(f);
        fontSample.style.fontFamily = `"${f}",serif`;
      });
      // Commit on click
      item.addEventListener('mousedown', e => {
        e.preventDefault();
        P.font = f;
        fontBtn.textContent = f;
        fontSample.style.fontFamily = `"${f}",serif`;
        fontDropdown.querySelectorAll('.tb-font-option').forEach(el =>
          el.classList.toggle('selected', el.dataset.font === f));
        ensureFont(f);
        fontDropdown.classList.remove('open');
        onChange();
      });
      fontDropdown.appendChild(item);
    });

    // Revert sample when mouse leaves without selecting
    fontDropdown.addEventListener('mouseleave', () => {
      fontSample.style.fontFamily = `"${P.font}",serif`;
    });

    // Toggle dropdown
    fontBtn.addEventListener('click', () => {
      const isOpen = fontDropdown.classList.toggle('open');
      if (isOpen) {
        const r = fontBtn.getBoundingClientRect();
        fontDropdown.style.left = r.left + 'px';
        fontDropdown.style.top  = (r.bottom + 2) + 'px';
        const sel = fontDropdown.querySelector('.selected');
        if (sel) sel.scrollIntoView({ block: 'center' });
      }
    });

    // Close on click outside
    document.addEventListener('mousedown', e => {
      if (!fontBtn.contains(e.target) && !fontDropdown.contains(e.target))
        fontDropdown.classList.remove('open');
    }, true);

    // Dropdown in body so it escapes toolbar overflow clipping
    document.body.appendChild(fontDropdown);
    group(fontBtn, fontSample);

    sep();

    // ── Size ──
    const sizeNum = document.createElement('input');
    sizeNum.id = 'tb-size-num'; sizeNum.type = 'number';
    sizeNum.className = 'tb-num tb-size-num';
    sizeNum.min = 12; sizeNum.max = 600; sizeNum.step = 1; sizeNum.value = P.size;

    const sizeRange = document.createElement('input');
    sizeRange.id = 'tb-size-range'; sizeRange.type = 'range';
    sizeRange.className = 'tb-range tb-size-range';
    sizeRange.min = 12; sizeRange.max = 600; sizeRange.step = 1; sizeRange.value = P.size;

    sizeRange.addEventListener('input', () => {
      P.size = parseFloat(sizeRange.value);
      sizeNum.value = P.size;
      onChange();
    });
    function commitSize() {
      let v = Math.max(12, Math.min(600, Math.round(parseFloat(sizeNum.value))));
      if (isNaN(v)) v = P.size;
      P.size = v; sizeNum.value = v; sizeRange.value = v;
      onChange();
    }
    sizeNum.addEventListener('change', commitSize);
    sizeNum.addEventListener('keydown', e => { if (e.key === 'Enter') sizeNum.blur(); });

    group(sizeNum, sizeRange);

    sep();

    // ── Fill ──
    const fillIcon = document.createElement('span');
    fillIcon.id = 'tb-fill-icon';
    fillIcon.className = 'tb-icon' + (P.fillOn ? ' on' : '');
    fillIcon.textContent = 'F'; fillIcon.title = 'Toggle fill';
    fillIcon.addEventListener('click', () => {
      P.fillOn = !P.fillOn;
      fillIcon.classList.toggle('on', P.fillOn);
      onChange();
    });

    const fillColor = document.createElement('input');
    fillColor.id = 'tb-fill-color'; fillColor.type = 'color';
    fillColor.className = 'tb-color'; fillColor.value = P.fillColor;
    fillColor.addEventListener('input', () => {
      P.fillColor = fillColor.value;
      onChange();
    });

    group(fillIcon, fillColor);

    sep();

    // ── Stroke ──
    const strokeIcon = document.createElement('span');
    strokeIcon.id = 'tb-stroke-icon';
    strokeIcon.className = 'tb-icon' + (P.strokeOn ? ' on' : '');
    strokeIcon.textContent = 'S'; strokeIcon.title = 'Toggle stroke';
    strokeIcon.addEventListener('click', () => {
      P.strokeOn = !P.strokeOn;
      strokeIcon.classList.toggle('on', P.strokeOn);
      onChange();
    });

    const strokeColor = document.createElement('input');
    strokeColor.id = 'tb-stroke-color'; strokeColor.type = 'color';
    strokeColor.className = 'tb-color'; strokeColor.value = P.strokeColor;
    strokeColor.addEventListener('input', () => {
      P.strokeColor = strokeColor.value;
      onChange();
    });

    const weightNum = document.createElement('input');
    weightNum.id = 'tb-weight-num'; weightNum.type = 'number';
    weightNum.className = 'tb-num tb-weight-num';
    weightNum.min = 1; weightNum.max = 100; weightNum.step = 1; weightNum.value = P.strokeWidth;

    const weightRange = document.createElement('input');
    weightRange.id = 'tb-weight-range'; weightRange.type = 'range';
    weightRange.className = 'tb-range tb-weight-range';
    weightRange.min = 1; weightRange.max = 100; weightRange.step = 1; weightRange.value = P.strokeWidth;

    weightRange.addEventListener('input', () => {
      P.strokeWidth = parseInt(weightRange.value, 10);
      weightNum.value = P.strokeWidth;
      onChange();
    });
    function commitWeight() {
      let v = Math.max(1, Math.min(100, Math.round(parseFloat(weightNum.value))));
      if (isNaN(v)) v = P.strokeWidth;
      P.strokeWidth = v; weightNum.value = v; weightRange.value = v;
      onChange();
    }
    weightNum.addEventListener('change', commitWeight);
    weightNum.addEventListener('keydown', e => { if (e.key === 'Enter') weightNum.blur(); });

    group(strokeIcon, strokeColor, weightNum, weightRange);
  }

  // ── syncFontToolbar ────────────────────────────────────────────────────────
  /**
   * Re-reads P and updates all toolbar controls. Call after file load.
   * @param {object} P - same params object passed to buildFontToolbar
   */
  function syncFontToolbar(P) {
    const fontBtn    = document.getElementById('tb-font');
    const sizeNum    = document.getElementById('tb-size-num');
    const sizeRange  = document.getElementById('tb-size-range');
    const fillIcon   = document.getElementById('tb-fill-icon');
    const fillColor  = document.getElementById('tb-fill-color');
    const strokeIcon = document.getElementById('tb-stroke-icon');
    const strokeColor= document.getElementById('tb-stroke-color');
    const weightNum  = document.getElementById('tb-weight-num');
    const weightRange= document.getElementById('tb-weight-range');

    if (fontBtn) {
      fontBtn.textContent = P.font;
      const dd = document.querySelector('.tb-font-dropdown');
      if (dd) dd.querySelectorAll('.tb-font-option').forEach(el =>
        el.classList.toggle('selected', el.dataset.font === P.font));
    }
    const fontSample = document.getElementById('tb-font-sample');
    if (fontSample) fontSample.style.fontFamily = `"${P.font}",serif`;
    if (sizeNum)     sizeNum.value      = P.size;
    if (sizeRange)   sizeRange.value    = P.size;
    if (fillIcon)    fillIcon.classList.toggle('on', P.fillOn);
    if (fillColor)   fillColor.value    = P.fillColor;
    if (strokeIcon)  strokeIcon.classList.toggle('on', P.strokeOn);
    if (strokeColor) strokeColor.value  = P.strokeColor;
    if (weightNum)   weightNum.value    = P.strokeWidth;
    if (weightRange) weightRange.value  = P.strokeWidth;
  }

  // ── Export ─────────────────────────────────────────────────────────────────
  window.FontToolbar = { buildFontToolbar, syncFontToolbar };

})();
