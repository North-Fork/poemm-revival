# Abecedarium — Planning

## 2026-03-18 — Clone Refinement

Four workstreams, roughly in order of complexity (simplest first):

---

### 1. Per-clone X/Y offset

**Goal:** Each clone panel gets an X offset and Y offset slider so layers can be nudged apart
and don't perfectly overlap. This unlocks shadow effects, ghost trails, and depth stacking.

**Implementation:**
- Add `offsetX: 0, offsetY: 0` to `_makeCloneDefault()` and `attachClone` / `_snapshotClones`
- In `drawClones`, after `dc.translate(cg.x, cg.y)` and before the path loop, apply an additional
  `dc.translate(cl.offsetX, cl.offsetY)` (scaled by `cg.scale` so it stays proportional to glyph size)
- Add two sliders to `_buildClonePanel`: X offset (−200 → 200, step 1) and Y offset (same)
- Include in Save/Load JSON (already handled by snapshot if fields are added to default)

**Open question:** Should offsets be in glyph-space (pre-scale) or canvas-space (post-scale)?
Glyph-space is more intuitive — a 10px offset looks the same regardless of glyph size.

---

### 2. Panel UX improvements

**Goal:** Reduce friction when working with many clone panels — collapse/expand all at once,
and copy settings from one clone to another.

**Implementation:**

**a. Collapse / Expand all**
- Add a row of two buttons ("Collapse all" / "Expand all") just below the Clones count control
- Each button iterates `_clonePanelList` and calls the same open/close toggle already used
  by individual subsection headers

**b. Copy clone settings**
- Add a small "Copy from…" dropdown (or button + number input) inside each clone panel header
- On select: deep-copy source clone's fill/stroke/noise/offset into target clone object;
  call `cp.syncEnabled()` on the target panel to refresh UI
- Note: does NOT copy `_noiseState` / `_displayCmds` (runtime buffers) — only user-editable fields

---

### 3. Global clone noise

**Goal:** A master noise section above the individual clone panels that drives ALL clones
simultaneously — so you can sweep one Gaussian slider and affect every layer at once.
Individual clone noise panels remain active and act as per-clone overrides/additions.

**Two design options — choose before implementing:**

**Option A — Override mode:** When global noise is enabled, it replaces each clone's own noise
params entirely. Simple but removes per-clone variation.

**Option B — Additive mode:** Global noise displacement is computed once and added on top of
each clone's own per-clone noise. More flexible; lets you set a shared base with per-clone
variation on top.

**Recommendation:** Option B (additive). A single global buffer is ticked once per frame;
its `_displayCmds` are passed as the `baseCmds` argument to each clone's `applyNoiseState` call.

**Implementation sketch (Option B):**
- Add `globalNoise` object to module state: same shape as a clone's noise block plus its own
  `_noiseState` / `_displayCmds`
- In `CloneBehavior.apply`, tick global noise first, then per-clone noise
- In `drawClones`, when global noise is active: run `applyNoiseState` on `cg._baseCmds` →
  `globalNoise._displayCmds`; pass that result as `baseCmds` into each clone's own
  `applyNoiseState` call instead of `cg._baseCmds`
- Build a "Global noise" sub-panel above the clone list (same feature rows: Independent + Perlin)
- Include in Save/Load JSON under `clone.globalNoise`

---

### 4. Perlin phase offsets across clones

**Goal:** Clones share the same Perlin noise field but each clone samples at a different time
offset, creating a wave-like phase-stagger effect across layers — e.g. clone 1 leads,
clone 10 lags, producing a visual echo or ripple.

**Implementation:**
- Add `perlinPhase: 0` to `_makeCloneDefault()` — a time offset in seconds
- In `applyNoiseState` (or the clone-specific Perlin sampling path), add `cl.perlinPhase`
  to the `time` argument when computing the Perlin lookup
