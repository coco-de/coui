/// <reference types="@figma/plugin-typings" />

import { Color, Dim, colorData, dimVal, familyTokenOf, isDim, textStyleData } from './compat/v1';
import { VarLookup } from './variables';
import {
  bestVariantName,
  bindVisibleProp,
  defineProp,
  setInstanceTextNamed,
} from './component-props';
import { BUTTON } from './data';
import { instanceOf } from './identity';
import {
  applyLetterSpacing,
  hasHangul,
  monoFaceUsable,
  paintHangulRunsSans,
  sansTargetOf,
} from './text-nodes';
import {
  ColorData,
  GradientData,
  borderData,
  gradientPaint,
  paintTokenFill,
  pinAbsolute,
  pinInFlow,
  setShadow,
  solid,
} from './paint';
import {
  PadData,
  bindBox,
  bindPad,
  bindRadiusN,
  bindSize,
  bindSpaceField,
  bindStrokeAxis,
} from './box';
import { fillData, insetLayerCorners, weightStyle } from './paint';
import { repointSurfaceMaterial, roundSurfaceLayers, surfaceMaterialLayer } from './surface-material';
import { StrokeHost, isSurfaceLayer, ownStrokeInsets } from './surface-layers';

// Reaching into an instance's subtree, and what Figma allows once you are there.
//
// A composed child arrives as an INSTANCE, and its descendants are not freely
// editable: some properties Figma refuses outright, some only on the instance root,
// and text inside one needs its own route. Everything here is about that boundary —
// overriding a label's style, revealing a value over a placeholder, forwarding a
// caller's button or panel chrome, drawing a focus ring on a host that owns none.
//
// This is the block the old dividers hid worst: 626 lines of it sat under one that
// said "Figma component properties", so a reader looking for any of it had no reason
// to open that section. It could only move after `paint`/`box` did — it draws
// through both, and pulling it out first would have made them import each other.
export function suppressFieldChrome(
  field: InstanceNode,
  lk: VarLookup,
  chromeless: {
    backgroundColor?: { argb?: number; ref?: string | null } | null;
    borderColor?: { argb?: number; ref?: string | null } | null;
    borderWidth?: { v: number } | null;
    /// The forwarded inset. `chromelessFieldStyle` states `padding: .zero` for the
    /// same reason it states a transparent fill — the outer box owns the box, so
    /// the field inside it owns no inset either. Applied to the field row rather
    /// than to the instance root: the root is the label column, and its padding is
    /// not what puts space around the text.
    padding?: PadData | null;
  },
): void {
  const clearsFill = isTransparentLeaf(chromeless.backgroundColor);
  const clearsStroke =
    isTransparentLeaf(chromeless.borderColor) ||
    (chromeless.borderWidth != null && chromeless.borderWidth.v === 0);
  if (!clearsFill && !clearsStroke) return;
  const walk = (node: SceneNode) => {
    const paintable = node as unknown as {
      fills?: unknown;
      strokes?: unknown;
      children?: readonly SceneNode[];
    };
    // The field's own INK is not its chrome: a TEXT node's fill is the glyph
    // colour (the placeholder's `placeholder` / `disabled-content` tone) and the
    // `caret` rectangle's fill is the caret colour. Clearing them with the box
    // left a composed field whose placeholder was visible and invisible at once
    // (`nofill`), and a caret with nothing to paint.
    const isInk = node.type === 'TEXT' || node.name === kFieldCaretName;
    if (clearsFill && !isInk && Array.isArray(paintable.fills)) {
      (node as SceneNode & MinimalFillsMixin).fills = [];
    }
    // A field whose box the outer box owns wears no material either: its fill
    // went with the line above, and the frost and glass would otherwise stay on
    // an empty layer.
    if (clearsFill && isSurfaceLayer(node)) {
      (node as RectangleNode).effects = [];
    }
    if (clearsStroke && Array.isArray(paintable.strokes)) {
      (node as SceneNode & MinimalStrokesMixin).strokes = [];
    }
    if (paintable.children != null) {
      for (const kid of paintable.children) walk(kid);
    }
  };
  walk(field);
  // The inset, on the row the field's own chrome sits on. Named lookup rather
  // than a walk: `padding` belongs to exactly one node and writing it on every
  // frame in the subtree would inset the label column too.
  if (chromeless.padding != null) {
    for (const node of field.children) {
      if (node.type !== 'FRAME' || node.name !== kFieldRowName) continue;
      bindPad(node, lk, chromeless.padding);
    }
  }
}

export function expandInstanceLabel(inst: InstanceNode): void {
  for (const text of ownTextNodes(inst)) {
    text.layoutSizingHorizontal = 'FILL';
  }
}

// Widened from `InstanceNode` to any node that owns children, because the
// forwarders below reach a NAMED FRAME inside an instance and then want that
// frame's own text — `applyForwardedCollapsibleStyle` gives the trigger row and
// the body two different roles, so "every text under the instance" is the wrong
// set for both. The walk is unchanged, including the stop at a nested INSTANCE:
// a composed grandchild owns its own text.
export function ownTextNodes(
  inst: InstanceNode | FrameNode | ComponentNode,
): TextNode[] {
  const out: TextNode[] = [];
  const walk = (node: SceneNode): void => {
    if (node.type === 'TEXT') {
      out.push(node);
      return;
    }
    if (node.type === 'INSTANCE') return;
    if ('children' in node) {
      for (const kid of node.children) walk(kid);
    }
  };
  for (const kid of inst.children) walk(kid);
  return out;
}

export function namedDescendant(inst: InstanceNode, name: string): FrameNode {
  const hits = inst.findAll((n) => n.type === 'FRAME' && n.name === name);
  const first = hits.length > 0 ? hits[0] : null;
  if (first == null || first.type !== 'FRAME') {
    throw new Error(
      `namedDescendant('${name}'): no such FRAME under ${inst.name}. The child ` +
        'builder renamed it — update this name, or the override lands nowhere.',
    );
  }
  return first;
}

export const kFieldRowName = 'field';

/// The caret rectangle `TextField` draws in every member, visible on `focus` only.
export const kFieldCaretName = 'caret';

/**
 * Shows the caret a composed `TextField` carries (hidden on every member but
 * `focus`). A parent whose pose is focus while its field member is the
 * enabled one — the field draws no ring of its own, the parent's border is the
 * boundary — states the caret this way, from the child's own node (width,
 * radius and colour are the field's `cursor*` fields). Throws when there is
 * none: a focus pose with no caret is green in every other signal.
 */
