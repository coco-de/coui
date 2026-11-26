/// <reference types="@figma/plugin-typings" />

import { slotNodes, SlotNodes, bindSlot, standInSlotNodes, bindOptionalSlot } from '../overlay-preview';
import { kPlainDividerAxes, kMenuRestingSize, iconOpts, overlayGlyph, mainId } from '../overlay-composition';
import { boundOrNull, bindLayoutBound } from '../layout-bound';
import { setInstanceLabel } from '../instance-label';
import { iconShapeGlyphSize, kPlainButtonForeground } from '../button-defaults';
import {
  ColorData,
  FocusRingNodes,
  RegistryEntry,
  VarLookup,
  applyPanelCompChrome,
  applySurfaceMaterial,
  autoFrame,
  pinAbsolute,
  sizePin,
  bestVariantName,
  bindPad,
  bindRadiusN,
  bindSize,
  bindSwapProp,
  bindTextProp,
  bindVisibleProp,
  borderData,
  defineProp,
  fillData,
  focusRing,
  glyphOpts,
  iconMainId,
  iconSwapDefault,
  instanceOf,
  layoutSet,
  lockWidth,
  makeIcon,
  makeLabel,
  mint,
  mintPanelComp,
  mountSet,
  panel,
  propertyOwner,
  textLabelOpts,
  typographyColorOpts,
  vStackSet,
  setShadow,
  withAlpha,
  hostedDivider,
  PadData,
  applyForwardedButtonStyle,
  applyForwardedPanelStyle,
  forwardFocusBand,
  pinComposedCorner,
  exposeAll,
  exposeSlot,
  setInstanceBoolNamed,
  setInstanceSwapNamed,
  setInstanceTextNamed,
  kSlotStandInComponent,
  slotStandIn,
  slotStandInDefault,
  type SurfaceCorners,
  setSlotIcon,
  glyphPaint,
  labelColor,
  iconMainIdAt,
} from '../helpers';
import { isSurfaceLayer } from '../surface-layers';
import { bindShowFocusRing, defineShowFocusRing, stateAxis } from '../state-axis';
import { Color, Dim, NormalizedColor, colorData, dimVal, optField, textStyleData } from '../compat/v1';
import { hidePopupContent, popupInstance, popupPaddingOverride } from '../popup-composition';
import { exampleMainId, kPopoverExample } from '../default-examples';

import { COMPONENTS } from '../data';
import { axisSpecsOf, composeVariantName, enumerateAxisCombos, restingValueOf } from '../axis-combos';
import { parseVariantKey } from '../variant-safety';

const DIALOG = COMPONENTS.dialog;
const DRAWER = COMPONENTS.drawer;
const TOAST = COMPONENTS.toast;
const MENU = COMPONENTS.menu;
const MENU_ITEM = COMPONENTS.menu_item;
const POPOVER = COMPONENTS.popover;
const POPUP = COMPONENTS.popup;
const CONTEXT_MENU = COMPONENTS.context_menu;
const DROPDOWN_MENU = COMPONENTS.dropdown_menu;
// `icon.constants.ambientSize` — the app root's ambient icon size, which an
// `Icon` handed to a caller slot draws at when the widget renders it as handed.
// MenuItem's `trailing` says why it qualifies.
const ICON = COMPONENTS.icon;

// ─── helpers (local) ─────────────────────────────────────────────────────────

// Dialog's action-button (Cancel/Confirm) shape + color aren't dialog-owned
// fields — no chrome for them exists under CoreDialogStyle, or on any of the
// panel-family components (#3755 OQ-2), so these stay hand-drawn.
//
// Not converted to Button instances on purpose: `actions` is a `List<W>?` slot
// the CALLER fills, and `CoreDialogStyle` forwards no Button style through a
// nested slot — so Dialog does not compose Button, these two pills are stand-in
// content for a slot a designer fills themselves. Instancing here would assert
// a composition edge the contract doesn't have.
//
// So the numbers below are preview scaffolding, and marked as such: `dialog`
// states only the gaps around its actions — `actionSpacing` BETWEEN them and
// `actionRunSpacing` between the rows they wrap onto, both bound on the
// `actions` row — and nothing about a single action's box or its label type.
// `dialog.dart` renders `actions!` verbatim inside
// `Wrap(spacing: resolved.actionSpacing, runSpacing: resolved.actionRunSpacing)`,
// so the widget draws none of this itself.
//
// ⚠️ Where the values came from is still worth recording: they were copied off
// `button`, not invented — `radius 10` = `button.sizes.defaultsBySize.md
// .borderRadius` (the md control's corner, height × 0.25), `pl/pr 16` and
// `pt/pb 8` = `button.sizes.defaultsBySize.md.padding`, `size 14` = md's
// `labelStyle` role `labelLarge`. A copy stops following Button the moment
// Button changes (the defect this file's own header describes) — and yet
// reading `COMPONENTS.button` from here is NOT the repair: Dialog composes no
// Button, so that read would be one component's builder reaching into another
// component's defaults (the reach `core/style-contract.md` forbids), and it
// would make the canvas assert a composition edge the contract denies. The
// repair is upstream and takes one of two shapes: `CoreDialogStyle` grows an
// action-button style forward, at which point Dialog composes Button and these
// pills become instances (the trade `closeButton` already makes) — or the
// pills stay a caller-slot placeholder and give up the Button likeness.
// Reported upward; both change what the canvas renders.
function pill(lk: VarLookup, label: string, bg: string | null, fg: string, border: string | null): FrameNode {
  const opts: { bg?: string; border?: string; radius: number; pl: number; pr: number; pt: number; pb: number } = {
    // g7-preview-only: stand-in box for one entry of the `actions` caller slot (`List<W>?`) — `dialog`'s action fields are only the gaps around actions (`actionSpacing`, `actionRunSpacing`), so nothing states an action's own radius or padding.
    radius: 10, pl: 16, pr: 16, pt: 8, pb: 8,
  };
  if (bg) opts.bg = bg;
  if (border) opts.border = border;
  const p = panel('action', 'HORIZONTAL', lk, opts);
  p.primaryAxisAlignItems = 'CENTER';
  p.counterAxisAlignItems = 'CENTER';
  // g7-preview-only: type size of that stand-in's label — the widget it stands for is the caller's, and no `CoreDialogStyle` field states an action's label style (`titleStyle` / `contentStyle` belong to the header and body).
  p.appendChild(makeLabel(label, lk, { size: 14, colorVar: lk.sem(fg) }));
  return p;
}

// ─── Composed children — instances, not redrawn boxes ────────────────────────
//
// Why an instance and not a box that looks like one: the child owns its own
// chrome, and a redrawn copy stops following it the moment the child changes.
// The content-hash skip leaves a parent whose own recipe didn't change alone,
// so the copy keeps painting last year's tokens with nothing to say so.
//
// ── Composing a CONTAINER, when an instance takes no children ────────────────
//
// A Figma INSTANCE takes no children. That is a hard limit, not a preference,
// and it decides the SHAPE a composition edge takes here — never whether the
// edge is drawn at all:
//
//   · the child is a LEAF, or a whole surface the parent puts nothing of its
//     own inside → append the instance in flow (ContextMenu / DropdownMenu's
//     `Menu`, the close `Button`s, `Divider`, Command's search `TextField`,
//     Popover's `Popup`).
//   · the child is the CONTAINER the parent's own elements live inside → the
//     instance goes BEHIND them: an absolutely-positioned sibling pinned to
//     all four edges, so it is the real surface and the parent's rows still
//     flow in auto-layout above it (Menu's `Popup`, Swiper's `Drawer`).
//     The child's own placeholder for those children is turned off through
//     its property (`hidePopupContent`), because it stands in for exactly the
//     children the parent is supplying.
//
// The container case used to be written off as impossible, which left Menu
// drawing a `Popup`-shaped box (at a radius that matched neither Popup's nor
// Menu's own) and Swiper drawing no panel at all — `swiper.dart` says in its
// own words that the composed Drawer "paints the panel surface — background,
// border and shadow. Handing it bare content would float the children over
// the barrier with no panel behind them", which is precisely the picture the
// builder shipped.
//
// A glyph that belongs INSIDE a composed instance's box (`Button(child:
// Icon(x))`, `Button(trailing: Icon(chevronRight))`) is reachable the same
// way, in the other direction: it rides ABOVE the instance as an absolutely-
// positioned sibling in a host frame (`overlayGlyph` below). That is what
// lets the button stay a real `Button` instance instead of a redrawn
// lookalike, and it is how the close affordances and the submenu chevron get
// their real Lucide glyph.
//
// Writing a composed child's own label is a different matter: it goes through
// `InstanceNode.setProperties`, never through `characters` / `visible` on the
// node inside the instance, because that node carries the child's own property
// binding and overriding it directly is how a parent silently decouples from
// the child it composed.

// Resting (idle, enabled, unselected) `Button` — the axes every composed
// affordance in this file asks for, spelled once. A close affordance is
// `Button(variant: .plain)` with no size argument, i.e. `CoreComponentSize.md`.
const kPlainButtonAxes = {
  Variant: 'plain',
  Size: 'md',
};

// The resting `Button` a trigger slot defaults to — `Button(variant: .outline)`
// with no size argument, which is what `popover.dart`'s own example passes.
const kOutlineButtonAxes = {
  Variant: 'outline',
  Size: 'md',
};

/** The label the Popover example's trigger carries (designer's copy, #6473). */
const kPopoverExampleTrigger = '알림';

// Empties a composed instance's own label — the close affordances here are
// `Button(child: Icon(…))`, no text at all.
//
// `setProperties` only. `Button` declares its label as a TEXT component
// property, and writing `characters` on the node that carries that binding is
// the override that decouples this parent from the child it composed. When the
// child declares no such property there is nothing to clear and this is a
// no-op — including in the runtime harness, whose instance double models
// component properties on a main component but not on an instance.
function clearInstanceLabel(inst: InstanceNode): void {
  const props: ComponentProperties | undefined = inst.componentProperties;
  if (!props || typeof inst.setProperties !== 'function') return;
  for (const key of Object.keys(props)) {
    if (props[key].type !== 'TEXT') continue;
    const patch: { [name: string]: string } = {};
    patch[key] = '';
    inst.setProperties(patch);
    return;
  }
}

// `Color.opacity × factor` — the plugin-side twin of `CoreColor.scaleAlpha`,
// which is how a resolver combines a token colour with a separately-stated alpha.
// Both modal barriers here are exactly that: `barrierColor` names a token and
// `barrierOpacity` says how far through it you can see, and the resolvers fold
// them with `.scaleAlpha(barrierOpacity)` before the route ever sees a colour.
//
// ⚠️ THIRD COPY. `display.ts` has a file-private `scaleAlpha` with this body and
// `display-media.ts` inlines the same expression, so this belongs in
// `helpers.ts` beside `fillData` — which reads it, and which every one of the
// three then stops needing to pre-compute for. That file is shared and not this
// one's to edit mid-pass; reported upward. Written out rather than spread
// because the Figma plugin runtime rejects `...` in an object literal.
function scaleAlpha(cd: ColorData, factor: number): ColorData {
  const scaled: ColorData = {
    color: cd.color,
    opacity: (cd.opacity == null ? 1 : cd.opacity) * factor,
  };
  if (cd.argb != null) scaled.argb = cd.argb;
  return scaled;
}

// A child of a PLACED root — one whose `layoutMode` is `'NONE'`, i.e. a Flutter
// `Stacks`.
//
// Deliberately not `pinAbsolute`: that sets `layoutPositioning = 'ABSOLUTE'`,
// which is the escape hatch for a child of an AUTO-LAYOUT frame, and a placed
// root has no auto-layout to escape. `constraints` alone is the plain Figma
// constraint system — the mechanism a non-auto-layout parent resizes its children
// by — so this is the same pin with nothing extra asserted.
//
// `InstanceNode` is excluded by the type rather than handled: Figma refuses
// `constraints` on an instance outright ("This property cannot be overridden in
// an instance"), and nothing rolls the throw back — the entry is reported
// failed and a half-drawn `TimePicker` stays on the canvas, gates all green. An
// instance goes inside a frame that carries the pin (which is what `pinAbsolute`
// does for the auto-layout case), and here that frame is the surface the
// instance fills.
function place(
  host: FrameNode | ComponentNode,
  node: FrameNode | RectangleNode | EllipseNode | TextNode,
  x: number,
  y: number,
  constraints: Constraints,
): void {
  host.appendChild(node);
  node.x = x;
  node.y = y;
  node.constraints = constraints;
}

// The panel-family close affordance: `Button(variant: .plain, child: Icon(x))`.
//
// The ✕'s size is the one the widget draws: the slot's `leadingIconStyle.size`
// when it states one, else the square button row's (`iconShapeGlyphSize`). Its colour has no field of its own on either panel — the
// widget leaves it null so the glyph inherits the button's foreground through
// the ambient `IconTheme` — so the caller passes the colour the widget would
// inherit, which for a bare `plain` button is that variant's own default.
function closeButton(
  page: PageNode,
  lk: VarLookup,
  o: {
    size: number | Dim;
    color: ColorData;
    /// The `Button` member the affordance is drawn from; `plain` `md` when absent.
    axes?: Record<string, string>;
    /// The parent's forwarded `closeButtonStyle`. Applied to the instance, which
    /// is where the app's chrome lives: `Drawer` and `Toast` both hand their close
    /// `Button` a whole `CoreButtonStyle`, and the instance was arriving with
    /// `Button`'s own `plain`-row inset and corner instead — a 12+12 row around a
    /// 16px glyph, at the child's radius rather than the parent's (Toast states 8,
    /// Drawer 4, and they were both showing the same thing).
    style?: {
      padding?: PadData | null;
      borderRadius?: { topLeft: number | Dim } | null;
      width?: number | Dim | null;
      height?: number | Dim | null;
      /// The slot's own ring — its corner is what the forwarded radius is
      /// measured out from, and its `offsetColor` is the band under it.
      focusOutlineStyle?: { align: Dim; borderWidth: Dim; offsetColor: Color } | null;
    };
  },
): FrameNode {
  const host = panel('close', 'HORIZONTAL', lk, {});
  const button = instanceOf(
    page,
    'Button',
    bestVariantName(page, 'Button', o.axes ?? kPlainButtonAxes),
  );
  host.appendChild(button);
  clearInstanceLabel(button);
  if (o.style) applyForwardedButtonStyle(button, lk, o.style);
  // The band under the ring, as the slot states it. `Toast` states an opaque
  // one — its panel is an inverse-surface fill, and a ring against it with the
  // panel showing through the gap is a ring against the one colour the design
  // system did not pick for it. `Drawer` states none of its own, so the band
  // stays Button's transparent default and the drawer's panel shows through.
  if (o.style?.focusOutlineStyle != null) {
    forwardFocusBand(button, lk, o.style.focusOutlineStyle);
  }
  const side = dimVal(o.size);
  const shape = (o.axes as Record<string, string> | undefined)?.Shape;
  if (shape === 'square' || shape === 'circle') {
    // A shaped member draws its own glyph in its `Leading` slot — swapped to
    // `Button`'s default icon, a check — and is already the size row's square,
    // so the ✕ goes into that slot rather than over it. Laid over it, the
    // check stayed underneath (Banner's dismiss showed both strokes, #6214).
    setSlotIcon(button, 'leading', iconMainIdAt(page, side), 'x', glyphPaint(lk, labelColor(lk, o.color)));
    return host;
  }
  // With its label cleared the instance hugs to its inset alone — an 8×40
  // strip under a 16px glyph, which is what the canvas showed on Toast, Alert
  // and Drawer. The widget's button is never smaller than the glyph plus its
  // inset on either axis, so state that box; a fixed size on an instance is
  // an ordinary override, and the glyph below centres on it.
  const minWidth = side + button.paddingLeft + button.paddingRight;
  const minHeight = side + button.paddingTop + button.paddingBottom;
  if (button.width < minWidth || button.height < minHeight) {
    button.resize(Math.max(button.width, minWidth), Math.max(button.height, minHeight));
  }
  const glyph = makeIcon('x', lk, iconOpts(lk, o.color, o.size));
  overlayGlyph(host, glyph, (button.width - side) / 2, (button.height - side) / 2);
  return host;
}
const kMenuButtonForeground = COMPONENTS.button.variants.defaultsByVariant.menu.foregroundColor;

// One interactive menu row drawn as a `Button` instance — not a rounded rect
// with a label dropped in it. (A Menu's own rows are `MenuItem` instances; see
// `buildMenu`. This helper is for the surfaces that still pose a menu row as a
// Button.) Every row-state chrome
// (`hover*` / `selected*` / `focused*` / `disabled*` colours on Button's own
// `menu` variant) therefore belongs to that set, and this parent must not
// repaint it: a redrawn copy would keep painting the old chrome forever, since
// the content-hash skip leaves a parent whose own recipe didn't change alone.
//
// `active` is asked for as Button's own state rather than painted here, because
// a highlight drawn here would not follow Button.
//
// It used to ask through a `Selected` axis and say that losing it was an
// acceptable degradation — "the row falls back to the plain `menu` one and the
// highlight is simply not previewed". That reasoning held only while there was
// nowhere else for it to go. `bestVariantName` SCORES rather than demands, so an
// axis that stops existing does not fail: the key just contributes nothing, and
// both branches of `active` resolved to the same member with nothing said.
// Button's poses are one `State=` enum now and `selected` is one of its rungs,
// so the highlight has a destination again.
function menuRow(page: PageNode, label: string, active: boolean): InstanceNode {
  const row = instanceOf(
    page,
    'Button',
    bestVariantName(page, 'Button', {
      Variant: 'menu',
      Size: 'md',
      State: active ? 'selected' : 'enabled',
    }),
  );
  setInstanceLabel(row, label);
  return row;
}


