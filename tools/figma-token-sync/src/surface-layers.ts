// The names of the layers a material surface paints its fill on
// (`surface-material.ts`), apart from that module so a pure reader — the sizing
// audit — can recognise them without importing anything that draws.

/** The child that carries a surface's fill, frost and rim. */
export const kMaterialLayerName = 'material';
/** The child that carries a refracting surface's GLASS effect. */
export const kGlassLayerName = 'glass';

/**
 * Whether [node] is one of a surface's own material layers. They are its fill —
 * they stretch with the box whatever the content does — so a reader asking
 * what the content does looks past them.
 */
export function isSurfaceLayer(node: { readonly type?: unknown; readonly name?: unknown }): boolean {
  return node.type === 'RECTANGLE' && (node.name === kMaterialLayerName || node.name === kGlassLayerName);
}

/**
 * What a node needs for its own stroke to be read — structural, so this module
 * stays one a pure reader (and a test) can use with plain objects.
 */
export interface StrokeHost {
  readonly strokes?: ReadonlyArray<{ readonly visible?: boolean }>;
  readonly strokeAlign?: string;
  readonly strokeWeight?: unknown;
  readonly strokeTopWeight?: unknown;
  readonly strokeRightWeight?: unknown;
  readonly strokeBottomWeight?: unknown;
  readonly strokeLeftWeight?: unknown;
}

export interface StrokeInsets {
  readonly top: number;
  readonly right: number;
  readonly bottom: number;
  readonly left: number;
}

/**
 * How far [host]'s own stroke reaches into its box on each side — what a layer
 * painted over the box must stay clear of for the border to show. Zero for a
 * host with no visible stroke (a surface that draws its border as a `tint
 * border` layer carries none), and for a stroke drawn outside the box.
 *
 * Read when the entry has settled, so the weight is the one the builder wrote.
 * A weight bound to a row that changes per mode (a border a surface style
 * contributes) is read at the mode the file is in; a layer cannot follow it.
 *
 * The one definition: the builder insets the layers by it, and the reader that
 * compares a canvas with a designer's copy asks it whether the layers do.
 */
export function ownStrokeInsets(host: StrokeHost): StrokeInsets {
  const strokes = host.strokes;
  if (!Array.isArray(strokes) || !strokes.some((s) => s.visible !== false)) {
    return { top: 0, right: 0, bottom: 0, left: 0 };
  }
  // A frame's stroke is inside unless the builder said otherwise.
  const reach = host.strokeAlign === 'OUTSIDE' ? 0 : host.strokeAlign === 'CENTER' ? 0.5 : 1;
  const uniform = typeof host.strokeWeight === 'number' ? host.strokeWeight : 0;
  const side = (weight: unknown): number => (typeof weight === 'number' ? weight : uniform) * reach;
  return {
    top: side(host.strokeTopWeight),
    right: side(host.strokeRightWeight),
    bottom: side(host.strokeBottomWeight),
    left: side(host.strokeLeftWeight),
  };
}

/** A child as the reader below needs it. */
export interface SurfaceChildLike {
  readonly type?: unknown;
  readonly name?: unknown;
  readonly visible?: boolean;
  readonly x?: number;
  readonly y?: number;
  readonly width?: number;
  readonly height?: number;
}

/** A node that may carry a material layer: its box, its stroke and its children. */
export interface SurfaceHostLike extends StrokeHost {
  readonly width: number;
  readonly height: number;
  readonly children: ReadonlyArray<SurfaceChildLike>;
}

export interface SurfaceMaterialRead {
  /** The index of the visible `material` layer among the host's children. */
  readonly index: number;
  /**
   * Set when the layer sits over the host's own stroke and hides it, as the
   * borders of a bordered surface were hidden before the layers were inset by
   * the stroke's reach; null when the stroke shows around it (or there is none).
   */
  readonly covers: string | null;
}

const kCoverTolerance = 0.01;

/**
 * The `material` layer [host] paints its fill on, and whether it hides the
 * host's stroke — or null when the host carries no such layer. A reader that
 * compares a canvas with a designer's copy folds the layer into the host's own
 * box (the copy has fill and stroke on one node); the cover is what folding
 * would otherwise hide, so the reader reports it as a difference of its own.
 */
export function readSurfaceMaterial(host: SurfaceHostLike): SurfaceMaterialRead | null {
  const index = host.children.findIndex(
    (c) => isSurfaceLayer(c) && c.name === kMaterialLayerName && c.visible !== false,
  );
  if (index < 0) return null;
  const layer = host.children[index];
  const inset = ownStrokeInsets(host);
  if (inset.top + inset.right + inset.bottom + inset.left === 0) return { index: index, covers: null };
  const x = layer.x ?? 0;
  const y = layer.y ?? 0;
  const w = layer.width ?? host.width;
  const h = layer.height ?? host.height;
  const covered =
    x + kCoverTolerance < inset.left ||
    y + kCoverTolerance < inset.top ||
    x + w > host.width - inset.right + kCoverTolerance ||
    y + h > host.height - inset.bottom + kCoverTolerance;
  return {
    index: index,
    covers: covered
      ? `material layer covers the border — at (${x}, ${y}) ${w}x${h}, stroke reaches ${inset.left}/${inset.top}/${inset.right}/${inset.bottom}`
      : null,
  };
}
