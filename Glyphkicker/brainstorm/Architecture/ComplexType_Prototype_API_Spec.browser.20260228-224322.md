# ComplexType Prototype API — Browser Canvas (v1)

*Refreshed:* 2026-02-28T22:43:22

## RenderBackend
```ts
export interface RenderBackend {
  readonly type: "canvas2d" | "webgl";
  resize(widthCssPx: number, heightCssPx: number, dpr: number): void;
  beginFrame(ctx: FrameContext): void;
  drawGlyph(g: GlyphInstance, ctx: FrameContext): void;
  endFrame(ctx: FrameContext): void;
  hitTest(xCssPx: number, yCssPx: number): HitResult | null;
}
```

## GeometryProvider
```ts
export type GeometryType = "particles" | "strokes" | "outline2d" | "custom";

export interface GeometryProvider {
  readonly type: GeometryType;
  instantiate(template: GlyphTemplate, seed: number): RuntimeGeometry;
  bounds(geom: RuntimeGeometry): AABB2;
  hitTest(geom: RuntimeGeometry, x: number, y: number): boolean;
  render(ctx2d: CanvasRenderingContext2D, geom: RuntimeGeometry, material: MaterialComponent): void;
}
```

## Particle Glyph Geometry
```ts
export interface Particle { x:number; y:number; vx:number; vy:number; mass:number; }
export interface Attractor { x:number; y:number; strength:number; radius:number; }

export interface ParticleGlyphGeometry {
  type: "particles";
  particles: Particle[];
  attractors: Attractor[];
}
```

## Behaviors
```ts
export interface Behavior {
  type: string;
  supports: GeometryType[];
  apply(g: GlyphInstance, ctx: UpdateContext): void;
}
```

Recommended v1 behaviors: `particle-attractor`, `repel-pointer`, `flow-field`, `noise-jitter`, `spring-to-anchor`, `fade-lifespan`.

## Determinism
- fixed timestep option
- seeded RNG per glyph instance
- record/replay input
- snapshot external data
