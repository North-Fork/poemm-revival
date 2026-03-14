# Glyphkicker

A browser typography lab built on the PoEMM agent/behaviour framework. Individual glyphs are autonomous agents that can be assigned emergent behaviours — contagion spreading, predator/prey dynamics, and more.

Part of the **PoEMM** (Poetry for Excitable [Mobile] Media) revitalization project.

---

## Running

Serve via the Abecedarium dev server (roots at `PoEMM/` so both projects are accessible):

```bash
cd ../Abecedarium
python3 server.py 8080
```

Open `http://localhost:8080/Glyphkicker/` (or `http://macmighty.local:8080/Glyphkicker/` from another machine).

---

## Usage

### Modes

- **Type mode** — click canvas and type to place glyphs
- **Select mode** — click or drag-select glyphs; apply behaviours to selection

### Top toolbar (font controls)

Font family, size, fill (F), fill colour, stroke (S), stroke colour, and stroke weight. Shared with Abecedarium via `PoEMM/shared/font-toolbar.js`.

### Left panel

- **Type** — font, size, justification (Left / Centre / Right)
- **Colour** — text colour, background colour
- **Mode** — Type / Select toggle
- **Agent** — Attach/Detach Contagion; Attach/Detach Predator/Prey (with param sliders when active)
- **Behaviours** — per-selection behaviour instances and sliders (Select mode)
- **Geometry** — outline2d / particles toggle + params (Select mode)

### Behaviours

| Behaviour | Description |
|-----------|-------------|
| Contagion | Idle ↔ Excited state machine; excitement spreads within 80px, 3s timer |
| Predator/Prey | Selected glyphs become predators (ChasePointer); remainder become prey (Flee) |
| Shake, Flicker, SpringHome, Drift, … | Stack freely on any glyph or selection |

### Agent messaging (Select mode)

Type a message type in the input at the bottom of the Agent section and click **Send** to deliver it to all selected glyphs' state machines.

---

## Architecture

Single self-contained HTML file (`index.html`). No build step. External dependency:
- `font-toolbar.js` — symlink to `PoEMM/shared/font-toolbar.js`; shared font/size/fill/stroke toolbar

### font-toolbar.js symlink

`Glyphkicker/font-toolbar.js` is a symlink → `../shared/font-toolbar.js`. This lets the toolbar load correctly both via the dev server and by opening `index.html` directly (`file://`). Edit only the shared file — changes are immediately reflected here.

### Making a standalone file

To produce a single portable HTML with the toolbar inlined (no symlink dependency):

```bash
# run from PoEMM/
python3 shared/inline-toolbar.py Glyphkicker/index.html
# → writes Glyphkicker/index-standalone.html
```

### Key globals

| Name | Description |
|------|-------------|
| `PARAMS` | `{ fontFamily, fontPt, fillOn, fillColor, strokeOn, strokeColor, strokeWidth, background, justify, bounceEdges }` |
| `AgentEngine` | 7-phase frame loop: timers → system messages → mailbox drain → flush outbox → behaviour tick → dynamics → particles |
| `glyphs[]` | All active glyph agents |
| `selectedGlyphs[]` | Current selection |
| `editorMode` | `'type'` or `'select'` |

### Behaviour system

Stateless behaviour singletons with `apply(g, dt, bCtx, params)`. Per-glyph state stored via Symbol keys. Behaviours stack freely.

### State machines

`makeStateMachine(statesDef, initial)` — optional per-glyph SM. Tag-scoped attach/detach helpers (`attachContagion` / `detachContagion`, `attachPredatorPrey` / `detachPredatorPrey`).
