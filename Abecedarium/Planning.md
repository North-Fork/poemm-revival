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