export function revealFieldCaret(inst: InstanceNode): void {
  const carets = inst.findAll((n) => n.name === kFieldCaretName);
  if (carets.length === 0) {
    throw new Error(
      `revealFieldCaret: ${inst.name} has no '${kFieldCaretName}' node — ` +
        'TextField renamed its caret, and the focus pose would show none.',
    );
  }
  for (const caret of carets) caret.visible = true;
}

/**
 * Writes the copy of the composed `TextField`'s placeholder through the
 * instance's own `Placeholder` TEXT property — the handle the field surfaces;
 * the text node inside cannot take a property override of its own.
 */
export function setFieldPlaceholder(inst: InstanceNode, text: string): void {
  const props: ComponentProperties | undefined = inst.componentProperties;
  const patch: { [key: string]: string } = {};
  if (props) {
    for (const key of Object.keys(props)) {
      if (key.split('#')[0] === 'Placeholder' && props[key].type === 'TEXT') patch[key] = text;
    }
  }
  if (Object.keys(patch).length !== 1 || typeof inst.setProperties !== 'function') {
    throw new Error(
      `setFieldPlaceholder: ${inst.name} does not surface exactly one 'Placeholder' ` +
        'TEXT property — TextField renamed it, or this is not a TextField.',
    );
  }
  inst.setProperties(patch);
}

export const kFieldInputName = 'input';

export const kFieldValueName = 'value';

export function paintPlaceholder(
  inst: InstanceNode,
  lk: VarLookup,
  cd: ColorData | null | undefined,
): void {
  if (!cd) return;
  const input = namedDescendant(inst, kFieldInputName);
  let painted = 0;
  for (const node of input.children) {
    // Not filtered on `visible`: a field showing its value has the placeholder
    // hidden beneath it (`revealValueOverPlaceholder`) and the colour still has
    // to be right for when it is not. The value is a frame rather than a TEXT
    // child of this stack — which is why the sibling helper can expect exactly
    // one text node here — so there is nothing to exclude by name.
    if (node.type !== 'TEXT') continue;
    fillData(node, lk, cd);
    painted += 1;
  }
  if (painted === 0) {
    throw new Error(
      `paintPlaceholder: ${inst.name} has no placeholder TEXT node in ` +
        `'${kFieldInputName}' — the parent states a placeholder colour and there ` +
        'is nothing showing it. The composed field\'s input stack changed shape.',
    );
  }
}

/**
 * Writes the BOOLEAN property `key` on `inst` — the key a layer inside it is
 * bound to, read off that layer's `componentPropertyReferences`. Throws when the
 * instance does not surface it: a layer bound to a property its own instance
 * cannot set is a field that cannot be driven, and a silent return would leave
 * the two strings stacked.
 */
function setBoundVisible(inst: InstanceNode, key: string, value: boolean): void {
  const props = inst.componentProperties;
  if (!props || !(key in props) || props[key].type !== 'BOOLEAN') {
    throw new Error(
      `revealValueOverPlaceholder: the placeholder of ${inst.name} is bound to ` +
        `'${key}', which the instance does not surface as a BOOLEAN ` +
        `(has: ${Object.keys(props ?? {}).map((k) => k.split('#')[0]).join(', ')}). ` +
        'Hiding the layer directly would be overridden by the binding.',
    );
  }
  const patch: { [k: string]: boolean } = {};
  patch[key] = value;
  inst.setProperties(patch);
}

export function revealValueOverPlaceholder(inst: InstanceNode): void {
  const input = namedDescendant(inst, kFieldInputName);
  const value = namedDescendant(inst, kFieldValueName);
  // `layoutPositioning` is refused on a node inside an instance — and this node is
  // BY DEFINITION inside one: it is a part of the composed `TextField` being
  // patched. So the write cannot be made, and the two sizing writes below can (the
  // instance-override surface allows sizing, not positioning).
  //
  // This one line failed `ColorPicker` and `TimePicker` for four runs, leaving
  // both half-drawn on the page.
  // It was invisible three ways at once: every static check read it as legal
  // (the property is written on a plain frame, not on an instance), the harness
  // double did not model the property at all, and Figma's own refusal names the
  // property and never the node — so the message said `layoutPositioning` while
  // twenty other sites also wrote it and the two components that died were the
  // only two calling THIS function (`DatePicker`, which calls the same
  // `appendPopoverWrapper` and the same `pinAbsolute`, built every time).
  //
  // What the write was for: the value node ships ABSOLUTE, stacked over the
  // placeholder. `layoutSizingHorizontal = 'FILL'` on an absolute child is what
  // actually puts it in flow for our purposes — it takes the row's width — and the
  // stack hugs it because the placeholder beneath is hidden below. The positioning
  // itself belongs to `TextField`'s main component and cannot be overridden from
  // here, so it is left to it.
  value.layoutSizingHorizontal = 'FILL';
  value.layoutSizingVertical = 'HUG';
  let hidden = 0;
  for (const node of input.children) {
    if (node.type !== 'TEXT') continue;
    // A placeholder whose `visible` the field binds to a BOOLEAN (`Show
    // placeholder`) is driven by that property: a write to the layer itself is
    // assigning around the binding, which the property wins back. It is hidden
    // the way a designer hides it — through the instance's own property. A
    // field that binds nothing there has no such handle, so the layer is
    // written directly.
    const driver = node.componentPropertyReferences?.visible;
    if (driver !== undefined) {
      setBoundVisible(inst, driver, false);
    } else {
      node.visible = false;
    }
    hidden += 1;
  }
  // Loud, like the patch above and for the same reason: a field showing two
  // copies of its value is green in every other signal here — the canvas holds
  // the component and every value it states is right.
  if (hidden !== 1) {
    throw new Error(
      `revealValueOverPlaceholder: hid ${hidden} placeholder text node(s) on ` +
        `${inst.name}, wanted 1 (in '${kFieldInputName}', beneath the value in ` +
        `'${kFieldValueName}'). TextField's input stack changed shape.`,
    );
  }
}

