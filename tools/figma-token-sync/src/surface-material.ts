/// <reference types="@figma/plugin-typings" />

import { Dim, argbAlpha, argbToRgb, dimVal } from './compat/v1';
import { bindRadiusN } from './box';
import { SURFACE_GLASS } from './data';
import {
  CastRow,
  ColorData,
  bindCast,
  composedColorPaint,
  deferMaterialLayers,
  fillData,
  insetLayerCorners,
  pinInFlow,
  solid,
} from './paint';
import { VarLookup } from './variables';
import { StrokeHost, isSurfaceLayer, kGlassLayerName, kMaterialLayerName, ownStrokeInsets } from './surface-layers';
import { isParkedForRedraw } from './redraw-keep';

// Surface material — the part of a surface style's material a number can carry,
// drawn on the canvas.
//
// A surface style can make a surface translucent, frost what is behind it, bend
// it at the rim and light an inset rim along it. Each is a value per style, and
// the token export carries them as rows of `Semantic/ Surface`, whose modes are
// the styles — so a frame pinned to a mode shows that style's material. Under
// the default style every row is identity (the fill at 100, no frost, the rim at
// zero alpha, the glass hidden), so a default frame draws what the single fill
// drew.
//
// None of it can ride on the surface node itself:
//
//  · the fill's share is an opacity, and the node's opacity would fade the
//    content on it too. So the fill moves to a child, `material`, behind the
//    content: its opacity binds the share, its effects carry the backdrop blur
//    and the rim, and the content stays at full strength as its sibling above.
//  · the bend is a GLASS effect, which takes no variable. It lives on a second
//    child, `glass`, with fixed dials (`SURFACE_GLASS`, from `components.json`)
//    and its visibility bound to the style's BOOLEAN row.
//  · an effect style REPLACES a node's effects, so the material's effects
//    cannot share a node with a cast that links one. The cast and the stroke
//    stay on the surface node; the material lives a layer below. A child paints
//    over its parent's stroke, so both layers are sized inside the stroke's
//    reach (`ownStrokeInsets`, paint.ts) and the border shows around them,
//    their corners pulled in by the same reach (`insetLayerCorners`) so the
//    fill meets the border's inner edge instead of leaving a sliver at it.
//
// What a surface wears is decided where the surface is drawn — a builder routes
// its surface fill here when the code it mirrors marks that element a material
// surface, with the role the code states. This module holds no component list.

/** The surface kinds of `CoreSurfaceRole`, spelled as its `.name`. */
export type SurfaceRole = 'content' | 'functional';

export { isSurfaceLayer, kGlassLayerName, kMaterialLayerName };

// Marks a layer this module made, so it is found again by the mark — a
// designer's own layer that happens to be called `material` is never taken.
const kLayerMarkerKey = 'coui-surface-layer';

// The most rim or cast layers read off the rows. The export states one of each
// today; this only stops a lookup that answers every index from looping forever.
const kMaxStyleLayers = 8;

// What the glass layer paints. Figma refracts through a layer that paints
// something, and this is the least that does — white, so it adds no hue. A
// structural device rather than a design value: the material layer below
// carries the surface's own fill.
const kGlassCarrierAlpha = 0.01;

// The glass layer's own frost. Zero: the frost is the material layer's bound
// background blur, and a second one here would frost twice with a radius no
// mode could move.
const kGlassFrost = 0;

/**
 * Four corners stated one by one — a surface whose corners differ (a chat
 * bubble squares the one its tail leaves from). A `null` corner copies the
 * surface's literal for that corner, for one the code states as a number with
 * no step.
 */
export interface SurfaceCorners {
  topLeft: number | Dim | null;
  topRight: number | Dim | null;
  bottomLeft: number | Dim | null;
  bottomRight: number | Dim | null;
}

type CornerField = 'topLeftRadius' | 'topRightRadius' | 'bottomLeftRadius' | 'bottomRightRadius';

export interface SurfaceMaterialOpts {
  /**
   * The corner radius the builder binds on the surface — one step for all four
   * or each corner's own — so the layers bind the same steps and round with it
   * under every mode. `null` copies the surface's literal corners, for a corner
   * that is a derived number with no step.
   */
  radius: number | Dim | SurfaceCorners | null;
  /**
   * Whether the surface takes the style's inset rim. Both platforms opt a
   * surface into the rim in its own source (`resolveSurfaceRim` on Flutter,
   * the rim variable on Web), so the builder states it where it draws.
   */
  rim?: boolean;
}