// ─── Dialog ──────────────────────────────────────────────────────────────────

// Data-driven from coui_core DIALOG.fields — no variant/size dispatch on
// CoreDialogStyle. Panel fill, border colour and width, padding, radius, max
// width, section gap, action spacing, and title/content typography are all
// real.
//
// Slots → Figma properties. The header is `dialog.dart`'s own `Row`:
//
// ```text
// Dialog (Column)
//   ├─ body      Column, sectionGapStyle between its parts
//   │    ├─ header    Row[ leading?, Gap, Expanded(title), Gap, trailing? ]
//   │    └─ content
//   │  Gap(actionsGapStyle)
//   └─ actions   Actions=end:     Wrap(alignment: .end, crossAxisAlignment: .center,
//                                      spacing: actionSpacing, runSpacing: actionRunSpacing)
//                Actions=stretch: every action at an equal share of the row
// ```
//
// Two gaps, two nesting levels: Figma auto-layout gives every child of a frame
// the same spacing, so the body is its own frame (gap = `sectionGapStyle`) and
// the panel (gap = `actionsGapStyle`) separates the body from the actions. Both
// ride their own variables; neither is a subtraction of the other.
//
// `title` and `content` are each rendered as ONE text node, so each becomes a
// TEXT property whose default is the copy already there. `leading` / `trailing`
// are `W?` slots the preview now actually draws — the widget puts them in that
// header Row, and a slot with no node is a slot a designer cannot reach — so
// each is an INSTANCE_SWAP (which component fills it) paired with a BOOLEAN
// (whether a caller passed one at all), starting hidden to match the widget's
// `null`. `actions` stays `List<W>?`: Figma has no repeated-slot property, and
// a designer adds or removes children directly.
//
// ── The actions axis ─────────────────────────────────────────────────────────
//
// `actionsLayout` (`CoreDialogActionsLayout`) is how the widget spreads
// `actions` along the panel's last row, and its two values draw two different
// rows, so it is the set's one axis — `Actions`, a member per enum value, read
// off the export with the value `actionsLayout` rests on first (the member Figma
// hands a freshly placed instance):
//
//   · `end` — the `Wrap` above: each action hugs its label at the panel's end,
//     centred across, and one that no longer fits wraps onto another row
//     `actionRunSpacing` below.
//   · `stretch` — every action starts at an equal share of the row and the row
//     fills its width (`CoreDialogActionsStretch.place`, the rule both
//     platforms lay the row out with). On the canvas that is one row whose
//     `Button`s FILL it: two split it in half, and with `Show cancel` off the
//     confirm takes the whole row. The canvas draws that one-line pose only;
//     the stacked pose — an action too wide for its half, so both take a
//     full-width row — is not drawn.
//
// An action list holding a `Flexible` / `Spacer` keeps Flutter's single `Row`
// under either value. That is the caller's own distribution and no member here
// draws it.
//
// Every property below is defined once, on the SET, and bound in both members,
// so a designer's override carries across a switch of `Actions`.
//
// ── The barrier ──────────────────────────────────────────────────────────────
//
// A dialog is a modal, and a modal is a panel ON something: `showDialog` pushes
// a route whose `barrierColor` comes from this component's own
// `resolveDialog(...)`, folding `barrierColor` with `barrierOpacity` through
// `scaleAlpha` exactly as the Web twin's `color-mix(...)` backdrop does. That
// makes the scrim a semi-transparent rectangle with a colour this component
// states, which is the whole of what Figma needs to draw one.
//
// It was previously written off, and the reason given was that the route paints
// it rather than the widget. That is a true statement about Flutter's
// composition and not a statement about Figma: the values are the component's,
// the shape is a rect, and "no node" left two fields with nowhere to land and a
// modal that reads as a card sitting on the page.
//
// So the root becomes the presentation — a placed frame with the barrier behind
// a centred panel — rather than the panel alone. Consequences worth stating:
//
//   · the root's own size is now preview geometry (a viewport extent no field
//     states), which is why it is a named constant applied through `resize`.
//   · `Show barrier` gates it, defaulting ON because `showDialog` always paints
//     one. OFF is the panel by itself, which is what `DatePicker` / `TimePicker`
//     compose — they instance the member `actionsLayout` rests on, hide it, and
//     expose it purely to reach its `Title`, so their picture is unaffected
//     either way.
//   · the panel keeps every one of its own chrome fields; they simply moved one
//     node in, and the shadow moved with them (`checkShadow` counts over the
//     subtree for exactly this reason).
//
// ── The two scale fields, which have no counterpart ──────────────────────────
//
// `scaleAnimationStart` (0.9) / `scaleAnimationEnd` (1.0) are the ends of the
// open animation's `Tween` — `ScaleTransition(scale: animation.drive(Tween(begin:
// start, end: end)))`. A static canvas has no time axis, and unlike a duration
// these also need a scale, which Figma will not give a node without cost:
//
//   · `relativeTransform` carries rotation and translation only. Scale is not
//     expressible there, so there is no non-destructive transform to write.
//   · `rescale(factor)` is destructive by design — it bakes absolute width /
//     height / font sizes, which would detach the bound Variables that carry
//     every token in this component. At `scaleAnimationEnd = 1.0` it is also a
//     no-op, so the only faithful application changes nothing.
//   · a prototype reaction's transition is where a duration would live, and it
//     needs `setReactionsAsync` — async, therefore unreachable from a
//     synchronous builder under `documentAccess: "dynamic-page"` (the same
//     constraint that makes `InstanceNode.mainComponent` write-only here, see
//     `mainId`). It would additionally need a second node at 0.9 standing for a
//     pose the widget never rests in, which a designer reads as a variant.
//
// So the canvas draws the settled panel, which is what `scaleAnimationEnd`
// resolves to, and the 0.9 is not drawn anywhere.
const kDialogHeaderSlot = 24; // preview geometry — DIALOG has no leading/trailing size field.
// Viewport stand-in for the scrim. No field states it — a barrier is as big as
// whatever it covers — so these are this preview's numbers, applied through
// `resize()` only, the same way `kSwiperPageWidth` is. Wider than
// `panelMaxWidth` so the panel reads as floating on the scrim rather than
// filling it.
//
// The page height is shared with Drawer; the Dialog's page width is its own —
// the panel's 480 plus the route's `routePadding` on both sides — because the
// width Drawer draws at (wider than the Dialog's cap) would fill the Dialog's
// panel out to its cap and take the float away.
const kModalPageWidth = 640;
const kModalPageHeight = 400;
// g7-preview-only: the Dialog preview's page width (panel 480 + route inset 16 on each side).
const kDialogPageWidth = 512;
// g7-preview-only: the Drawer preview's page — a desktop viewport the 400 wide side panel docks to.
const kDrawerPageWidth = 1200;
// g7-preview-only: the Drawer preview's page height, the screen height a side panel spans.
const kDrawerPageHeight = 760;
// The Drawer's close affordance: `Button(variant: .plain, size: .sm, shape: .square)`
// (`drawer.dart`), named by axis so a Button axis that grows cannot move the pick.
const kDrawerCloseAxes = { Variant: 'plain', Size: 'sm', State: 'enabled', Shape: 'square' };
const kToastCloseAxes = { Variant: 'plain', Size: 'md', State: 'enabled', Shape: 'square' };

// The two action buttons: the `Button` set's own `md` row (40), cancel as
// `secondary` and confirm as `primary`. `Size` is stated because
// `bestVariantName` scores — a missing axis lets any member of the variant win.
const kDialogCancelButtonAxes = { Variant: 'secondary', Size: 'md' };
const kDialogConfirmButtonAxes = { Variant: 'primary', Size: 'md' };

// The arrangements the style gives the actions (`CoreDialogActionsLayout`, the
// type of `CoreDialogStyle.actionsLayout`), read off the export with the one
// `actionsLayout` rests on first — Figma hands
// a freshly placed instance the first member. Throws when the export stops
// stating the enum, so the `Actions` axis cannot outlive what backs it.
function dialogActionsLayouts(): readonly string[] {
  const axis = DIALOG.axes.other.find((o) => o.enum === 'CoreDialogActionsLayout');
  if (!axis) {
    throw new Error(
      'Dialog: CoreDialogActionsLayout is gone from the exported axes — the canvas has ' +
        'an Actions axis that nothing in the style now backs. Restore the enum, or ' +
        'retire the axis deliberately (renames.ts) rather than letting this builder ' +
        'fold the arrangements into one.',
    );
  }
  const resting = DIALOG.fields.actionsLayout.choice;
  if (!axis.members.includes(resting)) {
    throw new Error(
      `Dialog: actionsLayout rests on "${resting}", which CoreDialogActionsLayout ` +
        `(${axis.members.join(' | ')}) does not declare.`,
    );
  }
  return [resting, ...axis.members.filter((m) => m !== resting)];
}

// `CoreDialogActionsLayout` member → whether its actions fill the row. Throws on
// a member it does not know, so a third arrangement surfaces as a failed build
// and not as the end row quietly standing in for it.
function dialogActionsFill(layout: string): boolean {
  switch (layout) {
    case 'end':
      return false;
    case 'stretch':
      return true;
    default:
      throw new Error(
        `dialog.actionsLayout: unknown CoreDialogActionsLayout "${layout}". Add it to ` +
          '`dialogActionsFill` in overlay.ts with the row its arm in dialog.dart ' +
          '(`_buildActions`) lays the actions out in.',
      );
  }
}

// Both modal barriers state their strength as `CoreOpacity.scrim`, the role the
// token export publishes as `Semantic/ Effect` › `opacity/scrim`. `fillData`
// leaves that strength on the node as a literal; this binds it to the role —
// not to the primitive step the role rests on today — so a change to the role
// reaches the canvas the way it reaches both platforms. A strength that is not
// the role (a caller's own `barrierOpacity`), or a document that has not
// imported the role, keeps the literal.
function bindScrimOpacity(barrier: RectangleNode, lk: VarLookup, opacity: number | Dim): void {
  const via = typeof opacity === 'number' ? null : (opacity.via ?? null);
  if (via == null || !via.startsWith('CoreOpacity.scrim')) return;
  const role = lk.stateOpacityOrNull('scrim');
  if (role === undefined) return;
  barrier.opacity = dimVal(opacity);
  barrier.setBoundVariable('opacity', role);
}

function buildDialog(page: PageNode, lk: VarLookup): ComponentSetNode {
  const pad = DIALOG.fields.panelPadding;
  const bg = colorData(DIALOG.fields.panelBackgroundColor)!;
  const border = colorData(DIALOG.fields.panelBorderColor)!;
  const layouts = dialogActionsLayouts();
  // The single component this set grew out of drew the arrangement the style
  // rests on, so it becomes that member — its key, and every instance a
  // consuming file holds (the two pickers' among them), survive.
  const mount = mountSet(
    page,
    'Dialog',
    layouts.map((layout) => composeVariantName([['Actions', layout]])),
    { adoptLooseAs: composeVariantName([['Actions', DIALOG.fields.actionsLayout.choice]]) },
  );
  const cancelVariant = bestVariantName(page, 'Button', kDialogCancelButtonAxes);
  const confirmVariant = bestVariantName(page, 'Button', kDialogConfirmButtonAxes);
  const titleCopy = '프로젝트를 삭제할까요?';
  const contentCopy = '삭제하면 되돌릴 수 없어요. 모든 데이터가 영구적으로 지워져요.';
  // Collected per member and bound after `mount.finish()`: a component property
  // lives on the SET, and until `combineAsVariants` runs a freshly minted
  // member's parent is still the page — so `propertyOwner` would answer with the
  // member itself and each one would grow its own copy of every property.
  const barriers: RectangleNode[] = [];
  const titles: TextNode[] = [];
  const leadings: SlotNodes[] = [];
  const trailings: SlotNodes[] = [];
  const bodies: TextNode[] = [];
  const contentSlots: SlotNodes[] = [];
  const cancels: InstanceNode[] = [];
  const exposed: InstanceNode[] = [];
  for (const layout of layouts) {
    const fills = dialogActionsFill(layout);
    const c = mount.getOrCreate(composeVariantName([['Actions', layout]]));
    // The route: the panel centred in it, inset by `routePadding` on all four
    // sides (Flutter pads the route by it; Web caps the panel at the viewport
    // less it). An auto-layout root is what lets the panel follow the instance
    // — `panelMaxWidth` is a CAP, not the panel's width: widened, the panel stops
    // at the cap and centres; narrowed to a phone, it fills the route less the
    // inset (measured on the canvas: 390 → 358).
    c.layoutMode = 'VERTICAL';
    c.primaryAxisAlignItems = 'CENTER';
    c.counterAxisAlignItems = 'CENTER';
    c.primaryAxisSizingMode = 'FIXED';
    c.counterAxisSizingMode = 'FIXED';
    c.fills = [];
    const route = DIALOG.fields.routePadding;
    bindPad(c, lk, { l: route, r: route, t: route, b: route });
    c.resize(kDialogPageWidth, kModalPageHeight);
    const barrier = figma.createRectangle();
    barrier.name = 'barrier';
    fillData(
      barrier,
      lk,
      scaleAlpha(
        colorData(DIALOG.fields.barrierColor)!,
        dimVal(DIALOG.fields.barrierOpacity),
      ),
    );
    bindScrimOpacity(barrier, lk, DIALOG.fields.barrierOpacity);
    // Out of the flow — the barrier covers the whole route, inset and all.
    c.appendChild(barrier);
    barrier.layoutPositioning = 'ABSOLUTE';
    barrier.resize(kDialogPageWidth, kModalPageHeight);
    barrier.x = 0;
    barrier.y = 0;
    barrier.constraints = { horizontal: 'STRETCH', vertical: 'STRETCH' };
    barriers.push(barrier);
    const panelFrame = panel('panel', 'VERTICAL', lk, {
      border: border.color!, borderOp: border.opacity, borderArgb: border.argb, strokeN: DIALOG.fields.panelBorderWidth,
      radius: DIALOG.fields.panelBorderRadius.topLeft,
      pl: pad.l, pr: pad.r, pt: pad.t, pb: pad.b,
      gap: DIALOG.fields.actionsGapStyle.size,
    });
    // A floating surface on both platforms (`dialog_style.dart` reads
    // `theme.surfaceFor(.functional)`; the Web twin marks its panel
    // `webSurfaceMarkerFor(.functional)`), and both opt it into the style's rim.
    applySurfaceMaterial(panelFrame, lk, bg, 'functional', {
      radius: DIALOG.fields.panelBorderRadius.topLeft,
      rim: true,
    });
    // A modal surface sits above a scrim; without its two layers it reads as a
    // card pasted onto the page rather than as something in front of it.
    setShadow(panelFrame, DIALOG.fields.panelBoxShadow, lk, colorData(DIALOG.fields.shadowBaseColor));
    // Placed before its children exist, so every node below is inside its member
    // by the time the properties are bound — Figma rejects
    // `componentPropertyReferences` on a node with no COMPONENT ancestor, and
    // nothing rolls that rejection back. The root's alignment centres it.
    c.appendChild(panelFrame);
    panelFrame.layoutSizingHorizontal = 'FILL';
    panelFrame.layoutSizingVertical = 'HUG';
    bindLayoutBound(panelFrame, lk, 'minWidth', boundOrNull(DIALOG.fields.panelMinWidth));
    bindLayoutBound(panelFrame, lk, 'maxWidth', boundOrNull(DIALOG.fields.panelMaxWidth));
    // The body — header, content text and content slot — is one frame so the
    // gap between its parts (`sectionGapStyle`) is not the gap to the actions
    // (`actionsGapStyle`, the panel's own). Placed under the panel before its
    // children exist, for the same reason the panel is placed under the root.
    const bodyFrame = panel('body', 'VERTICAL', lk, { gap: DIALOG.fields.sectionGapStyle.size });
    panelFrame.appendChild(bodyFrame);
    bodyFrame.layoutSizingHorizontal = 'FILL';
    const header = panel('header', 'HORIZONTAL', lk, { gap: DIALOG.fields.sectionGapStyle.size });
    header.counterAxisAlignItems = 'CENTER';
    const leading = standInSlotNodes(page, 'leading', 'rectangular');
    leading.instance.resize(kDialogHeaderSlot, kDialogHeaderSlot);
    header.appendChild(leading.holder);
    const title = makeLabel(titleCopy, lk, textLabelOpts(lk, textStyleData(DIALOG.fields.titleStyle)));
    header.appendChild(title);
    title.layoutSizingHorizontal = 'FILL';
    const trailing = standInSlotNodes(page, 'trailing', 'rectangular');
    trailing.instance.resize(kDialogHeaderSlot, kDialogHeaderSlot);
    header.appendChild(trailing.holder);
    bodyFrame.appendChild(header);
    header.layoutSizingHorizontal = 'FILL';
    titles.push(title);
    leadings.push(leading);
    trailings.push(trailing);
    const body = makeLabel(contentCopy, lk, textLabelOpts(lk, textStyleData(DIALOG.fields.contentStyle)));
    body.textAutoResize = 'HEIGHT';
    bodyFrame.appendChild(body);
    body.layoutSizingHorizontal = 'FILL';
    bodies.push(body);
    const contentSlot = standInSlotNodes(page, 'content slot', 'rectangular');
    bodyFrame.appendChild(contentSlot.holder);
    contentSlot.holder.layoutSizingHorizontal = 'FILL';
    contentSlots.push(contentSlot);
    // `actions` is `List<W>` the widget spreads across the panel's last row.
    // Real `Button` instances — a `secondary` cancel and a `primary` confirm —
    // exposed on the panel, so a destructive confirmation is a variant change
    // on the canvas rather than a detach.
    const actions = panel('actions', 'HORIZONTAL', lk, { gap: DIALOG.fields.actionSpacing });
    if (!fills) actions.primaryAxisAlignItems = 'MAX';
    // `Wrap(crossAxisAlignment: .center)` — a short action sits on the centre
    // line of a taller one, as it did in the single-line `Row`. A stretched line
    // centres each action in it the same way.
    actions.counterAxisAlignItems = 'CENTER';
    panelFrame.appendChild(actions);
    actions.layoutSizingHorizontal = 'FILL';
    if (fills) {
      // One line, and every action FILLs it: equal shares, which is where the
      // stretched row starts each action. Not `layoutWrap`: the canvas draws the
      // one-line pose only. The stacked pose — an action too wide for its half,
      // where both stack full width `actionRunSpacing` apart — is not drawn,
      // because how Figma lays out FILL children inside a wrapping row is
      // unverified.
      actions.layoutWrap = 'NO_WRAP';
    } else {
      // `Wrap(runSpacing: actionRunSpacing)` — actions that no longer fit the
      // panel's width wrap onto another row, still at the end. Figma's `Wrap`
      // is `layoutWrap` and the run gap is `counterAxisSpacing`; bound, because
      // the value is a spacing token.
      actions.layoutWrap = 'WRAP';
      actions.setBoundVariable('counterAxisSpacing', lk.space(dimVal(DIALOG.fields.actionRunSpacing)));
    }
    const cancel = instanceOf(page, 'Button', cancelVariant);
    cancel.name = 'cancel';
    actions.appendChild(cancel);
    setInstanceTextNamed(cancel, 'Child', '취소');
    cancels.push(cancel);
    const confirm = instanceOf(page, 'Button', confirmVariant);
    confirm.name = 'confirm';
    actions.appendChild(confirm);
    setInstanceTextNamed(confirm, 'Child', '삭제');
    // A stretched action takes its cell's width; the `Button` main centres its
    // row, so the label stays centred in the wider box. With `Show cancel` off
    // the confirm is the one action, and it fills the whole row.
    if (fills) {
      cancel.layoutSizingHorizontal = 'FILL';
      confirm.layoutSizingHorizontal = 'FILL';
    }
    exposed.push(cancel, confirm);
  }
  const set = mount.finish();
  // Defined once on the SET, in the order the panel lists them, and bound in
  // every member.
  const showBarrier = defineProp(set, 'Show barrier', 'BOOLEAN', true);
  for (const n of barriers) bindVisibleProp(n, showBarrier);
  // The TEXT property is named after the contract's `props.slots`
  // entry (`title`), read from schema v3, never invented. `leading`/
  // `trailing` are rendered here (as swappable instance holders), so unlike a
  // text slot they take an INSTANCE_SWAP + BOOLEAN pair rather than a TEXT
  // property.
  const titleProp = defineProp(set, 'title', 'TEXT', titleCopy);
  for (const n of titles) bindTextProp(n, titleProp);
  const slotDefault = slotStandInDefault(page, 'rectangular');
  const leadingSwap = defineProp(set, 'Leading', 'INSTANCE_SWAP', slotDefault);
  const showLeading = defineProp(set, 'Show leading', 'BOOLEAN', false);
  for (const n of leadings) bindOptionalSlot(n, leadingSwap, showLeading);
  const trailingSwap = defineProp(set, 'Trailing', 'INSTANCE_SWAP', slotDefault);
  const showTrailing = defineProp(set, 'Show trailing', 'BOOLEAN', false);
  for (const n of trailings) bindOptionalSlot(n, trailingSwap, showTrailing);
  const contentProp = defineProp(set, 'content', 'TEXT', contentCopy);
  for (const n of bodies) bindTextProp(n, contentProp);
  // `content` is `W?` — the shipped dialogs pass a `Text`, and the rest pass a
  // form, a list or a plan picker. The text above is the common case; the slot
  // is everything else, and `Show content text` lets a designer swap one for
  // the other instead of stacking a widget under a sentence the dialog does
  // not have.
  const showContentText = defineProp(set, 'Show content text', 'BOOLEAN', true);
  for (const n of bodies) bindVisibleProp(n, showContentText);
  const contentSwap = defineProp(set, 'Content', 'INSTANCE_SWAP', slotDefault);
  const showContent = defineProp(set, 'Show content', 'BOOLEAN', false);
  for (const n of contentSlots) bindOptionalSlot(n, contentSwap, showContent);
  const showCancel = defineProp(set, 'Show cancel', 'BOOLEAN', true);
  for (const n of cancels) bindVisibleProp(n, showCancel);
  exposeAll(exposed);
  return set;
}