export function applyInstanceTextStyle(
  inst: InstanceNode | FrameNode | ComponentNode,
  lk: VarLookup,
  ts: ReturnType<typeof textStyleData>,
  // Which of the instance's own text nodes the style is for — every one,
  // unless the child draws more than one text role and the forward names one
  // of them (a chip's label beside its key).
  which: (node: TextNode) => boolean = () => true,
): void {
  // A code role names its own family (monospace) and its own line box; every
  // other role names neither and draws in the text face, which is all this
  // used to know. The family drawn falls back to the text face when the mono
  // face did not load — `makeLabel`'s rule, so the binding names what renders.
  const face = weightStyle(ts.fontWeight);
  const family =
    familyTokenOf(ts.fontFamily) === 'mono' && monoFaceUsable(face) ? 'mono' : 'sans';
  for (const node of ownTextNodes(inst)) {
    if (!which(node)) continue;
    if (ts.fontWeight != null || family === 'mono') {
      node.fontName = { family: lk.fontFamilyName(family), style: face };
      if (family === 'mono') node.setBoundVariable('fontFamily', lk.fontFamily('mono'));
    }
    if (ts.fontSize != null) {
      node.fontSize = ts.fontSize;
      // Bound when the step exists on the scale, literal when it does not —
      // `makeLabel`'s own rule, for the same reason: an unbound number renders,
      // a throw fails the entry and leaves half a component on the page.
      const sizeVar = lk.fontSizeOrNull(ts.fontSize);
      if (sizeVar) node.setBoundVariable('fontSize', sizeVar);
    }
    // With the size, never after it: the pixels are the ratio times whatever
    // size this node now renders at, and leaving the child's tracking behind is
    // how a forwarded style arrives at the right size and the wrong width.
    // A colour-only repaint (`{role: null, color}`) states no typography at all,
    // and must leave the node's tracking as the child drew it. Writing "no
    // ratio" there reset it to PERCENT 0 — DatePicker's and TimePicker's value
    // text, Select's, lost their role's −1% to a call that only meant to tint.
    const statesTypography = ts.fontSize != null || ts.letterSpacing != null || ts.role != null;
    const renderedSize = ts.fontSize ?? (typeof node.fontSize === 'number' ? node.fontSize : null);
    if (statesTypography && renderedSize != null) {
      applyLetterSpacing(node, lk, { em: ts.letterSpacing, size: renderedSize, role: ts.role });
    }
    if (ts.lineHeightPx != null) {
      node.lineHeight = { unit: 'PIXELS', value: ts.lineHeightPx };
    } else if (ts.lineHeight != null) {
      node.lineHeight = { unit: 'PERCENT', value: ts.lineHeight * 100 };
    }
    if (ts.color != null) fillData(node, lk, ts.color);
    // The monospace face has no Hangul — paint it in the text face, as a label.
    if (family === 'mono' && typeof node.characters === 'string' && hasHangul(node.characters)) {
      paintHangulRunsSans(node, sansTargetOf(lk), { face });
    }
  }
}

// A parent handing the `valueStyle` of the `CoreTextFieldStyle` it forwards to a
// `TextField` it composes (FormattedInput's segment, ObjectInput's fields). The
// instance draws TextField's own md text until this reaches it, so a forward
// that names a code role would render in the body role — the size matching by
// accident is how that went unseen. The placeholder takes the same typography:
// in code both derive from the one segment style, and only the value side is
// exported (the placeholder overlay states a colour this does not repaint).
export function applyForwardedFieldText(
  inst: InstanceNode,
  lk: VarLookup,
  valueStyle: Parameters<typeof textStyleData>[0],
  /// The role the forward states for the hint on its own (`placeholderStyle`).
  /// A parent whose hint is not set in the value's role (a mask pattern in the
  /// body face over a value on the code grid) passes it; without one the
  /// placeholder takes the value's typography, as before. Only the role is
  /// repainted — never a colour, so the field's own placeholder and disabled
  /// tones stay the field's.
  placeholderStyle?: Parameters<typeof textStyleData>[0],
): void {
  if (valueStyle == null) return;
  const typed = (style: Parameters<typeof textStyleData>[0]) => ({
    ...textStyleData(style),
    color: null,
  });
  applyInstanceTextStyle(namedDescendant(inst, kFieldValueName), lk, typed(valueStyle));
  applyInstanceTextStyle(
    namedDescendant(inst, kFieldInputName),
    lk,
    typed(placeholderStyle ?? valueStyle),
  );
}

// The two frames `buildCollapsible` names inside every `Collapsible` member —
// the trigger row and the disclosed body. Exported so the forwarder below and
// the builder that names them are one string apart, not two.
export const kCollapsibleHeaderName = 'header';

export const kCollapsibleBodyName = 'body';

// A parent handing over the `CoreCollapsibleStyle` it states for a `Collapsible`
// it composes — the disclosure counterpart of `applyForwardedButtonStyle` /
// `applyForwardedPanelStyle`, and it exists for the same reason: the instance
// renders the CHILD's defaults until the parent's partial reaches it, and a
// canvas that shows the child's defaults where the parent overrode them is
// wrong in exactly the way nobody notices (it looks finished).
//
// Reaches two named frames rather than the whole subtree, because the trigger
// and the body carry DIFFERENT roles — `Footer` gives both `labelLarge` but the
// trigger keeps the child's `medium` weight overlay, so painting every text node
// with one style would flatten that. `namedDescendant` throws if either name
// moves, which is the loud failure this file prefers to a silent no-op.
export function applyForwardedCollapsibleStyle(
  disclosure: InstanceNode,
  lk: VarLookup,
  style: {
    contentInset?: PadData | null;
    iconLabelGap?: number | Dim | null;
    triggerTextStyle?: ReturnType<typeof textStyleData> | null;
    contentTextStyle?: ReturnType<typeof textStyleData> | null;
  },
): void {
  const header = namedDescendant(disclosure, kCollapsibleHeaderName);
  const body = namedDescendant(disclosure, kCollapsibleBodyName);
  if (style.iconLabelGap != null) {
    bindSpaceField(header, 'itemSpacing', lk, dimVal(style.iconLabelGap));
  }
  if (style.contentInset != null) bindPad(body, lk, style.contentInset);
  if (style.triggerTextStyle != null) {
    applyInstanceTextStyle(header, lk, style.triggerTextStyle);
  }
  if (style.contentTextStyle != null) {
    applyInstanceTextStyle(body, lk, style.contentTextStyle);
  }
}

export function applyForwardedButtonStyle(
  button: InstanceNode,
  lk: VarLookup,
  style: {
    padding?: PadData | null;
    borderRadius?: { topLeft: number | Dim } | null;
    width?: number | Dim | null;
    height?: number | Dim | null;
    foregroundColor?: ColorData | null;
    /// The stroke colour the forwarded style states. The child's own stroke is
    /// replaced, at `borderWidth` — or at the width the child already draws it
    /// when none is stated, because a forwarded colour is not a statement
    /// about thickness.
    borderColor?: ColorData | null;
    borderWidth?: number | Dim | null;
    /// The ring the forwarded corner is measured out from — the slot's own when
    /// it carries one, else `Button`'s.
    focusOutlineStyle?: { align: number | Dim; borderWidth: number | Dim } | null;
  },
): void {
  if (style.padding != null) bindPad(button, lk, style.padding);
  // The corner on the box AND on the layers the button draws from it (its wash,
  // focus band and ring) — a parent that holds a `Button` at a smaller corner
  // than its size row (Toast's close, a TextField's feature button) would
  // otherwise leave those layers at the size row's corner.
  if (style.borderRadius != null) {
    pinComposedCorner(
      button,
      lk,
      style.borderRadius.topLeft,
      style.focusOutlineStyle ?? BUTTON.fields.focusOutlineStyle,
    );
  }
  if (style.width != null && style.height != null) {
    bindSize(button, lk, style.width, style.height);
  }
  if (style.foregroundColor != null) {
    for (const text of ownTextNodes(button)) {
      fillData(text, lk, style.foregroundColor);
    }
  }
  if (style.borderColor != null) {
    const drawn = typeof button.strokeWeight === 'number' ? button.strokeWeight : 1;
    borderData(button, lk, style.borderColor, style.borderWidth ?? drawn);
  }
}