- Add a "Phase" slider to each clone's Perlin noise feature row (0 → 5s, step 0.05)
- **Auto-stagger shortcut:** Add a "Stagger" button in the global Clone section that
  automatically distributes `perlinPhase` evenly across all active clones (0 to N×step).
  A "Step" number input next to the button controls the per-clone increment (default 0.2s).
- Include in Save/Load JSON (already handled if field added to snapshot)

**Note:** This only makes a visible difference when Perlin noise is active on at least two
clones. Works independently of workstream 3 (global noise) but complements it well.

---

## Architecture — Abecedarium → ComplexFont → Glyphkicker

### Role of Abecedarium
Abecedarium is the **workshopping tool for ComplexFonts**. You work one letter at a time,
exploring outline behavior (Dance, Noise, Pointer reactions, Clone layers). The output is a
collection of per-character `.abcd.json` files. A separate **bundle step** (future workstream)
assembles these into a `.ctf` (ComplexType Font) package loadable by Glyphkicker.

### Geometry: Option C — Layered
A ComplexFont glyph has **two independent geometry layers**:
1. **Outline layer** — bezier path + behavior recipe (Dance, Noise, Pointer, etc.). This is
   what Abecedarium workshopping is entirely focused on right now.
2. **Particle layer** — particle cloud seeded from the outline + particle-specific behaviors
   (attractors, force fields, repellers). Future Abecedarium workstream; not started yet.

Both layers animate independently. The CTF format must accommodate both even before the
particle layer is implemented in Abecedarium.

**Note:** The existing `ComplexType-Codex-Plan/` draft spec treats particles as the sole
geometry type. That draft is exploratory and will be superseded by what Abecedarium
workshops into existence. Do not treat it as authoritative.

### Behavior naming convention
**Abecedarium is the canonical source of behavior names.** Glyphkicker's behavior registry
will be updated to match Abecedarium naming — not the other way around. Current behavior
names: `dance` (spin, pulse, drift, pinFeet, plantFeet), `noise` (independent, perlin),
`clone`, `pointer` (repel, attract, shake).

As new behaviors are added, think about dual-layer semantics: some behaviors will be
outline-only, some particle-only, some conceptually shared (e.g. `repel-pointer` exists
in both layers but with different mechanics — anchor spring displacement vs force-field
repulsion). Naming should eventually reflect this, but no rush.

Panel names (e.g. "Shake", "Plant feet") will need slight formalization for the CTF
behavior registry (e.g. `shake`, `plant-feet`). Flag any friction at registry time.

### Bundle step (future workstream)
When ready to export a ComplexFont from Abecedarium:
- Input: N × `.abcd.json` (one per character)
- Resolve: font-level metadata (base font, unitsPerEm, scale)
- Output: `.ctf` package containing:
  - `manifest.json` — ctfVersion, packageId
  - `fontinfo.json` — name, base font reference
  - `charmap.json` — per-character outline paths + behavior recipes
  - `/assets/` — embedded path edits if any

This is a self-contained future workstream that does not affect current Abecedarium
development. Abecedarium continues single-character output (`.abcd.json`) until bundle
step is implemented.

### Portability principle (for all future Abecedarium work)
When building new behaviors or modifying the rendering pipeline, keep the behavior
*logic* isolated from Abecedarium-specific *wiring* (global cursor vars, `P.interactionMode`,
`drawCG` internals). The wiring is expected to differ; the logic should be portable.
See portability debt notes under each implemented behavior.

---

## Backlog

---

## 2026-03-19 — Clone Refinement: Implemented

All four workstreams from 2026-03-18 are complete. Summary of what was built:

### Workstream 1 — Per-clone X/Y offset ✓
- `offsetX`, `offsetY` added to `_makeCloneDefault()`, `_snapshotClones`, `attachClone`, `loadPreset`
- `drawClones` applies `dc.translate(cl.offsetX, cl.offsetY)` in glyph-space (before rotate/scale)
- Two sliders per clone panel: X offset and Y offset, range −200 → 200

