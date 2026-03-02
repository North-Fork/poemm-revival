# Glyphkicker — Behaviour & SM Ideas

## To Do (priority order)

1. **Crystallisation** ← next
2. Murmuration
3. Heartbeat
4. Stampede
5. Ghost
6. Territorial
7. Word Mind

---

## Crystallisation

Glyphs that receive a `'freeze'` message spring rapidly to the nearest point on a regular grid
(cell size = font size). They lock in place (damping → 0.99, SpringHome to grid cell).
A `'melt'` message releases them back to Wander. The text self-organizes into a grid pattern
that looks like a completely different composition.

**States:** `liquid` (Wander) → `crystallising` (strong SpringHome to grid snap, 0.8s)
→ `crystal` (locked, no behaviours) → `melting` (fade SpringHome, back to liquid)

**Grid snap:**
```js
gridX = Math.round((g.homeX - MARGIN) / cellSize) * cellSize + MARGIN
```

**Poetically:** disorder suddenly organises. The poem becomes a grid of cells. It can melt back.

**Panel trigger:** send `'freeze'` / `'melt'` via the Agent Send button (or dedicated panel buttons).

---

## Murmuration

Glyphs flock at the letter level — whole glyphs steering toward the average position of their
neighbors. The text dissolves into a swirling flock, then recongeals when the mouse stops.

**States:** `resting` → `flocking`
**Each tick:** broadcast `{x, y, vx, vy}` as `'flock-data'` within 150px.
On receive: accumulate separation/alignment/cohesion forces (boids).
Transition back to `resting` when average speed < threshold for 2s.

**Poetically:** the poem atomises into a murmuration, letters wheeling around each other —
then lands again as text.

---

## Heartbeat

A single glyph is the pacemaker. Every N seconds it broadcasts `'beat'` to its nearest neighbor.
That neighbor pulses (Pulse behaviour, 1 beat) then re-broadcasts after a short delay.
The signal propagates letter-to-letter like an electrical impulse down a nerve.

**States:** `waiting` → `beating` (one Pulse, 80ms) → `waiting`
**Key:** `schedule(nearest.id, 'beat', {}, 0.08, bCtx)` — delay creates the traveling-wave feel.

**Poetically:** the text has a pulse. You can set the pacemaker anywhere, change the rhythm.

---

## Stampede

Glyphs that are already fleeing broadcast `'panic'` to nearby calm glyphs.
Panicking glyphs flee in the *same direction* as the broadcaster — pure social contagion,
not away from a predator. The whole text can cascade from a single scared letter.

**States:** `calm` → `panicking` (Flee in broadcast direction, 2s timer) → `calm`
**On 'panic':** copy flee vector `{dx, dy}` rather than a position.
**On enter:** broadcast `'panic'` to 120px neighbors.

**Poetically:** fear is directional and contagious. One word terrifies the sentence.

---

## Ghost

Glyphs slowly fade to near-invisibility (`opacity → 0.08`) and Wander aimlessly.
When the pointer comes within 60px (`pointer-near`), they briefly solidify (opacity → 1, Shake),
then fade again.

**States:** `haunting` (Wander + `opacity *= 0.995` each tick) → `manifesting` (0.4s: opacity spike + Shake) → `haunting`
**Implementation:** no separate behaviour needed — decay opacity in `onMessage('tick')`.

**Poetically:** the text is barely there. You reach for a word and it briefly appears, then recedes.

---

## Territorial

Each glyph owns its home position. When another glyph drifts within `territoryRadius` of its home,
it sends a `'get-out'` message to the intruder, which gets a SpringHome impulse.

**States:** always-on (`onMessage('tick')` only)
**Each tick:** scan for glyphs within radius whose home ≠ this home; send `'get-out'`.
**On 'get-out':** immediate impulse toward own homeX/homeY.

**Poetically:** letters are possessive. The poem resists disorder.

---

## Word Mind

Each word elects a "mind" glyph (first letter). The mind receives `'command'` from the author
panel and broadcasts it to its wordmates via `sendToWord`.
Commands: `'scatter'` (Wander), `'rally'` (SpringHome), `'spin'` (Orbit around word centroid),
`'shake'` (Shake burst).

**States:** `mind` (receives 'command' → broadcasts to word); `follower` (receives → switches behaviour)

**Poetically:** you direct words as units. "scatter" and "rally" become authorial gestures
on the poem's vocabulary.
