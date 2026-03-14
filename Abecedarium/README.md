# Abecedarium

A browser lab for the **ComplexGlyph (CG)** — a letter as an autonomous agent with physics, editable bezier paths, and layered noise. Foundation for a future dynamic agentic text editor.

Part of the **PoEMM** (Poetry for Excitable [Mobile] Media) revitalization project.

---

## Running

Requires the custom dev server (serves static files; plain `python3 -m http.server` will not work):

```bash
cd Abecedarium
python3 server.py 8080
```

Open `http://localhost:8080/Abecedarium/` (or `http://macmighty.local:8080/Abecedarium/` from another machine on the network).

> **Note:** The server roots at `PoEMM/` (one level up from `Abecedarium/`) so that the shared `PoEMM/shared/` directory is accessible to all PoEMM projects.

---

## Usage

Type any letter to spawn a ComplexGlyph. The control panel on the left lets you adjust:

- **Glyph** — font, size
- **Render** — text vs. vector mode; noise layers (Independent: Gaussian + Poisson; Spatially Coherent: Perlin)
- **Colour** — fill, stroke, background
- **Behaviour** — Dance (per-letter character animation: drift, spin, pulse, planted feet)
- **Actions** — Clear, Freeze/Unfreeze (pauses the clock — behaviours stay attached), alphabet auto-run
- **File** — Save / Load / Print (PNG) / Record video

### URL shortcut

`?char=A` — spawns that letter at 400pt with Dance active. Useful for per-letter review.

---

## File / Save

All saves go directly to the OS via blob download. Whether the browser prompts for a save location or silently saves to Downloads depends on your browser's **"Ask where to save files"** setting (Brave: Settings → Downloads; Safari: Preferences → General).

- **Save** — downloads `{char}-{font}.abcd.json` to your machine
- **Load** — opens OS file picker; accepts `.abcd.json` and `.json`
- **Print** — DPI dialog (default 300) → downloads `{char}-{font}-{dpi}dpi.png`

---

## Video Recording

- Click **Record** in the File section — button turns red and shows elapsed time
- Click **Stop Record** — downloads `{char}-{font}-{timestamp}.mp4` (or `.webm`)
- Anchors and handles are on a separate overlay canvas and **never appear in recordings**
- **Cursor checkbox** (next to Record): when enabled, a ✊ cursor is drawn on the canvas whenever the mouse button is held down — appears in recordings

---

## Alphabet Auto-run

In the **Actions** section:

- **abcde…** — cycles through A–Z (or a–z) with Dance active on each letter
- **Dwell** — seconds per letter (number input, default 5)
- **ABC/abc** — toggle uppercase / lowercase
- While running: drag the glyph to reposition; position is preserved when the next letter appears; holding the mouse button across a transition keeps the drag active
- Combine with **Record** to capture a full alphabet run as video

---

## Architecture

Single self-contained HTML file (`index.html`). No build step. External dependencies:
- [opentype.js](https://github.com/opentypejs/opentype.js) via CDN — bezier glyph paths
- `font-toolbar.js` — symlink to `PoEMM/shared/font-toolbar.js`; shared font/size/fill/stroke toolbar

Two canvases stacked: `#c` (main, captured by video recording and PNG export) and `#ov` (overlay, `pointer-events:none`). Anchors and handles are drawn on `#ov` only.

### font-toolbar.js symlink

`Abecedarium/font-toolbar.js` is a symlink → `../shared/font-toolbar.js`. This lets the toolbar load correctly both via the dev server and by opening `index.html` directly (`file://`). Edit only the shared file — changes are immediately reflected here.

### Making a standalone file

To produce a single portable HTML with the toolbar inlined (no symlink dependency):

```bash
# run from PoEMM/
python3 shared/inline-toolbar.py Abecedarium/index.html
# → writes Abecedarium/index-standalone.html
```

See Claude Code memory (`abecedarium.md`) for full technical notes.