### Workstream 2 — Panel UX ✓
- **Collapse / Expand all:** Two buttons below the clone count control; iterate `_clonePanelList`
- **Copy ▾ (copy-to):** Button on clone `i`; select destination `j`; deep-copies fill/stroke/noise/offset;
  calls `_syncClonePanels(j)` to refresh UI. Does NOT copy runtime noise buffers.
- Direction: "copy to" (source is the panel with the button)

### Workstream 3 — Global clone noise ✓
- `_globalNoise` module-level object (same shape as per-clone noise block + runtime buffers)
- Additive mode (Option B): global noise ticked once per frame; `_displayCmds` passed as `baseCmds`
  to each clone's `applyNoiseState` call
- "Global Noise" sub-panel built above the clone list; same feature rows as per-clone noise
- Saved/loaded under `clone.globalNoise` in `.abcd.json`

### Workstream 4 — Perlin phase offsets ✓
- `perlinPhase: 0` added to `_makeCloneDefault()` perlin params
- `applyNoiseState` now accepts `timeOffset` param; adds it to `_renderTime` for the Perlin lookup
- Phase slider per clone: 0 → 5s, step 0.05
- **Stagger button:** distributes `perlinPhase` evenly across active clones; step input controls increment (default 0.2s)

## 2026-03-19T18:17 — Mouse-Reactive Glyphs (Design / Act Modes): Implemented

### What was built
- `P.interactionMode` ('design' | 'act') with a two-button toggle bar at the top of the panel; `m` key shortcut
- Act mode: control-point overlay hidden, drag disabled; Design mode: all editing restored, pointer springs snap to rest
- `_pointerState` buffer on each `cg`: array of `{ dx, dy, vx, vy }` per slot (same indexing as `_noiseState`)
- `PointerBehavior` singleton — runs in physics tick via `AgentEngine`; spring-based reactions for anchor points only
- Three reactions: **Repel** (strength slider), **Attract** (strength slider), **Shake** (freq + amplitude sliders); shared Radius slider
- Pointer displacement applied in `drawCG()` on top of noise-displaced `_displayCmds`; `_baseCmds` stays pristine
- Pointer panel subsection (collapsed by default): Radius → Repel → Attract → Shake
- Save/Load: `pointerActive` + `pointer` key in `.abcd.json`; `loadPreset()` extended

### Porting note — Glyphkicker integration
**The intent is that all Abecedarium behaviour work (including PointerBehavior) will ultimately be ported into the Glyphkicker editor.** All new behaviours should be designed with clean portability in mind. See portability debt items below.

### Portability debt
The following wiring is Abecedarium-specific and must be refactored before porting PointerBehavior to Glyphkicker:

1. **Cursor input from globals** — `PointerBehavior.apply()` reads `_cursorX, _cursorY - 36` (module-level globals, Abecedarium toolbar offset hardcoded). Fix: read from `bCtx.inputState.pointerX/Y`, which is already how Glyphkicker's `bCtx` works.

2. **Mode gate inside the behavior** — `P.interactionMode !== 'act'` check bakes in Abecedarium's mode system. Fix: move the gate to the caller (or pass a flag on `bCtx`), so the behavior itself is mode-agnostic.

3. **Rendering path embedded in `drawCG()`** — The pointer displacement loop lives inside `drawCG()` rather than being a standalone `applyPointerState(baseCmds, pointerState, displayCmds)` function parallel to `applyNoiseState`. Fix: extract it so it can be called independently from any rendering pipeline.

These are small targeted refactors. Consider doing them before the next time PointerBehavior is significantly extended, to avoid deeper coupling.

---

