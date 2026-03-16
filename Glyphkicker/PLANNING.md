# Glyphkicker — Planning Log

--------------------------------------------------------------------------------

## NEXT SESSION — START HERE

**Step 4b: Mixed-level selection → LCA**

When the user drag-selects across a word or line boundary, the selection should automatically promote to the deepest common ancestor (LCA) of all touched glyphs.

- Implement `findLCA(glyphList)` — builds ancestor chain `[glyph, word, line, passage]` for each glyph, walks up until chains converge
- Wire into drag-select: after selection is committed, call `findLCA(selectedGlyphs)` and call `selectNode(lca)`
- Examples: select 'h','e','l' (same word) → Word; select last of "hello" + first of "world" → Line; select across lines → Passage

Full spec and verify checklist in the **Step 4b** section below.

--------------------------------------------------------------------------------

## [2026-03-15] HARD CONSTRAINT: BEZIER-SOURCE RENDERING REQUIRED

**All geometry must derive from bezier sources, not from `ctx.fillText()` rasterisation.**

PoEMM works will be produced as high-resolution prints. Any raster-based approach (blur+threshold goo, particle masks sampled from `fillText`, pixel-pushed SDFs) will produce artefacts at print scale. The glyph outlines must come from opentype.js as mathematical bezier contours, and all deformation — including the Ooze effect — must operate on those contours.

**Implications:**

- `outline2d` (current `ctx.fillText()` renderer) is **screen-preview only**. It stays for fast iteration but is not the print path.
- `outline2d-bezier` (Phase 2, opentype.js → Path2D) is the primary geometry provider going forward. All deformation behaviours target this provider.
- The Ooze effect (letters deforming and merging into each other) must be bezier-driven: glyph contours from opentype.js, smooth-union of implicit fields derived from those contours, isosurface extracted as bezier output — not as a raster blur trick.
- For print export: render to a high-resolution canvas (target DPI × physical size) from bezier sources. No quality degradation at any scale.
- This rules out Option A (blur+threshold) for the Ooze GeometryProvider.

**Confirmed output targets:** interactive screen (60fps) + high-resolution print.

--------------------------------------------------------------------------------

## [2026-03-15] RENDERING ROADMAP AND SEQUENCING DECISION

### Requirements confirmed

- Bezier control-point access (outline deformation behaviours)
- Thousands of simultaneously deforming glyphs
- Morphing between letterforms
- **High-resolution print output** (see constraint above)

### Option assessment

| Requirement | Canvas 2D + opentype.js | SVG | WebGL |
|---|---|---|---|
| Bezier access | ✓ opentype.js returns full contours | ✓ path `d` attribute editable | ✓ read from opentype.js, upload to GPU |
| Thousands of deforming glyphs | ⚠ workable to ~500, then degrades | ✗ DOM melts above ~300 animated elements | ✓ GPU-native, tens of thousands at 60fps |
| Morphing between letterforms | ⚠ possible but manual (interpolate contour points) | ✓ GSAP MorphSVG trivial | ✓ vertex shader interpolation |

### Decision: Three-phase rendering roadmap

**Phase 1 (now) — NextText hierarchy.** Execute the 8-step hierarchy plan first. Entirely rendering-agnostic — the text model, behaviour cascade, selection model, and panel are independent of renderer. No wasted work regardless of where rendering lands.

**Phase 2 (next) — Canvas 2D + opentype.js.** Add as `outline2d-bezier` GeometryProvider. Immediate Bezier access; fits current architecture; enables all deformation behaviours (noise warping, displacement, liquify, contour bending). Covers most of the intended work.

**Phase 3 (eventual) — WebGL.** When specific pieces target genuine scale (thousands of simultaneous deforming glyphs). The ECS structure (`g.transform`, `g.material`, `g.dynamics`) maps directly to GPU buffer layout — the behaviour system won't need to change, only the GeometryProvider.

### Constraint for Phase 1

During hierarchy implementation: no Canvas-2D-specific optimizations or assumptions in the geometry layer. Keep all rendering decisions inside the GeometryProvider. This keeps the Phase 3 transition contained.

