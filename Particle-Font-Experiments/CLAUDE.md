# CLAUDE.md — Particle Font Experiments

Working directory for particle typography experiments. Current active file: `particle-test-flocking-06.html`.

Earlier experiments archived in `archive/`.

---

## particle-test-flocking-06.html — Feature Summary

### Control Panel (left sidebar, 320px)
- **Text input** — live textarea; Apply button rebuilds glyphs
- **Freeze / Unfreeze** — pauses simulation
- **Export**
  - PNG (600 DPI, optional transparent background)
  - Video: `canvas.captureStream()` → `MediaRecorder` → `.mp4` (prefers `video/mp4;codecs=avc1`, falls back to WebM). FPS slider (12–60) and Duration slider (0–60s; 0 = manual stop). Record button turns red while active, shows elapsed/total timer. Downloads as `particles.mp4` or `particles.webm`.
- **Settings** — named Behaviour sets and Text sets, saved to `localStorage`

### Glyph Particle System
- Font, font size (pt), particle size (px), density (%), particle speed, particle colour, shape (square → circle roundness), unruliness
- Per-glyph alpha mask built from offscreen canvas; particles confined to mask shape
- At ≤2px particle size: snaps to solid glyph render (fixes grey fringe + perf crawl)

### Flocking (Reynolds Boids)
- Perception radius, Separation, Alignment, Cohesion
- Crystallisation: at small particle sizes, flocking scales down and particles snap toward birth-grid positions

### Letter Movement
- Letter Speed, Wander Radius, Letter Repulsion (soft collision between glyphs)

### Interaction
- Drag individual glyphs; Alt+drag moves whole word; Ctrl+click grabs all letters
- Spacebar + mousewheel adjusts font size
- Cmd/Ctrl+Z undo (position stack, 20 levels)

---

## TO DO

- **UNRULINESS:** When we redesigned particle size to snap to the regular glyph, it broke something with the rest of the particle behaviours. They are all too well-behaved now.
