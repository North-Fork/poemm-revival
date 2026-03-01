# Glyphkicker — Claude's Analysis and Development Notes

## Source
Based on: Lewis, J.E. and Nadeau, B. (2010) 'Post PostScript please', *Digital Creativity*, 21:1, 18–29.
Brainstorm architecture: `/Glyphkicker/brainstorm/Architecture/`

---

## Summary of "Post PostScript Please"

**Core argument:** Current font formats (TrueType, OpenType, PostScript) were built for print in the 1980s–90s and are fundamentally hostile to working programmatically at the level of individual letterforms. Digital writers need a new format — **ComplexType** — designed from scratch for the screen.

**The print paradigm problem:**
- Kerning tables, grid-based rendering, fidelity-to-paper — all optimized for simulating print
- Even the most adventurous experiments (Beowolf, Move Me MM, PostScript Type 3) were dead ends because they couldn't escape the OpenType/TrueType import requirement
- The binary kerning flag encodes the grid-like aesthetic of centuries of movable type

**What a ComplexType glyph should be able to do:**
- Move through space, have a lifespan, respond to the reader
- Respond to other glyphs
- Process external data sources
- Communicate across a network
- Change, evolve, and mutate over time

**The authoring insight — the most important section for Glyphkicker:**

> *"Making work which provides a reading experience as rich as its dynamic and interactive experience requires that the author be able to directly engage temporal change, interactivity, network connectivity, etc. as part of a conscious strategy of meaning making **within** the writing process."*

The tool must let writers shape letterform behaviour *while writing*, not as a post-production step. The poems *Dependency*, *History*, and *Stand Under* demonstrate this: the visual behaviour of letters **is** the meaning, not decoration applied after.

---

## Comparison: Claude's Initial Plan vs. Brainstorm Architecture

### Where they agree
Both land on the same core: glyphs as computational agents, layered text hierarchy, behaviours as the primary mechanism, Canvas2D rendering, particles as first-class geometry.

### Key differences

| Issue | Claude's plan | Brainstorm |
|---|---|---|
| Framing | Working authoring tool | Format standard (RFC/CTF package) |
| Glyph model | Property bag + behaviour list | ECS: GeometryComponent, MaterialComponent, DynamicsComponent, InteractionComponent, StateMachine |
| Geometry | Assumes particles | Pluggable GeometryProvider (particles, strokes, outline2d, bitmap, custom) |
| Determinism | Not addressed | Seeded RNG per glyph, fixed timestep, record/replay |
| Hierarchy | Document → Passage → Line → **Word** → Glyph | TextBlock → Line → Glyph (Word missing) |
| Behaviour cascade | Top-down: Word behaviour cascades to its Glyphs | interGlyphRelations at Line level only |
| Authoring UX | Addressed (inline selection → behaviour panel) | Not addressed |
| Scope | Single-file HTML prototype | Production system with Worker/WASM, NetworkLayer, PhysicsEngine solvers |

### Synthesis
Take the best of both:

| From the brainstorm | From Claude's plan |
|---|---|
| ECS component model per glyph | Word as explicit hierarchy level |
| GeometryProvider abstraction | Behaviour cascade top-down (Word → Glyphs) |
| Seeded RNG + determinism | Writing-first authoring UX |
| Formal glyph id + codepoint | Single-file HTML prototype to start |
| Layout modes: flow / freeform | Simple JSON save format |

Defer: CTF package format, NetworkLayer, ExternalDataSources, Worker/WASM sandboxing.

---

## Glyphkicker v1 Spec

### Guiding principle
A writer types text and immediately sees live glyph agents. Selecting any span of text — one glyph, a word, a line, a passage — opens a behaviour panel. Assigning and tuning behaviours is part of the act of composition, not post-processing.

---

### Text Hierarchy

```
Document
  └── Passage  (one or more blocks; separated by blank lines)
        └── Line
              └── Word
                    └── Glyph  (leaf agent)
```