--------------------------------------------------------------------------------

## [2026-03-15] RENDERING APPROACH FOR GLYPH OUTLINE DEFORMATION

**Question:** Given behaviours that involve deforming glyph outlines, should Glyphkicker switch from Canvas 2D to SVG or another framework?

**Context:** `ctx.fillText()` renders glyphs atomically — individual Bezier control points are inaccessible. Outline deformation requires those points.

### Options considered

**1. Canvas 2D + opentype.js** ← recommended
- opentype.js parses font files and returns each glyph as Bezier contours (on/off-curve control points)
- Deformation behaviours manipulate control points directly, draw with `Path2D`
- Preserves entire existing architecture — frame loop, physics, particle system, AgentEngine unchanged
- Good performance for hundreds of animated glyphs
- Best for: point displacement, noise-driven warping, liquify-style deformation, stroke bending

**2. SVG**
- Each glyph becomes a `<path>` DOM element — addressable, CSS-animatable
- GSAP MorphSVG makes letter-to-letter shape morphing trivial
- Resolution-independent
- Performance degrades at scale (500+ animated elements gets sluggish)
- Frame-loop / physics architecture would need full rethink
- Best for: path morphing between letterforms, smooth letter shape interpolation

**3. WebGL / Three.js**
- GPU-accelerated, thousands of deforming glyphs at 60fps
- Significant departure from current architecture
- Best for: massive-scale effects, shader-driven distortion

**Decision:** Pending — depends on which deformation types are central to the vision. opentype.js + Canvas 2D is the lowest-disruption path. SVG only if letter-to-letter morphing is a primary behaviour.

**Next step:** Jason to describe the outline deformation behaviours he's envisioning before finalising this choice.

--------------------------------------------------------------------------------

## [2026-03-15] NEXTTEXT HIERARCHY IMPLEMENTATION PLAN

## Goal

Add a full **Document → Passage → Line → Word → Glyph** hierarchy to Glyphkicker, matching the NextText architecture. Behaviours assigned at any level cascade down to all descendant glyphs (additive stack). The behaviour panel becomes hierarchy-aware.

--------------------------------------------------------------------------------

## Architecture: String-as-source, tree-as-derived

`docText` stays as the canonical editing state — no changes to text input, cursor, undo/redo, or position transfer. On every `layout()` call, the string is parsed into a full hierarchy tree. A flat `glyphs[]` is extracted from that tree for rendering (rendering loop unchanged).

**Node behaviour persistence** across layout rebuilds uses content-based matching: old Word/Line/Passage nodes are matched to new ones by text content + nearest `startIndex`. Their `behaviours[]` are carried over. Same approach as glyph position transfer.

--------------------------------------------------------------------------------

## Node Structures

Per the spec, **every node at every level** carries `behaviours[]`, `style`, `transform`, and `homeTransform` — not just glyphs.

```js
// Non-glyph nodes (Passage, Line, Word) shape:
{
  id,             // e.g. 'p0', 'p0-l2', 'p0-l2-w1'
  text,           // substring of docText
  startIndex,     // char index in docText (for matching)
  behaviours,     // [{ type: BehaviourObj, params: {...} }]
  style: {        // local typographic overrides (null → inherit from parent/PARAMS)
    fontFamily: null,
    fontPt:     null,
    fill:       null,
    fillOn:     null,
    strokeOn:   null,
    strokeColor:null,
    strokeWidth:null,
    opacity:    null,
  },
  transform: { x: 0, y: 0, rotation: 0, scale: 1 },  // offset from home
  homeTransform: { x: 0, y: 0 },                      // computed layout position (read-only)
  // children: passages[] / lines[] / words[] / glyphs[]
}

// Glyph additions (back-pointers, set during tree build, not copied in transfer):
g.parentWord     // Word node (null for space/newline glyphs)
g.parentLine     // Line node
g.parentPassage  // Passage node
```