// ─── Drawer ──────────────────────────────────────────────────────────────────

// Data-driven from coui_core DRAWER.fields. One axis — `Side`, the contract's
// `CoreDrawerSide` — because the four edges put the panel, its flattened
// corners and its grab handle in four different places; everything else is a
// property. panelBackgroundColor/panelBorderColor/panelBorderRadius/
// panelBorderWidth/panelWidth/panelPadding/headerPadding/titleStyle/
// descriptionStyle/titleDescriptionGapStyle/dragHandle* are all real.
//
// The shape mirrors `drawer.dart`'s `panelChildren` exactly:
//
// ```text
// Drawer (bg / border / radius — the widget's DecoratedBox; no padding of
//         its own, the Column is flush; the two corners on the docked edge
//         flattened, as both widgets do)
//   ├─ handle   Padding(dragHandleInset) > Center > pill   // bottom: first
//   ├─ header   Padding(headerPadding) > Row
//   │    ├─ heading    Column[title, Gap(titleDescriptionGapStyle), description]
//   │    └─ close      Button(variant: .plain, buttonStyle: closeButtonStyle)
//   ├─ Divider  Divider(dividerStyle: resolved.dividerStyle)
//   ├─ content  Padding(panelPadding) > content        // caller slot `W`
//   └─ handle                                          // top: last
// ```
//
// A side drawer puts its body and the handle side by side —
// `Row[Expanded(body), handle]` on the left, mirrored on the right — so the
// pill stands upright on the panel's inner edge.
//
// The header row and the divider only exist when the widget is given a
// `title` or a `description` (`hasHeader`), so that conditional is a BOOLEAN
// property over both nodes rather than a shape baked in: it defaults ON (this
// preview is the titled one), and `Swiper` — which composes this Drawer with
// no title — turns it off on its instance. Without the property that
// composition would have to show a header the swiper's drawer never renders,
// which is the kind of plausible-looking extra a designer reads as part of the
// contract. The other parts are properties for the same reason, each starting
// where the contract does: `Show description` off (`description` is null),
// `Show close button` on, `Show handle` off. A header holding a description
// and no title is the one shape the widget reaches that the canvas does not —
// the title is always drawn while the header is.
// `panelPadding` moves
// onto the content frame because that is the only thing the widget pads with
// it — the root Column has no spacing at all, so the root carries no `gap`.
//
// `content` is a required `W` the caller fills, and the widget puts exactly
// ONE widget inside `Padding(panelPadding)` — so it is one node here, drawn as
// the placeholder box and swappable. The four `Button(variant: .menu)` rows
// this replaces were a nav list, and a nav list is a claim the contract does
// not make: the slot takes any widget, and the docs' own example fills it with
// a plain `Column` of `Text`.
//
// `Icon` — the drawer's only `Icon` is the ✕ *inside* the close Button
// (`Button(child: Icon(x))`). It is drawn as a real glyph overlaid on that
// composed instance, because Figma will not reparent a node into an instance
// (see `overlayGlyph`); the button itself stays a `Button` instance so its
// chrome keeps following `Button`.
//
// ── The presentation: barrier and scaled backdrop ────────────────────────────
//
// The other four fields DRAWER states are the route's, and all four are a static
// picture. `openDrawer` pushes a route that, with a backdrop host mounted
// (`transformBackdrop` defaults to true), renders:
//
// ```text
// DrawerBackdropLayer
//   └─ ClipRRect (backdropCornerRadius at t=1)
//        └─ Transform.scale (backdropScale at t=1)
//             └─ app content, with the route's ColoredBox(barrierColor) over it
//   └─ the panel, ABOVE the clip (a route-rendered panel would be cut by it)
// ```
//
// At rest — drawer fully open, `t = 1` — that is a rounded rectangle of the app
// at 95%, dimmed, with the panel docked on `CoreDrawerSide.defaultSide` (left)
// over it. Nothing in it is a keyframe: `scaleAt(1)` IS `backdropScale`, and the
// corner radius at `t = 1` IS `backdropCornerRadius`. A scaled solid rectangle
// and a resized one are the same picture, which is why the scale lands as a size
// rather than as a transform (Figma's `relativeTransform` carries rotation and
// translation only, and `rescale` would bake the tokens out of the panel).
//
// The scrim sits INSIDE the clip because that is where the widget puts it — the
// route page lives in the navigator, which the host scales and clips, so it dims
// exactly the visible backdrop rather than the whole viewport.
//
// So the root becomes the presentation and the panel moves one node in. Two
// consequences:
//
//   · `Show barrier` gates the whole presentation layer, and `Swiper` turns it
//     OFF on its instance — Swiper composes the Drawer WIDGET (its own
//     `_buildDrawerPanel` calls the constructor, not `openDrawer`), and the
//     widget paints no barrier. Without the property that composition would show
//     a scrim the swiper's drawer never renders.
//   · the app behind is the slot stand-in, named `app content` — a placeholder
//     for content the component does not own. It is not a slot: no caller hands
//     the Drawer the app, the app shell hosts it.
//
// The route's other `Stacks(` — the nested-navigator barrier-catcher + slide host
// — stays unmodelled: it is a hit-test and transition scaffold with no chrome.
// (`figma_composition_parity` counts this builder as composing `Stacks` from the
// `.x =` inside `overlayGlyph`. The placed root now genuinely IS a stack, so that
// credit has stopped being an artifact.)
// The edges the contract docks a panel to (`CoreDrawerSide`), in the order the
// export states them — read off the export, so a side the code adds becomes a
// member here instead of a side the canvas cannot draw.
function drawerSides(): readonly string[] {
  const side = DRAWER.axes.other.find((o) => o.enum === 'CoreDrawerSide');
  if (side == null || side.members.length === 0) {
    throw new Error(
      'Drawer: CoreDrawerSide is gone from the exported axes — the canvas has a ' +
        'Side axis that nothing in the contract now backs.',
    );
  }
  return side.members;
}

// The canvas copy for the `description` slot. The field is the caller's
// `String?`, so this is only what the property shows until a designer types the
// real sentence.
const kDrawerDescription = '이 패널의 용도를 한 문장으로 적어요';

type DrawerCorner = 'topLeft' | 'topRight' | 'bottomLeft' | 'bottomRight';

// The two corners on the edge a panel docks to. Both widgets flatten them so
// the panel sits flush against the screen edge — `drawer_style.dart` builds a
// `BorderRadius.only` per side, and the Web twin zeroes the same two longhands.
const kDrawerDockedCorners: Readonly<Record<string, readonly DrawerCorner[]>> = {
  left: ['topLeft', 'bottomLeft'],
  right: ['topRight', 'bottomRight'],
  top: ['topLeft', 'topRight'],
  bottom: ['bottomLeft', 'bottomRight'],
};

// The grab handle — `_DrawerHandle`: `Padding(all: dragHandleInset) > Center >`
// the pill. Upright on a side drawer, which lays it along the panel's inner edge.
function drawerHandle(lk: VarLookup, upright: boolean): FrameNode {
  const f = DRAWER.fields;
  const inset = f.dragHandleInset;
  const handle = panel('handle', 'HORIZONTAL', lk, {});
  bindPad(handle, lk, { l: inset, r: inset, t: inset, b: inset });
  handle.primaryAxisAlignItems = 'CENTER';
  handle.counterAxisAlignItems = 'CENTER';
  const pill = figma.createRectangle();
  pill.name = 'pill';
  if (upright) bindSize(pill, lk, f.dragHandleThickness, f.dragHandleWidth);
  else bindSize(pill, lk, f.dragHandleWidth, f.dragHandleThickness);
  bindRadiusN(pill, lk, f.dragHandleBorderRadius.topLeft);
  fillData(pill, lk, colorData(f.dragHandleColor));
  handle.appendChild(pill);
  return handle;
}

