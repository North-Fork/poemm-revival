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

## Context

PoEMM = Poetry for Excitable [Mobile] Media. See MEMORY.md for full project overview.
The source codebases (ObjC iOS + Java/Processing) are at `/Users/jasonlocal/Documents/Coding-Experiments/`.