interface MaterialRows {
  fillOpacity: Variable;
  backdropBlur: Variable;
  glass: Variable;
  rims: CastRow[];
}

// Layer rows `<n>/x|y|blur|color` for n = 0, 1, … until a layer is missing.
function layerRows(read: (n: number, field: 'x' | 'y' | 'blur' | 'color') => Variable | undefined): CastRow[] {
  const out: CastRow[] = [];
  for (let n = 0; n < kMaxStyleLayers; n++) {
    const x = read(n, 'x');
    const y = read(n, 'y');
    const blur = read(n, 'blur');
    const color = read(n, 'color');
    if (!x || !y || !blur || !color) break;
    out.push({ x: x, y: y, blur: blur, color: color });
  }
  return out;
}

// The rows of [role], or null when the document lacks any of the three — a
// half-bound material never happens: either the surface follows the style or
// it draws the single fill it always drew.
function materialRows(lk: VarLookup, role: SurfaceRole): MaterialRows | null {
  const fillOpacity = lk.materialRowOrNull(role, 'fill-opacity');
  const backdropBlur = lk.materialRowOrNull(role, 'backdrop-blur');
  const glass = lk.materialRowOrNull(role, 'glass');
  if (!fillOpacity || !backdropBlur || !glass) return null;
  return {
    fillOpacity: fillOpacity,
    backdropBlur: backdropBlur,
    glass: glass,
    rims: layerRows((n, field) => lk.materialRimRowOrNull(n, field)),
  };
}

/**
 * Whether [fill] paints anything — a token at a share above zero, or a raw
 * colour with alpha. The same test both platforms put a material and a
 * contributed cast behind (a cast is the shadow of a filled box).
 */
export function paintsFill(fill: ColorData | null | undefined): boolean {
  if (!fill) return false;
  if (fill.color == null) return fill.argb != null && argbAlpha(fill.argb, fill.opacity) > 0;
  return (fill.opacity == null ? 1 : fill.opacity) > 0;
}

// The surface's fill as the material layer paints it, or null when the
// surface paints nothing. A token below full strength keeps its own alpha in a
// composed colour, because the layer's opacity is the style's share.
function materialPaint(lk: VarLookup, fill: ColorData | null | undefined, consumer: SceneNode): SolidPaint | null {
  if (!fill || !paintsFill(fill)) return null;
  if (fill.color == null) {
    return { type: 'SOLID', color: argbToRgb(fill.argb!), opacity: argbAlpha(fill.argb!, fill.opacity) };
  }
  const alpha = fill.opacity == null ? 1 : fill.opacity;
  return alpha >= 1 ? solid(lk.sem(fill.color), 1, consumer) : composedColorPaint(lk, fill.color, alpha, consumer);
}

function inInstance(node: BaseNode): boolean {
  for (let scan: BaseNode | null = node; scan != null; scan = scan.parent) {
    if (scan.type === 'INSTANCE') return true;
  }
  return false;
}

// A layer this module made on [host], found by its mark. A duplicate (two runs
// that both appended) is removed so one layer carries the material.
function ownLayer(host: FrameNode | ComponentNode, name: string): RectangleNode | undefined {
  const found = host.children.filter(
    // An old layer parked for a redraw is not this draw's to reuse — the
    // reconcile pairs it with the layer this draw makes (`redraw-keep.ts`).
    (c) =>
      c.type === 'RECTANGLE' &&
      c.name === name &&
      c.getPluginData(kLayerMarkerKey) === name &&
      !isParkedForRedraw(c),
  ) as RectangleNode[];
  for (const extra of found.slice(1)) extra.remove();
  return found[0];
}

// The same layer as an instance carries it, copied from its main component.
// Found by name: a copy's plugin data is not the main component's to read.
function instanceLayer(host: ChildrenMixin, name: string): RectangleNode | undefined {
  return host.children.find((c) => c.type === 'RECTANGLE' && c.name === name) as RectangleNode | undefined;
}