function buildDrawer(page: PageNode, lk: VarLookup): ComponentSetNode {
  const f = DRAWER.fields;
  const bg = colorData(f.panelBackgroundColor)!;
  const border = colorData(f.panelBorderColor)!;
  const sides = drawerSides();
  const combos = sides.map((side) => composeVariantName([['Side', side]]));
  // The single component this set grew out of docked the panel on the
  // contract's default side, so it becomes that member — its key, and every
  // instance a consuming file holds (Swiper's among them), survive.
  const mount = mountSet(page, 'Drawer', combos, {
    adoptLooseAs: composeVariantName([['Side', restingValueOf('Side')]]),
  });

  const presentations: FrameNode[] = [];
  const headers: SceneNode[] = [];
  const descriptions: TextNode[] = [];
  const closes: FrameNode[] = [];
  const handles: FrameNode[] = [];
  const contents: SlotNodes[] = [];
  const footers: FrameNode[] = [];
  const footerRules: InstanceNode[] = [];
  const footerSlots: SlotNodes[] = [];
  let footerSaveVariant: string | undefined;

  for (const side of sides) {
    const c = mount.getOrCreate(composeVariantName([['Side', side]]));
    c.layoutMode = 'NONE'; // the route's presentation stack
    c.fills = [];
    c.resize(kDrawerPageWidth, kDrawerPageHeight);

    // `ClipRRect(backdropCornerRadius) > Transform.scale(backdropScale)`, as one
    // clipping frame at the scaled size: the clip rounds whatever fills it,
    // which is what `ClipRRect` does to the app subtree.
    const backdropScale = dimVal(f.backdropScale);
    const backdrop = autoFrame('backdrop', 'VERTICAL');
    backdrop.clipsContent = true;
    backdrop.primaryAxisSizingMode = 'FIXED';
    backdrop.counterAxisSizingMode = 'FIXED';
    backdrop.resize(kDrawerPageWidth * backdropScale, kDrawerPageHeight * backdropScale);
    bindRadiusN(backdrop, lk, f.backdropCornerRadius.topLeft);
    // Named for what it stands in for — the app content the shell scales
    // behind the drawer (`DrawerBackdropLayer.child`), not for the stand-in.
    const appContent = slotStandIn(page, 'app content', 'rectangular');
    backdrop.appendChild(appContent);
    appContent.layoutSizingHorizontal = 'FILL';
    appContent.layoutSizingVertical = 'FILL';
    // SCALE, not CENTER: `backdropScale` is a RATIO of the page, so the clipped
    // app keeps that ratio when the instance is resized instead of staying at
    // the size it was minted at with only its centre following (#4805).
    place(
      c,
      backdrop,
      (kDrawerPageWidth - backdrop.width) / 2,
      (kDrawerPageHeight - backdrop.height) / 2,
      { horizontal: 'SCALE', vertical: 'SCALE' },
    );
    // The scrim, over the app and inside the clip — it dims the clipped
    // backdrop, not the viewport.
    const barrier = figma.createRectangle();
    barrier.name = 'barrier';
    fillData(barrier, lk, scaleAlpha(colorData(f.barrierColor)!, dimVal(f.barrierOpacity)));
    bindScrimOpacity(barrier, lk, f.barrierOpacity);
    barrier.resize(backdrop.width, backdrop.height);
    // `pinAbsolute`, not `place`: `backdrop` HAS auto-layout (the app content
    // flows in it), so the scrim needs the escape hatch to sit OVER that
    // content instead of after it.
    pinAbsolute(backdrop, barrier, 0, 0, { horizontal: 'STRETCH', vertical: 'STRETCH' });
    presentations.push(backdrop);

    // A side drawer spans the page's height at `panelWidth` and lays the
    // handle beside its body; a top or bottom sheet spans the width and is as
    // tall as what it holds (`panelHeight` is null by default — the route's
    // loose, screen-bounded constraints).
    const upright = side === 'left' || side === 'right';
    // The line sits on the inner edge only — the one facing the page — and only
    // on a side drawer: a top / bottom sheet states no line (`drawer_style.dart`
    // gives it no border at all), so it draws no stroke here either.
    const panelFrame = panel('panel', upright ? 'HORIZONTAL' : 'VERTICAL', lk, upright
      ? {
          border: border.color!,
          borderOp: border.opacity,
          borderArgb: border.argb,
          strokeN: f.panelBorderWidth,
          strokeSides: side === 'left' ? { right: true } : { left: true },
        }
      : {});
    const docked = kDrawerDockedCorners[side] ?? [];
    // A left / right panel reads the side-panel radius (0 — the line sits on
    // its inner edge alone); a top / bottom sheet keeps `panelBorderRadius`.
    const radius = side === 'left' || side === 'right' ? DRAWER.constants.sidePanelBorderRadius : f.panelBorderRadius;
    const corners: SurfaceCorners = {
      topLeft: docked.includes('topLeft') ? null : radius.topLeft,
      topRight: docked.includes('topRight') ? null : radius.topRight,
      bottomLeft: docked.includes('bottomLeft') ? null : radius.bottomLeft,
      bottomRight: docked.includes('bottomRight') ? null : radius.bottomRight,
    };
    for (const corner of ['topLeft', 'topRight', 'bottomLeft', 'bottomRight'] as const) {
      const value = corners[corner];
      const field = `${corner}Radius` as const;
      // The docked edge is flush — no step, a flattened corner.
      if (value == null || dimVal(value) === 0) panelFrame[field] = 0;
      else panelFrame.setBoundVariable(field, lk.radius(dimVal(value)));
    }
    // A floating surface on both platforms (`drawer_style.dart` reads
    // `theme.surfaceFor(.functional)`; the Web twin marks its panel
    // `webSurfaceMarkerFor(.functional)`), and both opt it into the style's rim.
    applySurfaceMaterial(panelFrame, lk, bg, 'functional', { radius: corners, rim: true });
    setShadow(panelFrame, f.panelBoxShadow, lk, colorData(f.shadowBaseColor));
    panelFrame.primaryAxisSizingMode = upright ? 'FIXED' : 'AUTO';
    panelFrame.counterAxisSizingMode = 'FIXED';
    if (upright) panelFrame.resize(dimVal(f.panelWidth), kDrawerPageHeight);
    else panelFrame.resize(kDrawerPageWidth, panelFrame.height);
    // Placed before its children so the property writes below have a COMPONENT
    // ancestor to bind against. MIN/MAX on the docked axis keeps the panel at
    // its own extent when the instance is resized; STRETCH on the other keeps
    // it spanning the page.
    place(
      c,
      panelFrame,
      side === 'right' ? kDrawerPageWidth - dimVal(f.panelWidth) : 0,
      0,
      upright
        ? { horizontal: side === 'right' ? 'MAX' : 'MIN', vertical: 'STRETCH' }
        : { horizontal: 'STRETCH', vertical: side === 'bottom' ? 'MAX' : 'MIN' },
    );

    let column: FrameNode = panelFrame;
    if (upright) {
      column = autoFrame('body', 'VERTICAL');
      panelFrame.appendChild(column);
      column.layoutSizingHorizontal = 'FILL';
      column.layoutSizingVertical = 'FILL';
    }

    const headerPad = f.headerPadding;
    const header = panel('header', 'HORIZONTAL', lk, {
      pl: headerPad.l, pr: headerPad.r, pt: headerPad.t, pb: headerPad.b,
      gap: f.headerSpacing,
    });
    // Top-aligned: the title and the close button share the header's top edge.
    header.counterAxisAlignItems = 'MIN';
    column.appendChild(header);
    header.layoutSizingHorizontal = 'FILL';
    // `Column[title, Gap(titleDescriptionGapStyle), description]` — one column
    // for both shapes: with the description hidden, auto-layout skips it and
    // its gap, which is the `Expanded(Text(title))` the widget draws then.
    const heading = autoFrame('heading', 'VERTICAL');
    heading.setBoundVariable('itemSpacing', lk.space(dimVal(f.titleDescriptionGapStyle.size)));
    header.appendChild(heading);
    heading.layoutSizingHorizontal = 'FILL';
    const title = makeLabel('메뉴', lk, textLabelOpts(lk, textStyleData(f.titleStyle)));
    heading.appendChild(title);
    title.layoutSizingHorizontal = 'FILL';
    const description = makeLabel(
      kDrawerDescription,
      lk,
      textLabelOpts(lk, textStyleData(f.descriptionStyle)),
    );
    heading.appendChild(description);
    description.layoutSizingHorizontal = 'FILL';
    descriptions.push(description);
    const close = closeButton(page, lk, {
      size: iconShapeGlyphSize(kDrawerCloseAxes.Size, f.closeButtonStyle),
      color: colorData(kPlainButtonForeground)!,
      axes: kDrawerCloseAxes,
      style: f.closeButtonStyle,
    });
    header.appendChild(close);
    closes.push(close);
    headers.push(header);

    // `Drawer` hands the rule a whole Style of its own
    // (`dividerStyle: style.dividerStyle`, raw-forwarded to the composed
    // `Divider`), so it is forwarded rather than left to the child's defaults.
    const rule = hostedDivider(page, lk, column, {
      axes: kPlainDividerAxes,
      forwarded: {
        color: colorData(f.dividerStyle.color),
        thickness: f.dividerStyle.thickness,
        indent: f.dividerStyle.indent,
        endIndent: f.dividerStyle.endIndent,
      },
    });
    headers.push(rule);

    const pad = f.panelPadding;
    const content = panel('content', 'VERTICAL', lk, {
      pl: pad.l, pr: pad.r, pt: pad.t, pb: pad.b,
    });
    column.appendChild(content);
    content.layoutSizingHorizontal = 'FILL';
    // A side drawer spans the route's full height, so its content fills what the
    // header and footer leave; a top / bottom sheet keeps the loose fit.
    if (upright) content.layoutSizingVertical = 'FILL';
    const body = standInSlotNodes(page, 'content', 'text');
    content.appendChild(body.holder);
    body.holder.layoutSizingHorizontal = 'FILL';
    body.instance.layoutSizingHorizontal = 'FILL';
    contents.push(body);

    // The footer: the rule, then the padded row at the end edge
    // (`Divider` + `Padding(footerPadding) > Align(centerEnd) > footer`). Off by
    // default — the contract's `footer` is null — so the rule and the row are
    // gated together, as the header's are. The two buttons are this preview's
    // example, not a default the code carries.
    footerRules.push(
      hostedDivider(page, lk, column, {
        axes: kPlainDividerAxes,
        forwarded: {
          color: colorData(f.dividerStyle.color),
          thickness: f.dividerStyle.thickness,
          indent: f.dividerStyle.indent,
          endIndent: f.dividerStyle.endIndent,
        },
      }),
    );
    const footerPad = f.footerPadding;
    const footerRow = panel('footer', 'HORIZONTAL', lk, {
      pl: footerPad.l, pr: footerPad.r, pt: footerPad.t, pb: footerPad.b,
    });
    footerRow.primaryAxisAlignItems = 'MAX';
    footerRow.counterAxisAlignItems = 'CENTER';
    column.appendChild(footerRow);
    footerRow.layoutSizingHorizontal = 'FILL';
    const cancel = instanceOf(page, 'Button', bestVariantName(page, 'Button', kDialogCancelButtonAxes));
    cancel.name = 'cancel';
    footerRow.appendChild(cancel);
    setInstanceTextNamed(cancel, 'Child', '취소');
    // `footer` is a `W?` slot — a caller's own widget, usually its action row. A
    // swap default has to be one component, so the example is the pair's
    // primary action as the swappable slot with the secondary one beside it.
    const saveVariant = bestVariantName(page, 'Button', kDialogConfirmButtonAxes);
    const save = slotNodes('footer', instanceOf(page, 'Button', saveVariant));
    footerRow.appendChild(save.holder);
    setInstanceTextNamed(save.instance, 'Child', '저장');
    footerSaveVariant = saveVariant;
    footerSlots.push(save);
    footers.push(footerRow);

    // On the edge facing the screen centre: above the header of a bottom
    // sheet, below the content of a top one, on the inner edge of a side
    // drawer — the order `panelChildren` builds.
    const handle = drawerHandle(lk, upright);
    if (side === 'bottom' || side === 'right') {
      // First in the flow, but above the surface layers the material put at the
      // bottom of the stack — under them the panel's own fill would cover it.
      const flowStart = panelFrame.children.findIndex((n) => !isSurfaceLayer(n));
      panelFrame.insertChild(flowStart === -1 ? panelFrame.children.length : flowStart, handle);
    } else {
      panelFrame.appendChild(handle);
    }
    if (upright) handle.layoutSizingVertical = 'FILL';
    else handle.layoutSizingHorizontal = 'FILL';
    handles.push(handle);

    // A sheet is as tall as what it holds, so its docked position is known
    // only now.
    if (side === 'bottom') panelFrame.y = kDrawerPageHeight - panelFrame.height;
  }

  const set = mount.finish();
  // `defineProp` reuses the id after the first variant — one property on the
  // SET, every member's node bound to it.
  const showBarrier = defineProp(set, 'Show barrier', 'BOOLEAN', true);
  for (const n of presentations) bindVisibleProp(n, showBarrier);
  // One property over the header row and its rule — `hasHeader` gates them
  // together, and two toggles could express a state the widget cannot reach
  // (a rule with nothing above it).
  const showHeader = defineProp(set, 'Show header', 'BOOLEAN', true);
  for (const n of headers) bindVisibleProp(n, showHeader);
  // `description` is `String?` and null by default, so the line starts
  // hidden; the TEXT property is the caller's sentence.
  const descriptionText = defineProp(set, 'Description', 'TEXT', kDrawerDescription);
  for (const n of descriptions) bindTextProp(n, descriptionText);
  const showDescription = defineProp(set, 'Show description', 'BOOLEAN', false);
  for (const n of descriptions) bindVisibleProp(n, showDescription);
  // `showCloseButton` — on by default (`CoreDrawerContract.defaultShowCloseButton`).
  const showClose = defineProp(
    set,
    'Show close button',
    'BOOLEAN',
    DRAWER.behaviour.showCloseButton,
  );
  for (const n of closes) bindVisibleProp(n, showClose);
  // `showDragHandle` — off by default (`CoreDrawerContract.defaultShowDragHandle`).
  const showHandle = defineProp(set, 'Show handle', 'BOOLEAN', DRAWER.behaviour.showDragHandle);
  for (const n of handles) bindVisibleProp(n, showHandle);
  const contentSwap = defineProp(set, 'Content', 'INSTANCE_SWAP', slotStandInDefault(page, 'text'));
  for (const b of contents) bindSlot(b, contentSwap);
  // `footer` is `W?` and null by default, so the rule and the row start hidden.
  const showFooter = defineProp(set, 'Show footer', 'BOOLEAN', false);
  for (const n of footerRules) bindVisibleProp(n, showFooter);
  for (const n of footers) bindVisibleProp(n, showFooter);
  const footerSwap = defineProp(set, 'Footer', 'INSTANCE_SWAP', mainId(page, 'Button', footerSaveVariant ?? bestVariantName(page, 'Button', kDialogConfirmButtonAxes)));
  for (const b of footerSlots) bindSlot(b, footerSwap);
  // `layoutSet` arranges the sibling members inside the SET container. No Dart
  // code has a notion of how wide a member grid on a Figma page is.
  // g7-preview-only: width of the member SET's wrap grid on the canvas, no code analogue.
  layoutSet(set, 1320);
  return set;
}

// ─── BottomSheet ─────────────────────────────────────────────────────────────

const BOTTOM_SHEET = COMPONENTS.bottom_sheet;
const BUTTON_SIZES = COMPONENTS.button.sizes.defaultsBySize;

// The close affordance's Button: `Button(variant: .plain, size: .sm, shape: .square)`
// (`bottom_sheet.dart`), named by axis so a Button axis that grows cannot move the pick.
const kBottomSheetCloseAxes = { Variant: 'plain', Size: 'sm', State: 'enabled', Shape: 'square' };
// The plain horizontal rule `Divider()` draws.
const kBottomSheetDividerAxes = kPlainDividerAxes;
// The Footer slot's default: the sheet's own example puts a horizontal
// `BottomActionBar` there.
const kBottomSheetFooterAxes = { Layout: 'horizontal' };
// Display copy — what the preview shows, not chrome.
const kBottomSheetTitleCopy = '옵션 선택';
const kBottomSheetDescriptionCopy = '원하는 항목을 골라 주세요.';

// A corner the field states as 0 is a flush edge, drawn as no step.
function bottomSheetCorner(d: Dim): Dim | null {
  return dimVal(d) > 0 ? d : null;
}

// ```text
// BottomSheet  (VERTICAL · surface material · top corners only)
//   ├─ handle   (pad handlePadding · pill handleWidth × handleHeight)         ← `Show handle`
//   ├─ header   (HORIZONTAL · headerPadding · gap headerSpacing)
//   │    ├─ heading   title (titleTextStyle) + description (gap titleGapStyle) ← `Show description`
//   │    └─ close     Button plain sm square + x                               ← `Show close button`
//   ├─ divider  Divider                                                        ← `Show divider`
//   ├─ content  (pad contentPadding) the `Content` swap                        ← `Show content`
//   └─ footer   the `Footer` swap, a horizontal BottomActionBar                ← `Show footer`
//                (footerBarStyle: no fill, no hairline of its own)
// ```
//
// The canvas draws the resting state only. The sheet's own hairline above the
// footer (`footerDividerColor` / `footerDividerWidth`) shows in the code only
// while the content scrolls past the bottom — a state a static frame has no
// scroll position for, so it is not drawn and has no property. Likewise the
// height ceiling (`maxHeightFactor`) is a fraction of a viewport the canvas
// does not have.
//
// A functional surface on both platforms (`bottom_sheet_style.dart` reads
// `surfaceFor(.functional)`), so the fill is painted through `applySurfaceMaterial`.
// The widgets state no border and no shadow, and the bottom corners are square —
// the sheet is docked to the screen's bottom edge.
function buildBottomSheet(page: PageNode, lk: VarLookup): ComponentNode {
  const f = BOTTOM_SHEET.fields;
  const c = mint(page, 'BottomSheet');
  applyPanelCompChrome(c, 'VERTICAL', lk, {});
  c.itemSpacing = 0;
  const radius = f.borderRadius;
  const corners: SurfaceCorners = {
    topLeft: bottomSheetCorner(radius.topLeft),
    topRight: bottomSheetCorner(radius.topRight),
    bottomLeft: bottomSheetCorner(radius.bottomLeft),
    bottomRight: bottomSheetCorner(radius.bottomRight),
  };
  for (const corner of ['topLeft', 'topRight', 'bottomLeft', 'bottomRight'] as const) {
    const value = corners[corner];
    const field = `${corner}Radius` as const;
    if (value == null) c[field] = 0;
    else c.setBoundVariable(field, lk.radius(dimVal(value)));
  }
  applySurfaceMaterial(c, lk, colorData(f.backgroundColor), 'functional', { radius: corners });
  // g7-preview-only: BottomSheet preview width, a phone screen; no extent field in the code.
  lockWidth(c, 390);

  // The handle: an area `handlePadding.top` over a `handleWidth × handleHeight` pill.
  const handle = panel('handle', 'HORIZONTAL', lk, {});
  bindPad(handle, lk, f.handlePadding);
  handle.primaryAxisAlignItems = 'CENTER';
  const pill = figma.createRectangle();
  pill.name = 'pill';
  bindSize(pill, lk, f.handleWidth, f.handleHeight);
  bindRadiusN(pill, lk, f.handleBorderRadius.topLeft);
  fillData(pill, lk, colorData(f.handleColor));
  handle.appendChild(pill);
  c.appendChild(handle);
  handle.layoutSizingHorizontal = 'FILL';

  const header = panel('header', 'HORIZONTAL', lk, { gap: f.headerSpacing });
  bindPad(header, lk, f.headerPadding);
  header.counterAxisAlignItems = 'CENTER';
  c.appendChild(header);
  header.layoutSizingHorizontal = 'FILL';
  const heading = autoFrame('heading', 'VERTICAL');
  heading.setBoundVariable('itemSpacing', lk.space(dimVal(f.titleGapStyle.size)));
  header.appendChild(heading);
  heading.layoutSizingHorizontal = 'FILL';
  const title = makeLabel(
    kBottomSheetTitleCopy,
    lk,
    textLabelOpts(lk, textStyleData(f.titleTextStyle)),
  );
  title.name = 'title';
  heading.appendChild(title);
  title.layoutSizingHorizontal = 'FILL';
  const description = makeLabel(
    kBottomSheetDescriptionCopy,
    lk,
    textLabelOpts(lk, textStyleData(f.descriptionTextStyle)),
  );
  description.name = 'description';
  heading.appendChild(description);
  description.layoutSizingHorizontal = 'FILL';
  const cbs = f.closeButtonStyle;
  const close = closeButton(page, lk, {
    axes: kBottomSheetCloseAxes,
    size: BUTTON_SIZES.sm.iconShapeIconStyle.size,
    color: colorData(cbs.foregroundColor)!,
    style: {
      padding: cbs.padding,
      borderRadius: cbs.borderRadius,
      width: cbs.width,
      height: cbs.height,
      focusOutlineStyle: cbs.focusOutlineStyle,
    },
  });
  header.appendChild(close);
  // Absent by default, like the flag in the code.
  close.visible = false;

  const rule = hostedDivider(page, lk, c, { axes: kBottomSheetDividerAxes });
  rule.name = 'divider';
  rule.layoutSizingHorizontal = 'FILL';
  rule.visible = false;

  const pad = f.contentPadding;
  const content = panel('content', 'VERTICAL', lk, {
    pl: pad.l, pr: pad.r, pt: pad.t, pb: pad.b,
  });
  c.appendChild(content);
  content.layoutSizingHorizontal = 'FILL';
  const body = standInSlotNodes(page, 'content', 'rectangular');
  content.appendChild(body.holder);
  body.holder.layoutSizingHorizontal = 'FILL';
  body.instance.layoutSizingHorizontal = 'FILL';

  const footerVariant = bestVariantName(page, 'BottomActionBar', kBottomSheetFooterAxes);
  const footer = slotNodes('footer', instanceOf(page, 'BottomActionBar', footerVariant));
  c.appendChild(footer.holder);
  footer.holder.layoutSizingHorizontal = 'FILL';
  footer.instance.layoutSizingHorizontal = 'FILL';
  applySheetFooterBarStyle(footer.instance, f.footerBarStyle);

  // Properties are defined once every node is inside the component.
  const titleProp = defineProp(propertyOwner(c), 'Title', 'TEXT', kBottomSheetTitleCopy);
  bindTextProp(title, titleProp);
  const descriptionProp = defineProp(propertyOwner(c), 'Description', 'TEXT', kBottomSheetDescriptionCopy);
  bindTextProp(description, descriptionProp);
  // `description` is `W?`; the contract has no default for it, so the line shows.
  bindVisibleProp(description, defineProp(propertyOwner(c), 'Show description', 'BOOLEAN', true));
  bindVisibleProp(handle, defineProp(propertyOwner(c), 'Show handle', 'BOOLEAN', BOTTOM_SHEET.behaviour.showHandle));
  bindVisibleProp(
    close,
    defineProp(propertyOwner(c), 'Show close button', 'BOOLEAN', BOTTOM_SHEET.behaviour.showCloseButton),
  );
  bindVisibleProp(rule, defineProp(propertyOwner(c), 'Show divider', 'BOOLEAN', BOTTOM_SHEET.behaviour.showDivider));
  bindVisibleProp(content, defineProp(propertyOwner(c), 'Show content', 'BOOLEAN', true));
  bindSwapProp(body.instance, defineProp(propertyOwner(c), 'Content', 'INSTANCE_SWAP', slotStandInDefault(page, 'rectangular')));
  bindVisibleProp(footer.holder, defineProp(propertyOwner(c), 'Show footer', 'BOOLEAN', true));
  bindSwapProp(
    footer.instance,
    defineProp(propertyOwner(c), 'Footer', 'INSTANCE_SWAP', mainId(page, 'BottomActionBar', footerVariant)),
  );
  return c;
}