// The overlays `Button` stacks over its fill — the `state layer` rectangle its
// hover/focus/pressed members carry, and the two layers its focus member shows
// (`focus ring` and the `focus offset` band inside it) — take their corner from
// Button's OWN size row, not from the instance root. So a composer that rounds
// the root past that (`Fab`'s 9999 circle) gets an instance whose corners are
// bound but whose overlays still stop at Button's corner: on the designer's
// hand-made hover member the 40×40 `state layer` sat at radius 8 inside a
// radius-9999 instance, unclipped, and its corners poked out of the circle.
// `resetNode` leaves a recycled member unclipped too, so clipping is not the
// fix — the overlays' corners have to follow the root's, and corner radius is
// one of the few things Figma lets a parent override on a nested node.
//
// The band was missed at first, and it showed: a focused circular Fab drew a
// circular ring around a rounded-SQUARE band, because only two of the three
// names were matched here. All three are drawn layers of the same overlay, so
// all three follow the same corner.
//
// They follow the host's corner directly rather than the ring/band derivation
// `forwardFocusOutlineHostRadius` uses (`host + align`, `host + align -
// borderWidth`): that helper forwards INTO a composed `FocusOutline` whose own
// geometry it knows, while this one reaches into a `Button` member and has only
// the root corner to go on. The sole caller states a full-round radius, where
// the two agree.
export function bindInstanceOverlayRadius(
  button: InstanceNode,
  lk: VarLookup,
  radius: number | Dim,
): void {
  for (const node of button.findAll(
    (n) =>
      (n.type === 'RECTANGLE' && n.name === kStateLayerName) ||
      (n.type === 'RECTANGLE' && n.name === kFocusOutlineBandName) ||
      (n.type === 'FRAME' && n.name === kFocusOutlineRingName),
  )) {
    bindRadiusN(node as RectangleNode | FrameNode, lk, radius);
  }
  // The fill itself moved under the root: on a material surface the paint is
  // the `material` (and `glass`) layer, not the root, and that layer keeps the
  // main component's corner just like the overlays above. A Fab circle bound
  // to 9999 still painted Button md's 10 — a rounded square under a round
  // shadow and ring.
  roundSurfaceLayers(button, lk, radius);
}

// The layer names `FocusOutline` gives the two things it draws — the ring and
// the `offsetColor` band behind the child. Shared between the builder that
// writes them (`primitives-chrome.ts`, `focus-ring.ts`) and the builders that
// compose an instance and forward something onto them — a ring colour
// (InputOtp, Range, DotIndicator), a host radius (ChipInput), a stated band
// (`forwardFocusBand`) — so a rename cannot leave one side painting a node the
// other no longer produces.
export const kFocusOutlineRingName = 'focus ring';
export const kFocusOutlineBandName = 'focus offset';

// The wash a control draws over its own fill on hover / focus / pressed — the
// name every builder gives it, matched by the corner forwards below.
export const kStateLayerName = 'state layer';

// A layer drawn `inset` outside a corner — the focus band and ring around a
// host. The pill sentinel is not a magnitude — `9999 + 4` is still "fully
// round", and the acceptance check reads the two layers as equal there rather
// than four apart (§3-1's table: circle → 9999 / 9999 / 9999). One derivation,
// shared by `focusRing` (which draws the layers) and `pinComposedCorner` (which
// re-rounds them on a composed instance), so the two cannot disagree.
const kPillRadius = 9999;
export function derivedCorner(corner: number, inset: number): number {
  return corner >= kPillRadius ? kPillRadius : corner + inset;
}

// A host's corner, pinned onto the painted box of a control it composes.
//
// A parent that states its child's corner through a nested style slot —
// `Menu.itemStyle` / `Select.optionStyle` holding a hosted row at 8 while the
// row's own size ladder says 10 or 12, `ItemPicker.searchFieldStyle` holding
// its search field at its own frame's 8, `Toast.closeButtonStyle` holding its
// close button at the panel's 8 — is stating more than the box. The composed
// control draws three layers from the same corner: the box, the `state layer`
// wash over its fill, and the focus band and ring outside it. Binding only the
// box (the root of a MenuItem or a Button, the `field` row of a TextField)
// would leave the wash at the child's own corner and the ring concentric with
// a box that is no longer there.
//
// So all three follow, in the widget's own derivation: the box, the wash and
// the box's material layers take the host corner, the band and the ring take
// `host + align - borderWidth` and `host + align` — the arithmetic `focusRing`
// drew them with, through the same `derivedCorner`, so a pinned control and a
// control drawn at that corner on its own are one picture. The two derived
// corners are written as numbers, not bound, for the reason `focusRing` gives:
// they are computed from the corner, not stated on the radius ladder (a 14 host
// has an 18 ring).
//
// The layers are the box's DIRECT children only. A TextField's row also holds a
// composed feature `Button`, whose own wash and ring are that button's and
// answer to its own corner — a recursive walk would re-round them.
export function pinComposedCorner(
  box: FrameNode | InstanceNode,
  lk: VarLookup,
  host: number | Dim,
  outline: { align: number | Dim; borderWidth: number | Dim },
): void {
  const hostCorner = dimVal(host);
  const align = dimVal(outline.align);
  const offsetExtent = align - dimVal(outline.borderWidth);
  bindRadiusN(box, lk, host);
  // The material layers sit inside the box's own stroke (`flushTintLayers`,
  // paint.ts), so their corner is the host's pulled in by that reach — the
  // inset the main component's layers already carry. Re-binding them to the
  // bare host corner undid it: a composed Select trigger drew its field fill
  // at 10 inside a 10 border, and the corner's diagonal showed a crescent of
  // background between the border's inner edge and the fill.
  const inset = ownStrokeInsets(box as unknown as StrokeHost);
  for (const node of box.children) {
    // The wash and a material surface's own layers (its fill, frost and glass)
    // round with the box they paint.
    if (isSurfaceLayer(node)) {
      bindRadiusN(node as RectangleNode, lk, host);
      insetLayerCorners(node as RectangleNode, inset);
    } else if (node.type === 'RECTANGLE' && node.name === kStateLayerName) {
      bindRadiusN(node as RectangleNode, lk, host);
    } else if (node.type === 'RECTANGLE' && node.name === kFocusOutlineBandName) {
      node.cornerRadius = derivedCorner(hostCorner, offsetExtent);
    } else if (node.type === 'FRAME' && node.name === kFocusOutlineRingName) {
      node.cornerRadius = derivedCorner(hostCorner, align);
    }
  }
}