`style` and `transform` on non-glyph nodes are deferred to a later step but the fields are allocated from day one so they can be wired in without structural changes.

--------------------------------------------------------------------------------

## Implementation Steps

### Step 1 — Node factories

Add `makeWord(text, startIndex, pi, li, wi)`, `makeLine(pi, li)`, `makePassage(pi)`, `makeDocument()` factory functions immediately after `makeGlyph` (~line 424).

Each returns `{ id, text, startIndex, behaviours: [], children }`.

**Verify (console):**
```js
const w = makeWord('hello', 0, 0, 0, 0);
console.assert(w.id === 'p0-l0-w0', 'word id');
console.assert(Array.isArray(w.behaviours), 'behaviours array');
console.assert(w.text === 'hello', 'word text');
const doc = makeDocument();
console.assert(Array.isArray(doc.passages), 'document has passages');
```

### Step 2 — Behaviour matching helper

```js
function transferNodeBehaviours(oldNodes, newNodes) {
  // Build map: text → [oldNodes with that text]
  const byText = new Map();
  for (const n of oldNodes) {
    if (!n.behaviours.length) continue;
    if (!byText.has(n.text)) byText.set(n.text, []);
    byText.get(n.text).push(n);
  }
  // Match each new node to the closest-index old node with same text
  for (const n of newNodes) {
    const candidates = byText.get(n.text);
    if (!candidates?.length) continue;
    const best = candidates.reduce((a, b) =>
      Math.abs(a.startIndex - n.startIndex) < Math.abs(b.startIndex - n.startIndex) ? a : b);
    n.behaviours = best.behaviours;
    candidates.splice(candidates.indexOf(best), 1);
  }
}
```

**Verify (console):**
```js
const fakeBeh = [{ type: 'Shake', params: {} }];
const old = [{ text: 'hello', startIndex: 0, behaviours: fakeBeh }];
const next = [{ text: 'hello', startIndex: 1, behaviours: [] }];
transferNodeBehaviours(old, next);
console.assert(next[0].behaviours === fakeBeh, 'behaviours transferred');

// No cross-contamination: different text should not transfer
const old2 = [{ text: 'hello', startIndex: 0, behaviours: fakeBeh }];
const next2 = [{ text: 'world', startIndex: 0, behaviours: [] }];
transferNodeBehaviours(old2, next2);
console.assert(next2[0].behaviours.length === 0, 'no spurious transfer');
```

### Step 3 — Refactor `layout()` to build hierarchy tree

After the existing two-pass (segment parsing + glyph placement), add a **Stage B** that groups `next[]` into the hierarchy:

```
Stage B:
  Split next[] into Passages by blank-line (\n\n) boundaries
  Within each Passage, split into Lines by \n or visual-wrap boundaries
  Within each Line, split into Words by space glyphs
  Set g.parentWord / g.parentLine / g.parentPassage back-pointers
  Call transferNodeBehaviours() for Words, Lines, Passages
    (using prevDocModel's nodes as oldNodes)
  Store result as docModel
  glyphs = docModel.flatGlyphs()   ← same flat array, same order
```

`prevDocModel` replaces `prevByIdx` for node matching (glyph matching by index unchanged).

**Verify (console after typing "hello world"):**
```js
// In browser console after typing "hello world":
console.assert(docModel.passages.length === 1, '1 passage');
console.assert(docModel.passages[0].lines[0].words.length === 2, '2 words');
console.assert(docModel.passages[0].lines[0].words[0].text === 'hello', 'word 0 = hello');
console.assert(docModel.passages[0].lines[0].words[1].text === 'world', 'word 1 = world');

// Back-pointers
const h = glyphs.find(g => g.char === 'h');
console.assert(h.parentWord.text === 'hello', 'h.parentWord');
console.assert(h.parentLine != null, 'h.parentLine');
console.assert(h.parentPassage != null, 'h.parentPassage');

// Space glyph has no parentWord
const sp = glyphs.find(g => g.char === ' ');
console.assert(sp.parentWord === null, 'space.parentWord = null');

// flatGlyphs order matches original glyphs[]
const flat = docModel.flatGlyphs();
console.assert(flat.length === glyphs.length, 'flatGlyphs same length');
console.assert(flat.every((g, i) => g === glyphs[i]), 'flatGlyphs same order');
```