// Writes the sheet's `footerBarStyle` onto the composed BottomActionBar — the
// two values the sheet's default diverges in, read from the export rather than
// restated: a fill that paints nothing clears the bar's fill and its material
// layers (a fill-less bar takes no material on either platform), and a zero
// hairline turns the bar's `Show divider` off. Only the bar's root and its own
// material layers: the composed Buttons inside keep their fills.
function applySheetFooterBarStyle(
  bar: InstanceNode,
  style: (typeof BOTTOM_SHEET.fields)['footerBarStyle'],
): void {
  const fill = style.backgroundColor;
  if (fill.ref == null && fill.argb === 0) {
    bar.fills = [];
    for (const child of bar.children) {
      if (!isSurfaceLayer(child)) continue;
      const layer = child as RectangleNode;
      layer.fills = [];
      layer.effects = [];
    }
  }
  if (dimVal(style.dividerWidth) === 0) setInstanceBoolNamed(bar, 'Show divider', false);
}

// ─── Popover ─────────────────────────────────────────────────────────────────

// `popover.dart#_buildPanel` is two lines long, and they are the whole
// component:
//
// ```dart
// Popup(popupStyle: liveResolved.panelStyle, children: [widget.content])
// ```
//
// So the floating panel is not "a box that resembles Popup" — it IS a
// `Popup`, and the panel's background / border / radius / padding / shadow /
// content colour are that component's fields, not Popover's. That is exactly
// why `COMPONENTS.popover.fields` carries none of them: only
// `placementOffset` / `openAnimationDuration` / `closeAnimationDuration` /
// `viewportPadding` (positioning + timing, nothing a static frame shows) and
// the `panelStyle` forward. The previous hand-drawn `surface`-filled,
// `outline`-bordered, radius-12 box asserted eight chrome values that no
// `CorePopoverStyle` default decides.
//
// ── The two slots ────────────────────────────────────────────────────────────
//
// `trigger` is a required `W` rendered INLINE (the panel is the overlay), so
// it is a real node here — it was missing entirely, which left the component
// showing only half of what the widget renders. It defaults to the `Button`
// the widget's own example passes, and the INSTANCE_SWAP is what keeps that a
// default rather than a claim that a popover trigger must be a button.
//
// `placementOffset` — the trigger↔panel distance — becomes that column's gap.
// It was previously written off as "positioning, nothing a static frame
// shows", which was true only while the trigger had no node to be offset from.
//
// `content` is `Popup(children: [widget.content])` — it lives INSIDE the
// composed instance, and Figma will not reparent a node into an instance. So
// it is reached the way the code reaches it: through the child. `Popup` draws
// `children` as its `Content` INSTANCE_SWAP slot, and the popover exposes the
// instance so that property surfaces on every Popover — the designer's swap is
// the caller's `content`. Hand-drawing the panel so the content could sit in
// it would trade that for a `Popup` that stops following `Popup`, asserting
// eight chrome values no `CorePopoverStyle` default decides. The `Padding` axis
// stays a VARIANT the popover fixes to the member its code states
// (16 → `Padding=content`).
function buildPopover(page: PageNode, lk: VarLookup): ComponentNode {
  const c = mintPanelComp(page, 'Popover', 'VERTICAL', lk, {
    gap: POPOVER.fields.placementOffset,
  });
  const variant = bestVariantName(page, 'Button', kOutlineButtonAxes);
  const triggerButton = instanceOf(page, 'Button', variant);
  // The example's trigger — the button that opens a notification panel (#6473,
  // the designer's copy); a caller's trigger is any widget.
  setInstanceTextNamed(triggerButton, 'Child', kPopoverExampleTrigger);
  const trigger = slotNodes('trigger', triggerButton);
  c.appendChild(trigger.holder);
  // `triggerSizing` — `_applySizing` wraps the trigger so the wrapper either
  // takes the trigger's intrinsic width or fills the parent's inline axis, and
  // that is exactly the two values a Figma child's horizontal sizing has. It
  // sits on the HOLDER because the holder IS that wrapper; the trigger instance
  // keeps its own width either way.
  //
  // Its default is `intrinsic`, so the picture does not change today — what
  // changes is that the picture now follows the field instead of agreeing with
  // it by accident. Flipping the Core default to `expand` moves this canvas.
  trigger.holder.layoutSizingHorizontal =
    POPOVER.fields.triggerSizing.choice === 'expand' ? 'FILL' : 'HUG';
  // `panelStyle.padding`, forwarded into the composed `Popup`: the popover
  // states the panel's inset, and the `Popup` member that IS that inset is the
  // one composed (16 → `Padding=content`). An inset that is neither preset is
  // still written onto the instance — the one reachable half of a forward whose
  // other fields the composed child already agrees with.
  const panelInstance = popupInstance(page, POPOVER.fields.panelStyle.padding);
  applyForwardedPanelStyle(panelInstance, lk, {
    padding: popupPaddingOverride(POPOVER.fields.panelStyle.padding),
  });
  // The panel holds the example content rather than the stand-in (#6473): a
  // popover whose panel is a dashed box reads as empty. Written on the
  // composed instance — the `Content` swap is the `Popup`'s own slot, exposed
  // below — so a placed Popover still takes any content through it.
  setInstanceSwapNamed(panelInstance, 'Content', exampleMainId(page, kPopoverExample));
  c.appendChild(panelInstance);
  bindSlot(
    trigger,
    defineProp(propertyOwner(c), 'Trigger', 'INSTANCE_SWAP', mainId(page, 'Button', variant)),
  );
  // After the append: exposing needs a COMPONENT ancestor (`exposeAll`).
  exposeSlot([panelInstance], 'Content', 'INSTANCE_SWAP');
  return c;
}

// ─── Toast ───────────────────────────────────────────────────────────────────

// The real CoreToastStyle carries `variants.defaultsByVariant` (default/
// destructive) — the old hardcoded builder rendered a single node with none
// of that dispatch, so this becomes a 2-variant set (mirrors the Button
// 4→12-variant precedent: follow the real variant set, #3755). Panel
// geometry (`panelPaddingWithDismiss` — this preview always shows the
// dismiss button — border radius/width, content/action gap,
// message/description gap) and both variants' background/foreground/
// border/close/description colors are all real TOAST data.
// `descriptionStyle` carries only a role (no color of its own) —
// `textLabelOpts`'s fallback param supplies the variant's
// `descriptionForeground`. TOAST has no titleStyle/iconColor field at all
// (only `descriptionStyle`) — the "Saved" title's size/weight and the
// checkmark glyph's color stay literal, but the title's own *color* still
// comes from the variant's `foregroundColor` (#3755 OQ-2 for size/weight/icon
// color only).
//
// Structure, from `toast.dart`:
//
// ```text
// Toast (bg / border / radius — DecoratedBox)          // root == Stacks
//   ├─ content   Padding(panelPaddingWithDismiss) > Row
//   │    ├─ message column   Column[ Text(messageStyle),
//   │    │                           Gap(messageDescriptionGapStyle),
//   │    │                           Text(descriptionStyle) ]
//   │    └─ (Gap(contentActionGapStyle) + `action`)     // caller slot `W?`
//   └─ close     Position(top/right/bottom: closeInset) > Align > Button(variant: .plain)
// ```
//
// The root is a `Stacks`, not a row, and that is load-bearing rather than
// cosmetic: the widget's own comment says the close button is anchored on the
// panel (not inset inside the padding box) because a negative offset would put
// it outside the stack's bounds and Flutter would miss the hit test entirely.
// So the close affordance is placed at `closeInset` from the panel's trailing
// edge, centred in the band its block insets leave — a real field that had no consumer while the ✕ rode along as a third
// flow child.
//
// The ✕ itself is a `Button(variant: .plain)` whose child is an `Icon`, so the
// button is a composed instance and the glyph is a real `Icon` overlaid on it
// (an instance takes no children — `overlayGlyph`). Its size is the real
// `closeButtonStyle.leadingIconStyle.size`; its colour is the variant's own
// `closeForeground`, which is exactly what `closeButtonStyle` forwards INTO
// that Button and therefore what the glyph inherits. Repainting the button
// itself is what would break the moment Button's plain variant moves.
//
// `action` is a `W?` the widget appends to the content Row after
// `Gap(contentActionGapStyle)`. It has a node now — a placeholder box, not a
// `Button`: `action` is a caller slot and `CoreToastStyle` forwards no button
// style, so defaulting it to a Button would assert a composition edge the
// contract does not have (same reading as Dialog's `actions`). It starts
// hidden, matching the widget's `null`, so the panel's picture is unchanged.
//
// There is no leading status glyph: `Toast` has message / description /
// action / onDismiss and no icon slot, and no icon field. The `circle-check`
// that used to sit here was a fabrication — a mark for a state the component
// never draws.
//
// `messageStyle` is a real field (labelLarge with a bold 700 overlay), so the
// title's size and weight are no longer literals — the overlay departs from
// the role's 500, so the label binds the size step rather than the role (see
// `applyRole`); the per-variant `foregroundColor` still wins on colour.
//
// The description and the resting close ✕ are `inverse-on-surface` at 75 % /
// 70 %. Both go through the sub-1 token path (`labelColor` / `iconOpts`): the
// paint stays bound to the variable at full strength and the NODE is faded,
// so the token still shows and Dark mode still flips it.
//
// No state axis: `focusOutlineStyle` is nested inside `closeButtonStyle`, i.e.
// it is the composed Button's focus ring, not Toast's — repainting it on the
// parent is what this epic's instance rule forbids. Toast has no own hover /
// selected / disabled chrome to key an axis on.
// Preview geometry for the `action` slot's placeholder box — TOAST has no
// action-size field (the caller's widget decides), so these are this preview's
// numbers, applied through `resize()` only.
const kToastActionWidth = 64;
const kToastActionHeight = 28;

// The two members of a boolean axis. Local rather than shared with `display.ts`'s
// copy: an axis-member list is a naming convention, and importing one builder's
// private constant into another to save two words couples them for nothing.
const kToastBoolAxis = ['false', 'true'] as const;

// #4035 (C3) — the combinations come out of the SAME function G10 measures
// with (T-14), so numerator and denominator cannot drift apart. Toast has no
// Size and no Enabled axis in v3, so the four schema axes contribute exactly
// the variant enum; `Dismissible` is appended as a POSE axis (declared by
// this builder, listed in `kAxisOrder`, not by `axes` — recording without
// promotion, §4-2), which makes the set `variant × {false,true}`.
//
// Member names use the axis's own spellings, so `default` reads `default_`
// (Dart's trailing-underscore stand-in for the reserved word — a rename row
// in src/renames.ts, so the child keeps its key). `defaultsByVariant` is
// still keyed by the bare `default`, which is why the data lookup falls back
// to it rather than assuming the two spellings match.
// Which glyph each Toast variant carries. `neutral` is absent on purpose —
// the three variants fill with the SAME inverse surface and draw the mark in
// the SAME message colour, so the glyph's shape is what distinguishes them,
// and `neutral` distinguishes itself by having none.
//
// The panel's authored default AND its cap. `toast` states no width field
// (its only width is `panelBorderWidth`) and `toast.dart` sets no width or
// constraint either — a real toast is sized by the overlay hosting it. This
// canvas panel is g7-preview-only: something has to be drawn, and this is
// the value that was drawn. The panel opens at it and `content` FILLs the
// panel; an instance set to Fill container shrinks below it with a narrower
// host and stops here in a wider one (`c.maxWidth`) — Material 3's snackbar
// caps the same way.
const kToastPreviewWidth = 340;

// Keyed by the axis spelling, which is the member name — `success` since
// the rename off `default_`.
const kToastIcon: Record<string, string> = {
  success: 'circle-check',
  destructive: 'circle-alert',
};