// That ring, inside a composed `FocusOutline` instance.
//
// A composing widget forwards its own `focusOutlineStyle` into the child, and
// the parts of it Figma can carry are instance overrides. They have to land on
// the RING, not on the instance root: the root is the child's own box (the
// widget's `Stacks` contributes none of its own), so a stroke written there
// would draw a second ring flush against the child while the real one sits
// `align` px outside it.
//
// Throws rather than returning null, unlike `instanceFrameSlot`'s reach for a
// caller-facing slot: this name is this repo's own constant on both sides, so
// a miss is a code error and not a canvas condition, and a silent miss would
// drop a forwarded colour with nothing on the canvas saying it went nowhere.
export function focusOutlineRing(inst: InstanceNode): RectangleNode {
  return focusOutlineLayer(inst, kFocusOutlineRingName);
}

// The `offsetColor` band, inside a composed `FocusOutline` instance — same
// contract as the ring above.
export function focusOutlineBand(inst: InstanceNode): RectangleNode {
  return focusOutlineLayer(inst, kFocusOutlineBandName);
}

// A composing widget's host corner, forwarded into a `FocusOutline` instance.
//
// `FocusOutline.borderRadius` is `@hostDerived`: the wrapper draws no corner
// of its own and takes the host's. The main binds its ring at `host + align`
// and its band at `host + align - borderWidth`, so a host radius that lands
// only on the instance root (which paints nothing under this shape) leaves the
// two drawn layers at the preview's corner. This writes all three from one
// value — the root because that is the box being wrapped, the layers because
// they are what the canvas shows — using FocusOutline's own stated `align` and
// `borderWidth` so the derivation cannot drift from the main's.
export function forwardFocusOutlineHostRadius(
  inst: InstanceNode,
  lk: VarLookup,
  host: number | Dim,
  outline: { align: number | Dim; borderWidth: number | Dim },
): void {
  const hostRadius = dimVal(host);
  const align = dimVal(outline.align);
  const offsetExtent = align - dimVal(outline.borderWidth);
  for (const corner of kInstanceCorners) {
    inst.setBoundVariable(corner, lk.radius(hostRadius));
  }
  bindRadiusN(focusOutlineRing(inst), lk, hostRadius + align);
  bindRadiusN(focusOutlineBand(inst), lk, hostRadius + offsetExtent);
}

// Strokes a focus band `gap` wide — the space between the control's edge and
// the ring's inner edge (`align - borderWidth`), which is what Flutter strokes
// (`BorderSide(width: offsetExtent)`) and Web spreads (`align - stroke`). The
// ring's own `borderWidth` only agrees with it while both happen to be 2.
//
// Bound to `stroke/<gap>` when the ladder has that step. A gap off the ladder
// (a fractional ring width leaves one) is a literal, the same as the inset the
// band is drawn at: `borderData` binds whatever number it is handed, and a
// stroke step the ladder lacks would fail the whole entry over a number that
// renders fine unbound.
export function strokeFocusBand(
  band: RectangleNode,
  lk: VarLookup,
  cd: ColorData | null | undefined,
  gap: number,
): void {
  if (lk.strokeOrNull(gap) != null) {
    borderData(band, lk, cd, gap);
    return;
  }
  borderData(band, lk, cd, kFocusBandLadderFallback);
  band.setBoundVariable('strokeWeight', null);
  band.strokeWeight = gap;
}

// A step every stroke ladder carries, for the paint call above to bind before
// the literal replaces it.
const kFocusBandLadderFallback = 1;

// A composer's stated focus band, painted onto the band its composed control
// already draws.
//
// The band defaults to transparent: the gap between the control and its ring
// shows whatever is behind the control. A composer that places the control
// where it cannot know that background — a FAB over scrolling content, a close
// button on an inverse-surface toast, carousel controls over a photo — states
// an opaque band in its own nested slot (`CoreFocusRing.opaqueOffsetColor`), so
// the ring reads against a colour the design system chose. On the canvas the
// composed control is an instance whose main drew the band transparent, and a
// parent cannot add a child to an instance, so the band is repainted where it
// already is: every `focus offset` RECTANGLE in the instance.
//
// Two band shapes answer to the one name, and the caller says which it
// composed: `focusRing` draws a host's band as an INSIDE stroke (`Button`, a
// composed control's own box paints its fill underneath), `FocusOutline`'s set
// draws it as a fill behind its child. Repainting the wrong one would either
// cover the control or draw nothing.
//
// The colour is the composer's slot value, read from `components.json` like
// every other forwarded paint — never a semantic name spelled at the call site.
// A miss throws: the name is this repo's own constant on both sides, so finding
// no band is a code error, and a silent miss would leave the ring against a
// photo with nothing on the canvas saying the band went nowhere.
//
// The stroke is the gap's width, not the ring's — see `strokeFocusBand`.
export function forwardFocusBand(
  inst: InstanceNode,
  lk: VarLookup,
  outline: { offsetColor: Color; borderWidth: number | Dim; align: number | Dim },
  shape: 'stroke' | 'fill' = 'stroke',
): void {
  const bands = inst.findAll(
    (n) => n.type === 'RECTANGLE' && n.name === kFocusOutlineBandName,
  ) as RectangleNode[];
  if (bands.length === 0) {
    throw new Error(
      `forwardFocusBand: no '${kFocusOutlineBandName}' RECTANGLE under ${inst.name}. ` +
        'The ring builder renamed or dropped it — the stated band lands nowhere.',
    );
  }
  const cd = colorData(outline.offsetColor);
  for (const band of bands) {
    if (shape === 'fill') {
      fillData(band, lk, cd);
    } else {
      strokeFocusBand(band, lk, cd, dimVal(outline.align) - dimVal(outline.borderWidth));
    }
  }
}

const kInstanceCorners = [
  'topLeftRadius',
  'topRightRadius',
  'bottomLeftRadius',
  'bottomRightRadius',
] as const;

function focusOutlineLayer(inst: InstanceNode, name: string): RectangleNode {
  for (const node of inst.findAll((n) => n.name === name)) {
    if (node.type === 'RECTANGLE') return node;
  }
  throw new Error(
    `focusOutlineRing: no '${kFocusOutlineRingName}' RECTANGLE under ${inst.name}. ` +
      'The FocusOutline builder renamed it — update `kFocusOutlineRingName`, or ' +
      'every forwarded ring colour lands nowhere.',
  );
}