### Step 4 — AgentEngine cascade (Phase 5)

Replace flat glyph behaviour loop with:

```js
// Phase 5 — behaviour tick with cascade
for (const g of glyphs) {
  if (g.char === '\n' || g.char === ' ') continue;
  const bCtx = { document: docModel, inputState, time };
  // Passage → Line → Word → Glyph (all run, additive)
  for (const ancestor of [g.parentPassage, g.parentLine, g.parentWord]) {
    if (!ancestor) continue;
    for (const inst of ancestor.behaviours.slice())
      inst.type.apply(g, dt, bCtx, inst.params);
  }
  for (const inst of g.behaviours.slice())
    inst.type.apply(g, dt, bCtx, inst.params);
}
```

**Note:** Same-type cascaded and glyph-level behaviours share the `_state` slot keyed by `BehaviourType.sym`. Known simplification for v1 — additive effect is acceptable.

**Verify (checklist):**
- [ ] Type "hello world". Double-click "hello" to select word (Step 5 must be done first). Add Shake to word → all 5 glyphs of "hello" shake; "world" is still.
- [ ] Existing glyph-level behaviours (added before Step 4) still work unchanged.
- [ ] Predator/Prey demo still runs (uses `selectGlyphs`, not `selectNode`).

### Step 4b — Mixed-level selection → deepest common ancestor

The spec says: *"The selection can span mixed hierarchy levels; behaviours are assigned to the deepest common ancestor."*

When the user drag-selects across word or line boundaries, compute the **lowest common ancestor (LCA)** of all touched glyphs in the hierarchy tree and set that as `selectedNode`:

```js
function findLCA(glyphList) {
  // Build ancestor chains for each glyph: [glyph, word, line, passage]
  // Walk up from glyph until chains converge on the same node
  // Return the deepest shared ancestor
}
```

Examples:
- Drag selects 'h','e','l' (all in word "hello") → LCA = Word "hello"
- Drag selects last glyph of "hello" + first of "world" → LCA = Line
- Drag selects across lines → LCA = Passage

`selectNode(lca)` is then called with the LCA as usual. This integrates with Step 5's `selectNode()` without extra special cases.

**Verify (console):**
```js
// Type "hello world" (single line). Simulate drag across both words:
const allGlyphs = glyphs.filter(g => g.char !== ' ' && g.char !== '\n');
const lca1 = findLCA(allGlyphs.slice(0, 3)); // 'h','e','l' — same word
console.assert(lca1 === docModel.passages[0].lines[0].words[0], 'LCA = word');

const lastOfHello = allGlyphs[4];  // 'o'
const firstOfWorld = allGlyphs[5]; // 'w'
const lca2 = findLCA([lastOfHello, firstOfWorld]);
console.assert(lca2 === docModel.passages[0].lines[0], 'LCA = line');
```

**Verify (checklist):**
- [ ] Drag across "hello world" → LCA = Line; behaviours added go to Line node, not Word.

### Step 4c — Save format update

Update `saveDoc()` / `loadDoc()` to emit and consume the full hierarchy JSON per the spec:

```json
{
  "version": "1",
  "meta": { "title": "", "author": "", "created": "" },
  "style": { "fontFamily": "Gill Sans", "fontSize": 48, ... },
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
              "text": "hello",
              "behaviours": [{ "type": "Shake", "amplitude": 5, "speed": 8 }],
              "glyphs": [
                { "id": "p0-l0-w0-g0", "char": "h", "behaviours": [] }
              ]
            }
          ]
        }
      ]
    }
  ]
}
```

On load: restore the hierarchy tree from the JSON, then derive `docText` from it, then call `layout()`.

