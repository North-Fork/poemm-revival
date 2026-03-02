# PoEMM Architecture Notes

This folder contains general technical notes for the PoEMM coding experiments.

## Files

| File | Contents |
|------|----------|
| `poemm-behaviour-inventory.md` | Full inventory of behaviours across all 8 poems |
| `poemm-cvc-port-paul.txt` | Full Q&A notes on porting PoEMM to VCV Rack |

## Memory files (Claude Code session memory)

Detailed reference notes are stored in the Claude Code memory directory:

| Topic | File |
|-------|------|
| Porting landscape (all routes) | `memory/porting-landscape.md` |
| VCV Rack specifics | `memory/vcv.md` |
| ObjC / Java codebase details | `memory/codebase.md` |
| JS behaviour experiments | `memory/behaviour-experiments.md` |

Memory files live at:
`/Users/jasonlocal/.claude/projects/-Users-jasonlocal-Documents-Coding-Experiments/memory/`

## PoEMM Sketch / Experiment Rules

**Every PoEMM sketch or experiment HTML file must include a control panel** modelled on the one in `PoEMM-Sandbox/index.html`:

- Fixed left sidebar, **240px wide**, full height, dark background (`#111`), 1px right border
- **Collapsible sections** (`<h3>` or `.sec-hd`) with ▾/▸ toggle and `.sec-bd.hidden` class
- **Poem text** — a `<textarea id="poem-input">` at the top for live text editing
- **Behaviour toggles** — checkboxes (`.beh-row`) for any named behaviours
- **Parameter sliders** (`.param-row`) with label, live numeric readout in blue (`#7af`), and a styled `<input type="range">`
- **Color pickers** (`.color-row`) for text color, background color, and any other color params
- **Rebuild button** (`#rebuild-btn`) to re-initialise the scene with current settings
- **Canvas** positioned to the right of the panel (`left: 240px`), filling remaining space; use `window.devicePixelRatio` scaling
- Panel CSS and behaviour must be self-contained in the single HTML file (no external dependencies)

## NextText Framework

NextText is the underlying framework for all PoEMM works.

- **Repository:** https://github.com/prisonerjohn/NextText
- **Language:** Processing/Java library (`net.nexttext` package)
- **Co-created by:** Bruno Nadeau (Jason's PoEMM collaborator)

### Text Hierarchy (top → bottom)

```
Book → Page → TextObjectGroup (passage/line) → TextObjectGlyph (glyph)
```
In PoEMM terms: book → passage → line → word → glyph

### Behaviour System

- Behaviours can be applied at any level of the hierarchy and stack on top of each other
- e.g. apply Shake to a word → whole word shakes
- e.g. also apply Flicker to the first two glyphs → those letters flicker AND shake simultaneously
- The JS port uses stateless singleton behaviour objects with `apply(node, dt, book)`; per-node state stored on node via Symbol keys

### Key Classes

- `Book`, `TextObject`, `TextObjectGroup`, `TextObjectGlyph`
- `TextObjectBuilder`, `TextObjectRoot`
- Sub-packages: `behaviour/`, `input/`, `property/`, `renderer/`

### Ports

| Platform | Language | Used for |
|----------|----------|----------|
| iOS apps | Objective-C | Mobile PoEMM releases |
| Gallery builds | Java/Processing | macOS 50" touchscreens |
| Web port | JavaScript | Revitalization / new work |

The JS port mirrors the hierarchy with `NTBook`, `NTTextObject`, `NTWord`, `NTGlyph`.

---

## Glyphkicker — JS Experiment

`PoEMM/Glyphkicker/index.html` — single self-contained HTML file, no build step.

### Architecture overview

**ECS layer (v1):** Each glyph is an agent `{ id, char, index, homeX/homeY, x/y, rotation, scale, dynamics, material, geometry, interaction, behaviours[], _state, mailbox, stateMachine, rng }`. Stateless behaviour singletons (`apply(g, dt, bCtx, params)`) run each frame.

**Agent layer (v2):** Adds message-passing and optional per-glyph state machines on top.

| Concept | Description |
|---------|-------------|
| `g.mailbox[]` | Message queue, drained each frame by AgentEngine |
| `g.stateMachine` | Optional SM instance from `makeStateMachine()` |
| `AgentEngine` | Module-level singleton; 7-phase `processFrame(dt, bCtx)` |
| `makeStateMachine(statesDef, initial)` | Returns `{ init, receive, currentState, detach }` |
| `contagionStates` | Demo SM: idle ↔ excited (Shake+Flicker, 80px broadcast, 3s timer) |
| `attachContagion(glyphs)` / `detachContagion(glyphs)` | Attach/remove contagion SM from all printable glyphs |

**AgentEngine phases:**
1. Timer delivery (fire due timers → mailbox, immediate)
2. System messages (`tick`, `pointer-near`, `pointer-exit`) — SM glyphs only
3. Mailbox drain → `sm.receive()` — sends during processing go to `_outbox` (one-frame delay)
4. Flush `_outbox` to target mailboxes
5. Tick behaviours (v1 unchanged)
6. Dynamics integration + damping (v1 unchanged)
7. Particle step (v1 unchanged)

**`bCtx`** passed to all behaviours and SM callbacks: `{ glyphs, inputState, time, engine: AgentEngine }`

**SM behaviour management:** SM tracks `_injected[]`; auto-spliced on exit/detach. User-added behaviours never touched.

### Panel sections
- **Type** — font family, size, justify
- **Colour** — text, background
- **Mode** — Type / Select toggle
- **Agent** — Attach/Detach Contagion toggle (permanent, outside selectionPanel)
- **Behaviours** — per-selection behaviour instances + param sliders (Select mode)
- **Geometry** — outline2d / particles toggle + particle params (Select mode)
- **Agent** (in selectionPanel) — message-type input + Send button; SM state display in bPanel header

---

## Context

PoEMM = Poetry for Excitable [Mobile] Media. See MEMORY.md for full project overview.
The source codebases (ObjC iOS + Java/Processing) are at `/Users/jasonlocal/Documents/Coding-Experiments/`.