export interface FocusOutlineSlot {
  align: Dim;
  borderWidth: Dim;
  ringOpacity: Dim;
  borderColor: Color;
}

export function scaleAlpha(cd: ColorData | null, factor: number): ColorData | null {
  if (cd == null) return null;
  const scaled: ColorData = { color: cd.color, opacity: (cd.opacity == null ? 1 : cd.opacity) * factor };
  if (cd.argb != null) scaled.argb = cd.argb;
  return scaled;
}

export function addFocusRing(
  comp: ComponentNode | FrameNode,
  lk: VarLookup,
  focus: FocusOutlineSlot,
  radius: number | Dim,
): RectangleNode {
  const align = dimVal(focus.align);
  const outerWidth = comp.width + align * 2;
  const outerHeight = comp.height + align * 2;
  // Named for the widget it stands in for, so a designer selecting the layer
  // reads which composed child put it there rather than "focus ring".
  const focusRing = figma.createRectangle();
  focusRing.name = 'FocusOutline ring';
  focusRing.fills = [];
  borderData(
    focusRing,
    lk,
    scaleAlpha(colorData(focus.borderColor), dimVal(focus.ringOpacity)),
    focus.borderWidth,
  );
  bindRadiusN(focusRing, lk, radius);
  comp.appendChild(focusRing);
  pinInFlow(comp, focusRing);
  focusRing.resize(outerWidth, outerHeight);
  focusRing.x = -align;
  focusRing.y = -align;
  // Returned so a caller can hide it and put it behind a BOOLEAN property.
  // Focus is a pose, and on a set that already has five axes a sixth is a
  // node-identity change; a property is the way to show the pose without one.
  return focusRing;
}

export function applyForwardedPanelStyle(
  panelInstance: InstanceNode | FrameNode | ComponentNode,
  lk: VarLookup,
  style: {
    padding?: PadData | null;
    borderRadius?: { topLeft: number | Dim } | null;
    borderWidth?: number | Dim | null;
    minWidth?: number | Dim | null;
    backgroundColor?: ColorData | null;
    /**
     * `CoreOutlinedContainerStyle.backgroundGradient`. When stated it is painted
     * INSTEAD of `backgroundColor` — the same precedence the widget's primitive
     * gives it — so a caller that forwards both (the solid a style states and the
     * gradient it resolved) states what the primitive receives.
     */
    backgroundGradient?: GradientData | null;
    borderColor?: ColorData | null;
  },
): void {
  if (style.padding != null) bindPad(panelInstance, lk, style.padding);
  if (style.borderRadius != null) {
    bindRadiusN(panelInstance, lk, style.borderRadius.topLeft);
    // A composed material surface paints its fill on a layer under the root
    // (`surface-material.ts`), and that layer rounds with the corner too.
    roundSurfaceLayers(panelInstance, lk, style.borderRadius.topLeft);
  }
  if (style.backgroundGradient != null) {
    const paint = gradientPaint(style.backgroundGradient, { lk });
    const material = surfaceMaterialLayer(panelInstance);
    if (material != null) {
      panelInstance.fills = [];
      material.fills = [paint];
    } else {
      panelInstance.fills = [paint];
    }
  } else if (style.backgroundColor != null) {
    // On a material surface the colour goes to its material layer — painted on
    // the root it would sit under that layer's fill and never show.
    if (!repointSurfaceMaterial(panelInstance, lk, style.backgroundColor, null)) {
      fillData(panelInstance, lk, style.backgroundColor);
    }
  }
  if (style.borderColor != null) {
    borderData(panelInstance, lk, style.borderColor, style.borderWidth ?? 1);
  }
  // Bound only when the stated width names a token, the same rule the picker
  // panels already follow: a literal 0 here would be this builder inventing a
  // constraint the design system never named.
  if (style.minWidth != null) {
    const want = dimVal(style.minWidth);
    const variable = lk.sizeOrNull(want);
    if (variable) {
      panelInstance.minWidth = want;
      panelInstance.setBoundVariable('minWidth', variable);
    }
  }
}

export function hostedDivider(
  page: PageNode,
  lk: VarLookup,
  host: FrameNode | ComponentNode | null,
  opts: {
    axes?: Record<string, string>;
    vertical?: boolean;
    color?: ColorData | null;
    size?: { length: number | Dim; thickness: number | Dim };
    /**
     * A whole forwarded `CoreDividerStyle`, for a parent that states one
     * (`dividerStyle: style.dividerStyle`). Its colour and thickness reach the
     * rule; a stated indent narrows it.
     *
     * Separate from `color` rather than folded into it because the two are
     * different claims: `color` is a parent recolouring the rule from a field of
     * its own (a drawer's seam taking the panel's border colour), while this is
     * the parent handing over the child's own Style — and the child's OTHER
     * fields come with it.
     */
    forwarded?: {
      color?: ColorData | null;
      thickness?: number | Dim;
      indent?: number | Dim;
      endIndent?: number | Dim;
    };
  } = {},
): InstanceNode {
  const vertical = opts.vertical === true;
  // The forward's colour is the rule's colour — one is the parent's field for the
  // child, the other the parent's field for itself, and a caller passing both
  // means the recolour wins because it is the more specific statement.
  const color = opts.color ?? opts.forwarded?.color ?? null;
  const axes =
    opts.axes ??
    { Orientation: vertical ? 'Vertical' : 'Horizontal', Label: 'None' };
  const rule = instanceOf(page, 'Divider', bestVariantName(page, 'Divider', axes));
  if (host != null) host.appendChild(rule);
  // Sized mode — the rule has a length of its own instead of taking its host's.
  //
  // Both modes exist in the widgets and neither is a lesser version of the
  // other: a rule between two rows spans the box (`Container(width:
  // double.infinity)`), while a stepper's connector and a navigation rail's rule
  // are drawn at a stated length. Putting both behind one function is what keeps
  // the door single — a second local helper for sized rules is how the
  // half-applied state came back the last time, in a file this one could not see.
  if (opts.size != null) {
    // The size lands on the INSTANCE, never on the line inside it. Figma keeps a
    // sublayer's geometry from its main component — `resize` / a size binding on
    // a rectangle inside an instance is dropped without an error — so every rule
    // sized this way used to stay at the main's 200px, and a footer's 12px tick
    // ran the full height of its row. The instance root is a node the API can
    // size; the line fills it on both axes and inherits the length from there.
    const length = dimVal(opts.size.length);
    const thickness = dimVal(opts.size.thickness);
    // Axis modes, not `layoutSizing*`: a connector is sized before it has a
    // host, and the child-side setters need an auto-layout parent. The rule's
    // own layout runs along its orientation, so length is the primary axis and
    // thickness the counter axis in both orientations.
    rule.primaryAxisSizingMode = 'FIXED';
    rule.counterAxisSizingMode = 'FIXED';
    // The thickness axis is the one that carries a design value, so it is the
    // axis bound here, to the stroke step it names (`bindStrokeAxis`). A length
    // is usually this preview's own layout choice (a connector's 24, a stepper's
    // 40) and stays unbound; only a length that arrived as a stated field, with a
    // source of its own (a footer's `inlineDividerLength`), binds too.
    rule.resize(vertical ? thickness : length, vertical ? length : thickness);
    bindStrokeAxis(rule, lk, vertical ? 'width' : 'height', opts.size.thickness);
    for (const line of rule.children) {
      if (line.type !== 'RECTANGLE') continue;
      line.layoutSizingHorizontal = 'FILL';
      line.layoutSizingVertical = 'FILL';
      if (color != null) fillData(line, lk, color);
      applyDividerForward(rule, line, lk, opts.forwarded, vertical);
    }
    // Bound last, after the forward's own resize has run — nothing writes the
    // root's geometry after this point, so the binding cannot be shaken off.
    if (isDim(opts.size.length) && opts.size.length.ref != null) {
      const lengthVar = lk.sizeOrNull(length);
      if (lengthVar) rule.setBoundVariable(vertical ? 'height' : 'width', lengthVar);
    }
    return rule;
  }
  if (host == null) {
    throw new Error(
      'hostedDivider: a filling rule needs a host to fill — pass one, or pass ' +
        'size to state a length instead.',
    );
  }
  if (vertical) {
    rule.layoutSizingVertical = 'FILL';
  } else {
    rule.layoutSizingHorizontal = 'FILL';
  }
  for (const line of rule.children) {
    if (line.type !== 'RECTANGLE') continue;
    if (vertical) {
      line.layoutSizingVertical = 'FILL';
    } else {
      line.layoutSizingHorizontal = 'FILL';
    }
    if (color != null) fillData(line, lk, color);
    applyDividerForward(rule, line, lk, opts.forwarded, vertical);
  }
  return rule;
}

