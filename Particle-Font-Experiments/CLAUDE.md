# CLAUDE.md — Particle Font Experiments

Working directory for particle typography experiments. Current active file: `particle-test-flocking-07.html`.

Earlier experiments archived in `archive/`.

---

## particle-test-flocking-07.html — Feature Summary

### Control Panel (left sidebar, 320px)
- **Text input** — live textarea; Apply button rebuilds glyphs
- **Freeze / Unfreeze** — pauses simulation
- **Export**
  - PNG (600 DPI, optional transparent background)
  - Video: `canvas.captureStream()` → `MediaRecorder` → `.mp4` (prefers `video/mp4;codecs=avc1`, falls back to WebM). FPS slider (12–60) and Duration slider (0–60s; 0 = manual stop). Record button turns red while active, shows elapsed/total timer. Downloads as `particles.mp4` or `particles.webm`.
- **Settings** — named Behaviour sets and Text sets, saved to `localStorage`

### Glyph Particle System
- Font, font size (pt), particle size (px), density (%), particle speed, particle colour, shape (square → circle roundness), Outside
- Per-glyph alpha mask built from offscreen canvas; particles confined to mask shape
- At ≤2px particle size: snaps to solid glyph render (fixes grey fringe + perf crawl)

### Containment — Outside behaviour
- **Outside** (0–100%): relaxes glyph boundary so particles drift outside and wander back
  - Wall avoidance scales to zero as Outside rises
  - Return force always present (15% minimum at Outside=100%) — particles wander, never escape permanently
  - Return force aims at each particle's **birth position** (not glyph centre), fixing counter clusters in 'o', 'h', 'e', etc.
  - At Outside=0: escaped particles have flocking suppressed so return force dominates and they stream back
- Crystallisation ramp: `solidifyT` runs from cellPx=3→2 only (was 6→2), restoring full flocking at default 4px

### Flocking (Reynolds Boids)
- Perception radius, Separation, Alignment, Cohesion
- Crystallisation: at small particle sizes (≤3px), flocking scales down and particles snap toward birth-grid positions

### Letter Movement
- Letter Speed, Wander Radius, Letter Repulsion (soft collision between glyphs)

### Interaction
- Drag individual glyphs; Alt+drag moves whole word; Ctrl+click grabs all letters
- Spacebar + mousewheel adjusts font size
- Cmd/Ctrl+Z undo (position stack, 20 levels)

---

## TO DO

(none)