function newLayer(host: FrameNode | ComponentNode, name: string, index: number): RectangleNode {
  const layer = figma.createRectangle();
  layer.name = name;
  layer.setPluginData(kLayerMarkerKey, name);
  host.insertChild(Math.min(index, host.children.length), layer);
  pinInFlow(host, layer);
  layer.resize(Math.max(host.width, 0.01), Math.max(host.height, 0.01));
  layer.x = 0;
  layer.y = 0;
  return layer;
}

function removeOwnLayers(host: FrameNode | ComponentNode): void {
  for (const name of [kMaterialLayerName, kGlassLayerName]) {
    for (const c of host.children.slice()) {
      if (isParkedForRedraw(c)) continue;
      if (c.type === 'RECTANGLE' && c.name === name && c.getPluginData(kLayerMarkerKey) === name) c.remove();
    }
  }
}

// The layer rounds with the surface: bound to the surface's own step, or its
// literal corners copied when it has no step.
function roundLike(
  layer: RectangleNode,
  surface: SceneNode,
  lk: VarLookup,
  radius: number | Dim | SurfaceCorners | null,
): void {
  const literal = surface as unknown as Partial<Record<CornerField, number>>;
  const copy = (field: CornerField): void => {
    layer[field] = literal[field] ?? 0;
  };
  if (radius != null && typeof radius === 'object' && 'topLeft' in radius) {
    const each: [CornerField, number | Dim | null][] = [
      ['topLeftRadius', radius.topLeft],
      ['topRightRadius', radius.topRight],
      ['bottomLeftRadius', radius.bottomLeft],
      ['bottomRightRadius', radius.bottomRight],
    ];
    for (const [field, value] of each) {
      if (value == null) copy(field);
      else layer.setBoundVariable(field, lk.radius(dimVal(value)));
    }
    return;
  }
  if (radius != null) {
    bindRadiusN(layer, lk, radius);
    return;
  }
  copy('topLeftRadius');
  copy('topRightRadius');
  copy('bottomLeftRadius');
  copy('bottomRightRadius');
}

/**
 * The `material` layer [node] carries — its own (found by the mark) or, inside
 * an instance, the copy of its main component's (found by name) — or null.
 */
export function surfaceMaterialLayer(node: SceneNode & ChildrenMixin): RectangleNode | null {
  if (node.type === 'INSTANCE' || inInstance(node)) {
    return instanceLayer(node, kMaterialLayerName) ?? null;
  }
  return ownLayer(node as FrameNode | ComponentNode, kMaterialLayerName) ?? null;
}

/**
 * Re-rounds [node]'s material layers to [radius] — for a composer that forwards
 * a corner onto a composed surface: the instance root takes the corner, and the
 * layers under it would keep the main component's. A no-op without layers.
 */
export function roundSurfaceLayers(node: SceneNode & ChildrenMixin, lk: VarLookup, radius: number | Dim): void {
  const own = !(node.type === 'INSTANCE' || inInstance(node));
  const inset = ownStrokeInsets(node as unknown as StrokeHost);
  for (const name of [kMaterialLayerName, kGlassLayerName]) {
    const layer = own ? ownLayer(node as FrameNode | ComponentNode, name) : instanceLayer(node, name);
    if (layer == null) continue;
    bindRadiusN(layer, lk, radius);
    insetLayerCorners(layer, inset);
  }
}

/**
 * Repoints a composed surface at [fill]: the instance's copy of its main
 * component's `material` layer takes the colour and the instance root paints
 * none, and the layers re-round to [radius] when the composer forwards one
 * (`null` leaves the main component's corners). Returns false when [node]
 * carries no material layer — an instance of a component that is not a material
 * surface, or one predating the layers — so the caller paints the root the way
 * it always did.
 */
export function repointSurfaceMaterial(
  node: SceneNode & ChildrenMixin & MinimalFillsMixin,
  lk: VarLookup,
  fill: ColorData | null | undefined,
  radius: number | Dim | SurfaceCorners | null,
): boolean {
  const material = surfaceMaterialLayer(node);
  if (material == null) return false;
  node.fills = [];
  const paint = materialPaint(lk, fill, material);
  material.fills = paint == null ? [] : [paint];
  if (radius != null) {
    const own = !(node.type === 'INSTANCE' || inInstance(node));
    const inset = ownStrokeInsets(node as unknown as StrokeHost);
    for (const name of [kMaterialLayerName, kGlassLayerName]) {
      const layer = own ? ownLayer(node as FrameNode | ComponentNode, name) : instanceLayer(node, name);
      if (layer == null) continue;
      roundLike(layer, node, lk, radius);
      insetLayerCorners(layer, inset);
    }
  }
  return true;
}

