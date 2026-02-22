# PoEMM Behaviour Inventory
> Generated from Objective-C iOS source code survey, February 2026

---

## 1. What They Speak When They Speak to Me
**Core files**: `WTSWTSTMScene.h/m`, `NTTextObject.h`, `NTGlyph.h`
**Renderer**: cocos2d

### Behaviours
| Behaviour | Target | Description |
|-----------|--------|-------------|
| Swim | Glyph | Cloud-like drift toward a random target near home position |
| Path-Follow | Glyph | Glyphs string along a touch-drawn path |
| Rotate | Glyph | Rotate toward path tangent direction |
| Fade | Glyph | Fade to foreground opacity when led, background otherwise |
| Led/Unlead | Line | Touch activates path-following for nearest line |

### Interactions
- Touch down → pick nearest line → activate path-following (`setLed(true)`)
- Drag → path grows; glyphs string along it
- Touch up → glyphs swim back to home positions

### Physics
None — pure kinematic positioning

### Unique
- Path-based interaction: user draws the line, text follows
- Background/foreground state switching (`runBackground()` / `runForeground()`)
- Leader (`isLed`) flag propagates from line to all its glyphs

---

## 2. Buzz Aldrin Doesn't Know Any Better
**Core files**: `Word.h/m`, `Sentence.h/m`, `Text.h/m`, `ES1Renderer.m`
**Renderer**: OpenGL ES 1 (custom bitmap font)

### Behaviours
| Behaviour | Target | Description |
|-----------|--------|-------------|
| Wander | Word | Circular wandering at variable speed/radius |
| Smooth Friction | Word | Velocity damping toward target |
| Rotate | Word | Continuous angular velocity with friction |
| Fade/Color | Word | Smooth color transitions between states |
| Focus/Unfocus | Word | 3-state visual change (bg / focus / dragging) |
| Z-depth | Word | `bringToFront()` / `sendToBack()` depth sorting |

### Interactions
- Touch → focus word (faster wander, changed color)
- Double-tap → bring to foreground (z = -1)
- Drag → word follows finger
- Release → word resumes wandering

### Physics
None — kinematic with speed/radius parameters

### Key Parameters
`defaultSpeed` 0.05, `focusSpeed` 0.0375, `draggingSpeed`
`defaultRadius`, `focusRadius`, `draggingRadius`
`friction` for motion damping

### Unique
- 3-state word system (background / focus / dragging)
- Outline bitmap font with separate fill/outline colors
- Words wander at different speeds per state

---

## 3. The Great Migration
**Core files**: `Beast.h/m`, `KineticObject.h`, `Perlin.h`
**Renderer**: OpenGL ES (custom)

### Behaviours
| Behaviour | Target | Description |
|-----------|--------|-------------|
| Swim | Beast | Velocity/acceleration-based creature motion |
| Scatter | Beast | Perlin noise randomises movement direction |
| Approach | Beast | Creature seeks touch target position |
| Spray | Beast mouth | Words ejected from creature mouth |
| Deform / Lens | Beast body | Magnification lens effect at mouth |
| Magnification Pulse | Beast | Animate lens magnification radius on touch |
| Current Force | Beast | Flow-field force applied to velocity |

### Interactions
- Touch → creatures approach finger
- Long-press → lens effect animates
- Creatures spray words continuously

### Physics
Perlin noise for scatter; velocity + acceleration + friction (KineticObject)

### Key Parameters
`speed`, `scatter` (0–1 Perlin-driven), `magnification`, `radius`, `offsetAngle`

### Unique
- Creatures are the primary actors — text is emitted by creatures
- Lens/magnification distortion of text near mouth
- Perlin noise for organic, non-repeating scatter

---

## 4. Smooth Second Bastard
**Core files**: `TessGlyph.h/m`, `TessWord.h/m`, `TessSentence.h/m`, `KineticObject.h/m`
**Renderer**: OpenGL ES (tessellated / vector glyphs)

### Behaviours
| Behaviour | Target | Description |
|-----------|--------|-------------|
| Wander | Glyph | Proximity-based wander (new target when too close) |
| Fold / Unfold | Glyph | Deform glyph geometry toward/away from a point |
| Approach | Glyph/Word | Smooth position targeting with friction |
| Scale | Sentence | Smooth scale tweening via acceleration/friction |
| Rotate / Spin | Glyph | Angular velocity + angular acceleration + friction |
| Color Fade | Glyph | Smooth per-glyph color interpolation |