function isTransparentLeaf(
  leaf: { argb?: number; ref?: string | null } | null | undefined,
): boolean {
  if (leaf == null) return false;
  if (leaf.ref != null) return false;
  return (leaf.argb ?? 0) === 0;
}

function applyDividerForward(
  rule: InstanceNode,
  line: RectangleNode,
  lk: VarLookup,
  forwarded:
    | {
        thickness?: number | Dim;
        indent?: number | Dim;
        endIndent?: number | Dim;
      }
    | undefined,
  vertical: boolean,
): void {
  if (forwarded === undefined) return;
  if (forwarded.thickness !== undefined) {
    const thickness = dimVal(forwarded.thickness);
    // Same rule as the sized mode above: the thickness goes on the instance's
    // cross axis and the line fills it — a resize on the line itself is dropped
    // inside an instance.
    // `resize` on an auto-layout child resets both of its axes to FIXED, which
    // would take a filling rule's FILL with it — remember the length axis and
    // put it back after.
    const filling = vertical
      ? rule.layoutSizingVertical === 'FILL'
      : rule.layoutSizingHorizontal === 'FILL';
    rule.counterAxisSizingMode = 'FIXED';
    if (vertical) {
      rule.resize(thickness, rule.height);
      bindStrokeAxis(rule, lk, 'width', forwarded.thickness);
      line.layoutSizingHorizontal = 'FILL';
      if (filling) rule.layoutSizingVertical = 'FILL';
    } else {
      rule.resize(rule.width, thickness);
      bindStrokeAxis(rule, lk, 'height', forwarded.thickness);
      line.layoutSizingVertical = 'FILL';
      if (filling) rule.layoutSizingHorizontal = 'FILL';
    }
  }
  const start = forwarded.indent === undefined ? undefined : dimVal(forwarded.indent);
  const end = forwarded.endIndent === undefined ? undefined : dimVal(forwarded.endIndent);
  if (start === undefined && end === undefined) return;
  // Insets go on the PARENT — the instance root, whose own padding is what pulls
  // a filling line in from both ends. Writing them on the line would fight the
  // FILL above, which is the sizing that makes the rule span its host at all.
  const root = line.parent;
  if (root === null || !('paddingLeft' in root)) return;
  if (vertical) {
    if (start !== undefined) root.paddingTop = start;
    if (end !== undefined) root.paddingBottom = end;
  } else {
    if (start !== undefined) root.paddingLeft = start;
    if (end !== undefined) root.paddingRight = end;
  }
}

// ─── A count `Badge` composed after a tab's label ────────────────────────────
//
// `CoreTabItem.badge` is a composition slot both `Tabs` and `TabPane` render
// after the label behind a 1-off `Gap` (`tabs.dart#_labelWithBadge`,
// `tab_pane.dart`'s `Row([label, Gap, badge])`). The caller supplies a styled
// `Badge`, and the payload the docs example ships is `Badge(variant: .filled,
// form: .count, size: .xs, child: Text('3'))` — the count a tab carries, which
// the badge spec's count mapping states for Tabs and NavigationBar (filled,
// count, xs, a neutral or info tone). On the canvas that is a composed `Badge`
// INSTANCE in the
// label row, hidden at rest and revealed by the parent's `Show count` BOOLEAN.
// Two builders draw that row — `TabItem` (navigation.ts) and `TabPane`
// (primitives-data.ts) — and the pose has to be ONE statement so a count reads
// the same in a bar and a strip. This is that statement; neither builder
// spells any of it.
//
// The pose is the member that payload resolves to: what it names, and the
// widget's own default for what it does not.
//   · `Tone` — `kBadgeDefaultTone`, `CoreBadgeTone.defaultTone` (below); the
//     payload names no tone.
//   · `Variant` — `kCountBadgeVariant`, the strength the payload names.
//   · `Size` — `kCountBadgeSize`, the step the payload names.
//   · `Style=count` — `CoreBadgeForm.count`, the form the payload names.
//   · `Child` — the count's copy, `kCountBadgeDefault`.
// The runtime selftest reads the variant and the size off the docs payload,
// so the example and this pose cannot part.
// Handed to `bestVariantName` as preferences rather than spelled as a variant
// name: it scores the axes named here, so a Badge axis added later degrades to
// "ignored" rather than failing every member of both callers. All four design
// axes are named, so the score picks one member — none of them falls to set
// order, which would put the composed count on whatever value an axis happens
// to list first.
//
// Nothing else is written. Hover and focus are BOOLEAN properties of the Badge
// set (`Hover`, `Show focus ring`), off at rest — the pose of a badge with no
// `onPressed`, which the payload has none of. The icon slots are likewise
// off: `buildBadge` declares `Show leading` / `Show trailing` `false` because
// `leading` / `trailing` are null unless a caller passes one, and the payload
// passes neither — so the set's default IS the payload, and an override here
// would state something the code does not.
//
// Called AFTER `row` is inside a component — `TabItem`'s member is only in
// its set after `finish()`, `TabPane`'s strip only in its component after the
// append — because two of the writes below are refused on a detached node: the
// `visible` binding (`componentPropertyReferences`), and `isExposedInstance`,
// which `exposeAll`'s note in component-props.ts records failing five
// components in the real file when written where the instance was minted. The
// late append moves nothing: a hidden child bills no `itemSpacing`, so the
// row's gap is the stated `labelBadgeGapStyle` whether or not the badge shows,
// and a row sized before the badge exists is the row the resting pose draws.
//
// Bound to `showCountProp` (the parent's `Show count`, default `false` — the
// node is hidden at rest so the node and the property's default say the same
// thing), then exposed so the badge's own `Child` reaches the parent's panel.
// That exposure is the one way Figma has to put the count on the parent: a
// set-level TEXT property cannot bind to a node inside an instance
// (`componentPropertyReferences` is rejected on an instance sublayer — the wall
// `CardImage`'s `Basic` slots and the pickers' `Dialog` title hit). Wrapped
// for `display-media.ts`'s `exposeNested` reason: a rejected write must not
// fail the entry and leave a half-drawn set on the page, while the fallback is
// a designer selecting one level deeper — which Figma allows.