**Verify (checklist):**
- [ ] Add Shake to word "hello". Save → open JSON → confirm `behaviours` array is present on the word node, absent on glyphs with no overrides.
- [ ] Load the saved file → "hello" immediately shakes; no re-assignment needed.
- [ ] Load into a fresh page (clear docText first) → text and behaviours fully restored.

### Step 5 — Selection model

Add `let selectedNode = null` alongside `selectedGlyphs`/`selectedIds`.

Update multi-click handler:
- **1 click** → `selectNode(glyph)` — selectedNode = glyph, selectedGlyphs = [glyph]
- **2 clicks** → `selectNode(word)` — selectedNode = word, selectedGlyphs = word.glyphs
- **3 clicks** → `selectNode(line)` — selectedNode = line, selectedGlyphs = line.flatGlyphs()
- **4 clicks** → `selectNode(passage)` — selectedNode = passage, selectedGlyphs = passage.flatGlyphs()

`selectGlyphs(gs)` preserved unchanged (used by predator/prey, sets `selectedNode = null`).

Add `selectNode(node)` that sets `selectedNode`, derives `selectedGlyphs` from node descendants, updates `selectedIds`, calls `updateBehaviourPanel()` + `updateGeometryPanel()` + `FontToolbar.syncFontToolbar(_toolbarP)`.

**Verify (checklist):**
- [ ] Single-click 'h' → `selectedNode === glyphs[0]`, `selectedGlyphs.length === 1`.
- [ ] Double-click "hello" → `selectedNode` is the Word node, `selectedGlyphs.length === 5`.
- [ ] Triple-click → `selectedNode` is Line, all glyphs on that line are highlighted.
- [ ] Quadruple-click → `selectedNode` is Passage.
- [ ] Escape → `selectedNode === null`, `selectedGlyphs` empty.
- [ ] `selectGlyphs([g])` (predator/prey path) → `selectedNode === null`, highlight still works.

### Step 6 — Hierarchy-aware behaviour panel

`updateBehaviourPanel()` branches on `selectedNode` type:

```
If selectedNode is Word / Line / Passage:
  Header: "Word: 'hello'"  (or Line: ... / Passage: ...)
  Section — "[Level] behaviours (cascades to N glyphs)":
    list with [×] buttons and parameter sliders
    [+ add behaviour] button
  Section — "Per-glyph overrides":
    compact list: char + override count per glyph
    click a char → selectNode(that glyph)

If selectedNode is a Glyph:
  Header: "'h' — glyph"
  Section — "Inherited" (greyed, read-only):
    list ancestor behaviours from parentWord, parentLine, parentPassage
  Section — "Glyph behaviours":
    list with [×] and sliders
    [+ add behaviour] button
```

**Verify (checklist):**
- [ ] Double-click "hello" → panel header reads "Word: 'hello'".
- [ ] Panel shows cascade count: "Word behaviours (cascades to 5 glyphs)".
- [ ] Per-glyph overrides section lists 'h','e','l','l','o'; clicking 'h' switches panel to glyph view.
- [ ] Single-click 'h' after adding Shake to the word → panel shows inherited Shake greyed out + empty glyph behaviours section.
- [ ] Triple-click → panel header reads "Line: ..." with correct glyph count.

### Step 7 — addBehaviour / removeBehaviour

```js
function addBehaviour(defKey) {
  if (!selectedNode) return;
  const def = BEHAVIOUR_DEFS.find(d => d.key === defKey);
  selectedNode.behaviours.push({ type: def.type, params: { ...def.defaults } });
  updateBehaviourPanel();
}
function removeBehaviour(idx) {
  if (!selectedNode) return;
  selectedNode.behaviours.splice(idx, 1);
  updateBehaviourPanel();
}
```

Parameter sliders bind to `selectedNode.behaviours[i].params[pk]`.

**Verify (checklist):**
- [ ] Double-click "hello" → [+ add behaviour] → add Shake → all 5 glyphs shake immediately.
- [ ] [×] on Shake → glyphs stop shaking immediately.
- [ ] Single-click 'h' → add Flicker to glyph → only 'h' flickers; others unaffected.
- [ ] Word-level Shake + glyph-level Flicker on 'h' → 'h' both shakes and flickers; others only shake.
- [ ] Amplitude slider on word Shake → all descendant glyphs respond live.