### Interactions
- Touch 1 → scale sentence
- Touch 2 → deform (fold) glyphs toward touch point
- Release → glyphs unfold and resume wandering

### Physics
Symmetric kinematic subsystems: position, rotation, scale — each with velocity + acceleration + friction

### Key Parameters
`WANDER_THRESHOLD`, `WANDER_FRICTION`, `FADE_SPEED`
`BACKGROUND_GLYPH_WANDER_RANGE`, `BACKGROUND_GLYPH_WANDER_SPEED`

### Unique
- Tessellated glyph geometry that can physically deform
- Three completely independent motion subsystems per glyph (pos/rot/scale)
- Two simultaneous touches control independent behaviours

---

## 5. No Choice About the Terminology
**Core files**: `TessSentence.h/m`, `TessGlyph.h`, `KineticObject.h`, `Choice.h`
**Renderer**: OpenGL ES (tessellated)

### Behaviours
| Behaviour | Target | Description |
|-----------|--------|-------------|
| Scale | Sentence | Smooth radius-based scaling with friction |
| Lens / Magnify | Sentence | Magnifying-glass effect at a position |
| Scroll | Sentence | Horizontal scrolling with momentum |
| Flick | Sentence | Momentum-based swipe scrolling |
| Drift | Sentence | Apply drifting momentum after release |
| Reform | Glyph | Return to original position after deformation |
| Follow Touch | Sentence | Track finger position |

### Interactions
- Touch 1 → scale entire sentence
- Touch 2 → deform glyphs with lens
- Drag → horizontal scroll
- Flick → momentum scroll
- Release → drift

### Physics
Kinematic with acceleration and friction; momentum accumulates

### Key Parameters
`scaSpeed`, `scaFriction`, `speed`, `friction`, `direction` (L/R)

### Unique
- Dual simultaneous touch behaviors (scale + deform) managed independently
- Horizontal sentence scrolling with friction and flick
- Lens effect magnifies glyphs in a specific diameter

---

## 6. The Summer the Rattlesnakes Came
**Core files**: `Snake.h/m`, `Word.h/m`, `Line.h/m`, `Ripple.h/m` + CMTraerPhysics
**Renderer**: OpenGL ES

### Behaviours
| Behaviour | Target | Description |
|-----------|--------|-------------|
| Spring chain | Snake sections | Springs connect adjacent sections |
| Attraction | Snake head→prey | Physics attraction pulls head to target |
| Bite | Word | Strike and hold a word |
| Contract | Word | Compress word geometry when bitten |
| Retract | Snake | Pull snake back with wave motion via springs |
| Ripple | Scene | Radial ripple propagates from bite point |
| Fade (audio) | SoundManager | Strike/rattle audio samples fade in/out |

### Interactions
- Snake AI targets words autonomously
- Touch creates additional bite target
- Words contract on bite; ripple emanates from contact point

### Physics
CMTraerPhysics (Traer.js Obj-C port)
- Particle system for snake body sections
- Springs between adjacent sections (stiffness, rest length, damping)
- Springs from current pos → origin (for retraction)
- Attraction particles pulling head to prey
- `strengthMult = 7.69`

### Key Parameters
Spring stiffness/damping, attraction strength, contraction period, ripple speed/max-radius

### Unique
- Procedurally animated snake body (spring physics)
- Real-time particle system
- Bite → word contraction feedback
- Ripple wave propagation from impact points
- Dual audio layer (strike + rattle) with independent fading

---

## 7. The World Was White
**Core files**: `Word.h/m`, `Line.h/m`, `OutlinedWord.h`, `Fade.h`
**Renderer**: OpenGL ES

### Behaviours
| Behaviour | Target | Description |
|-----------|--------|-------------|
| Fade In/Out | Word | Asymmetric fade: faster out, slower in |
| Contract | Word | Compress word toward a point |
| Decontract | Word | Expand word back to normal size |
| Glyph Scaling | Glyph | Uniform scale applied to all glyphs in word |
| Kinetic Motion | Word | Velocity + drag-based positioning |
| Shadow | Word | Drop shadow for depth cue |

### Interactions
- Words appear and disappear with fade
- Touch to highlight (state-based color change)
- Drag to move words (kinetic motion)
- Release → momentum carries word

### Physics
Kinematic: `velocity` × `drag` (0.98) each frame