function buildToast(page: PageNode, lk: VarLookup): ComponentSetNode {
  const inset = TOAST.fields.closeInset;
  // NOT `|| 1`. Core states `defaultPanelBorderWidth = stroke0` — no
  // stroke — and JS's falsy `0 || 1` was rewriting that to a 1px stroke in
  // the fill's own colour, so the canvas carried a border the code never
  // draws (both platforms emit width 0). Dialog / drawer in this file pass
  // the Dim straight through; this one now does too, and skips the stroke
  // paint entirely at zero rather than binding a weight-0 stroke.
  const strokeN = dimVal(TOAST.fields.panelBorderWidth);
  const messageStyle = textStyleData(TOAST.fields.messageStyle);
  const descStyle = textStyleData(TOAST.fields.descriptionStyle);
  const variantData = new Map(Object.entries(TOAST.variants.defaultsByVariant));
  // `Dismissible` is `onDismiss != null` (both `toast.dart` files), and it is the
  // only switch between the two padding fields the component states:
  // `panelPaddingWithDismiss` when a caller passed the callback,
  // `panelPadding` when it did not. Only the with-dismiss one was drawn, so the
  // plain inset — the widget's DEFAULT, since `onDismiss` is optional — reached no
  // node, and the close ✕ was on every toast the canvas showed.
  //
  // An axis rather than a second component: the two differ in one inset and in
  // whether one child is there, which is what a variant axis is for. It is
  // appended to `axisSpecsOf`'s four rather than looped by hand, so the member
  // names come out of `composeVariantName` like every other set's.
  const combos = enumerateAxisCombos([
    ...axisSpecsOf(TOAST.axes),
    { axis: 'Dismissible', values: kToastBoolAxis },
  ]);
  const mount = mountSet(page, 'Toast', combos);
  // Collected so the text can become a PROPERTY, the way Banner's does.
  // Without it the only way to change a toast's wording is to edit the
  // nested text node, and the English default survives into screens that
  // are otherwise fully localised.
  const messageNodes: TextNode[] = [];
  const descriptionNodes: TextNode[] = [];
  const actionSlots: SlotNodes[] = [];
  // The leading glyphs — one per member that draws one, none on `neutral`.
  // Collected so `Show icon` can bind them (below).
  const glyphNodes: InstanceNode[] = [];
  for (const comboName of combos) {
    const combo = parseVariantKey(comboName);
    // The axis member is `default_`; `defaultsByVariant` keys the same variant
    // as `default`, so the bare spelling is the fallback — not a guess about a
    // missing variant.
    const v = variantData.get(combo['Variant']) ?? variantData.get('default');
    if (!v) throw new Error(`Toast: no data for combo "${comboName}"`);
    const withDismiss = combo['Dismissible'] === 'true';
    const pad = withDismiss
      ? TOAST.fields.panelPaddingWithDismiss
      : TOAST.fields.panelPadding;
    const c = mount.getOrCreate(comboName);
    // Auto-layout — NOT `Stacks` (`layoutMode: 'NONE'`) any more. `maxWidth`
    // can only land on an auto-layout node or a child of one, and a `NONE`
    // panel inside a grid-laid-out set (Toast's own axes read as a grid, so
    // `defaultSetLayout` leaves the SET at `NONE` too — absolute positions,
    // not auto-layout, is what a per-block grid needs) satisfies neither: a
    // `maxWidth` on a `NONE` panel threw on every Toast build.
    //
    // FIXED at the authored 340 on the main axis, hugging the cross axis
    // (#4826): the bubble's height is its content's — one line, two with
    // `Show description`, taller with an action — and its width is the
    // host's, which reaches `content` only as a FILL child, and a FILL child
    // needs a FIXED parent axis. `close` stays pinned over `content` via
    // `pinInFlow`, which already treats an auto-layout host as the normal case.
    c.layoutMode = 'HORIZONTAL';
    lockWidth(c, kToastPreviewWidth);
    c.paddingLeft = 0;
    c.paddingRight = 0;
    c.paddingTop = 0;
    c.paddingBottom = 0;
    c.itemSpacing = 0;
    // `maxWidth` on the panel itself — Material 3's snackbar caps the same
    // way. Below 340 the panel narrows with whatever hosts it; above 340 it
    // stops, so a wide tablet screen does not stretch a toast bubble
    // edge-to-edge. Written HERE, on the loose member: `c` is auto-layout
    // now, so the cap is legal on the node itself and needs neither its set
    // nor `finish()`. It could not live after `finish()` any more: the set is
    // withheld until the run loop reassembles it (`identity.ts`, deferred
    // reassembly), so a walk of `set.children` there sees only the anchor on
    // a first build (and only the recycled members on a rebuild) — a cap that
    // lands on some members and not others. Writing before the member's trip
    // through the staging set is the shape TextArea already ships (`form.ts`,
    // `c.maxWidth` before `finish()`).
    c.maxWidth = kToastPreviewWidth;
    bindRadiusN(c, lk, TOAST.fields.panelBorderRadius.topLeft);
    // A floating surface on both platforms (`toast_style.dart` reads
    // `theme.surfaceFor(.functional)`; the Web twin marks itself
    // `webSurfaceMarkerFor(.functional)`). It takes the rim because it casts:
    // both platforms draw the rim on a panel whose own shadow is there to draw
    // (`resolveSurfaceRim` over the panel stack on Flutter, the rim variable
    // appended to the panel's `box-shadow` on Web), and none on one stated
    // shadowless.
    applySurfaceMaterial(c, lk, colorData(v.backgroundColor), 'functional', {
      radius: TOAST.fields.panelBorderRadius.topLeft,
      rim: TOAST.fields.panelBoxShadow.layers.length > 0,
    });
    if (strokeN > 0) borderData(c, lk, colorData(v.borderColor), strokeN);
    setShadow(c, TOAST.fields.panelBoxShadow, lk);

    const content = panel('content', 'HORIZONTAL', lk, {
      gap: TOAST.fields.contentActionGapStyle.size,
    });
    // `toast.dart` is a `Row` with Flutter's default cross alignment —
    // centre — and the Web twin is `items-center`. `MIN` here put a
    // one-line message at the top of the band with the action beside it
    // hanging lower, which is not what either widget draws.
    content.counterAxisAlignItems = 'CENTER';
    // `CoreToastStyle.minHeight` — the floor both widgets state
    // (`ConstrainedBox(minHeight:)` / `min-height`). Without it the panel
    // measured its one-line content and stopped short of the height a
    // toast carrying an action lands on.
    content.minHeight = dimVal(TOAST.fields.minHeight);
    content.setBoundVariable('minHeight', lk.spaceLadder(dimVal(TOAST.fields.minHeight)));
    bindPad(content, lk, pad); // logical CoreEdgeInsets.directional (start/end) — bindPad handles the RTL-aware dispatch
    // The leading glyph, on the variants that carry one. Its colour comes
    // from the variant row rather than this file — the message colour, the
    // same ink as the text; the shape is what carries the state.
    //
    // A holder frame with its own gap rather than the content frame's:
    // `contentActionGapStyle` spaces the content from the action, and the
    // glyph sits closer than that.
    const iconGlyph = kToastIcon[combo['Variant'] ?? ''];
    // Optional: only the two variants that draw a glyph state a colour for
    // it, so the row union does not carry the field at all on `neutral`.
    const iconColor = optField<Color>(v, 'iconColor');
    if (iconGlyph != null && iconColor != null) {
      content.itemSpacing = dimVal(TOAST.fields.iconContentGapStyle.size);
      content.setBoundVariable(
        'itemSpacing',
        lk.space(dimVal(TOAST.fields.iconContentGapStyle.size)),
      );
      const icon = makeIcon(
        iconGlyph,
        lk,
        glyphOpts(
          lk,
          colorData(iconColor),
          TOAST.fields.iconStyle.size,
          'size',
        ),
      );
      content.appendChild(icon);
      glyphNodes.push(icon);
    }
    const col = autoFrame('message', 'VERTICAL');
    col.setBoundVariable('itemSpacing', lk.space(dimVal(TOAST.fields.messageDescriptionGapStyle.size)));
    const msg = makeLabel(
      '저장했어요',
      lk,
      typographyColorOpts(lk, messageStyle, colorData(v.foregroundColor)),
    );
    col.appendChild(msg);
    messageNodes.push(msg);
    const desc = makeLabel('변경 사항을 저장했어요.', lk, textLabelOpts(lk, descStyle, colorData(v.descriptionForeground)));
    col.appendChild(desc);
    descriptionNodes.push(desc);
    content.appendChild(col);
    col.layoutSizingHorizontal = 'FILL';
    desc.layoutSizingHorizontal = 'FILL';
    // `description` is `String?` and the widget draws the second line only
    // when it is given one — the default toast is a single line. Hidden
    // BEFORE the panel measures itself below, so the resting height is the
    // one-line height; `Show description` (bound after `finish()`) is what
    // reveals it, and the column's gap follows the visibility for free.
    desc.visible = false;
    const action = standInSlotNodes(page, 'action', 'rectangular');
    action.instance.resize(kToastActionWidth, kToastActionHeight);
    content.appendChild(action.holder);
    actionSlots.push(action);
    // Same reason: `Show action` defaults to false, and a panel measured
    // with the action visible was 40px taller than the pose it opens on.
    action.holder.visible = false;
    // A real toast is sized by the overlay hosting it: `toast` states no width
    // field (its only width is `panelBorderWidth`), and `toast.dart` sets no
    // width or constraint either — the 340 the panel opens at is
    // g7-preview-only, and it lives on `c` (`lockWidth` above).
    //
    // `content` FILLs the panel (#4826). A consumer dropping the toast into a
    // 393pt phone frame and picking Fill container hands the instance that
    // width; `content` follows it, `message` and the description already FILL
    // inside `content`, and `close` is pinned to the far edge. Above 340 the
    // panel stops at `c.maxWidth`. This is the gap the auto-layout panel used
    // to name and leave — a FILL child needs a FIXED parent axis, which the
    // panel now has.
    c.appendChild(content);
    content.layoutSizingHorizontal = 'FILL';

    // Only the dismissible pose has one — the ✕ IS `onDismiss != null`, and the
    // inset above already changed with it.
    if (withDismiss) {
      // `toast.dart` composes the dismiss with `shape: .square` — the `md`
      // row's 40 × 40, made a circle by the slot's full corner (#6214).
      const close = closeButton(page, lk, {
        size: iconShapeGlyphSize(kToastCloseAxes.Size, TOAST.fields.closeButtonStyle),
        color: colorData(v.closeForeground)!,
        axes: kToastCloseAxes,
        style: TOAST.fields.closeButtonStyle,
      });
      // Pinned to the right edge (`horizontal: 'MAX'`) rather than placed at
      // a fixed x computed from the 340-wide build: with `content` now able
      // to shrink or grow, an x baked in at build time would drift away
      // from the dismiss glyph it is supposed to sit beside.
      //
      // Centred on the block axis (`vertical: 'CENTER'`) in the band the
      // block insets leave — both widgets pin top and bottom and centre the
      // button between them — so showing the description keeps the circle on
      // the panel's centre line instead of leaving it at the top.
      const bandTop = dimVal(inset.t);
      const band = c.height - bandTop - dimVal(inset.b);
      pinAbsolute(
        c,
        close,
        content.width - dimVal(inset.r) - close.width,
        bandTop + (band - close.height) / 2,
        { horizontal: 'MAX', vertical: 'CENTER' },
      );
    }
    // No explicit resize: `c` hugs its height, so it settles to `content`'s
    // (plus the pinned `close`, which does not count toward a hug) on its own
    // once the loop above is done touching it.
  }
  const set = mount.finish();
  // Same shape Banner uses (`display-data.ts`): one property per text
  // slot, bound across every variant. Figma has no per-variant property
  // default, so all three carry the neutral wording — that is the limit
  // being paid, not a claim that a destructive toast reads the same.
  const messageProp = defineProp(set, 'Message', 'TEXT', '저장했어요');
  for (const n of messageNodes) bindTextProp(n, messageProp);
  const descriptionProp = defineProp(
    set,
    'Description',
    'TEXT',
    '변경 사항을 저장했어요.',
  );
  const showDescriptionProp = defineProp(set, 'Show description', 'BOOLEAN', false);
  for (const n of descriptionNodes) {
    bindTextProp(n, descriptionProp);
    bindVisibleProp(n, showDescriptionProp);
  }
  // `showIcon` — the glyph and the gap after it, on or off together: both
  // widgets drop them in one `if (showIcon && …)` branch. The glyph is a direct
  // child of `content` and the row's `itemSpacing` is the gap that follows it,
  // and auto-layout skips a hidden child with its spacing — so hiding the glyph
  // node leaves no empty cell and no gap, and the text starts at the panel's
  // inset. (There is no wrapper frame around the glyph to hide instead, which
  // is the shape that kept its width when everything inside it went.) `neutral`
  // draws no glyph in code, so it has none to bind here either: the property is
  // a no-op on that member, as `showIcon` is in the widgets. Its default is the
  // contract's (`CoreToastContract.defaultShowIcon`), read from the export
  // rather than restated here.
  const showIconProp = defineProp(set, 'Show icon', 'BOOLEAN', TOAST.behaviour.showIcon);
  for (const n of glyphNodes) bindVisibleProp(n, showIconProp);
  const actionDefault = slotStandInDefault(page, 'rectangular');
  for (const a of actionSlots) {
    // `defineProp` reuses the id after the first variant — the property lives
    // on the SET, and every variant's node binds to that one id.
    bindOptionalSlot(
      a,
      defineProp(set, 'Action', 'INSTANCE_SWAP', actionDefault),
      defineProp(set, 'Show action', 'BOOLEAN', false),
    );
  }
  vStackSet(set);
  return set;
}

// ─── MenuItem ────────────────────────────────────────────────────────────────
//
// `Size(3) × State(5) × Tone(2)` = 30 — the row every menu surface places,
// drawn once so the five agree. Size is the row ladder (32 / 36 / 48),
// State the interaction poses, Tone the ordinary-vs-destructive foreground.
//
// The row is `menu_item.dart`, one to one:
//
// ```text
// row (HORIZONTAL · padding · contentGapStyle · borderRadius · minHeight)
//   ├─ state layer  // pinned full; the foreground washed at stateLayer's weight
//   ├─ mark         // Icon instance — `Show mark` (default OFF)
//   ├─ leading      // Icon instance — `Show leading` (default OFF)
//   ├─ text (VERTICAL · labelDescriptionGapStyle)
//   │    ├─ label        // labelStyle
//   │    └─ description  // `Show description` (default OFF) — descriptionStyle
//   ├─ shortcut     // `Show shortcut` — shortcutTextStyle; hidden by Has submenu
//   ├─ chevron      // Icon instance — `Has submenu` (default OFF)
//   └─ trailing     // Icon instance — `Show trailing` (default OFF)
// ```
//
// Why the wash is a pinned layer rather than a second fill: the row's own
// fill is `transparent` at rest and `primary` when selected, and a state
// layer has to stack over whichever of those is showing. Replacing the fill
// would make hover *erase* the selected pose instead of shading it.
//
// The alpha is a literal here. A layer's opacity binds to a percent FLOAT
// (`VarLookup.opacity`, `bindLayerOpacity`), but this wash binds no rung, so the
// `state-layer/*` aliases are authoring registry and the number is written from
// the ramp data — the same arrangement `line-height/control` has.
//
// Tone moves the foreground, and for the critical tone the active state: a
// neutral row is washed (its foreground over the resting fill), while a
// critical row's hover, focus and pressed poses are a solid `error-container`
// fill and no wash — a wash of the error ink over a transparent fill would be
// the error colour itself. The tone row states the fills
// (`hoverBackgroundColor`, `pressedBackgroundColor`) and may state an ink for
// them (`activeForegroundColor`); without one every ink keeps its resting
// colour. A tone that states no fill is washed.
const MENU_ITEM_NAME = 'MenuItem';

// A tone row's colour for a field only some tones state — the critical tone's
// active fill and ink. The exported row carries a key only when the tone states
// it, so the access is by name and a tone without it reads `null`.
function menuItemToneColor(row: object, key: string): NormalizedColor | null {
  return colorData(optField<Color>(row, key));
}
const kMenuItemSizes = ['sm', 'md', 'lg'] as const;
const kMenuItemStates = stateAxis(['enabled', 'hover', 'focus', 'pressed', 'disabled']);
const kMenuItemTones = ['neutral', 'critical'] as const;
type MenuItemSize = (typeof kMenuItemSizes)[number];
type MenuItemState = (typeof kMenuItemStates)[number];
type MenuItemTone = (typeof kMenuItemTones)[number];

