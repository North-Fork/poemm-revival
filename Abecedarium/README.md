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

Open `http://localhost:8080` (or `http://macmighty.local:8080` from another machine on the network).

---

## Usage

Type any letter to spawn a ComplexGlyph. The control panel on the left lets you adjust:

- **Glyph** — font, size
- **Render** — text vs. vector mode; noise layers (Independent: Gaussian + Poisson; Spatially Coherent: Perlin)
- **Colour** — fill, stroke, background
- **Behaviour** — Dance (per-letter character animation: drift, spin, pulse, planted feet)
- **Actions** — Clear, Freeze noise, alphabet auto-run
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

Single self-contained HTML file (`index.html`). No build step. One external dependency: [opentype.js](https://github.com/opentypejs/opentype.js) via CDN for bezier glyph paths.

Two canvases stacked: `#c` (main, captured by video recording and PNG export) and `#ov` (overlay, `pointer-events:none`). Anchors and handles are drawn on `#ov` only.

See `memory/abecedarium.md` (Claude Code memory) for full technical notes.