### Step 8 — Undo/Redo

Extend `captureSnapshot()` / `applySnapshot()` to include node behaviours:

```js
// captureSnapshot: add
snapshot.nodeBehaviours = docModel ? serializeNodeBehaviours(docModel) : {};

// applySnapshot: add
if (snapshot.nodeBehaviours) nodeStore = deserializeNodeBehaviours(snapshot.nodeBehaviours);
```

`nodeStore` is a `Map<nodeId, behaviours[]>` maintained independently of the in-memory hierarchy. Layout reads from `nodeStore` when building the tree (takes priority over content-matching). This makes snapshot restore reliable.

**Verify (checklist):**
- [ ] Add Shake to word "hello". Type a character inside it → layout rebuilds → Shake persists on word.
- [ ] Undo the typed character (Cmd+Z) → Shake still present on "hello".
- [ ] Undo adding Shake (Cmd+Z) → Shake gone.
- [ ] Redo (Cmd+Shift+Z) → Shake returns.
- [ ] Add Shake to word, then undo back to before the word existed → no crash, clean state.

--------------------------------------------------------------------------------

## Key Design Decisions

| Decision | Choice | Rationale |
|---|---|---|
| Source of truth | `docText` (string) | Preserves all text editing logic unchanged |
| Node persistence | Content-based matching + nodeStore for undo | Handles insertions/deletions gracefully |
| Cascade semantics | Additive — passage → line → word → glyph, all run | Confirmed by user; matches NextText |
| _state slot sharing | Same `BehaviourType.sym` per type | Acceptable v1 simplification |
| Space/newline glyphs | `parentWord = null`; belong to Line only | Spaces aren't words |
| Document node | Root, no behaviours for now | Global cascade = future feature |

--------------------------------------------------------------------------------

## Files to Modify

- `PoEMM/Glyphkicker/index.html` — all implementation
- `PoEMM/Glyphkicker/CLAUDE.md` — update build order
- **Repo:** `https://github.com/North-Fork/poemm-revival`

--------------------------------------------------------------------------------

## Step Summary

| # | Step | Scope |
|---|------|-------|
| 1 | Node factories (`makeWord`, `makeLine`, `makePassage`, `makeDocument`) | New code |
| 2 | `transferNodeBehaviours()` helper | New code |
| 3 | `layout()` Stage B — build hierarchy tree, set back-pointers | Refactor |
| 4 | AgentEngine Phase 5 — cascade tick | Refactor |
| 4b | Mixed-level selection → LCA | New code |
| 4c | Save format — emit/consume full hierarchy JSON | Refactor |
| 5 | Selection model — `selectedNode`, `selectNode()` | Refactor |
| 6 | Hierarchy-aware behaviour panel | Refactor |
| 7 | `addBehaviour` / `removeBehaviour` target `selectedNode` | Refactor |
| 8 | Undo/Redo — snapshot node behaviours via `nodeStore` | Refactor |

--------------------------------------------------------------------------------

## Verification Checklist

- [ ] Type "hello world", double-click "hello" → panel shows "Word: 'hello'"
- [ ] Add Shake to word → all 5 glyphs shake; "world" unaffected
- [ ] Single-click 'h' → panel shows inherited Shake (greyed) + glyph-level add button
- [ ] Add Flicker to 'h' → only 'h' flickers; others still just shake
- [ ] Type a char in "hello" → Shake persists on word after rebuild
- [ ] Triple-click a line → panel shows "Line: ..." with cascade count
- [ ] Undo typing → Shake still on "hello"
- [ ] Predator/Prey demo still works
- [ ] Drag across word boundary → LCA = Line selected, behaviours assign to Line
- [ ] Save → JSON contains full hierarchy with behaviours at correct levels
- [ ] Load → hierarchy restored, behaviours active immediately