// The `material` layer's effects: the frost bound to the role's blur, then —
// only on a surface that casts its own shadow — the style's rim, each field
// bound to its row. Literals are the default style's, so with the rows at
// identity the layer draws nothing a single fill did not.
function materialEffects(rows: MaterialRows, rim: boolean): Effect[] {
  const frost = figma.variables.setBoundVariableForEffect(
    { type: 'BACKGROUND_BLUR', blurType: 'NORMAL', radius: 0, visible: true },
    'radius',
    rows.backdropBlur,
  );
  const rims = rim
    ? rows.rims.map((row) =>
        bindCast(
          {
            type: 'INNER_SHADOW',
            color: { r: 1, g: 1, b: 1, a: 0 },
            offset: { x: 0, y: 0 },
            radius: 0,
            spread: 0,
            visible: true,
            blendMode: 'NORMAL',
          },
          row,
        ),
      )
    : [];
  return [frost as Effect].concat(rims);
}

/**
 * Turns the style's rim on or off on [node]'s material layer — its own, or the
 * copy an instance carries of its main component's.
 *
 * A rim decorates a surface that casts its own shadow; it does not raise a flat
 * one. Both platforms key it on the stack the surface states, so a composed
 * surface that a composer makes cast (a mockup's container, a lifted card)
 * takes the rim its main component — flat — does not carry. Written only when
 * the layer's rim differs from [on], so an instance that agrees with its main
 * gathers no override.
 *
 * A no-op on a surface without a material layer, and in a document without the
 * rows — such a surface draws the single fill, which has no rim to carry.
 */
export function setSurfaceRim(
  node: SceneNode & ChildrenMixin,
  lk: VarLookup,
  role: SurfaceRole,
  on: boolean,
): void {
  const material = surfaceMaterialLayer(node);
  if (material == null) return;
  const rows = materialRows(lk, role);
  if (rows == null) return;
  const lit = (material.effects as readonly Effect[]).some((e) => e.type === 'INNER_SHADOW');
  if (lit === on) return;
  material.effects = materialEffects(rows, on);
}

/**
 * Paints [fill] as a surface of [role]: the fill on a `material` child bound to
 * the style's share, frost and (when [opts.rim]) rim, and a `glass` child that
 * refracts under a style that bends. The surface node keeps its stroke and cast.
 *
 * Idempotent on a persistent node — the layers are found by their mark and
 * rewritten. On an instance (a builder recolouring a composed surface) the
 * layers belong to the main component, so the instance's `material` layer is
 * repointed at [fill] and rounded to [opts.radius]; an instance of a main
 * component that predates the layers gets the single fill.
 *
 * Degrades to the single fill (`fillData`) in a document without the rows, and
 * for a surface that paints nothing — a material behind no fill has nothing to
 * be translucent.
 */