function buildMenuItem(page: PageNode, lk: VarLookup): ComponentSetNode {
  const f = MENU_ITEM.fields;
  const names: string[] = [];
  const poses: { size: MenuItemSize; state: MenuItemState; tone: MenuItemTone }[] = [];
  for (const size of kMenuItemSizes) {
    for (const state of kMenuItemStates) {
      for (const tone of kMenuItemTones) {
        poses.push({ size: size, state: state, tone: tone });
        names.push(`Size=${size}, State=${state}, Tone=${tone}`);
      }
    }
  }
  // The three glyphs are drawn from their swap defaults, so the properties'
  // first binds leave them at their own sizes (see `IconOpts.fromVariant`). A
  // default this run cannot instance (a remote library node, a bare glyph)
  // falls back to `bindSwapProp`'s rescale after the bind lands.
  const markSwap = iconSwapDefault(page, MENU_ITEM_NAME, 'Mark', iconMainId(page));
  const leadingSwap = iconSwapDefault(page, MENU_ITEM_NAME, 'Leading', iconMainId(page));
  const trailingSwap = iconSwapDefault(page, MENU_ITEM_NAME, 'Trailing', iconMainId(page));
  const mount = mountSet(page, MENU_ITEM_NAME, names);

  const toneRows = new Map(Object.entries(MENU_ITEM.variants.defaultsByTone));
  const sizeRows = new Map(Object.entries(MENU_ITEM.sizes.defaultsBySize));
  const selectedForeground = colorData(f.selectedForegroundColor)!;
  const disabledForeground = colorData(f.disabledForegroundColor)!;

  const labelNodes: TextNode[] = [];
  const descriptionNodes: TextNode[] = [];
  const shortcutNodes: TextNode[] = [];
  const markSeatNodes: FrameNode[] = [];
  const markNodes: InstanceNode[] = [];
  const leadingNodes: InstanceNode[] = [];
  const trailingNodes: InstanceNode[] = [];
  const chevronNodes: InstanceNode[] = [];
  const rings: FocusRingNodes[] = [];

  for (let i = 0; i < poses.length; i++) {
    const pose = poses[i];
    const sz = sizeRows.get(pose.size);
    if (!sz) throw new Error(`MenuItem: \`menu_item.sizes.defaultsBySize\` has no \`${pose.size}\` row`);
    const toneRow = toneRows.get(pose.tone);
    if (!toneRow) throw new Error(`MenuItem: \`menu_item.variants.defaultsByTone\` has no \`${pose.tone}\` row`);
    const disabled = pose.state === 'disabled';
    // Disabled wins over tone: a row that cannot be activated says so
    // before it says what kind of action it would have been.
    const restForeground = disabled ? disabledForeground : colorData(toneRow.foregroundColor)!;
    // A tone that states an active fill replaces the wash in the three active
    // poses: the fill, and the ink chosen for it, come from the tone row.
    const activePose = pose.state === 'hover' || pose.state === 'focus' || pose.state === 'pressed';
    const activeFill = activePose
      ? menuItemToneColor(
          toneRow,
          pose.state === 'pressed' ? 'pressedBackgroundColor' : 'hoverBackgroundColor',
        ) ??
        (pose.state === 'pressed' ? menuItemToneColor(toneRow, 'hoverBackgroundColor') : null)
      : null;
    const activeInk = activeFill ? menuItemToneColor(toneRow, 'activeForegroundColor') : null;
    const fg = activeInk ?? restForeground;
    // A standalone row's corner is its size row's (sm 8 · md 8 · lg 12). A
    // row inside a panel is pinned by the host (`Menu.itemStyle` /
    // `Select.optionStyle`), which `buildMenu` binds onto its instances; the
    // set draws the row on its own.
    const radius = sz.borderRadius.topLeft;

    const c = mount.getOrCreate(names[i]);
    applyPanelCompChrome(c, 'HORIZONTAL', lk, {
      radius: radius,
      pl: sz.padding.l, pr: sz.padding.r, pt: sz.padding.t, pb: sz.padding.b,
      gap: sz.contentGapStyle.size,
    });
    // The resting fill — transparent, which is a statement rather than an
    // omission: the panel behind the row is the surface, and the wash
    // stacks over whatever is showing rather than replacing it.
    fillData(c, lk, activeFill ?? colorData(f.backgroundColor));
    c.counterAxisAlignItems = 'CENTER';
    c.clipsContent = true;
    // g7-preview-only: a row's width is its panel's; 240 is the menu floor.
    lockWidth(c, dimVal(MENU.fields.popupStyle.minWidth));
    c.minHeight = dimVal(sz.minHeight);
    // A height on the control ladder binds its density row, which a density
    // moves on both platforms; the 36 `md` row binds the primitive size and
    // stays put.
    const menuRow =
      lk.controlHeightOrNull(dimVal(sz.minHeight)) ?? lk.sizeOrNull(dimVal(sz.minHeight));
    if (menuRow) c.setBoundVariable('minHeight', menuRow);

    // The wash — the foreground at the ramp's weight for this pose, hidden
    // at rest and while disabled (an inert row that shaded under the
    // pointer would be promising something).
    const washWeight = activeFill
      ? null
      : pose.state === 'hover'
        ? f.stateLayer.hover
        : pose.state === 'focus'
          ? f.stateLayer.focus
          : pose.state === 'pressed'
            ? f.stateLayer.pressed
            : null;
    const wash = figma.createRectangle();
    wash.name = 'state layer';
    fillData(wash, lk, washWeight == null ? null : withAlpha(fg, washWeight));
    wash.visible = washWeight != null;
    bindRadiusN(wash, lk, radius);
    wash.resize(c.width, Math.max(c.minHeight ?? 0, 1));
    pinAbsolute(c, wash, 0, 0, { horizontal: 'STRETCH', vertical: 'STRETCH' });

    // Two properties, not one — and the split is the fix a real Select
    // panel forced (Select 코드 인계 통합본 2026-09-08 §6-4). `Show mark`
    // reserves the column: in a menu that can select, EVERY row turns it
    // on, so the labels keep one start line. `Marked` draws the glyph,
    // and only the chosen row turns that on. With a single boolean the
    // unchosen rows started their labels at the panel edge and the chosen
    // one started a check further in — Primer and Fluent both hide the
    // glyph with `visibility`, not `display`, for exactly this reason.
    const markSeat = autoFrame('mark', 'HORIZONTAL');
    markSeat.counterAxisAlignItems = 'CENTER';
    markSeat.primaryAxisAlignItems = 'CENTER';
    markSeat.visible = false;
    c.appendChild(markSeat);
    // Fixed to the glyph's own box, after the append — a child can only
    // be told it is FIXED once it has an auto-layout parent to be fixed
    // inside. This is the width that stays when `Marked` is off.
    markSeat.layoutSizingHorizontal = 'FIXED';
    markSeat.layoutSizingVertical = 'FIXED';
    bindSize(markSeat, lk, f.markIconStyle.size, f.markIconStyle.size);
    markSeatNodes.push(markSeat);
    const mark = makeIcon('check', lk, {
      ...iconOpts(lk, fg, f.markIconStyle.size),
      fromVariant: markSwap.variant,
    });
    mark.name = 'glyph';
    markSeat.appendChild(mark);
    markNodes.push(mark);

    const leading = makeIcon('file', lk, {
      ...iconOpts(lk, fg, sz.leadingIconStyle.size),
      fromVariant: leadingSwap.variant,
    });
    leading.name = 'leading';
    leading.visible = false;
    c.appendChild(leading);
    leadingNodes.push(leading);

    const text = autoFrame('text', 'VERTICAL');
    text.itemSpacing = dimVal(f.labelDescriptionGapStyle.size);
    c.appendChild(text);
    text.layoutSizingHorizontal = 'FILL';

    const label = makeLabel(
      '이름 바꾸기',
      lk,
      typographyColorOpts(lk, textStyleData(sz.labelStyle), fg),
    );
    label.name = 'label';
    text.appendChild(label);
    label.layoutSizingHorizontal = 'FILL';
    labelNodes.push(label);

    // The description and the shortcut keep the muted colour their size row
    // states — except while disabled or selected, where the row's own
    // foreground has to win or the second line stays grey on a filled row.
    const secondary = disabled
      ? disabledForeground
      : (activeInk ?? colorData(sz.descriptionStyle.color));
    const description = makeLabel(
      '표시 이름을 바꿔요',
      lk,
      typographyColorOpts(lk, textStyleData(sz.descriptionStyle), secondary),
    );
    description.name = 'description';
    description.visible = false;
    text.appendChild(description);
    description.layoutSizingHorizontal = 'FILL';
    descriptionNodes.push(description);

    const shortcut = makeLabel(
      'F2',
      lk,
      typographyColorOpts(
        lk,
        textStyleData(sz.shortcutTextStyle),
        disabled ? disabledForeground : (activeInk ?? colorData(sz.shortcutTextStyle.color)),
      ),
    );
    shortcut.name = 'shortcut';
    c.appendChild(shortcut);
    shortcutNodes.push(shortcut);

    // The chevron takes the shortcut's seat rather than sitting beside it —
    // a row that opens a submenu has no shortcut to show, and two promises
    // in one place is what the boolean below prevents.
    const chevron = makeIcon('chevron-right', lk, iconOpts(lk, fg, f.chevronIconStyle.size));
    chevron.name = 'chevron';
    chevron.visible = false;
    c.appendChild(chevron);
    chevronNodes.push(chevron);

    // Not the size row's `leadingIconStyle`: the widget sizes only the mark
    // and the leading seat (`IconTheme.merge` on Flutter, `IconTheme` on Web)
    // and adds `trailing` to the row as handed, on both platforms. So an
    // `Icon` passed there draws at the app root's ambient icon size on every
    // size row, where `lg`'s leading glyph is larger. The colour stays the
    // row's foreground — Web's `currentColor` inherits it from the row; Flutter
    // takes the app root's ambient colour instead, a difference that is the
    // widgets', not this builder's.
    const trailing = makeIcon('ellipsis', lk, {
      ...iconOpts(lk, fg, ICON.constants.ambientSize),
      fromVariant: trailingSwap.variant,
    });
    trailing.name = 'trailing';
    trailing.visible = false;
    c.appendChild(trailing);
    trailingNodes.push(trailing);

    // The ring is measured from the settled box, so it is built last.
    rings.push(
      focusRing(c, lk, {
        outline: f.clickableStyle.focusOutlineStyle,
        color: colorData(f.clickableStyle.focusOutlineStyle.borderColor),
        corner: radius,
        width: c.width,
        height: Math.max(c.minHeight ?? 0, 1),
        // A focused row wears its ring — the state says so, and a member
        // that named the state without drawing it would be the axis lying.
        visible: pose.state === 'focus',
      }),
    );

    // Sized again now the row has settled (#5609). `pinAbsolute` drops the
    // wash into the flow before it turns ABSOLUTE, so the row briefly hugs
    // wash + padding and STRETCH records that padding as the bottom offset —
    // the wash then came out at the row less its vertical padding (md 20/36).
    sizePin(wash, c.width, c.height);
  }

  const set = mount.finish();
  const labelProp = defineProp(set, 'Label', 'TEXT', '이름 바꾸기');
  for (const n of labelNodes) bindTextProp(n, labelProp);
  const showDescriptionProp = defineProp(set, 'Show description', 'BOOLEAN', false);
  const descriptionProp = defineProp(set, 'Description', 'TEXT', '표시 이름을 바꿔요');
  for (const n of descriptionNodes) {
    bindVisibleProp(n, showDescriptionProp);
    bindTextProp(n, descriptionProp);
  }
  const showShortcutProp = defineProp(set, 'Show shortcut', 'BOOLEAN', true);
  const shortcutProp = defineProp(set, 'Shortcut', 'TEXT', 'F2');
  for (const n of shortcutNodes) {
    bindVisibleProp(n, showShortcutProp);
    bindTextProp(n, shortcutProp);
  }
  // `Show mark` is the COLUMN and `Marked` is the GLYPH — see the split's
  // reason at the seat above. A menu row that never toggles leaves both
  // off; a selection menu turns the column on for every row and the glyph
  // on for one.
  const showMarkProp = defineProp(set, 'Show mark', 'BOOLEAN', false);
  for (const n of markSeatNodes) bindVisibleProp(n, showMarkProp);
  const markedProp = defineProp(set, 'Marked', 'BOOLEAN', true);
  const markProp = defineProp(set, 'Mark', 'INSTANCE_SWAP', markSwap.id);
  for (const n of markNodes) {
    bindVisibleProp(n, markedProp);
    bindSwapProp(n, markProp);
  }
  const showLeadingProp = defineProp(set, 'Show leading', 'BOOLEAN', false);
  const leadingProp = defineProp(set, 'Leading', 'INSTANCE_SWAP', leadingSwap.id);
  for (const n of leadingNodes) {
    bindVisibleProp(n, showLeadingProp);
    bindSwapProp(n, leadingProp);
  }
  const showTrailingProp = defineProp(set, 'Show trailing', 'BOOLEAN', false);
  const trailingProp = defineProp(set, 'Trailing', 'INSTANCE_SWAP', trailingSwap.id);
  for (const n of trailingNodes) {
    bindVisibleProp(n, showTrailingProp);
    bindSwapProp(n, trailingProp);
  }
  const hasSubmenuProp = defineProp(set, 'Has submenu', 'BOOLEAN', false);
  for (const n of chevronNodes) bindVisibleProp(n, hasSubmenuProp);
  const showFocusId = defineShowFocusRing(set);
  for (const ring of rings) {
    // NOT bound on the focus members: a bound `visible` has one source of
    // truth — the property — so binding here would hand every focus member
    // the default `false` and take the ring off the state that exists to
    // show it. On the other four it stays a pose behind the BOOLEAN.
    bindShowFocusRing(ring, showFocusId);
  }
  return set;
}


// ─── Menu ────────────────────────────────────────────────────────────────────

// Everything inside the panel is a composed child, because that is what the
// code composes: an action row is `Button(variant: .menu)` (→ `menuRow`) and
// the separator is a `Divider` (`MENU.fields.dividerStyle` is a nested
// `CoreDividerStyle` slot), so both are INSTANCES here. The one row that is
// not a row is `menu.dart#_buildLabelEntry` — a non-interactive section
// label — and it is the only consumer of MENU's own `labelTextStyle` (its
// insets come from the row ladder, `MENU_ITEM.sizes.defaultsBySize`).
//
// ── The panel is a `Popup` instance ──────────────────────────────────────────
//
// `menu.dart` says it outright — "The bordered, elevated floating box is the
// unified `Popup` — `Menu` composes it (no self-painted `Container` /
// `DecoratedBox`)" — and returns `Popup(popupStyle: resolved.popupStyle,
// children: entries)`. So the panel is not a box that resembles a Popup; it IS
// one, and it is the CONTAINER the rows live in.
//
// A Figma instance takes no children, so the instance goes BEHIND the rows:
// absolutely positioned, pinned to all four edges, with the root auto-layout
// frame carrying no chrome of its own. The rows keep flowing above it, and the
// surface follows `Popup` for good — which is the whole point, because the
// content-hash skip leaves a parent whose own recipe didn't change alone, so a
// redrawn copy paints last year's tokens with nothing to say so. The box this
// replaces was drawn at radius 12, a number that matched neither Popup's own 8
// nor the 16 Menu actually asks for.
//
// What the instance cannot carry is `resolved.popupStyle` itself — a
// per-instance patch on the child's Style, which a Figma instance cannot hold
// without repainting it (the same trade `buildHoverCard` makes with its
// forwarded `panelStyle`). So the surface shows Popup's own resting chrome, and
// the two fields of that patch that are the ROOT's own auto-layout properties
// rather than the instance's chrome — `padding` and `spacing` — are bound here
// from `MENU.fields.popupStyle`. They were literals (`4` / `2`) that happened
// to be right; now they are sourced, and they move when coui_core moves.
//
// One action row also carries its keyboard-shortcut hint — `item.shortcut`,
// which `_buildActionTrailing` renders as `Text(…, style: shortcutTextStyle)`
// inside the row's Button. See `appendShortcutRow` for why it rides above the
// instance, and for what its absence used to cost.
//
// `Icon` — Menu's two glyphs are the submenu chevron
// (`Icon(chevronRight, chevronIconStyle)`, passed as `Button.trailing`) and
// the checkbox / radio mark (`Icon(mark, markIconStyle)`, passed as
// `Button.leading`). Both live inside a composed Button, so both are drawn as
// real `Icon` instances over the row rather than as marks beside it — beside the
// row would put them outside the button they belong to. Both are drawn: the
// chevron on the submenu trigger, and the check inside the leading column of a
// `checkbox` entry (`appendToggleRow`, which is also `leadingColumnWidth`'s only
// subject). Whichever glyph a row carries, it is never chosen by reading the
// mark back off the canvas — that comparison is what silently turned every
// checkbox entry into a radio when a catalog changed.
//
// (The `.x =` inside `overlayGlyph` also makes `figma_composition_parity`
// credit this builder with `Stacks`. Menu composes no `Stacks` — the credit is
// an artifact of that heuristic, and `menu.dart` never names one.)
// The rungs `Menu(size:)` takes — `CoreMenuItemSize`, which lives with
// `MenuItem` rather than in Menu's own directory, so it is read from the row's
// data (the same way `CommandSearch` reads `Command`'s). The resting rung
// first: Figma hands a freshly placed instance the first member. Throws when
// the export stops stating the enum or the resting rung is not one of its
// members, so the `Size` axis cannot outlive what backs it.
function menuSizes(): readonly string[] {
  const axis = MENU_ITEM.axes.other.find((o) => o.enum === 'CoreMenuItemSize');
  if (!axis) {
    throw new Error(
      'Menu: CoreMenuItemSize is gone from the exported MenuItem axes — the canvas has a ' +
        'Size axis that nothing now backs. Restore the enum, or retire the axis ' +
        'deliberately (renames.ts) rather than letting this builder fold the rungs into one.',
    );
  }
  if (!axis.members.includes(kMenuRestingSize)) {
    throw new Error(
      `Menu: the resting size "${kMenuRestingSize}" is not a CoreMenuItemSize member ` +
        `(${axis.members.join(' | ')}). Update kMenuRestingSize to CoreMenuItemSize.defaultSize.`,
    );
  }
  return [kMenuRestingSize, ...axis.members.filter((m) => m !== kMenuRestingSize)];
}

function buildMenu(page: PageNode, lk: VarLookup): ComponentSetNode {
  const sizes = menuSizes();
  // The single component this set grew out of drew `md` rows, so it becomes
  // that member — its key, and every instance a consuming file holds (the
  // dropdown's, the context menu's, the menubar's) survive the promotion.
  const mount = mountSet(
    page,
    'Menu',
    sizes.map((size) => composeVariantName([['Size', size]])),
    { adoptLooseAs: composeVariantName([['Size', 'md']]) },
  );
  const box = MENU.fields.popupStyle.padding;
  for (const size of sizes) {
    const c = mount.getOrCreate(composeVariantName([['Size', size]]));
    applyPanelCompChrome(c, 'VERTICAL', lk, {
      pl: box.l, pr: box.r, pt: box.t, pb: box.b, gap: MENU.fields.popupStyle.spacing,
    });
    drawMenuMember(page, lk, c, size);
  }
  const set = mount.finish();
  vStackSet(set);
  return set;
}