### Key Parameters
`fadeInSpeed`, `fadeOutSpeed` (independent), `drag` 0.98, `contractFac` (0–1), `contractPeriod`, `contractStart`

### Unique
- Asymmetric fade speeds (readability tuning)
- Time-tracked contraction animation (not physics-based)
- Outline word rendering with separate fill color

---

## 8. The World That Surrounds You Wants Your Death
**Core files**: `Funnel.h/m`, `FunnelString.h/m`, `Word.h/m`, `Fade.h` + CMTraerPhysics
**Renderer**: OpenGL ES + FBO

### Behaviours
| Behaviour | Target | Description |
|-----------|--------|-------------|
| Funnel / Vortex | Word | Words spiral inward toward a center point |
| Color Gradient | FunnelString | Color shifts along the word string as it moves |
| Swipe / Flick | Word | Momentum-based word ejection from funnel |
| Sequence | Word | Words revealed in order from funnel |
| Speed Control | Funnel | Swirl speed variable |
| Audio Fade | SoundManager | Audio fades synced to visual transitions |
| FBO Rendering | Scene | Frame buffer for advanced visual compositing |

### Interactions
- Words spiral into funnel continuously
- Swipe to eject a word from the funnel
- Colors shift as words move through sequence

### Physics
CMTraerPhysics
- Springs position words in swirl pattern
- Particle positions drive word motion
- Attraction toward funnel center
- Damping for smooth spiraling

### Key Parameters
Target (x, y) for funnel center, speed multiplier, color range (RGBA start/end), font scale

### Unique
- Spatial funnel/vortex: words orbit and spiral inward
- Sequential word reveal from funnel
- Simultaneous color gradient along motion path
- Frame Buffer Object rendering for compositing
- Audio synchronized with visual transitions

---

## Cross-Project Patterns

### Physics Approaches
| Approach | Projects |
|----------|---------|
| No physics (kinematic positions) | WTSWTSTM, Buzz Aldrin |
| Kinematic + friction (velocity damping) | Smooth, No-Choice, White |
| Spring physics (CMTraerPhysics) | Rattlesnakes, Death |
| Perlin noise forces | Great Migration |

### Text Hierarchy Usage
| Level | Projects |
|-------|---------|
| Glyph | WTSWTSTM, Smooth, (deform in No-Choice) |
| Word | Buzz Aldrin, White, Rattlesnakes |
| Sentence/Line | Great Migration, No-Choice, Death |

### Behaviour Catalogue (all behaviours across all poems)
- **Swim / Wander / Drift** — WTSWTSTM, Buzz Aldrin, Smooth
- **Path-Follow** — WTSWTSTM
- **Fade (opacity)** — WTSWTSTM, Smooth, White (asymmetric)
- **Fade (audio)** — Rattlesnakes, Death
- **Rotate / Spin** — WTSWTSTM, Buzz Aldrin, Smooth
- **Scale** — Smooth, No-Choice, Great Migration (lens)
- **Fold / Deform geometry** — Smooth, No-Choice (lens)
- **Contract / Decontract** — White, Rattlesnakes
- **Approach / Seek** — Great Migration, Smooth, No-Choice
- **Scroll + Flick + Drift (horizontal)** — No-Choice
- **Funnel / Vortex / Spiral** — Death
- **Spring chain (snake body)** — Rattlesnakes
- **Attraction** — Rattlesnakes (snake→prey), Death (words→center)
- **Perlin noise scatter** — Great Migration
- **Ripple** — Rattlesnakes
- **Color gradient along path** — Death
- **Spray / Emit** — Great Migration (creatures emit words)
- **Z-depth sort** — Buzz Aldrin
- **Shadow** — White, Great Migration
- **Sequenced reveal** — Death (funnel order)
- **State machine (bg/focus/drag)** — Buzz Aldrin

---

## Notes for JS Port
- CMTraerPhysics projects (Rattlesnakes, Death) will need a lightweight JS physics lib or a hand-ported particle/spring system
- Tessellated glyph deformation (Smooth, No-Choice) requires Canvas path manipulation or SVG font outlines — non-trivial
- Great Migration's Perlin noise: use `simplex-noise` npm package or inline implementation
- Lens/magnification (Great Migration, No-Choice): implementable with Canvas `drawImage` + clip transforms
- Audio (Rattlesnakes, Death): Web Audio API
- FBO (Death): `OffscreenCanvas` or layered `<canvas>` elements