export function applySurfaceMaterial(
  node: FrameNode | ComponentNode | InstanceNode,
  lk: VarLookup,
  fill: ColorData | null | undefined,
  role: SurfaceRole,
  opts: SurfaceMaterialOpts,
): void {
  if (node.type === 'INSTANCE' || inInstance(node)) {
    // The main component's role stands: an instance cannot rebind its layers.
    if (!repointSurfaceMaterial(node, lk, fill, opts.radius)) fillData(node, lk, fill);
    return;
  }

  const host = node as FrameNode | ComponentNode;
  const rows = materialRows(lk, role);
  const paint = rows == null ? null : materialPaint(lk, fill, host);
  if (rows == null || paint == null) {
    removeOwnLayers(host);
    fillData(host, lk, fill);
    return;
  }

  host.fills = [];
  const material = ownLayer(host, kMaterialLayerName) ?? newLayer(host, kMaterialLayerName, 0);
  material.fills = [paint];
  // The node takes the default share before the binding, the way a bound
  // opacity is written everywhere else (`bindLayerOpacity`).
  material.opacity = 1;
  material.setBoundVariable('opacity', rows.fillOpacity);
  material.effects = materialEffects(rows, opts.rim === true);
  roundLike(material, host, lk, opts.radius);
  const layers = [material];

  const dials = SURFACE_GLASS;
  if (dials == null) {
    const stale = ownLayer(host, kGlassLayerName);
    if (stale != null) stale.remove();
  } else {
    const glass = ownLayer(host, kGlassLayerName) ?? newLayer(host, kGlassLayerName, 1);
    glass.fills = [{ type: 'SOLID', color: { r: 1, g: 1, b: 1 }, opacity: kGlassCarrierAlpha }];
    const effect: GlassEffect = {
      type: 'GLASS',
      visible: true,
      lightIntensity: dials.lightIntensity,
      lightAngle: dials.lightAngle,
      refraction: dials.refraction,
      depth: dials.depth,
      dispersion: dials.dispersion,
      radius: kGlassFrost,
    };
    glass.effects = [effect];
    // Hidden at rest — the default style's answer — and then bound.
    glass.visible = false;
    glass.setBoundVariable('visible', rows.glass);
    roundLike(glass, host, lk, opts.radius);
    layers.push(glass);
  }
  deferMaterialLayers(host, layers);
}

/**
 * Binds [node] — a shape that carries a surface's fill past the surface's own
 * box, such as a tail — to the share of that fill the [role] material keeps, so
 * the two halves of one silhouette stay one material. Both platforms paint such
 * a shape from the surface's fill at that share: Flutter folds the share into
 * the colour it paints, and Web gives the shape the surface's computed fill.
 * The share only — the frost and the rim belong to the surface's box.
 *
 * A no-op in a document without the row, where the surface draws its single
 * fill and the shape keeps the full one beside it.
 */
export function bindSurfaceShare(node: SceneNode & MinimalBlendMixin, lk: VarLookup, role: SurfaceRole): void {
  const share = lk.materialRowOrNull(role, 'fill-opacity');
  if (share == null) return;
  // The default share before the binding, as on the material layer.
  node.opacity = 1;
  node.setBoundVariable('opacity', share);
}

/**
 * Appends the cast a surface style gives a control that casts none —
 * `material/control-shadow/<n>/*` — to [node]'s effects, at zero alpha under
 * every style that gives none. For a node whose own cast at rest is empty;
 * one that casts bends its own shadow through `setShadow` instead.
 *
 * Replaces a contributed cast a previous call left, recognised by its bound
 * colour, so a re-run does not stack a second one.
 */
export function addControlShadow(node: SceneNode & { effects: readonly Effect[] }, lk: VarLookup): void {
  const rows = layerRows((n, field) => lk.controlShadowRowOrNull(n, field));
  if (rows.length === 0) return;
  const ids = new Set(rows.map((row) => row.color.id).filter((id) => id != null && id !== ''));
  const kept = node.effects.filter(
    (e) => !(e.type === 'DROP_SHADOW' && ids.has(e.boundVariables?.color?.id ?? '')),
  );
  const casts = rows.map((row) =>
    bindCast(
      {
        type: 'DROP_SHADOW',
        color: { r: 0, g: 0, b: 0, a: 0 },
        offset: { x: 0, y: 0 },
        radius: 0,
        spread: 0,
        visible: true,
        blendMode: 'NORMAL',
      },
      row,
    ),
  );
  node.effects = kept.concat(casts);
}

/**
 * Gives a surface that draws no boundary the one a surface style contributes
 * — an `outline` stroke inside its edge, its weight bound to
 * `material/control-border` (0 under every style that gives none). The colour
 * is the palette's `outline`, as `CoreSurfaceGeometryConstraint.controlBorder`
 * states and both platforms paint it. Not for a surface with a border of its
 * own: a style floors that one through `stroke/*`.
 */
export function addControlBorder(node: SceneNode & MinimalStrokesMixin, lk: VarLookup): void {
  const weight = lk.controlBorderOrNull();
  if (weight == null) return;
  node.strokes = [solid(lk.sem('outline'), 1, node)];
  node.strokeAlign = 'INSIDE';
  // The default style's width before the binding, so a reader of the literal
  // sees the stroke the default draws: none.
  node.strokeWeight = 0;
  node.setBoundVariable('strokeWeight', weight);
}