// One `Size` member: the panel, the heading and the rows at that rung.
function drawMenuMember(page: PageNode, lk: VarLookup, c: ComponentNode, size: string): void {
  // The panel is content-driven between a floor and a ceiling now
  // (`popupStyle.minWidth` / `maxWidth`, 240–280): narrower than the floor a
  // menu reads as a tooltip, wider than the ceiling a label and its shortcut
  // stop scanning as one row. The preview sits at the floor.
  lockWidth(c, dimVal(MENU.fields.popupStyle.minWidth));
  // The panel surface, as the first (bottom-most) child so every row draws
  // over it. STRETCH on both axes is what keeps an absolutely-positioned child
  // tracking the frame as the rows change its size.
  // The panel states the list inset (`popupStyle.padding` = 6), so the surface
  // behind the rows is the `Padding=list` member.
  const surface = popupInstance(page, MENU.fields.popupStyle.padding);
  const surfacePin = pinAbsolute(c, surface, 0, 0, {
    horizontal: 'STRETCH',
    vertical: 'STRETCH',
  });
  hidePopupContent(surface);

  // The heading is the menu's own — a label, not a row — but it sits in the
  // same column as the rows under it, so it takes the row ladder's top and
  // side insets and seat gap rather than a set of its own. Its bottom is its
  // own (`labelBottomInset`): a heading belongs to the rows below it, so it
  // leaves them less room than a row does.
  const rowSize = MENU_ITEM.sizes.defaultsBySize[size as 'sm' | 'md' | 'lg'];
  const labelEntry = panel('label', 'HORIZONTAL', lk, {
    pl: rowSize.padding.l, pr: rowSize.padding.r,
    pt: rowSize.padding.t, pb: MENU.fields.labelBottomInset,
    gap: rowSize.contentGapStyle.size,
  });
  labelEntry.counterAxisAlignItems = 'CENTER';
  labelEntry.appendChild(
    makeLabel('계정', lk, textLabelOpts(lk, textStyleData(MENU.fields.labelTextStyle))),
  );
  c.appendChild(labelEntry);
  labelEntry.layoutSizingHorizontal = 'FILL';

  // The composed row's own ring geometry — what its `Clickable` draws around the
  // corner the panel hands it.
  const rowOutline = MENU_ITEM.fields.clickableStyle.focusOutlineStyle;

  // Every interactive row is a `MenuItem` instance — the row owns its fill,
  // wash, ring, typography and glyph tint, and the menu only says which of
  // its slots are filled. Only text and boolean properties — and the corner
  // the panel states — are written here: a nested instance's VARIANT
  // property propagates to the whole set, so the pose stays the set's
  // resting one and the poses live on `MenuItem` itself.
  const menuRowInstance = (
    label: string,
    o: { shortcut?: string; mark?: boolean; submenu?: boolean } = {},
  ): InstanceNode => {
    // The literal, not the constant: the composition-parity gate reads the
    // builder's source for `instanceOf(page, '<Child>')` and a name behind a
    // constant is a composition it cannot see.
    const row = instanceOf(
      page,
      'MenuItem',
      bestVariantName(page, 'MenuItem', { Size: size, State: 'enabled', Tone: 'neutral' }),
    );
    setInstanceTextNamed(row, 'Label', label);
    setInstanceBoolNamed(row, 'Show shortcut', o.shortcut != null);
    if (o.shortcut != null) setInstanceTextNamed(row, 'Shortcut', o.shortcut);
    setInstanceBoolNamed(row, 'Show mark', o.mark === true);
    setInstanceBoolNamed(row, 'Marked', o.mark === true);
    setInstanceBoolNamed(row, 'Has submenu', o.submenu === true);
    c.appendChild(row);
    row.layoutSizingHorizontal = 'FILL';
    // `menuItemStyle: style.itemStyle` — the panel states its rows' corner
    // in Core (Menu's designer copy, #5967), independently of the standalone
    // row's size ladder. The row instance arrives at that ladder's corner, so
    // the host's corner is pinned onto it — the box, its wash and its ring,
    // which `DropdownMenu` / `ContextMenu` / `Menubar` inherit by composing
    // this `Menu`.
    pinComposedCorner(row, lk, MENU.fields.itemStyle.borderRadius.topLeft, rowOutline);
    return row;
  };

  // Copy from the widget's own doc example, which is where the shortcut row,
  // the submenu pair and the checkbox all come from:
  // `action('Profile', shortcut: 'Ctrl+P')` · `action('Home', active: true)` ·
  // `action('More', submenu: ['Settings'])` · `checkbox('Show grid', checked: true)`.
  menuRowInstance('프로필', { shortcut: 'Ctrl+P' });
  menuRowInstance('홈');
  menuRowInstance('더보기', { submenu: true });
  // The inline nested submenu — indented one level, drawn flush inside the
  // parent panel. `submenuStyle.popupStyle` is box-less by default (no fill,
  // no border, no corner), so what marks it as nested is the indent, not a
  // second panel; a designer who wants a boxed one overrides that slot and
  // this frame picks the box up.
  const indent = panel('submenu-indent', 'VERTICAL', lk, {
    pl: MENU.fields.submenuIndent,
  });
  const sub = MENU.fields.submenuStyle.popupStyle;
  const nested = panel('submenu-items', 'VERTICAL', lk, { gap: sub.spacing });
  fillData(nested, lk, colorData(sub.backgroundColor));
  borderData(nested, lk, colorData(sub.borderColor), dimVal(sub.borderWidth));
  indent.appendChild(nested);
  c.appendChild(indent);
  indent.layoutSizingHorizontal = 'FILL';
  nested.layoutSizingHorizontal = 'FILL';
  const nestedRow = instanceOf(
    page,
    'MenuItem',
    bestVariantName(page, 'MenuItem', { Size: size, State: 'enabled', Tone: 'neutral' }),
  );
  setInstanceTextNamed(nestedRow, 'Label', '설정');
  setInstanceBoolNamed(nestedRow, 'Show shortcut', false);
  nested.appendChild(nestedRow);
  nestedRow.layoutSizingHorizontal = 'FILL';
  // The inline submenu is itself a `Menu` (`submenuStyle`), so its rows take
  // ITS item corner — the same 8, read from the slot that states it for them.
  pinComposedCorner(
    nestedRow,
    lk,
    MENU.fields.submenuStyle.itemStyle.borderRadius.topLeft,
    rowOutline,
  );
  menuRowInstance('격자 보기', { mark: true });
  // `Divider(dividerStyle: style.dividerStyle, semantic: true)` — the Menu hands
  // the rule a whole Style of its own, so it is forwarded rather than left to the
  // child's defaults. They agree on the colour today (both `outline-variant`),
  // which is why the canvas looked right while nothing pointed at Menu's field.
  //
  // The rule rides in a holder that keeps `dividerInset` above and below it
  // (`menu.dart#_buildDivider` wraps the `Divider` in that padding in a column
  // menu), so the group boundary reads as a pause rather than a hairline pressed
  // between two rows.
  const dividerHolder = panel('divider', 'VERTICAL', lk, {
    pt: MENU.fields.dividerInset, pb: MENU.fields.dividerInset,
  });
  c.appendChild(dividerHolder);
  dividerHolder.layoutSizingHorizontal = 'FILL';
  hostedDivider(page, lk, dividerHolder, {
    axes: kPlainDividerAxes,
    forwarded: {
      color: colorData(MENU.fields.dividerStyle.color),
      thickness: MENU.fields.dividerStyle.thickness,
      indent: MENU.fields.dividerStyle.indent,
      endIndent: MENU.fields.dividerStyle.endIndent,
    },
  });
  menuRowInstance('로그아웃');
  // Last, once the rows have settled the frame's size: an absolute child is
  // laid out from its own box, so the surface has to start at the size its
  // STRETCH constraints will then keep it at. The HOLDER's box, through
  // `sizePin` — sizing the instance left the holder, which is the node the
  // constraints live on, at the 162×50 it was minted at.
  sizePin(surfacePin, c.width, c.height);
}

// ─── DropdownMenu ────────────────────────────────────────────────────────────

// `dropdown_menu.dart#_buildPanel` returns `Menu(items: widget.items,
// menuStyle: resolved.menuStyle, onActivate: _handleClose)` and nothing else —
// its own doc says it "no longer hand-rolls a `Popup` + per-entry `Button` /
// `Separator`; `Menu` owns the whole item-row renderer". So the panel here is
// a `Menu` INSTANCE. The rows it shows are Menu's, which is the point: a
// dropdown's row chrome changing without the dropdown changing is exactly what
// the composition means, and the hand-drawn copy this replaces could not do
// that (the content-hash skip would leave it painting the old chrome).
//
// This also removes the panel-box literals that were never a data gap — the
// bg / border / radius / padding belong to Menu's own `Popup`, not to
// `CoreDropdownMenuStyle`, whose only fields are `menuOffset` and the
// `menuStyle` forward.
//
// `menuOffset` is not invisible here, and it is what the root's own `gap` is.
// `dropdown_menu.dart:155` spends it as `offset:
// _placement.toPopoverOffset(resolved.menuOffset)` — the distance between the
// trigger and the panel along the placement axis — and in this frame, whose two
// children are exactly that trigger and that panel, that distance IS the
// vertical gap between them. So the gap is bound from the field.
//
// The canvas moves: the literal that stood here said 8, and the data says 4.0
// (`CoreSpace.space4`). The gap closes by half, which is the point — the frame
// was showing a distance no dropdown ever renders.
//
// The trigger stays a hand-drawn placeholder: in code it is `widget.trigger`, a
// caller slot that `dropdown_menu.dart` wraps in `MouseRegion >
// TriggerTapDetector > Semantics` and draws no chrome around, and nothing in
// `CoreDropdownMenuStyle` describes it.
function buildDropdownMenu(page: PageNode, lk: VarLookup): ComponentNode {
  const c = mintPanelComp(page, 'DropdownMenu', 'VERTICAL', lk, {
    gap: DROPDOWN_MENU.fields.menuOffset,
  });
  // `dropdown_menu` states only `menuOffset` and the `menuStyle` forward — no
  // width anywhere — and the widget's width comes from the caller's trigger.
  // g7-preview-only: DropdownMenu preview demo width, no width field in the code.
  lockWidth(c, 220);
  // The stand-in for `widget.trigger`, a caller slot the widget wraps without
  // drawing any chrome around it, so every number below is invented.
  const trig = panel('trigger', 'HORIZONTAL', lk, {
    // g7-preview-only: placeholder trigger box for the `widget.trigger` caller slot.
    bg: 'surface-container', radius: 8, pl: 12, pr: 12, pt: 8, pb: 8, gap: 8,
  });
  trig.counterAxisAlignItems = 'CENTER';
  // g7-preview-only: invented caption inside that placeholder trigger — the text a caller supplies.
  const tl = makeLabel('옵션', lk, { size: 14, colorVar: lk.sem('on-surface') });
  trig.appendChild(tl);
  tl.layoutSizingHorizontal = 'FILL';
  // `dropdown_menu` has no icon field and `dropdown_menu.dart` renders no
  // chevron — this one exists so the placeholder reads as a dropdown. Not the
  // app root's ambient icon size: it stands in for no `Icon` handed to the
  // slot, only for one piece of the trigger a caller composes whole, sizes
  // included, as the caption beside it is.
  // g7-preview-only: invented chevron glyph on the placeholder trigger.
  trig.appendChild(makeIcon('chevron-down', lk, { size: 12, colorVar: lk.sem('on-surface-variant') }));
  c.appendChild(trig);
  trig.layoutSizingHorizontal = 'FILL';
  const menu = instanceOf(page, 'Menu', bestVariantName(page, 'Menu', { Size: kMenuRestingSize }));
  c.appendChild(menu);
  menu.layoutSizingHorizontal = 'FILL';
  return c;
}

// ─── ContextMenu ─────────────────────────────────────────────────────────────

// `context_menu.dart` renders `Menu(...)` as its resting chrome — the
// `menuStyle` forward — and `CoreContextMenuStyle` states no resting chrome of
// its own. So the component is one `Menu` INSTANCE: everything a designer sees
// here (panel box, rows, separator) belongs to Menu and follows it. The other
// fields of the style (`liftScale` … `retractScale`) are the look of the opt-in
// lift, a pose the widget draws only while a press is held, so no member of
// this set shows it and none is invented here.
//
// `child` is the right-click target — a required `W` the widget renders inline
// (`context_menu.dart` returns it wrapped in the gesture layer), so it is a
// real node here, and it was missing entirely. It defaults to the
// `OutlinedContainer` the widget's own example draws around "Right-click
// here", and the INSTANCE_SWAP is what makes that a default rather than a
// claim that a context menu wraps a bordered box.
//
// The root is placed, not flowed: the menu is an OVERLAY over the target, not
// a sibling below it, and stacking them in a column would state a layout the
// widget never produces. The anchor offset is where a right-click plausibly
// lands — preview geometry, applied through `.x` / `.y` only.
const kContextMenuAnchorX = 72;
const kContextMenuAnchorY = 32;

// `preview` is a `W?` the widget draws in a `Popup` of its own beside the open
// menu, by one rule in Core (`CoreContextMenuPreview.place`): above the menu,
// else below, else at its end, else at its start, `gap` from it. It is null
// unless a caller passes one, so the member draws none and `Show preview` is
// the designer's way to turn it on.
//
// Drawn the way `Fab` draws its card and `Menu` its panel: the `Popup` is an
// INSTANCE pinned behind the frame that holds the slot, because an instance
// takes no children and the preview lives INSIDE that panel. The frame is
// placed below the menu — the side the rule falls back to when there is no room
// above, which is the case here: the menu sits near the top of its member — and
// the member is not resized to hold it, so the default picture is the one the
// member always drew. A member too short for a shown preview clips it;
// resizing the instance is how a designer makes room.
//
// The gap is `CoreContextMenuContract.defaultPreviewGap`, the one number the
// widgets place the preview with, read from the export's `behaviour` and
// applied through `.y` only.
const kContextMenuPreviewGap = CONTEXT_MENU.behaviour.previewGap;

interface ContextMenuPreviewNodes {
  frame: FrameNode;
  slot: SlotNodes;
}

// The preview frame: the `Popup` surface behind the padding the panel states,
// and the slot's holder inside it.
function contextMenuPreview(page: PageNode, lk: VarLookup): ContextMenuPreviewNodes {
  const pad = POPUP.fields.padding;
  const frame = panel('preview panel', 'VERTICAL', lk, {
    pl: pad.l, pr: pad.r, pt: pad.t, pb: pad.b, gap: POPUP.fields.spacing,
  });
  // Unclipped, like the Menu set's own panel: the card's cast falls outside it.
  frame.clipsContent = false;
  // The floor the panel keeps under any preview (`minWidth`), as `Popup` draws it.
  frame.minWidth = dimVal(POPUP.fields.minWidth);
  frame.setBoundVariable('minWidth', lk.spaceLadder(dimVal(POPUP.fields.minWidth)));
  // `context_menu_preview.dart` composes `Popup(children: [child])` with no
  // style, so the preview surface is the default `content` member.
  const surface = popupInstance(page, pad);
  const surfacePin = pinAbsolute(frame, surface, 0, 0, {
    horizontal: 'STRETCH',
    vertical: 'STRETCH',
  });
  hidePopupContent(surface);
  const slot = standInSlotNodes(page, 'preview', 'rectangular');
  frame.appendChild(slot.holder);
  // Last, once the slot has settled the frame's size: an absolute child is
  // laid out from its own box (see `buildMenu` for the same line).
  sizePin(surfacePin, frame.width, frame.height);
  return { frame: frame, slot: slot };
}

// COMPONENTS.context_menu.variants/sizes are empty in the real schema doc, and
// its `fields` are the six lift numbers — the look of a pose no member of this
// set shows (see above). Every item value here comes from the composed `Menu`
// instance below (which is MENU-sourced through its own builder), so
// ContextMenu's own slug contributes nothing to the resting component
// (#3755 OQ-2 — whole component).
//
// #4036 (C4a) — static→variant-set promotion by ADOPTION. This is the one
// component in this batch whose only axis is `Enabled`: no Variant/Size/State
// is declared, so the enumeration is exactly `Enabled=true`/`Enabled=false`,
// and the loose COMPONENT is adopted as `Enabled=true` — the interactive look
// it drew. `Enabled=false` renders identically, and that is the honest
// rendering rather than a gap papered over: neither CoreContextMenuStyle (its
// fields are the lift's numbers) nor CoreMenuStyle (which supplies every item
// value here) declares a single disabled colour, so there is nothing to
// recolour without inventing one.
function buildContextMenu(page: PageNode, lk: VarLookup): ComponentSetNode {
  const combos = enumerateAxisCombos(axisSpecsOf(CONTEXT_MENU.axes));
  const mount = mountSet(page, 'ContextMenu', combos, { adoptLooseAs: 'Enabled=true' });
  const targets: SlotNodes[] = [];
  const previews: ContextMenuPreviewNodes[] = [];
  for (const comboName of combos) {
    const c = mount.getOrCreate(comboName);
    c.layoutMode = 'NONE';
    c.fills = [];
    const target = slotNodes('child', instanceOf(page, 'OutlinedContainer'));
    c.appendChild(target.holder);
    target.holder.x = 0;
    target.holder.y = 0;
    // The child is what the menu is attached to; it spans the member so a
    // designer's FILL widens the target, and the menu keeps its anchor (#4805).
    target.holder.constraints = { horizontal: 'STRETCH', vertical: 'STRETCH' };
    targets.push(target);
    const menu = instanceOf(page, 'Menu', bestVariantName(page, 'Menu', { Size: kMenuRestingSize }));
    c.appendChild(menu);
    menu.x = kContextMenuAnchorX;
    menu.y = kContextMenuAnchorY;
    c.resize(
      Math.max(target.holder.width, menu.x + menu.width),
      Math.max(target.holder.height, menu.y + menu.height),
    );
    // After the resize: the preview is not part of the member's extent.
    const preview = contextMenuPreview(page, lk);
    c.appendChild(preview.frame);
    preview.frame.x = menu.x;
    preview.frame.y = menu.y + menu.height + kContextMenuPreviewGap;
    previews.push(preview);
  }
  const set = mount.finish();
  // After `finish()`, not inside the loop: the property lives on the SET
  // (`addComponentProperty` on a member throws), and every member's holder
  // binds to that one id.
  const childDefault = mainId(page, 'OutlinedContainer');
  for (const target of targets) {
    bindSlot(target, defineProp(set, 'Child', 'INSTANCE_SWAP', childDefault));
  }
  const previewSwap = defineProp(set, 'Preview', 'INSTANCE_SWAP', slotStandInDefault(page, 'rectangular'));
  const showPreview = defineProp(set, 'Show preview', 'BOOLEAN', false);
  for (const preview of previews) {
    bindSlot(preview.slot, previewSwap);
    preview.frame.visible = false;
    bindVisibleProp(preview.frame, showPreview);
  }
  vStackSet(set);
  return set;
}

// ─── Registry ────────────────────────────────────────────────────────────────

// `needs` names every REGISTRY component these builders instantiate, so
// `topoSortRegistry` builds the child first. Most of these edges cross a
// section boundary — the menu family's rows are `Button` (Form) instances,
// Menu's separator is a `Divider` (Layout), Popover's panel is a `Popup`
// (Display), HoverCard's surface is a `Card` (Display) — which is exactly the
// constraint section order cannot express.
//
// The intra-section edges (`ContextMenu`/`DropdownMenu` → `Menu`,
// `Swiper` → `Drawer`) still have to be declared: `needs` is what orders the
// build, not position, and two of these three parents are registered BEFORE
// the child they instantiate.
// The slot stand-in joins most of them for the same reason: a caller slot is
// drawn as it, and an INSTANCE_SWAP's default is its main component — so the
// set has to exist before the parent runs.
export const OVERLAY_BUILDERS: RegistryEntry[] = [
  { section: 'Overlay', name: 'Dialog', build: buildDialog, needs: ['Button', kSlotStandInComponent] },
  {
    section: 'Overlay',
    name: 'Drawer',
    build: buildDrawer,
    needs: ['Button', 'Divider', 'Icon', kSlotStandInComponent],
  },
  { section: 'Layout', name: 'BottomSheet', build: buildBottomSheet, needs: ['BottomActionBar', 'Button', 'Divider', 'Icon', kSlotStandInComponent] },
  { section: 'Overlay', name: 'Popover', build: buildPopover, needs: ['Button', 'Popup', kPopoverExample] },
  { section: 'Overlay', name: 'Toast', build: buildToast, needs: ['Button', 'Icon', kSlotStandInComponent] },
  { section: 'Overlay', name: 'MenuItem', build: buildMenuItem, needs: ['Icon'] },
  {
    section: 'Overlay',
    name: 'Menu',
    // No `Icon`: the chevron and the mark moved into `MenuItem`, which
    // draws them — the menu now instantiates rows, not glyphs.
    build: buildMenu,
    needs: ['Divider', 'MenuItem', 'Popup'],
  },
  { section: 'Overlay', name: 'DropdownMenu', build: buildDropdownMenu, needs: ['Icon', 'Menu'] },
  {
    section: 'Overlay',
    name: 'ContextMenu',
    build: buildContextMenu,
    needs: ['Menu', 'OutlinedContainer', 'Popup', kSlotStandInComponent],
  },
];