### Additional changes
- Max clone count raised 10 → 15; `_cloneCountInp.max = 15`
- Dance, Noise, Clone subsections start collapsed (`startOpen = false`)
- `_snapshotClones` bug fixed: was saving `opacity` (undefined); now saves `fillOpacity` / `strokeOpacity`
- Font toolbar: slider thumbs no longer overflow past adjacent controls (`.tb-range-clip` overflow:hidden wrapper)
- Font size upper limit raised 600 → 1500
- `loadPreset()` extended: accepts `offsetX`, `offsetY`, `globalNoise`

### Debug notes
- **ReferenceError: cloneIdx not defined** — stale `cb.id` assignment left in `_makeNoiseFeatureRow`
  after refactor from `_makeCloneNoiseFeatureRow`; removed
- **All panels blank** — `shared/font-toolbar.js` was missing from disk (broken symlink target);
  `window.FontToolbar` undefined → `buildToolbar()` threw → `buildUI()` never ran; recreated file

---

## 2026-03-29 — Pointer Fixes + UX improvements

### 1. Pointer spring: frame-rate-independent damping ✓
`POINTER_DAMPING` (0.75) was multiplied directly each tick, making effective damping
`0.75^60 ≈ 0.000001` per second — effectively overdamped. Fixed to `Math.pow(POINTER_DAMPING, dt)`
so 0.75 is now correctly interpreted as "fraction of velocity retained per second."
Side effect: Repel and Attract are visibly snappier.

### 2. Shake: direct displacement (not spring-based) ✓
Even with correct damping, a spring with K=15 cannot track an 8 Hz sinusoidal target —
gain at that frequency is too low (~8% of target amplitude). Fix: Shake is no longer fed
into the spring as a target. Instead it writes `shakeDx / shakeDy` directly to each
`_pointerState` slot each tick. `drawCG` applies `s.dx + s.shakeDx` (spring + shake sum).
Repel/Attract remain spring-based for their smooth follow feel.
`_pointerState` slots now carry `{ dx, dy, vx, vy, shakeDx, shakeDy }`.

### 3. Behavior-apply prompt ✓
When the canvas is empty (after delete/escape) and at least one behavior is active,
typing a new letter now shows a banner: **"Apply [Dance/Noise/etc.] to new glyph? [Apply] [Start fresh]"**
- **Apply**: attaches all active behaviors with their saved params
- **Start fresh**: spawns the glyph clean; active flags remain on for the next letter

Implementation:
- `spawnCG` accepts `{ applyBehaviors: false }` to suppress attachment
- `clearCG` now snapshots all four behaviors (Dance/Noise/Clone/Pointer) before discarding,
  so the prompt's Apply always has the freshest state
- `_snapshotPointerFeatures(cg)` extracted as a standalone helper (was inlined in `detachPointer`)
- `#behavior-prompt` div + CSS added to HTML; shown/hidden via `.visible` class

### 4. abcde: Pointer settings no longer revert on second run ✓
**Bug:** Stop abcde, change Pointer params, restart → settings revert to those from the
first run. **Root cause:** `spawnCG` snapshots Dance/Noise/Clone from the outgoing glyph
on each letter swap, but never snapshotted Pointer — so `_savedPointerFeatures` was frozen
at the value from the original `attachPointer` call. **Fix:** Added
`_savedPointerFeatures = _snapshotPointerFeatures(currentCG) ?? _savedPointerFeatures`
to `spawnCG`, mirroring the existing pattern for the other three behaviors.

### 5. Text ↔ Vector mode switch no longer shifts glyph ✓
**Bug:** Switching render mode caused the glyph to jump position.
**Root cause:** Vector mode positions the path with `baselineY = (ascender + descender) / 2 * scale`
as the y-origin, while Text mode used `textBaseline = 'middle'` which the browser computes
differently (different font metrics table).
**Fix:** Text mode now uses `textBaseline = 'alphabetic'` and draws at `(cg._textX, cg._footY)` —
the same origin as the vector path. `cg._textX = startX` (= `−adv/2`) stored in `initCGPath`
alongside the existing `cg._footY = baselineY`. Falls back to `center/middle` at `(0,0)` if
path has not yet been initialized.