Each node (at any level) carries:
- `id` — unique string
- `text` — string content
- `behaviours[]` — ordered list of active behaviour instances
- `style` — local typographic overrides (font, size, color, opacity)
- `transform` — position (x, y), rotation, scale — offset from home position
- `homeTransform` — the computed typographic layout position (read-only)

Behaviours assigned at a higher level cascade down to all descendants. A behaviour on a Word applies to each of its Glyphs. Multiple behaviours on the same node stack and all run each frame.

---

### Glyph Agent (leaf node)

Each Glyph is a live agent with:

```js
{
  id,
  codepoint,        // Unicode code point
  char,             // rendered character

  // ECS components
  geometry,         // { type: 'outline2d' | 'particles', data: {...} }
  material,         // { fill, stroke, strokeWidth, opacity, blendMode }
  dynamics,         // velocity, angular velocity, damping
  interaction,      // pointer hover/click handlers
  stateMachine,     // optional: named states + transitions

  // position
  transform,        // { x, y, rotation, scale }
  homeTransform,    // typographic home { x, y, rotation:0, scale:1 }

  // behaviour state (keyed by Symbol, one entry per behaviour instance)
  _state: Map<Symbol, object>,

  // seeded RNG (determinism)
  rng,              // seeded from id hash at spawn time
}
```

---

### GeometryProvider

Two providers required for v1; others deferred:

| Type | Description |
|---|---|
| `outline2d` | Plain `ctx.fillText()` — the default, zero setup cost |
| `particles` | Alpha-mask particle system ported from `particle-test-flocking-07.html` |

Behaviours receive the glyph node and do not need to know which geometry type is active — they operate on `transform`, `dynamics`, and `material` only. Geometry-specific behaviours (e.g. particle flocking) check `glyph.geometry.type` and no-op if not applicable.

---

### Behaviour System

Stateless singleton objects. Same pattern as the particle experiments:

```js
behaviour.apply(glyph, dt, context)
// context = { document, inputState, time }
```

- Per-glyph state stored in `glyph._state.get(behaviourSymbol)`
- Behaviours stack — all run each frame in order
- Cascade: when applied to a Word/Line/Passage, the engine calls `apply()` on every descendant Glyph

**v1 behaviour palette** (drawn from PoEMM inventory):

| Behaviour | Operates on | Description |
|---|---|---|
| Drift | transform | Slow random walk away from home |
| Wander | transform | Autonomous movement toward a changing target |
| Shake | transform | Rapid small oscillation around current position |
| Flicker | material.opacity | Alpha oscillation |
| Pulse | transform.scale | Size oscillation |
| Gravity | dynamics | Falls toward a floor; bounces |
| Attract | transform | Pulled toward pointer or a named anchor |
| Repel | transform | Pushed away from pointer or neighbouring glyphs |
| SpringHome | transform | Elastic return toward home position |
| Orbit | transform | Circular motion around a point |

Each behaviour has a parameter set (amplitude, speed, radius, etc.) tunable per instance.

---

### Rendering Loop

```
each frame:
  1. poll input (pointer, keyboard)
  2. tick time (fixed timestep: 1/60s; accumulate remainder)
  3. for each Glyph (depth-first, document order):
       a. apply all cascaded behaviours (top-down from Document → Glyph)
       b. integrate dynamics (velocity → position)
       c. clamp to canvas bounds if configured
  4. clear canvas
  5. for each Glyph:
       a. save ctx; apply transform
       b. dispatch to GeometryProvider.render()
       c. restore ctx
  6. draw editor overlay (cursor, selection highlight, behaviour tags)
```

Fixed timestep (1/60s) with remainder accumulation ensures deterministic simulation regardless of display refresh rate.

---

### Determinism

- Each Glyph gets a **seeded RNG** derived from its `id` hash at spawn time
- All random values in behaviours draw from `glyph.rng`, not `Math.random()`
- Fixed timestep means same seed → same visual output every time
- (Record/replay deferred to v2)

---

### Authoring Interface

**Layout:** Split view — left panel (240px) for controls, canvas fills the rest.