// The tab's OTHER two slots do not live here. `CoreTabItem.leading` /
// `.trailing` are rendered by `TabPane` alone — `Tabs` ignores them, the split
// `content` already documents — so exactly one builder draws them
// (`primitives-data.ts`'s `buildTabPane`) and there is no second caller for a
// shared statement to keep honest. The badge is here precisely because it has
// two: a count has to read the same in a bar and a strip. A pose stated in one
// place for one caller would be indirection without a reason.
//
// They also share the badge's gap rather than stating their own. A Figma
// auto-layout frame has ONE `itemSpacing`, so three distinct 1-off gaps in the
// tab row is a handle the canvas cannot hold — `labelBadgeGapStyle` is the
// tab's single in-tab step and all three slots sit on it.

// `Badge`'s own resting size — `CoreBadgeContract.defaultSize`, which both
// platforms' constructors take as their default (`this.size =
// CoreBadgeContract.defaultSize`, `badge.dart` on each), so a badge whose
// caller names no size renders at it. components.json carries
// `sizes.defaultsBySize` but records no default key (`axes.size` has no
// `default`, and `props` lists slots only), so the name is stated here rather
// than derived — the `kProgressDefaultSize` shape — and read by `buildBadge`'s
// resting member. The runtime selftest reads the Dart constant and fails when
// the two part.
export const kBadgeDefaultSize = 'md';
// `CoreBadgeTone.defaultTone` — the tone a Badge takes when its caller names
// none, which the tab count payload does not. The tone axis comes from the
// exported `axes.other`, which carries no default key either, so the member is
// named here the same way the size is, and read by `buildBadge` from here.
export const kBadgeDefaultTone = 'neutral';
// `Progress`'s own resting bar — `CoreProgressSize.defaultSize` and
// `CoreProgressTone.defaultTone`, which both platforms' constructors take as
// their defaults, so a bar whose caller names neither renders at them.
// components.json records `axes.other` without a default key, so the two are
// named here, the way the Badge pair above is. `buildProgress` reads them for
// the member a placed instance becomes, and `Scaffold`'s loading bar for the
// member it composes (`Progress(value: …)` names neither). The runtime selftest
// reads the Dart constants and fails when they part.
export const kProgressDefaultSize = 'sm';
export const kProgressDefaultTone = 'primary';
// `CoreBadgeForm.count` — the form the payload names. Not the default form:
// `CoreBadgeForm.defaultForm` is `label`, a word, which is why the payload has
// to say `count`.
export const kCountBadgeForm = 'count';
// `CoreBadgeVariant.filled` and `CoreComponentSize.xs` — the strength and the
// step the payload names. Not the widget's defaults (`tonal`, `md`): a tab's
// count is the small filled pill, not a word-sized label.
export const kCountBadgeVariant = 'filled';
export const kCountBadgeSize = 'xs';
// The designer's `Count` default — the copy a composed badge shows until an
// instance overrides its `Child`.
export const kCountBadgeDefault = '0';

// `Avatar`'s own resting member — `CoreAvatarContract.defaultSize` and
// `CoreAvatarShape.defaultShape`, the two defaults both platforms'
// constructors take (`this.size = CoreAvatarContract.defaultSize`,
// `this.shape = CoreAvatarShape.defaultShape`, `avatar.dart` on each).
// components.json records neither as a default key (`axes.size` has no
// `default`, and `axes.other` lists members only), so they are named here the
// way the Badge's are, and read by `buildAvatar`'s lead member. The runtime
// selftest reads the Dart constants and fails when the two part.
export const kAvatarDefaultSize = 'sm';
export const kAvatarDefaultShape = 'circle';
// The pose a composed Avatar rests in whatever step its host picks: the
// default shape, no ring (`ring` defaults to `false` on both platforms). A
// composer spreads it beside its own `Size` so every axis is named —
// `bestVariantName` scores only the axes it is given and breaks a tie on set
// order, so a composer that named `Size` alone would land on whichever shape
// the set happened to list first.
export const kAvatarRest = { Shape: kAvatarDefaultShape, Ring: 'false' } as const;

// `tone` is the composing caller's: a tab's count takes the badge's own
// default tone, a navigation destination's count the one its docs and
// examples hand the badge.
export function composeCountBadge(
  page: PageNode,
  // A row frame, or a member that IS the row (`TabPaneTab`'s tab).
  row: FrameNode | ComponentNode,
  showCountProp: string | null,
  tone: string = kBadgeDefaultTone,
): InstanceNode {
  const badge = instanceOf(
    page,
    'Badge',
    bestVariantName(page, 'Badge', {
      Tone: tone,
      Variant: kCountBadgeVariant,
      Size: kCountBadgeSize,
      Style: kCountBadgeForm,
    }),
  );
  badge.name = 'badge';
  setInstanceTextNamed(badge, 'Child', kCountBadgeDefault);
  row.appendChild(badge);
  badge.visible = false;
  bindVisibleProp(badge, showCountProp);
  try {
    badge.isExposedInstance = true;
  } catch {
    // The badge's `Child` stays reachable by selecting the nested instance.
  }
  return badge;
}
