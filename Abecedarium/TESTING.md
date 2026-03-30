# Abecedarium — Testing Log

---

## 2026-03-19T18:52 — Mouse-Reactive Glyphs (Design / Act Modes)

**Status:** Partially tested 2026-03-29. Tests 1–4 complete; 5–7 pending next session.

**Server:** `http://localhost:3000/Abecedarium/` (run `python3 -m http.server 3000 --bind 0.0.0.0` from `PoEMM/`)

### Test sequence

**1. Mode toggle basics**
- [x] Load page — "Design / Act" bar appears at top of panel
- [x] Press `m` — switches to Act; press again → back to Design
- [x] In Act mode: blue anchor dots disappear, dragging does not move control points

**2. Repel**
- [x] Type a letter, Vector mode, switch to Act mode
- [x] Behaviour → Pointer: enable Pointer checkbox + Repel
- [x] Move mouse toward glyph → anchors spring away; move away → they return

**3. Attract**
- [x] Disable Repel, enable Attract → anchors pull toward cursor

**4. Shake**
- [x] Enable Shake → anchors oscillate when cursor within radius
- [x] Freq and Amplitude sliders have visible effect
- **Bug found and fixed:** Shake had no visible effect. Two-part fix:
  1. `POINTER_DAMPING` was applied per-tick (0.75 × each frame) instead of per-second —
     fixed to `Math.pow(POINTER_DAMPING, dt)`. Side effect: Repel/Attract are now snappier too.
  2. Even with correct damping, the spring could not track an 8 Hz oscillating target at K=15 —
     the gain at that frequency is too low. Fix: moved Shake out of the spring entirely.
     Shake now writes a direct sinusoidal displacement into `s.shakeDx / s.shakeDy` each tick,
     bypassing the spring. Repel/Attract still use the spring for their smooth follow behaviour.
     `drawCG` sums `s.dx + s.shakeDx` when applying pointer displacement.

**5. Combined reactions**
- [ ] Repel + Shake both enabled → effects sum

**6. Design mode integrity**
- [ ] Switch back to Design → drag editing still works, glyph looks clean (springs reset to 0)
- [ ] `_baseCmds` unmodified — edits made in Design mode survive an Act-mode excursion

**7. Save / Load**
- [ ] Save `.abcd.json` with Pointer active → reload → Pointer settings restore correctly

### Known risk areas
- **`_cursorY - 36` offset** — if reactions feel spatially displaced, this toolbar-height
  subtraction is the likely culprit. Fix: adjust the constant or compute dynamically from
  canvas bounding rect.
- **`_pointerState` init timing** — if no reaction on first Act-mode frame, the lazy init
  in `PointerBehavior.apply()` may be one frame behind. Should self-correct by frame 2.