**Writing area:** A `<textarea>` (or `contenteditable`) overlaid on the canvas. Typing updates the document model live; each new character spawns a Glyph agent at its typographic home position.

**Selection:** Click or click-drag selects at Glyph granularity. Double-click selects a Word. Triple-click selects a Line. The selection can span mixed hierarchy levels; behaviours are assigned to the deepest common ancestor.

**Behaviour panel** (in the left sidebar, per selection):
- Shows the text hierarchy level of the current selection
- Lists active behaviours with parameter sliders
- Add button opens a behaviour palette picker
- Remove button on each behaviour
- Changes take effect immediately on the live canvas

**Global controls:**
- Font family, font size
- Background colour
- Freeze / Unfreeze
- Rebuild (re-layout from scratch)
- PNG export

---

### Save Format (v1 JSON)

```json
{
  "version": "1",
  "meta": { "title": "", "author": "", "created": "" },
  "style": { "fontFamily": "Gill Sans", "fontSize": 48, "color": "#ffffff", "background": "#000000" },
  "passages": [
    {
      "id": "p0",
      "behaviours": [],
      "lines": [
        {
          "id": "p0-l0",
          "behaviours": [],
          "words": [
            {
              "id": "p0-l0-w0",
              "text": "electric",
              "behaviours": [{ "type": "Shake", "amplitude": 5, "speed": 8 }],
              "glyphs": [
                {
                  "id": "p0-l0-w0-g0",
                  "char": "e",
                  "behaviours": [{ "type": "Flicker", "rate": 2, "min": 0.2 }]
                }
              ]
            }
          ]
        }
      ]
    }
  ]
}
```

Behaviours at higher levels are stored on the node that owns them; the engine cascades at runtime, not in the file.

---

### Open Questions (to resolve before building)

1. **Writing interface feel** ✓ — Text editor feel. Glyphs can still be moved anywhere; `homeTransform` and `transform` are separate. New glyphs spawn by **interpolating** between their logical neighbours' current visual positions. Plan to move to **Home is always now** (layout continuously recomputes home, glyphs drift relative to a moving anchor) in a future version.
2. **Layout model** ✓ — Flow layout. Glyphs start in proper typographic layout (lines, word spacing, kerning). Behaviours and dragging move them away from home. A glyph can be moved anywhere including off-canvas, but home is always known and a SpringHome behaviour can return it.
3. **Geometry default** ✓ — Both `outline2d` (vector) and `particles` from day one. GeometryProvider abstraction means each glyph can be either; the behaviour system doesn't care which.
4. **Particle mode** ✓ — Clean rewrite for the new architecture (glyph as agent, ECS components, seeded RNG), but port all behaviours from `particle-test-flocking-07.html`: flocking (separation, alignment, cohesion), crystallisation, Outside, wall avoidance, return-to-birth-position. The particle system becomes a GeometryProvider that the glyph agent owns, not a standalone experiment.

---

## Build Order

1. ✅ **Scaffolding** — canvas, text editor overlay, flow layout, glyph spawn/destroy
2. ✅ **Glyph agents** — ECS structure, homeTransform/transform, dynamics integration, seeded RNG, interpolated spawn, position transfer diff
3. ✅ **outline2d geometry** — plain fillText; layout verified (merged with step 4)
4. ✅ **Behaviour system** — `apply(g, dt, ctx, params)` interface, `syncTestBehaviours()` harness, Drift + Shake; test checkboxes + sliders in panel
5. ✅ **Authoring UI** — Type/Select mode toggle, click to select glyph, dblclick to select word, Escape to deselect, dynamic behaviour panel, add/remove/tune behaviours per selection, orange selection highlight
6. Particle geometry — clean rewrite of flocking-07 as GeometryProvider
7. Port particle behaviours — flocking, Outside, crystallisation

---

## File/Folder Plan

```
Glyphkicker/
  index.html          — single self-contained file (v1 prototype)
  Glyphkicker-Claude.md
  postpostscriptplease.pdf
  brainstorm/
```
