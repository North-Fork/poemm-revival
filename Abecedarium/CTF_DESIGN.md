# CTF Design Log — ComplexType Font Format

Decisions and insights that emerge from workshopping in Abecedarium.
This is the **living spec** for the CTF format. It supersedes the exploratory drafts in `ComplexType-Codex-Plan/`.

**How to use:** When a workshopping session reveals something about how behaviors should work,
what params feel right, or what the format needs to support — log it here under a dated entry.
These experiential decisions are the spec.

---

## Resolved Decisions

### Geometry model
**Option C — Layered.** Each CTF glyph has two independent geometry layers:
- `outline` — bezier path + behavior recipe. Abecedarium's current focus.
- `particles` — particle cloud (seeded from outline) + particle-specific behaviors. Future workstream.

Both animate independently. CTF format must accommodate both even before particles are implemented.

### Behavior naming authority
**Abecedarium names are canonical.** Glyphkicker's behavior registry will be updated to match.
Current canonical behavior names:
| Abecedarium name | Features |
|-----------------|----------|
| `dance` | spin, pulse, drift, pinFeet, plantFeet |
| `noise` | independent (gaussian, poisson), perlin |
| `clone` | up to 15 layers, each with independent noise + fill/stroke |
| `pointer` | repel, attract, shake |

Panel display names (e.g. "Plant feet", "Shake") will need slug-form equivalents for the CTF
behavior registry (e.g. `plant-feet`, `shake`). Formalize when the bundle step is built.

### Assembly workflow
- Workshop one character at a time in Abecedarium → save `.abcd.json` per character
- A separate **bundle step** (future workstream) assembles N × `.abcd.json` → `.ctf` package
- `.ctf` package structure: `manifest.json`, `fontinfo.json`, `charmap.json`, `/assets/`
- Abecedarium stays single-character until bundle step is implemented

### Dual-layer behavior semantics
Some behaviors are outline-only, some particle-only, some conceptually shared with
layer-specific implementations. Example: `pointer.repel` on the outline layer = anchor spring
displacement; on the particle layer = force-field repulsion. CTF behavior entries will need
to specify which layer(s) they apply to. Formalize when particles are implemented.

---

## Open Questions

- **Path source in CTF** — embed edited bezier paths in `charmap.json`, or store as delta
  from source font + record which font was used? Embedding is portable; delta is lighter.
  *Decide when bundle step is designed.*

- **Font-level defaults vs per-character overrides** — should a CTF define a default behavior
  recipe that applies to all characters, with per-character overrides on top? Or fully
  per-character? *Workshopping will reveal what's practical.*

- **Behavior registry: shared name across layers?** — Does `repel-pointer` appear once in the
  CTF with layer-specific params, or as separate `outline.repel-pointer` / `particle.repel-pointer`
  entries? *Decide when particles are implemented.*

- **Param ranges** — what ranges feel right for each behavior param? Record discoveries below
  as you workshop. These become the CTF default/min/max values.

---

## Workshopping Log

*Append dated entries here as insights emerge from Abecedarium sessions.*

### 2026-03-19T18:17

- **`pointer.repel` / `pointer.attract`**: strength range 0–300, radius 50–600 (glyph-local px)
  feels workable. Spring constants `k=15`, `damping=0.75` give responsive-but-not-jittery
  behaviour at 60fps fixed timestep.
- **`pointer.shake`**: freq 1–20 Hz, amp 0–100 glyph-local px. Incommensurate X/Y oscillators
  (`freq` and `freq × 1.3`) produce more organic motion than matched frequencies.
- **Anchor-only displacement**: applying pointer reactions to on-curve anchor points only
  (not off-curve handles) produces cleaner deformation than displacing all control points.
  Off-curve handles stay noise-displaced; anchors get pointer-displaced on top. This layering
  order (noise first, pointer second) feels right — consider making it canonical.
