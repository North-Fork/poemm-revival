# RFC: ComplexType Font Package (CTF) — Browser Canvas Profile (Draft 0.1)

*Refreshed:* 2026-02-28T22:43:22

## Profile Scope
- Canvas2D REQUIRED; WebGL OPTIONAL
- geometry:particles REQUIRED; geometry:strokes OPTIONAL; outline2d OPTIONAL fallback
- declarative behaviors REQUIRED; sandboxed code behaviors OPTIONAL (Worker/WASM)

## Container Layout
- /manifest.json (required)
- /fontinfo.json (required)
- /charmap.json (required)
- /modules/<id>/... (optional)
- /assets/... (optional)

## Capability Negotiation
Hosts MUST read the manifest, load supported modules, and degrade gracefully.

## Browser Concerns
- DPR-aware rendering, avoid per-frame allocations
- sandbox untrusted behavior code in Worker/WASM

## Determinism / Archival
- fixed timestep
- seeded RNG
- record/replay input stream
- snapshot external data feeds
