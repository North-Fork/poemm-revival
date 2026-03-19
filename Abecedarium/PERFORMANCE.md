# Abecedarium — Performance Notes

## Status
All known JavaScript-level performance issues resolved. Remaining stutter on Dev MacMighty was due to timing artifacts introduced by fact dev machine is accessed through Share Screens.

---

## JavaScript fixes applied

### 1. `applyNoiseState` — GC freeze cycle (first and worst)
**Symptom:** Smooth animation then periodic hard freeze, cycling.
**Cause:** `applyNoiseState` called `baseCmds.map(cmd => ({...cmd}))` every render frame,
allocating ~100–300 new objects per frame → ~12,000+ objects/second → major V8 GC pause.
**Fix:** Pre-allocate `_displayCmds` once in `initCGPath`; `applyNoiseState` writes in-place
with no allocation.

### 2. `bCtx` and `cgs` array — per-frame allocation
**Cause:** `const bCtx = { cgs: currentCG ? [currentCG] : [], ... }` created two new objects
every frame (the context object + the array).
**Fix:** Pre-allocated module-level `_bCtx` and `_cgsList`; update in-place each frame
(`_cgsList.length = 0; _cgsList.push(currentCG)`).

### 3. `ctx.font` template string — per-frame allocation
**Cause:** `` `${cg.size}px "${cg.font}"` `` evaluated every frame in text mode, creating
a new string object.
**Fix:** Cached in `cg._fontStr`; rebuilt only when font or size changes.

### 4. `ctx.setLineDash([])` — per-call array allocation
**Cause:** `[]` literal creates a new array on every call. In vector mode with control points
visible, called ~50–100 times per frame (once per handle line + handle circle).
**Fix:** Shared module-level `const EMPTY_DASH = []`; passed by reference everywhere.

### 5. `isSel` closure in `drawControlPoints` — per-frame allocation
**Cause:** `const isSel = (i, role) => ...` defined inside `drawControlPoints`, creating
a new closure object every render frame.
**Fix:** Replaced with two scalar variables `selIdx` / `selRole` extracted before the loop.

### 6. `_noiseSlotCount` with `for...of` — per-tick iterator
**Cause:** Called every physics tick (60×/s) to validate noise slot count; used `for...of`
which creates an iterator object.
**Fix:** Cached slot count in `cg._noiseSlots`; set once in `initNoiseState`.
Validation check simplified to `!cg._noiseState`.

### 7. `for...of` on hot paths — iterator allocations
**Cause:** Path command loop in `drawCG` and AgentEngine loops used `for...of` on arrays,
potentially allocating iterator objects.
**Fix:** Converted all hot-path loops to indexed `for (let i = 0; ...)` with local array refs.

### 8. Control point rendering — O(n) GPU draw calls
**Cause:** Each anchor, handle, and handle line was drawn with its own `beginPath()` +
`stroke()` / `fill()` call. For a typical glyph (~30 curves) this was ~100 individual GPU
draw calls per frame, which can cause compositor command-buffer stalls.
**Fix:** Batched into 4–5 total draw calls regardless of glyph complexity:
- Batch 1: all handle lines → one `stroke()`
- Batch 2: all non-selected anchors → one `fill()`
- Batch 3: selected anchor (0 or 1) → one `fill()` + one `stroke()`
- Batch 4: all non-selected handle circles → one `stroke()`
- Batch 5: selected handle (0 or 1) → one `stroke()`

### 9. Noise slot synchronization — periodic CPU spike
**Cause:** All noise slots initialize with `timer: 0` (since default `noisePeriod` is 0).
When user moves the `noisePeriod` slider from 0 to any value X, all slots have `timer ≈ 0`
and fire simultaneously on the same tick. They all reset to `timer = X` — synchronized
permanently. Result: one large CPU burst every X seconds, matching the Period slider value
exactly.
**Fix:** Added `cg._cachedPeriod` tracking. In `updateNoiseState`, when `P.noisePeriod`
changes value, immediately re-stagger all slot timers to `Math.random() * period` before
the tick loop runs. Also stagger on `initNoiseState` so freshly created glyphs start spread.

### 10. `Math.exp(-lambda)` in `poissonRand` — redundant transcendental call
**Cause:** `Math.exp(-lambda)` recomputed on every `poissonRand()` call. With `noisePeriod = 0`
and a complex glyph, this ran ~400×/tick (200 slots × 2 samples).
`P.poissonAmt` (= lambda) only changes when the user moves a slider.
**Fix:** Cache: `_poissonLambda` and `_poissonL` module-level vars; `Math.exp` only runs
when `lambda !== _poissonLambda`.

### Other micro-optimisations
- `const TAU = Math.PI * 2` — computed once at startup
- `_canvasW` / `_canvasH` — cached at module level, updated only in `resizeCanvas()`;
  removed `window.innerWidth` / `window.innerHeight` reads from the render loop
- AgentEngine: converted `for...of bCtx.cgs` and `for...of cg.behaviours` to indexed loops
  with local refs (`const cgs = bCtx.cgs; const nc = cgs.length`)

---

## System-level issue — Dev MacMighty

### Diagnosis summary

JavaScript GC is **not** the cause:
- Performance Monitor: CPU 3–4%, JS Heap stable at 6–8 MB (no sawtooth)
- Same pause in Brave/Chrome and Safari → browser-agnostic

`powermetrics` ruled out thermal throttling — P1 cluster boosts to 4000+ MHz (near maximum),
confirming no thermal cap. P0 cluster (CPUs 4–8) is mostly power-gated (0 MHz), normal for
light load on Apple Silicon.

`pmset -g` identified the cause:
```
sleep   1 (sleep prevented by screensharingd, powerd)
```

### Root cause: screensharingd

Dev MacMighty runs **headless** (no display attached), accessed remotely via Screen Sharing
from MBP. The `screensharingd` daemon periodically captures the entire display to send to the
remote viewer. These captures go through macOS's WindowServer compositor, briefly blocking
frame delivery to all applications. Both Chrome and Safari are affected simultaneously because
they share the same compositor.

The animation code is correct — confirmed smooth on another machine without screen sharing.
The stutter is a compositor artefact visible only inside the Screen Sharing window.

Screen sharing cannot be disabled as it is the only means of accessing the headless machine.

### Workarounds

**Option 1 — Preview in MBP's browser (recommended)**
Edit files on MacMighty; preview the animation locally on MBP. Since Abecedarium is a
single self-contained HTML file, no build step is needed.

Serve from MacMighty:
```bash
cd /Users/jasonlocal/Documents/Dev-MacMighty/PoEMM/Abecedarium
python3 -m http.server 8080
```
Open on MBP: `http://macmighty.local:8080` (or MacMighty's IP address).

The animation runs on MBP's own GPU with no screen sharing in the loop. MacMighty remains
the edit/source machine; MBP is purely the preview machine.

**Option 2 — HDMI dummy plug (~$10)**
Plugging a headless ghost display adapter into MacMighty makes macOS think a real display is
attached. This switches the compositor to the normal display pipeline rather than the
screen-capture path. Screen Sharing still runs but may stutter less. No software change
required.

**Option 3 — Accept it as a known development artefact**
The stutter exists only inside the Screen Sharing window. Any real user of the animation on
a normal machine won't see it. Mentally discount it during development on MacMighty and
verify on MBP or another machine for final checks.
