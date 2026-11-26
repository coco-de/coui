/// <reference types="@figma/plugin-typings" />

import { kCanvasOnlyApiNotes } from '../canvas-only-notes';
import {
  ColorData,
  RegistryEntry,
  VarLookup,
  addControlShadow,
  applyPanelCompChrome,
  applySurfaceMaterial,
  autoFrame,
  bestVariantName,
  bindLayerOpacity,
  paintsFill,
  bindPad,
  bindRadiusN,
  bindSize,
  bindSwapProp,
  bindTextProp,
  bindVisibleProp,
  borderData,
  defaultSetLayout,
  defineProp,
  fillData,
  focusOutlineRingColor,
  focusRing,
  glyphOpts,
  glyphPaint,
  iconMainId,
  iconMainIdAt,
  iconSwapDefault,
  instanceOf,
  lockWidth,
  makeIcon,
  makeLabel,
  PadData,
  mountSet,
  panel,
  pinInFlow,
  propertyOwner,
  rowSet,
  setShadow,
  setInstanceTextNamed,
  setSlotIcon,
  sizePin,
  textLabelOpts,
  typographyColorOpts,
  vStackSet,
  composeCountBadge,
  hostedDivider,
  applyInstanceTextStyle,
  ownTextNodes,
  applyForwardedPanelStyle,
  applyForwardedButtonStyle,
  exposeAll,
  kSlotStandInComponent,
  pinAbsolute,
  slotStandIn,
  slotStandInDefault,
  setInstanceSwapNamed,
} from '../helpers';
import { popupInstance, popupPaddingOverride } from '../popup-composition';
import { exampleMainId, kNavigationMenuExample } from '../default-examples';
import { bindShowFocusRing, defineShowFocusRing, stateAxis } from '../state-axis';
import type { FocusRingNodes, IconOpts } from '../helpers';
import {
  Color,
  Dim,
  TextLeaf,
  colorData,
  dimVal,
  mergeTextStyleData,
  optField,
  textStyleData,
} from '../compat/v1';
import { COMPONENTS } from '../data';
import {
  AxisSpec,
  ComponentAxesJson,
  axisSpecsOf,
  composeVariantName,
  enumerateAxisAssignments,
  enumerateAxisCombos,
} from '../axis-combos';
import { parseVariantKey } from '../variant-safety';
import { kBadgeDefaultTone } from '../instance-reach';
import { boundOrNull } from '../layout-bound';
import { repointSurfaceMaterial } from '../surface-material';
import { queueTextStyleAttach } from '../text-nodes';
import { linkShadowStyle } from '../shadow-style';
import { kMenuRestingSize } from '../overlay-composition';

const BREADCRUMB = COMPONENTS.breadcrumb;
const PAGINATION = COMPONENTS.pagination;
const TABS = COMPONENTS.tabs;
const STEPS = COMPONENTS.steps;
const STEP_ITEM = COMPONENTS.step_item;
const LINK = COMPONENTS.link;
const MENUBAR = COMPONENTS.menubar;
const NAVIGATION_BAR = COMPONENTS.navigation_bar;
const NAVIGATION_MENU = COMPONENTS.navigation_menu;
// A trigger's label → chevron gap is `triggerButtonStyle.iconLabelGapStyle` —
// the slot states it (4), and a stated gap wins over the `Button` size row's.
// The Button's own inner inset is spent on the trigger frame instead, so the
// instance is held at no inset of its own.
const NAVIGATION_MENU_BUTTON_NO_INSET = { l: 0, t: 0, r: 0, b: 0 };
const DOCK = COMPONENTS.dock;

// ─── Boolean state axes ──────────────────────────────────────────────────────
//
// A CoUI component's interaction states are not mutually exclusive — a control
// can be hovered AND focused, or focused AND disabled, and each combination has
// its own resolved chrome. So each state gets its OWN boolean axis in the Figma
// variant name (`Variant=x, Size=md, Disabled=true`) rather than all of them
// collapsing into one `State=` enum: a single enum can only ever express one
// state at a time, which makes every combination unrepresentable and forces a
// designer to pick the one the enum happens to name.
//
// An axis is added only where the component's OWN Core fields carry chrome that
// actually differs between the two sides. Two rules follow from that, and both
// removed axes from this file rather than adding them:
//
//   · A state whose only difference is a value that renders identically is
//     noise — `pressedScale: 1` (Breadcrumb / Link) scales by nothing, so a
//     `Pressed` axis would be two identical pictures a designer has to click
//     through. (`pressedScale: 0.97` elsewhere is a transform, not chrome:
//     re-scaling a component in Figma overwrites the very width/height/
//     font-size bindings this plugin exists to install, so it is not
//     expressible as a variant either — recorded, not silently dropped.)
//   · A state that belongs to a CHILD component is that child's axis. Menubar
//     reaches every state it has through `triggerButtonStyle` — a nested
//     `CoreButtonStyle`, and `MENUBAR.fields` carries no state colour of its
//     own — so those states live on `Button`, and painting them here would be a
//     second source for chrome the child already owns
//     (`core/style-contract.md`, "합성 = 재구현 금지").
//
//     The test is per FIELD, not per component, and reading it per component
//     cost NavigationMenu its Hover pose: its focus chrome is indeed the
//     child's, but `triggerHoverColor` is a FLAT field of its own that the Web
//     resolver spends on the trigger's own box, so the hover half is this
//     component's axis and only the focus half is Button's.
type StateAxis = 'Hover' | 'Disabled' | 'Focus';

interface StateFlags {
  Hover: boolean;
  Disabled: boolean;
  Focus: boolean;
}

// Every on/off combination of `axes`, in a deterministic order — `mountSet`'s
// identity is the variant NAME string, so two runs that enumerate in different
// orders would still agree, but a stable order keeps the generated page's
// reading order stable too.
//
// Explicit field copy rather than object spread: the Figma plugin runtime
// rejects `...` (see helpers.ts's header).
function stateCombos(axes: readonly StateAxis[]): StateFlags[] {
  let out: StateFlags[] = [{ Hover: false, Disabled: false, Focus: false }];
  for (const axis of axes) {
    const next: StateFlags[] = [];
    for (const flags of out) {
      for (const on of [false, true]) {
        const copy: StateFlags = {
          Hover: flags.Hover,
          Disabled: flags.Disabled,
          Focus: flags.Focus,
        };
        copy[axis] = on;
        next.push(copy);
      }
    }
    out = next;
  }
  return out;
}

// `Hover=false, Disabled=true` — the state segments of one variant name.
function stateSuffix(axes: readonly StateAxis[], flags: StateFlags): string {
  const parts: string[] = [];
  for (const axis of axes) parts.push(`${axis}=${flags[axis] ? 'true' : 'false'}`);
  return parts.join(', ');
}

// Joins a component's semantic prefix (`Variant=pill, Size=md`) to its state
// segments. Either side may be empty — a component with no variant/size axis
// carries only state segments, and vice versa.
function variantName(prefix: string, suffix: string): string {
  if (!prefix) return suffix;
  if (!suffix) return prefix;
  return `${prefix}, ${suffix}`;
}

// One member of a pose-bearing set: the four-axis enumeration crossed with the
// pose combos.
//
// The prefix is NOT spelled here. It comes from `enumerateAxisCombos(
// axisSpecsOf(component.axes))` — the same function the axis-coverage check uses
// as its denominator, which re-composes a member's four-axis part back out of
// `variantProperties` and compares it against that enumeration. A prefix this
// file wrote by hand (or omitted) would therefore read as a coverage GAP even
// when the picture is right, which is the drift-by-arithmetic that sharing one
// enumerator exists to make unrepresentable.
//
// The poses come after it, which is where `kAxisOrder` puts them: a component
// has a variant and a size whatever else is true of it, while a pose qualifies
// that variant. The coverage check ignores axes outside the four, so a pose
// neither adds nor removes coverage — it multiplies the members within one
// combination.
interface PoseMember {
  /** The whole name — `Variant=standard, Hover=false, Disabled=false`. */
  name: string;
  /** The four-axis part alone, for a builder that must look up variant data. */
  prefix: string;
  /**
   * The four-axis part's VALUES (`Enabled` → `'false'`), for a builder that
   * reads one of them off a member rather than parsing `prefix`.
   */
  axisValues: Readonly<Record<string, string>>;
  flags: StateFlags;
}

function poseMembers(
  axesJson: ComponentAxesJson,
  poses: readonly StateAxis[],
  // Design axes a builder declares beyond the four — `Mode` for the
  // navigation bar. They join the PREFIX, not the pose suffix: a shape is
  // something the component has before any pointer touches it, and
  // `composeVariantName` spells them in `kAxisOrder` so the name is the same
  // whichever builder composes it.
  designAxes: readonly AxisSpec[] = [],
): PoseMember[] {
  const out: PoseMember[] = [];
  const combos = stateCombos(poses);
  for (const assignment of enumerateAxisAssignments([
    ...axisSpecsOf(axesJson),
    ...designAxes,
  ])) {
    const prefix = assignment.name;
    for (const flags of combos) {
      out.push({
        name: variantName(prefix, stateSuffix(poses, flags)),
        prefix,
        axisValues: assignment.values,
        flags,
      });
    }
  }
  return out;
}

// ─── Focus ring ──────────────────────────────────────────────────────────────

// The Focus axis's ring on a component whose item is a `Clickable`.
//
// Every destination, cell and tile in this file is a `Clickable` in the
// widget, and `Clickable` builds its ring as `FocusOutline(focusOutlineStyle:
// resolved.focusOutlineStyle)` around its child. That outline is two layers:
// the `offsetColor` band filling the `align - borderWidth` gap, and the ring
// at `-align`. A stroke on the box has no offset, so it could draw neither the
// gap nor the band — the shared `focusRing` draws the pair, and this is the one
// place the three inputs it needs are read from a `clickableStyle`:
//
//   · the colour is `borderColor.scaleAlpha(ringOpacity)` —
//     `focusOutlineRingColor`, because an alpha does not travel with a
//     Variable binding;
//   · the corner is `clickableStyle.borderRadius`, which is what
//     `clickable_style.dart` hands the outline when `focusOutlineStyle`
//     states no radius of its own (`merged.focusOutlineStyle?.borderRadius ??
//     borderRadiusCore`), and none of these slots does;
//   · the size is the host's own, so the caller runs this LAST, after
//     whatever settles the host's box — both layers pin STRETCH×STRETCH to it
//     and would otherwise be measured from a box that is not there yet.
function clickableFocusRing(
  host: FrameNode | ComponentNode,
  lk: VarLookup,
  clickable: {
    borderRadius: { topLeft: Dim };
    focusOutlineStyle: {
      align: Dim;
      borderWidth: Dim;
      ringOpacity: Dim;
      borderColor: Color;
      // The band — transparent unless the slot states an opaque one.
      offsetColor: Color;
    };
  },
): void {
  focusRing(host, lk, {
    outline: clickable.focusOutlineStyle,
    color: focusOutlineRingColor(clickable.focusOutlineStyle),
    corner: clickable.borderRadius.topLeft,
    width: host.width,
    height: host.height,
    visible: true,
  });
}

// ─── Stated corners ──────────────────────────────────────────────────────────

// A corner radius the data states, bound to its token when it HAS one and
// written as a plain number when it does not.
//
// `bindRadiusN` always binds, which is right for every value that traces to a
// `CoreRadius` step and wrong for the two that do not. `Dock`'s and
// `NavigationBar`'s `barRadius` both default to `CoreBorderRadius.zero`, and
// that constant is `CoreBorderRadius.all(0)` — a bare literal, so the export
// carries `ref: null` for all four corners. `Primitives/radius/0` does exist,
// so binding it would succeed and would then tell a designer inspecting the
// node that the design system named this corner, which it did not. That is the
// failure `bindAxisSize` was split out of `bindSize` to stop: a binding is a
// provenance claim, and a claim nobody made is worse than a bare number.
//
// So the picture is the same either way today (a square corner is Figma's own
// default) and the READ is what changes: the field is consulted instead of a
// literal 16 sitting where it should be, and the day Core states
// `CoreRadius.radius16` here the canvas rounds and binds without another edit.
function statedRadius(
  node: FrameNode | ComponentNode,
  lk: VarLookup,
  corner: Dim,
): void {
  if (corner.ref != null) {
    bindRadiusN(node, lk, corner);
    return;
  }
  node.cornerRadius = dimVal(corner);
}

// The corner `statedRadius` bound, in the shape `applySurfaceMaterial` takes for
// its layers: the stated step, or null — the layers then copy the literal corner
// the node already carries.
function statedCorner(corner: Dim): Dim | null {
  return corner.ref != null ? corner : null;
}

// ─── Composed instances ──────────────────────────────────────────────────────

// Puts this use site's copy into a composed child instance.
//
// Two paths, in the order Figma prefers them.
//
// `setProperties` is the supported way to drive a TEXT component property, and
// it is the path both children here take: `Button` binds its label node to a
// `Child` TEXT property and `Tooltip` binds its bubble text to a `TooltipChild`
// one. A node bound to a property is driven by that property — a direct
// `characters` write on it is rejected, so the copy would never arrive and the
// instance would keep showing the property's own default.
//
// The key is READ OFF the instance, never spelled here: the property id belongs
// to the child's builder, which is free to rename or re-suffix it, and this file
// owns neither. Discovery is by `type === 'TEXT'`, not by name — `Tooltip`
// declares BOTH a `TooltipChild` TEXT and a `Child` INSTANCE_SWAP, so matching
// on the word would drive the wrong slot.
//
// The `setProperties` call is deliberately NOT wrapped: the key came from the
// instance's own `componentProperties`, so a throw means the child's property
// table changed shape underneath this call, and one loudly failing entry with a
// name on it beats a component that looks finished and shows demo copy.
//
// The fallback is for a child that declares no TEXT property at all — then the
// first TEXT descendant's `characters` is written, the same override a
// designer's double-click produces. Its catch covers the remaining case, a node
// bound to a property the instance does not surface: losing one line of demo
// copy is the right trade against losing the whole component to a throw, since
// the bound property's own default already reads as placeholder copy.
function setInstanceLabel(instance: InstanceNode, text: string): void {
  const props: ComponentProperties | undefined = instance.componentProperties;
  if (props && typeof instance.setProperties === 'function') {
    for (const key of Object.keys(props)) {
      if (props[key].type !== 'TEXT') continue;
      const patch: { [key: string]: string } = {};
      patch[key] = text;
      instance.setProperties(patch);
      return;
    }
  }
  for (const node of instance.findAll((n) => n.type === 'TEXT')) {
    if (node.type !== 'TEXT') continue;
    try {
      node.characters = text;
    } catch {
      // Bound to a property this instance does not surface — the designer sets
      // it on the instance.
    }
    return;
  }
}

// The text nodes an instance's own `Label` TEXT property writes — found by the
// property they are bound to, so text that belongs to a nested instance (a
// count badge's digits, bound to the badge's own property) is never taken for
// the caption.
export function instanceLabelNodes(instance: InstanceNode): TextNode[] {
  const props: ComponentProperties | undefined = instance.componentProperties;
  if (!props) return [];
  const key = Object.keys(props).find(
    (k) => props[k].type === 'TEXT' && k.split('#')[0] === 'Label',
  );
  if (key == null) return [];
  return instance.findAll((n) => {
    if (n.type !== 'TEXT') return false;
    const refs = n.componentPropertyReferences as Record<string, string> | null | undefined;
    return refs?.characters === key;
  }) as TextNode[];
}

// A `Button` instance for a composed trigger.
//
// The variant IS named — `Button(variant: .menubar)` is what both `Menubar` and
// `NavigationMenu` pass, so it is a decision the code makes and not a starting
// pick for a designer to correct.
//
// It used to be omitted, on the reasoning that naming a variant would break this
// builder the moment `Button`'s axis list grew (`instanceOf` matches the full
// variant name exactly, and a miss throws). The concern was real and the
// conclusion was not: `bestVariantName` exists for exactly that, matching on the
// axes you name and ignoring the ones you do not. Omitting the name does not
// leave the choice open either — `instanceOf` with no name returns whichever
// variant sorts FIRST, so File / Edit / View arrived as `primary` buttons: three
// filled pills across a menu bar the app draws flat. That is the report
// ("Ghost 버튼으로 되어야 하는거 아닌가" — the answer is `menubar`, which is the
// variant that exists for this and sits between the two).
function composedButton(
  page: PageNode,
  lk: VarLookup,
  label: string,
  labelStyle: ReturnType<typeof textStyleData>,
  /**
   * The `buttonStyle:` the parent hands this trigger, for a parent whose trigger
   * IS the chrome. `NavigationMenu` passes only the corner — it wraps its trigger
   * in a frame carrying its own `triggerPadding` / `triggerBorderRadius`, so the
   * inset is that frame's and applying it here too would spend it twice.
   */
  forward?: { padding?: PadData | null; borderRadius?: { topLeft: number | Dim } | null },
  /**
   * Whether this trigger's menu is the open one. The widget forces
   * `WidgetState.selected` onto it, and `Button`'s own `State=selected` member
   * is that state's drawing — so the open trigger is asked for as Button's
   * state rather than painted here, and a fill drawn here would not follow
   * `Button`'s `menubar` variant row.
   */
  selected: boolean = false,
): InstanceNode {
  // Explicit field copy rather than object spread — the plugin runtime rejects
  // `...` (see helpers.ts's header).
  const prefs: Record<string, string> = { Variant: kMenuTriggerButtonVariant };
  if (selected) prefs['State'] = 'selected';
  const instance = instanceOf(page, 'Button', bestVariantName(page, 'Button', prefs));
  setInstanceLabel(instance, label);
  // The trigger's own typography, forwarded. Both parents state it
  // (`Menubar.labelTextStyle` — `labelLarge` at weight 400, 500 on the open
  // trigger; `NavigationMenu.triggerTextStyle` — `labelLarge` at weight 500), and
  // the instance was rendering at `Button`'s own row size and weight instead, so
  // the bar's words were a different size from the app's.
  applyInstanceTextStyle(instance, lk, labelStyle);
  if (forward != null) applyForwardedButtonStyle(instance, lk, forward);
  return instance;
}

// `Button(variant: .menubar)` — `menubar.dart` and `navigation_menu.dart` both
// pass it, and `Button`'s own variant table carries the row.
const kMenuTriggerButtonVariant = 'menubar';

// A `Divider` instance for a composed rule — Steps' connector between two
// indicator circles, NavigationBar's separator between destination groups.
// Both widgets compose the unified `Divider` (`steps.dart`'s
// `Expanded(child: Divider(orientation: …, dividerStyle: …))`,
// `_NavigationDividerLine`'s `Divider(orientation: …, dividerStyle: …)`), so
// neither is a rectangle that resembles one.
//
// The colour and thickness ARE repainted here because each parent resolves a
// `CoreDividerStyle` of its own and forwards it into that slot
// (`ResolvedSteps.active/inactiveConnectorStyle` from
// `activeIndicatorColor`/`indicatorColor` + `connectorThickness`,
// `ResolvedNavigationBar.dividerStyle` from `dividerColor` +
// `dividerThickness`). Every other Divider field stays whatever the child's
// own resolver decided — the parent does not reach into those.
//
// Only the thickness is a design value, so it is the one axis `hostedDivider`
// binds (to its `Primitives/stroke` step). The rule's rendered length is this
// static preview's layout choice, and binding it too would make the canvas
// assert a `Primitives/space/N` source the design system never named.
function composedDivider(
  page: PageNode,
  lk: VarLookup,
  o: {
    horizontal: boolean;
    length: number;
    thickness: number | Dim;
    color: ColorData | null;
  },
): InstanceNode {
  // Through `hostedDivider`'s sized mode — the Divider main component hugs a
  // fixed-length preview line, and resizing a layer inside an instance is an
  // ordinary override (a structure change upstream leaves the line at its own
  // length instead of throwing). Delegated rather than open-coded because a
  // second local way to instance a `Divider` is how three call sites ended up
  // stretching the instance and leaving the line at its build length.
  return hostedDivider(page, lk, null, {
    vertical: !o.horizontal,
    color: o.color,
    size: { length: o.length, thickness: o.thickness },
  });
}

// ─── Breadcrumb ──────────────────────────────────────────────────────────────

// Data-driven from coui_core BREADCRUMB.fields (itemColor / itemHoverColor /
// currentItemColor / disabledColor / itemTextStyle / currentItemTextStyle /
// itemPadding / separatorIconStyle / itemSeparatorGapStyle / clickableStyle).
// The separator glyph's size traces to CoreIconSize (`via`), not CoreFontSize —
// glyphOpts(..., 'size') binds the correct scale (#3754 axis fix).
//
// #4036 (C4a) — the semantic prefix comes from `breadcrumb.axes`, not from a
// name this builder spells: one Variant member (`standard`) and no
// Size/State/Enabled, so the four-axis enumeration is one combination and every
// member below reads `Variant=standard, <pose>`. The pose axes are appended
// after it, which is where `kAxisOrder` puts them (a pose qualifies a variant).
// `defaultsByVariant` is empty for this component: `standard` names the only
// look CoreBreadcrumbStyle declares, and every value below still comes from the
// flat `fields`.
//
// static→variant-set promotion is by ADOPTION: the loose COMPONENT this builder
// used to mint is renamed to the RESTING pose of that one combination — the one
// thing it actually rendered — so its node id/key (and every instance of it)
// survives the promotion instead of being rebuilt.
//
// State axes: Hover (itemHoverColor — on-surface, a real step up from
// itemColor's on-surface-variant), Enabled (the contract's own axis — `false`
// draws `disabledColor` on every label and on the separator, the widget's
// `enabled: false`), Focus
// (clickableStyle.focusOutlineStyle.borderColor). Hover and focus land on the
// FIRST item: a breadcrumb renders several items and only one is pointed at or
// focused at a time, so a per-item state is shown on one item exactly as the
// current-item state already is.
//
// Disabled is a colour, not a dim. The widget's disabled trail is not wrapped
// in a `Clickable` at all (no link, so no `disabledOpacity` to apply) — it draws
// `disabledColor` on the labels and the chevrons, and so does this canvas. The
// Focus ring is drawn on the first item of an ENABLED `Focus=true` member only.
// The pose matrix still enumerates `Enabled=false, Focus=true` — the member
// exists and draws what `Enabled=false` draws — but a disabled trail is not a
// `Clickable` and takes no focus, so there is nowhere for a ring to stand and
// the member carries no pair (the designer's copy has both layers hidden, which
// shows the same picture). The designer drew this axis as `Disabled=<bool>`;
// the contract's `enabled` promotes it to `Enabled=<bool>` with the value
// flipped, and `renames.ts` carries the eight rows that keep every member's key.
//
// Each item is wrapped in a frame carrying `itemPadding` and
// `clickableStyle.borderRadius` — the real item is a Clickable around a padded
// label, and the focus ring wraps the padded box (a bare text node has none).
//
// The current item is one role heavier than the links: `itemTextStyle` is the
// links' role (bodyMedium, Regular) and `currentItemTextStyle` the current
// item's (labelLarge, Medium), each with its own colour (`itemColor` /
// `currentItemColor`).
function buildBreadcrumb(page: PageNode, lk: VarLookup): ComponentSetNode {
  const f = BREADCRUMB.fields;
  const clickable = f.clickableStyle;
  // `Disabled` is not a pose here: the contract states `enabled`, so the schema
  // promotes the `Enabled` axis and it rides the member's prefix.
  const axes: StateAxis[] = ['Hover', 'Focus'];
  const members = poseMembers(BREADCRUMB.axes, axes);
  const mount = mountSet(
    page,
    'Breadcrumb',
    members.map((m) => m.name),
    // What the legacy static node actually rendered: the one combination
    // `breadcrumb.axes` enumerates, at rest.
    { adoptLooseAs: 'Variant=standard, Enabled=true, Hover=false, Focus=false' },
  );
  const itemText = textStyleData(f.itemTextStyle);
  const currentItemText = textStyleData(f.currentItemTextStyle);
  const items: { label: string; current: boolean }[] = [
    { label: '홈', current: false },
    { label: '라이브러리', current: false },
    { label: '데이터', current: true },
  ];
  for (const member of members) {
    const flags = member.flags;
    const disabled = member.axisValues['Enabled'] === 'false';
    const c = mount.getOrCreate(member.name);
    applyPanelCompChrome(c, 'HORIZONTAL', lk, { gap: f.itemSeparatorGapStyle.size });
    c.counterAxisAlignItems = 'CENTER';
    for (let i = 0; i < items.length; i++) {
      const it = items[i];
      // The one item a pointer/focus is on — see the state-axis note above.
      const interactive = i === 0;
      let color: ColorData | null;
      if (disabled) color = colorData(f.disabledColor);
      else if (it.current) color = colorData(f.currentItemColor);
      else if (interactive && flags.Hover) color = colorData(f.itemHoverColor);
      else color = colorData(f.itemColor);
      // Each item is a `Clickable` in the widget. A Figma instance cannot host
      // the child it wraps and `Clickable` exists only to wrap one, so there is
      // no node to instantiate here — what it resolves to is drawn on this
      // frame instead: `itemPadding` and `clickableStyle.borderRadius` below,
      // `focusOutlineStyle.borderColor` as the Focus ring.
      const item = panel('item', 'HORIZONTAL', lk, {
        pl: f.itemPadding.l,
        pr: f.itemPadding.r,
        pt: f.itemPadding.t,
        pb: f.itemPadding.b,
        radius: clickable.borderRadius.topLeft,
      });
      item.counterAxisAlignItems = 'CENTER';
      item.appendChild(
        makeLabel(
          it.label,
          lk,
          typographyColorOpts(lk, it.current ? currentItemText : itemText, color),
        ),
      );
      c.appendChild(item);
      // After the append: the ring's insets are measured from the item's
      // settled box. See `clickableFocusRing` on the corner and the colour. A
      // disabled item takes no focus, so `Enabled=false, Focus=true` draws none.
      if (interactive && flags.Focus && !disabled) clickableFocusRing(item, lk, clickable);
      if (i < items.length - 1) {
        c.appendChild(
          makeIcon(
            'chevron-right',
            lk,
            glyphOpts(
              lk,
              colorData(disabled ? f.disabledColor : f.separatorIconStyle.color),
              f.separatorIconStyle.size,
              'size',
            ),
          ),
        );
      }
    }
  }
  // No `vStackSet`: `finish()` already applies `defaultSetLayout`, whose
  // ceil(sqrt(n)) grid stays roughly square as the pose count grows, and a
  // single column of eight breadcrumbs is a component's height of scrolling.
  return mount.finish();
}

// ─── Pagination ──────────────────────────────────────────────────────────────

// Data-driven from coui_core PAGINATION.fields (itemSpacing / buttonSize /
// buttonRadius / activeBackgroundColor / hoverBackgroundColor / buttonTextStyle
// / activeButtonTextStyle / activeTextStyle / hoverTextStyle / textStyle /
// ellipsisStyle / disabledColor / disabledBackgroundColor / iconStyle /
// clickableStyle). There is no
// `inactiveBackgroundColor` (or any default cell-fill) field on
// CorePaginationStyle — only the active and hovered cells' backgrounds are
// Style defaults — so the resting cell's 'surface-container' fill stays literal
// (#3755 OQ-2). The field is absent because neither platform paints one: the
// resting cell is `const Color(0x00000000)` (pagination.dart:192) and the Web
// resolver emits no idle background at all (only active + a `hover:bg-*`
// class). So this fill is the preview's own choice to keep resting cells
// visible, not a token that went missing — lifting it would write a Core
// default both renderers contradict, and wiring their transparent would erase
// the cells. Either way the pixel moves, so it stays literal until the design
// answers which one is wanted.
//
// The four typography fields split into ONE size and THREE colours, and reading
// them the other way round is a defect this builder shipped. `pagination.dart`
// takes `baseTextStyle = resolved.buttonTextStyle` — labelLarge, medium weight,
// deliberately **no colour** — and gives every cell
// `baseTextStyle.copyWith(color: foregroundColor)`, where that foreground is
// `activeTextStyle.color` / `hoverTextStyle.color` / `textStyle.color`. The
// resolver says so outright: it keeps `buttonTextStyle` whole and pulls `.color!`
// off the other three. Reading the SIZE off a per-state slot instead rendered
// every page number at labelMedium's 13 while the data states labelLarge's 14,
// and nothing caught it because the field arrived — `typographyColorOpts` is the
// shape that says "this style supplies the metrics, that colour wins".
//
// The row drawn is the TRUNCATED one, because the ellipsis exists only there.
// `_buildEllipsis` is not an optional flourish: `pagination.dart`'s `build`
// emits one whenever `_hasMorePreviousPages` / `_hasMoreNextPages`, and
// `maxPages` is 3 by default, so every page count above three has one. Drawing
// 1/2/3 instead showed a pagination that never truncates — the `…` cell absent
// from the canvas and `absent.ellipsisStyle` in the data pointing straight at
// it.
//
// So the preview states `page: 5, totalPages: 10` (caller data, like every
// other string here) and renders what the widget then renders:
// `_pages` yields 4/5/6, both `_hasMore*` are true, and
// `showSkipToFirstPage`/`showSkipToLastPage` — both defaulted `true` — add the
// 1 and the 10, giving [prev][1][…][4][5][6][…][10][next].
//
// Its own text style is the base one. `_buildEllipsis` passes
// `baseTextStyle.merge(resolved.ellipsisTextStyle)`, and `ellipsisStyle` reached
// no value at all (`absent.ellipsisStyle: "text"` — "inherits the ancestor text
// style"), so the merge is a no-op and the cell renders at `buttonTextStyle`
// with the resting foreground, exactly like a numbered cell that is neither
// active nor hovered. Reading `textStyleData(f.ellipsisStyle)` for it would look
// data-driven and land on `textLabelOpts`'s 14 fallback — the same number
// labelLarge happens to carry today, agreeing by arithmetic rather than by
// source (see the note on Steps' circle number).
//
// State axes: Hover (hoverBackgroundColor + hoverTextStyle), Enabled (the
// contract's own axis — `false` draws `disabledColor` on every number, the
// ellipsis and the chevrons and puts the current page on
// `disabledBackgroundColor`, the widget's `enabled: false`; the designer drew it
// as `Disabled=<bool>`, see `renames.ts`), Focus (clickableStyle.focusOutlineStyle,
// via `focusRing`). Hover shows on a resting numbered cell and focus on the
// active one — one cell each, for the same reason Breadcrumb shows them on one
// item. The ring is drawn on an ENABLED `Focus=true` member only: the
// pose matrix still enumerates `Enabled=false, Focus=true` — the member exists
// and draws what `Enabled=false` draws — but a disabled cell takes no focus in
// the widget, so there is nowhere for a ring to stand and that member carries no
// pair (the designer's copy has both layers hidden, which shows the same
// picture).
//
// #4036 (C4a) — the semantic prefix is `pagination.axes`', the same shape as
// Breadcrumb above: one Variant member (`standard`), no Size/State/Enabled, so
// the four-axis enumeration is one combination and the poses qualify it. The
// existing loose COMPONENT is adopted as that combination at rest — what it
// already rendered — rather than rebuilt, so its key survives.
function buildPagination(page: PageNode, lk: VarLookup): ComponentSetNode {
  const f = PAGINATION.fields;
  const clickable = f.clickableStyle;
  // `Disabled` is not a pose here: the contract states `enabled`, so the schema
  // promotes the `Enabled` axis and it rides the member's prefix (the designer
  // drew `Disabled=<bool>`; `renames.ts` carries the eight rows onto it).
  const axes: StateAxis[] = ['Hover', 'Focus'];
  const standardMembers = poseMembers(PAGINATION.axes, axes);
  // `Variant=compact` is canvas-only (#6577 decision): the code has one
  // `CorePaginationVariant` and narrows the row by itself from the current page
  // and the width it gets. The compact row is what the widget draws at
  // `page: 2, totalPages: 10` — the same cells, the same poses — so it rides
  // the Variant axis as a second value beside the code's `standard`, and the
  // component's description says the value has no code API (`generate.ts`
  // `kCanvasOnlyApiNotes`).
  const compactMembers = standardMembers.map((m) => ({
    ...m,
    name: m.name.replace('Variant=standard', 'Variant=compact'),
  }));
  const members = [...standardMembers, ...compactMembers];
  const mount = mountSet(
    page,
    'Pagination',
    members.map((m) => m.name),
    { adoptLooseAs: 'Variant=standard, Enabled=true, Hover=false, Focus=false' },
  );
  // Icon at the ends, text in the middle — a cell is one or the other, and
  // which it is is declared here rather than sniffed from the string.
  //
  // `active` / `hover` / `ellipsis` are per-cell flags rather than a match on
  // the label, which is how the widget marks them too (`_buildButton` takes
  // `active:` and a per-cell `hoverKey`). A string match cannot work here at
  // all: the two ellipsis cells carry the same `…`, so one comparison would
  // claim both.
  type Cell = {
    text?: string;
    icon?: string;
    ellipsis?: boolean;
    active?: boolean;
    hover?: boolean;
  };
  // The compact row: page 2 of 10 — no leading `1 …`, since the window
  // already starts at the first page.
  const compactCells: Cell[] = [
    { icon: 'chevron-left' },
    { text: '1' },
    { text: '2', active: true },
    { text: '3', hover: true },
    { text: '…', ellipsis: true },
    { text: '10' },
    { icon: 'chevron-right' },
  ];
  const cells: Cell[] = [
    { icon: 'chevron-left' },
    { text: '1' },
    { text: '…', ellipsis: true },
    { text: '4' },
    { text: '5', active: true },
    { text: '6', hover: true },
    { text: '…', ellipsis: true },
    { text: '10' },
    { icon: 'chevron-right' },
  ];
  // One typography for every cell but the current page's, three colours to
  // choose from — the split the widget makes (header note). `buttonTextStyle`
  // carries no colour of its own, so it is never read for one; the current
  // page's number states its own role and weight (`activeButtonTextStyle`), and
  // the ellipsis its own colour (`ellipsisStyle`).
  const buttonText = textStyleData(f.buttonTextStyle);
  const activeButtonText = textStyleData(f.activeButtonTextStyle);
  const activeText = textStyleData(f.activeTextStyle);
  const hoverText = textStyleData(f.hoverTextStyle);
  const restingText = textStyleData(f.textStyle);
  const ellipsisText = textStyleData(f.ellipsisStyle);
  for (const member of members) {
    const flags = member.flags;
    const disabled = member.axisValues['Enabled'] === 'false';
    const c = mount.getOrCreate(member.name);
    applyPanelCompChrome(c, 'HORIZONTAL', lk, { gap: f.itemSpacing });
    c.counterAxisAlignItems = 'CENTER';
    const row = member.name.includes('Variant=compact') ? compactCells : cells;
    for (const cell of row) {
      const isActive = cell.active === true;
      const isHovered = flags.Hover && cell.hover === true;
      // Each cell is a `Clickable` in the widget — a wrapper with nothing but
      // its child inside it, and a Figma instance cannot take a child, so
      // there is no node to instantiate. Its resolved chrome is on this frame:
      // `focusOutlineStyle` as the Focus ring below, `disabledOpacity` as the
      // Disabled axis on the root.
      //
      // The ellipsis cell is the same square button as the rest — same
      // `buttonSize`, same `buttonRadius`, same resting fill and foreground —
      // because `_buildEllipsis` routes through the same `_buildButton` with
      // `active: false`. Only its name says which it is.
      const btn = autoFrame(cell.ellipsis === true ? 'ellipsis' : 'page', 'HORIZONTAL');
      bindRadiusN(btn, lk, f.buttonRadius.topLeft);
      // A resting cell has NO fill, and that is a value rather than an omission:
      // `_buildButton`'s third branch is `backgroundColor = const
      // Color(0x00000000)` (pagination.dart), and the Web resolver emits no
      // resting `bg-*` at all — only the active and hover colours, which are the
      // only two background fields CorePaginationStyle carries. A literal
      // `surface-container` stood here, so every resting cell — and both
      // ellipses — read as a filled chip on a canvas where the widget draws bare
      // text. `autoFrame` already leaves `fills` empty, so the two stated
      // colours below are the whole set.
      // A disabled pagination has no hover, and its current page sits on the
      // disabled container instead of the primary fill.
      if (isActive) {
        fillData(
          btn,
          lk,
          colorData(disabled ? f.disabledBackgroundColor : f.activeBackgroundColor),
        );
      } else if (isHovered && !disabled) {
        fillData(btn, lk, colorData(f.hoverBackgroundColor));
      }
      btn.primaryAxisAlignItems = 'CENTER';
      btn.counterAxisAlignItems = 'CENTER';
      // `DefaultTextStyle.merge(style: baseTextStyle.copyWith(color: fg))` and
      // `IconTheme.merge(data: IconThemeData(color: fg))` are the same `fg` in
      // the widget, so the chevrons take the cell's foreground too rather than a
      // fixed slot name. The chevron's size is `iconStyle.size` (16): the
      // widget reads the same slot, and it is not derived from `buttonSize`.
      let cellColor = cell.ellipsis === true ? ellipsisText.color : restingText.color;
      if (disabled) cellColor = colorData(f.disabledColor);
      else if (isActive) cellColor = activeText.color;
      else if (isHovered) cellColor = hoverText.color;
      btn.appendChild(
        cell.icon
          ? makeIcon(cell.icon, lk, glyphOpts(lk, cellColor, f.iconStyle.size, 'size'))
          : makeLabel(
              cell.text!,
              lk,
              typographyColorOpts(lk, isActive ? activeButtonText : buttonText, cellColor),
            ),
      );
      c.appendChild(btn);
      bindSize(btn, lk, f.buttonSize, f.buttonSize);
      // After `bindSize`, the call that gives the cell its box. A disabled cell
      // takes no focus, so `Enabled=false, Focus=true` draws none.
      if (isActive && flags.Focus && !disabled) clickableFocusRing(btn, lk, clickable);
    }
  }
  const set = mount.finish();
  set.description = kCanvasOnlyApiNotes.Pagination;
  // `defaultSetLayout` over `vStackSet` — see the note at Breadcrumb's return.
  return set;
}

// ─── Tabs ────────────────────────────────────────────────────────────────────

// Data-driven from coui_core: TABS.fields (activeIndicatorRadius/Thickness,
// containerRadius, activeContentColor, contentTextStyle, tabSpacing,
// clickableStyle — bar-level chrome shared across variants) +
// TABS.variants.defaultsByVariant (pill / underline) + TABS.sizes.defaultsBySize
// (itemHeight).
//
// Two sets, both the designer's, and both backed by the code. `Tabs` is the
// bar — `Variant=pill|underline` × `Size=sm|md|lg` × `Width=fill|scroll` —
// and every member of it holds six INSTANCES of `TabItem`, the per-tab set
// (`Variant` × `Size` × `State` × `Selected`, see its own header below). The
// bar COMPOSES the
// item rather than drawing an equivalent frame by hand, the shape
// `NavigationBar` / `NavigationBarItem` already take: it is what keeps a future
// Generate from overwriting the structure the designer built with a look-alike
// this file invents, and it is the widget's own structure — `tabs.dart` builds
// a `Row` of one button per `CoreTabItem` (`_buildPillTab` /
// `_buildUnderlineTab`), and the Web twin resolves each tab on its own through
// `resolveTabsTab({ variant, size, active, enabled, expand })`.
//
// The item set is named after the code — `CoreTabItem`, so `TabItem`
// (Flutter-first, the way `NavigationBarItem` is named after
// `CoreNavigationBarItem`) — where the designer called it `Tab`. `SET_RENAMES`
// renames it in place, so the member keys and the six instances inside every
// `Tabs` member that point at them survive.
//
// `Size` is the Tabs-owned `CoreTabsSize` (`sm` · `md` · `lg`), the three
// `defaultsBySize` rows. It lands in `axes.other` rather than `axes.size`, so
// both builders enumerate it themselves (see the note in `buildTabs`).
// Members that predate the ladder migrate through `VARIANT_RENAMES` as the
// `md` row.
//
// Two stated fields are NOT on the canvas, and neither is a value this builder
// could place:
//
//   · `indicatorTransitionDuration` (100ms) is the `AnimatedContainer` duration
//     both tab builders pass, i.e. how long the indicator takes to move from
//     one tab to the next. A component set is a set of still frames — Figma
//     models prototype transitions between FRAMES on a flow, not a duration a
//     variant carries, and there is no reaction on a main component that would
//     let this number live on the node it belongs to. It is the one shape of
//     value a static canvas has no axis for.
//   · `swipeSensitivity` (20) is not chrome at all — it is the velocity
//     threshold `_handleHorizontalDragEnd` compares `details.primaryVelocity`
//     against before switching tabs. Nothing about the picture changes with it,
//     on either platform, so there is nothing here to draw. It is on the Style
//     plane against `core/style-contract.md` ("Style 슬롯은 시각 chrome only" —
//     "이 값이 바뀌면 컴포넌트의 모양이 바뀌나, 동작이 바뀌나?"), and the Core
//     doc comment says so itself: "A velocity value — not a layout dimension".
//     Moving it to the widget plane is a Core change, not a builder one.
//
// The two variants are not a colour swap: `underline` draws a bar under the
// active tab, `pill` fills the active tab with a raised chip — that is
// what `activeIndicatorColor` means in each (Semantic/primary as a 2px bar vs
// Semantic/surface-raised as a background), so both are rendered.
//
// The `Size` rung is the bar's outside height, and each variant row says
// whether it is the track's (`sizeRungIsTrack`). Where it is (`pill`) the bar
// stands its track at the rung and each `TabItem` inside the track's
// `tabBarPadding`, so the item is the rung less that inset's top and bottom;
// where it is not (`underline`) the item is the rung. `buildTabItem` sizes the
// item that way and the track here hugs it, so the track comes out at the
// rung without stating a height of its own — the same layout both widgets
// draw.
//
// Both of the per-variant bar keys reach a pixel, and each through the node the
// widget puts it on: `pill`'s `backgroundColor` fills the track (with
// `containerRadius` rounding it), `underline`'s `borderColor` is the bar's
// bottom-only hairline — drawn as a stroke whose other three weights are zero,
// because that edge does not exist rather than because a design value was
// hardcoded. Both are keyed on the variant below, since only one row of the
// dispatch table carries each key.
//
// The `State` axis lives on `TabItem`, not on the bar. Every rung of it is a
// fact about ONE tab — `CoreTabItem.enabled` is per item, the `Clickable` that
// takes focus wraps each tab rather than the row, and the hover / pressed
// washes composite over a single tab's own fill — and the designer's bar set
// carries no such axis either.
//
// `TabPane` and `FadeScroll` are NOT composed here, and that is not an
// omission. `tabs.dart` names neither — zero occurrences of either identifier
// in the whole file; its `build` returns a `Row` of tab buttons inside a
// `DecoratedBox`. Both names come from `tab_pane.dart`, which sits in the same
// `tabs/` directory but IS a different component: `TabPane` is its own REGISTRY
// entry with its own builder, and the `FadeScroll(` call in it is TabPane
// composing FadeScroll, not Tabs composing anything. The parity scan globs a
// directory, so it attributes a sibling's file to this one.
//
// The skip is NOT the cycle escape hatch — neither child depends on `Tabs`
// (TabPane's REGISTRY entry declares no `needs`), so `topoSortRegistry` would
// happily order them and `instanceOf` would succeed. That is exactly why the
// reason has to be written down: composing them here would BUILD, and the
// canvas would show a tab bar containing a fade-scrolled tab pane — structure
// the widget does not have. Drawing a child the widget never composes fails the
// same criterion as omitting one it does, and fails it in the direction that
// looks finished.

// `Width` is `CoreTabsContract.expand` — "whether the tabs expand to fill the
// available horizontal space" — a widget `bool` (`this.expand = false`) rather
// than a Style field or an enum in `tabs.axes`, so it is enumerated here the
// way `Window` promotes its own `Focused` / `Minimized` runtime bools. The
// values are the designer's spellings: `fill` is `expand: true` (`mainAxisSize:
// .max`, every tab wrapped in `Expanded`), `scroll` is `expand: false` (`.min`,
// the tabs hug their labels) — and `scroll` is the contract default, which is
// why `kRestingAxisValue` rests the axis there.
const kTabsWidth = ['fill', 'scroll'] as const;

// The `Selected` axis of `TabItem` — a flag, not an index. Whether THIS tab is
// the current one is the tab's own fact (`active` in `resolveTabsTab`, `i ==
// selectedIndex` in `tabs.dart`); WHICH tab is current is the bar's, answered
// by which instance it asks for `Selected=true`. Spelled `true`/`false` like
// `Chip`'s, which is not the spelling `kRestingAxisValue` answers for the axis
// name — see `tabItemVariantName` for why that never matters here.
const kTabItemSelected = ['false', 'true'] as const;

// The close glyph — the widgets' `LucideIcons.x`, the glyph `TabPaneTab`
// draws for the same slot.
const kTabItemCloseGlyph = 'x';

// The `State` axis of `TabItem` — the five rungs the designer drew, which are
// letter-for-letter `Fab`'s, `Checkbox`'s and `Toggle`'s (`kFabStates`,
// `kCheckboxStates`, `kToggleStates`). Each is backed by something a resolver
// states:
//   · `enabled`  — rest; no wash, no ring, full opacity.
//   · `hover`    — `CoreTabsStyle.hoverStateLayerColor` (on-surface 8%),
//                  composited over whatever the tab's own fill is.
//   · `focus`    — the `Clickable` ring (`clickableStyle.focusOutlineStyle`).
//   · `pressed`  — `CoreTabsStyle.pressedStateLayerColor` (on-surface 16%).
//   · `disabled` — `CoreTabItem.enabled == false`: the label takes
//                  `disabledContentColor` AND the whole tab takes
//                  `clickableStyle.disabledOpacity`, which is what the two
//                  widgets do together.
//
// One rung at a time, because that is what the widgets resolve: `_TabButton`
// picks pressed-or-hovered-or-neither and a disabled tab reaches neither
// branch (`_withStateLayer` returns early when `!_isEnabled`). That is also
// why the old `Focus` × `Disabled` product retires rather than folding — its
// `Focus=true, Disabled=true` corner named a pose no widget can reach.
//
// Chip's five-rung note argues the opposite for `focus`: there the ring is
// `Show focus ring`'s pose and a rung would draw the same picture under a
// second name. `TabItem` has no such property — the ring only ever showed as
// an axis here — so the rung is the ONLY name for it, and the designer's set
// spells it the way the four other state-bearing sets do.
const kTabItemStates = stateAxis([
  'enabled',
  'hover',
  'focus',
  'pressed',
  'disabled',
]);

// Six tabs — the designer's bar holds `Tab 1`…`Tab 6`. The first two are
// always drawn; the last four sit behind `Show tab 3|4|5|6` BOOLEANs. Plain
// nouns a settings screen would carry.
const kTabsLabels = [
  '개요',
  '활동',
  '설정',
  '멤버',
  '결제',
  '보고서',
] as const;

// How many tabs a bar always draws, i.e. where the `Show tab N` toggles
// start. The code has no lower bound: Flutter `tabs.dart` builds one button
// per `tabs` entry and spaces them only when `rowChildren.length > 1`, and
// the Web twin loops over `tabs.length` the same way. Two is a canvas floor,
// the smallest bar that still offers a choice, and it is a designer decision.
// A one-tab bar is not drawn on the canvas.
const kTabsAlwaysShown = 2;

// How many tabs a bar shows at rest. This is where the `Show tab N` defaults
// switch from on to off: the three-tab preview the set has always drawn. A
// designer turns the rest on per instance.
const kTabsShownAtRest = 3;

// g7-preview-only: the designer's horizontal inset on the `Width=scroll` members (16) — at `expand: false` `tabs.dart` wraps a `mainAxisSize: .min` row in its `DecoratedBox` and lays it wherever the parent puts it, so no CoreTabsStyle field states an inset for a hugging bar; the canvas mirrors the designer's 16 so the scroll pose reads as a bar sitting in page margins rather than flush against the frame's edge. On the pill member it is the frame's padding around the track; on the underline member it is the ruled row's own padding, so the rule keeps the member's full width and only the tabs sit inset (see `buildTabs`). The `Width=fill` members carry no inset, which is also the designer's.
const kTabsScrollInset = 16;

// The `TabItem` member a bar asks for, spelled through `composeVariantName` so
// the name a `Tabs` member instances cannot drift from the name
// `buildTabItem` mints for the same pose (the `restingButton` shape).
//
// Every axis is named — none is left to `restingValueOf`. `kRestingAxisValue`
// is keyed by axis NAME and answers `Selected` with `'1'`, `Filter`'s one-based
// index, while this set spells its `Selected` as `true`/`false`: the two
// consumers of resting values (`restingVariant` in display-media.ts,
// `restingVariantName` in form-pickers.ts) are asked only about `Button`,
// `TextField` and `Calendar`, so neither ever meets `TabItem`, and this helper
// is what keeps it that way — a bar names the pose outright, the way
// `ChipInput` names `Selected: 'true'`.
//
// `State` rests at `enabled`: a bar composes every tab at rest, the way
// `NavigationBar` asks its items for `State=enabled`. It is the item's own
// axis, flipped on the instance by a designer.
function tabItemVariantName(
  variant: string,
  selected: boolean,
  size: string,
): string {
  return composeVariantName([
    ['Variant', variant],
    ['Size', size],
    ['State', 'enabled'],
    ['Selected', selected ? 'true' : 'false'],
  ]);
}

// A `Tabs` member's name — the same one-code-path argument as above, for the
// adoption name below.
function tabsVariantName(
  variant: string,
  width: (typeof kTabsWidth)[number],
  size: string,
): string {
  return composeVariantName([
    ['Variant', variant],
    ['Size', size],
    ['Width', width],
  ]);
}

// Puts a bar's copy into a composed `TabItem`'s `Label`.
//
// Not `setInstanceLabel`: that helper drives the FIRST TEXT property it finds,
// which is the right answer for a child with one. The designer's `TabItem` set
// carries two — `Label`, and the `Count` her set declares (see the `TabItem`
// header on where that value actually lands) — and the order
// `componentProperties` lists them in is the set's, not this file's. Matching
// the key's human prefix is how `defineProp` itself finds a property, so the
// same rule is applied here rather than a position that would drive the badge
// on a set whose `Count` happens to sort first.
//
// Not wrapped, for `setInstanceLabel`'s reason: the key came from the
// instance's own table, so a throw means the child's properties changed shape
// underneath this call, and one loudly failing entry beats a bar that looks
// finished and shows six tabs reading "Label".
function setTabItemLabel(instance: InstanceNode, text: string): void {
  const props: ComponentProperties | undefined = instance.componentProperties;
  if (!props || typeof instance.setProperties !== 'function') {
    throw new Error(
      `Tabs: the composed TabItem instance exposes no component properties — ` +
        `its \`Label\` TEXT is what carries each tab's copy.`,
    );
  }
  for (const key of Object.keys(props)) {
    if (props[key].type !== 'TEXT' || key.split('#')[0] !== 'Label') continue;
    const patch: { [key: string]: string } = {};
    patch[key] = text;
    instance.setProperties(patch);
    return;
  }
  throw new Error(
    `Tabs: the composed TabItem instance has no \`Label\` TEXT property ` +
      `(has: ${Object.keys(props).join(', ')}).`,
  );
}

// ─── TabItem ─────────────────────────────────────────────────────────────────

// The designer's per-tab set (she called it `Tab`; renamed in place, see the
// Tabs header), composed by `buildTabs` six times per bar. Data-driven from the
// same `TABS.fields` / `defaultsByVariant` a tab read when the bar still drew
// it inline — there is no separate Core contract for one tab: `CoreTabItem<W>`
// is a data value (`label` / `enabled` / `content`), its chrome is entirely
// `CoreTabsStyle`'s (`tabPadding`, `activeIndicatorColor` / `Radius` /
// `Thickness`, `activeContentColor` / `inactiveContentColor`, `clickableStyle`),
// and the per-tab resolver is `resolveTabsTab`. The REGISTRY entry declares
// `dataSlug: 'tabs'` for that reason, the way `NavigationBarItem` reads
// `navigation_bar`.
//
// Four axes, every one the designer's spelling and every one backed by code:
//   · `Variant` — `tabs.axes`', enumerated rather than spelled.
//   · `Size` — `CoreTabsSize`, enumerated here (see the note at `combos`).
//   · `State` — the tab's interaction rung, `kTabItemStates`.
//   · `Selected` — `active`. See `kTabItemSelected` on why it is a flag here.
//
// `Selected` stays its own axis rather than folding into `State` because the
// two answer different questions and both are true at once: `State` is what
// the pointer and the keyboard are doing to THIS tab, `Selected` is whether
// this tab is the one the bar is showing. A hovered tab that is also the
// current one is a pose both widgets draw (the wash composites over the pill's
// active fill, `_withStateLayer(activeIndicatorColor)`), so collapsing them
// would lose it.
//
// The designer's per-tab badge — her `Show count` (BOOLEAN) and `Count`
// (TEXT) — is `CoreTabItem.badge`: a composition slot both widgets render
// after the label behind a 1-off `Gap` (`tabs.dart#_labelWithBadge`, the Web
// span's `Text` → `Gap` → badge). The caller supplies a styled `Badge`; the
// only thing the bar states is the spacer, `CoreTabsStyle.labelBadgeGapStyle`
// (6). So the canvas composes a `Badge` INSTANCE after the label, inside a
// row whose `itemSpacing` is that gap. The badge's pose — the docs payload's
// filled count at `xs` in the widget's default tone, `Child` at the
// designer's "0" — is `composeCountBadge`'s (instance-reach.ts), the one
// statement `TabItem` and `TabPane` share so a count reads the same in a bar
// and a strip; nothing about it is spelled here. Her two properties are then
// adopted by name:
//   · `Show count` (BOOLEAN, default false) drives the badge instance's
//     `visible`. No gap node to hide beside it: the spacer is the row's own
//     auto-layout `itemSpacing`, which a hidden child stops billing on its
//     own — so `Show count=false` leaves no gap, the way the widgets compose
//     no `Gap` for an item without a badge.
//   · `Count` (TEXT, default "0") is the badge's copy. It reaches the badge
//     as the composed instance's own `Child` — set to "0" and surfaced on the
//     TabItem panel by exposing the nested instance — because that is the
//     one way Figma has: a set-level TEXT property cannot bind to a node
//     inside an instance (`componentPropertyReferences` is rejected on an
//     instance sublayer, the same wall `CardImage`'s `Basic` slots and the
//     pickers' `Dialog` title hit). So `Count` is NOT declared on this set by
//     this builder — a declaration nothing binds would be a knob that moves
//     nothing, which is what the previous note here called it. On her live
//     file the definition stays (`defineProp` never removes); the value that
//     drives the badge is the exposed `Child`. `Label` IS adopted — it is
//     `CoreTabItem.label`.
//
// Two values have no CoreTabsStyle field and stay literal (#3755 OQ-2):
// - the intra-tab label→indicator gap (8) — `tabSpacing` is the BAR-level
//   inter-tab gap, not this one, and the widget has no gap here at all: the
//   rule is a `Border(bottom:)` on the tab's own box, so there is no sibling
//   for a gap to sit between (see the marker at the call);
// - the indicator bar's own rendered width (100) — a static-preview layout
//   choice, not a Style default; it is `FILL` in the frame anyway.
//
// The inactive tab's rule is not one of them. It used to be a literal
// `outline-variant`, on the reading that "only `activeIndicatorColor` exists";
// `tabs_style.dart` states the other side too, by derivation —
// `inactiveIndicatorColor = activeIndicatorColor.withAlpha(0)`, the same hue
// held at alpha 0 so the `AnimatedContainer` border lerp never drags a tab
// switch through transparent black. So an inactive tab's rule is INVISIBLE, and
// the literal drew a visible hairline under every tab the widget leaves bare.
// The label is the variant row's `contentTextStyle` where it states one
// (`underline`: `labelXl`), else the rung's role, and its weight follows
// `Selected`: the row's `activeFontWeight` on a selected tab,
// `inactiveFontWeight` on every other one — the two finished styles
// `resolveTabs` hands the widget to pick between.
function buildTabItem(page: PageNode, lk: VarLookup): ComponentSetNode {
  const f = TABS.fields;
  const clickable = f.clickableStyle;
  const variantData = new Map(Object.entries(TABS.variants.defaultsByVariant));
  const sizeData = new Map(Object.entries(TABS.sizes.defaultsBySize));
  // `Size` is enumerated here rather than arriving through `axisSpecsOf` — see
  // the note in `buildTabs`. The ladder is three rungs now (the redesign
  // narrowed the shared six-step one to a Tabs-owned `CoreTabsSize`), and the
  // `VARIANT_RENAMES` rows that carry the old members into `Size=md` name only
  // that rung, so narrowing the ladder retires the four the canvas no longer
  // draws rather than orphaning them.
  const combos = enumerateAxisCombos([
    ...axisSpecsOf(TABS.axes),
    { axis: 'Size', values: [...sizeData.keys()] },
    { axis: 'State', values: kTabItemStates },
    { axis: 'Selected', values: kTabItemSelected },
  ]);
  // The names the designer's set carried (as `Tab`, renamed by SET_RENAMES
  // before any builder looks anything up) are the `Size=md` row of these —
  // VARIANT_RENAMES carries them across so the members keep their keys and the
  // instances that point at them survive. Adoption names the resting member
  // for a document holding only a loose `TabItem` COMPONENT.
  const mount = mountSet(page, 'TabItem', combos, { adoptLooseAs: combos[0] });
  // Collected across every member so the copy becomes ONE set-level `Label`
  // after `finish()` — the designer's own property, which the bar overrides
  // per instance.
  const labels: TextNode[] = [];
  // The label rows, likewise — each gets its count badge composed into it
  // after `finish()`, when the set exists to own the `Show count` the badge
  // binds to and to be the COMPONENT ancestor its exposure needs (see
  // `composeCountBadge`).
  const labelRows: FrameNode[] = [];
  // Each row's close box, by the same index — the badge is placed before it
  // after `finish()`, so the row reads label → badge → ×.
  const closeBoxes: FrameNode[] = [];
  for (const comboName of combos) {
    const combo = parseVariantKey(comboName);
    const variant = variantData.get(combo['Variant']);
    if (!variant) throw new Error(`TabItem: no data for combo "${comboName}"`);
    const sizeRow = sizeData.get(combo['Size']);
    if (!sizeRow) throw new Error(`TabItem: no size row for "${combo['Size']}"`);
    const pill = combo['Variant'] === 'pill';
    const active = combo['Selected'] === 'true';
    const state = combo['State'];
    const disabled = state === 'disabled';
    const c = mount.getOrCreate(comboName);
    const tabPad = variant.tabPadding;
    // The chrome sits on the member itself, not on a child frame: the member
    // IS the tab box — `_buildPillTab` / `_buildUnderlineTab` each return one
    // `Clickable` around one box — so a bar that stretches the instance
    // (`Width=fill`) stretches the pill's fill and the rule with it. `Clickable`
    // is nothing but that wrapper and a Figma instance cannot host the child
    // it wraps, so its resolved chrome lands here too: `focusOutlineStyle` as
    // the Focus ring, `disabledOpacity` on the root. That is also the shape
    // the designer drew — padding, gap and radius bound on the member.
    applyPanelCompChrome(c, 'VERTICAL', lk, {
      pl: tabPad.l, pr: tabPad.r, pt: tabPad.t, pb: tabPad.b,
      // g7-preview-only: the member's `itemSpacing` — it has one flow child (the label row; the underline rule is bottom-pinned below, outside the flow), so no spacing is ever drawn between siblings and no `CoreTabsStyle` field states one. It is written rather than omitted because members are recycled: a run that left it alone would keep whatever the previous build set, and the 8 this replaces put a separation under every label — on `pill`, which has no rule at all, between a label and nothing.
      gap: 0,
      radius: pill ? f.activeIndicatorRadius.topLeft : undefined,
    });
    c.counterAxisAlignItems = 'CENTER';
    c.primaryAxisAlignItems = 'CENTER';
    // `fillData`, not `ChromeOpts.bg`. That option takes a bare Semantic
    // NAME, so passing `colorData(...)?.color` handed over the token and
    // dropped the alpha beside it — `applyChrome` then paints at its own
    // default of 1. The pill's active fill is opaque today, so nothing
    // moves on the canvas; what moves is that the value now arrives
    // whole, the way this variant's inactive label already does (its
    // `inactiveContentColor` is 50% and reaches the paint through
    // `typographyColorOpts`).
    if (pill && active) {
      // Disabled swaps the variant's `disabledIndicatorColor` in — the
      // pill is an area, so that is `disabled-container` rather than the
      // label's ink token. Same branch both platforms take.
      fillData(
        c,
        lk,
        colorData(
          disabled ? variant.disabledIndicatorColor : variant.activeIndicatorColor,
        ),
      );
    }
    if (disabled) c.opacity = dimVal(clickable.disabledOpacity);
    // Typography: the variant row's role where it states one (`underline`
    // draws `labelXl` on every rung), else this member's own rung — the label
    // role is per-size (`sm` `labelMedium`, `md` `labelLarge`, `lg`
    // `labelXl`), so reading the flat default here would draw all three rungs
    // at the middle one's type. The weight is the row's per selection, on top
    // of whichever role that was.
    // A variant row that states no weight for this selection leaves the
    // role's own (the resolver's `copyWith(fontWeight: null)` keeps it), so
    // a missing weight falls back to the merged role style. The weights are
    // read as members of the row (`variant.activeFontWeight`) — the
    // unread-key guard counts only that form as a read.
    const roleStyle = mergeTextStyleData(
      textStyleData(sizeRow.contentTextStyle),
      textStyleData(optField(variant, 'contentTextStyle')),
    );
    const rowWeight: number | Dim | undefined = active
      ? variant.activeFontWeight
      : variant.inactiveFontWeight;
    const labelStyle = {
      ...roleStyle,
      fontWeight: rowWeight != null ? dimVal(rowWeight) : roleStyle.fontWeight,
    };
    // Disabled speaks through its own colour, not only through the
    // `Clickable` dim above — the redesign gave `CoreTabsStyle` a
    // `disabledContentColor` and both resolvers paint the label with it
    // (`tabs.dart` / `tabs_style.dart`). The opacity stays because
    // `Clickable` still applies it to the whole tab; drawing only the dim
    // here said half of what the widgets say.
    const o = typographyColorOpts(
      lk,
      labelStyle,
      colorData(
        disabled
          ? f.disabledContentColor
          : active
            ? f.activeContentColor
            : variant.inactiveContentColor,
      ),
    );
    // `Label` — the designer's property default, and the copy a bare instance
    // shows until a bar overrides it.
    const label = makeLabel('개요', lk, o);
    labels.push(label);
    // The label and its badge share a row — `tabs.dart#_labelWithBadge`'s
    // `Row(mainAxisSize: .min)` — whose `itemSpacing` is the stated
    // `labelBadgeGapStyle`. The row, not the member, because the member is
    // the VERTICAL stack that puts the underline rule beneath the content.
    const labelRow = panel('content', 'HORIZONTAL', lk, {
      gap: f.labelBadgeGapStyle.size,
    });
    labelRow.counterAxisAlignItems = 'CENTER';
    labelRow.appendChild(label);
    // The badge — a composed `Badge`, the way the widget takes one from the
    // caller — joins this row after `finish()` (`composeCountBadge`). Hidden
    // at rest there AND bound to `Show count`, so the node and the property's
    // default say the same thing (`Tabs`'s hidden tabs).
    labelRows.push(labelRow);
    c.appendChild(labelRow);
    // The close affordance (`CoreTabItem.onClose`): the widget's ghost
    // `Button(buttonStyle: closeButtonStyle, child: Icon(x, iconStyle:
    // closeIconStyle))`, after the label and the badge with the label↔badge
    // step before it (the row's `itemSpacing`). Drawn the way `TabPaneTab`
    // draws its own — a box of the stated size, inset and corner around the
    // glyph in its stated ink — rather than a composed `Button`, whose ghost
    // row would have to be overridden back to these values on every
    // instance. Hidden at rest and bound to `Show close`: the widget draws it
    // only for an item given `onClose`.
    const closeButton = f.closeButtonStyle;
    const closeIcon = f.closeIconStyle;
    const closeBox = autoFrame('close', 'HORIZONTAL');
    closeBox.primaryAxisAlignItems = 'CENTER';
    closeBox.counterAxisAlignItems = 'CENTER';
    bindPad(closeBox, lk, closeButton.padding);
    bindRadiusN(closeBox, lk, closeButton.borderRadius.topLeft);
    closeBox.primaryAxisSizingMode = 'FIXED';
    closeBox.counterAxisSizingMode = 'FIXED';
    bindSize(closeBox, lk, closeButton.width, closeButton.height);
    closeBox.appendChild(
      makeIcon(
        kTabItemCloseGlyph,
        lk,
        glyphOpts(lk, colorData(closeIcon.color), closeIcon.size, 'size'),
      ),
    );
    closeBox.visible = false;
    labelRow.appendChild(closeBox);
    closeBoxes.push(closeBox);
    // The state-layer wash — `_withStateLayer`'s overlay, drawn rather than
    // pre-blended. Both widgets `alphaBlend` the layer colour over whatever
    // the tab's fill is, so a translucent rect over that fill is the same
    // stacking: on `pill, Selected=true` it sits over the active indicator's
    // fill, everywhere else over nothing. `disabled` carries none — the
    // widgets return before reaching the overlay when the item is disabled.
    //
    // Child 0, so it is above the member's own fill and below the label row
    // and the rule. The colour arrives whole from `colorData` (the token AND
    // its 8% / 16% alpha, so a theme change follows it) rather than as a
    // weight multiplied onto a foreground the way `Chip` does — `CoreTabsStyle`
    // states these as finished colours, not as a ramp.
    let stateWash: RectangleNode | null = null;
    if (state === 'hover' || state === 'pressed') {
      const wash = figma.createRectangle();
      stateWash = wash;
      wash.name = 'state layer';
      // Rounded on `pill` only, matching the box whose fill it washes over —
      // `activeIndicatorRadius` is what `_TabButton` gives the pill's
      // `BoxDecoration`, and the underline tab's decoration states no radius
      // at all. Left alone rather than bound to a literal 0 in that case: a
      // fresh rectangle is square already (`resetNode` wipes the member's
      // children every run), and binding would claim the design system named
      // this corner when no field does.
      if (pill) bindRadiusN(wash, lk, f.activeIndicatorRadius.topLeft);
      fillData(
        wash,
        lk,
        colorData(
          state === 'pressed' ? f.pressedStateLayerColor : f.hoverStateLayerColor,
        ),
      );
      c.insertChild(0, wash);
      pinInFlow(c, wash);
    }
    let underlineRule: RectangleNode | null = null;
    if (!pill) {
      const ul = figma.createRectangle();
      underlineRule = ul;
      ul.resize(100, dimVal(f.activeIndicatorThickness));
      // g7-preview-only: the rule's corners — square, and no `CoreTabsStyle` field says so, because the widgets say it by SHAPE: `tabs.dart` draws this as `Border(bottom:)` (Web as a CSS border), which has no corners to round, and reads `activeIndicatorRadius` only in the `pill` branch where it rounds that variant's fill. This canvas models the border as a rect, and a rect has corners it must state — it states 0. Binding the pill's 4 here rounded a border neither platform renders and the designer's preview does not draw. Written rather than left alone because members are recycled: an untouched rect keeps the 4 a previous build gave it.
      bindRadiusN(ul, lk, 0);
      // Three cases, and all three are stated by the widgets.
      //
      // A selected tab's rule paints `activeIndicatorColor` whole — unless
      // the tab is DISABLED, when both platforms swap in the variant's
      // `disabledIndicatorColor`. A disabled tab still has to say which one
      // is current, so the rule stays visible and only its hue drops out of
      // the accent. The canvas drew the accent here and the designer's
      // preview caught it.
      //
      // An unselected tab's rule is that same `activeIndicatorColor`
      // Variable held at alpha 0 — `tabs_style.dart`'s own
      // `activeIndicatorColor.withAlpha(0)`, the one hue the border lerp
      // holds so a tab switch never drags through transparent black. A
      // fresh Figma rectangle arrives with a default grey fill, so the
      // invisible case still has to be painted rather than left alone, and
      // painting it from the token keeps that hue readable to anyone
      // inspecting the node.
      const rule = colorData(
        active && disabled
          ? variant.disabledIndicatorColor
          : variant.activeIndicatorColor,
      );
      if (rule && !active) rule.opacity = 0;
      fillData(ul, lk, rule);
      c.appendChild(ul);
    }
    // The tab's own height, from this member's rung (`itemHeight`). The rung
    // is the bar's outside height, and the variant row says whether it is the
    // TRACK's (`sizeRungIsTrack`): a tab inside a track sits inside its
    // `tabBarPadding`, so it is the rung less that inset's top and bottom;
    // a tab with no track around it is the rung. That is
    // `CoreTabsStyle.tabHeight`, which both resolvers state their tab height
    // through (`resolveTabs` subtracts the resolved inset, `resolveTabsTab`
    // emits the same subtraction as a `calc`). Fixed on the primary
    // (vertical) axis once the children are in, the way `lockWidth` fixes the
    // other one; the width keeps hugging the label so a `Width=scroll` bar
    // can hug its tabs, and a `Width=fill` bar stretches the instance
    // instead.
    const trackInset = variant.sizeRungIsTrack.v
      ? dimVal(variant.tabBarPadding.t) + dimVal(variant.tabBarPadding.b)
      : 0;
    c.primaryAxisSizingMode = 'FIXED';
    c.resize(c.width, Math.max(0, dimVal(sizeRow.itemHeight) - trackInset));
    c.counterAxisSizingMode = 'AUTO';
    // The rule sits ON the bottom edge, not in the flow above it. The widget
    // draws it as `Border(bottom:)` on the tab's own box, which is always at
    // the box's edge while the label stays centred in the FULL height — but a
    // flow child rides `primaryAxisAlignItems: CENTER`, so the label and the
    // rule centred as a pair and the rule floated roughly half the leftover
    // height above the edge. Absolute + bottom-pinned reproduces the border:
    // the label is then the only thing the centring sees.
    //
    // After the resize, because the pin is measured from an edge that does not
    // exist until the member has its height, and after `counterAxisSizingMode`
    // because the width the rule spans is the hugged one.
    if (underlineRule) {
      underlineRule.layoutPositioning = 'ABSOLUTE';
      underlineRule.constraints = { horizontal: 'STRETCH', vertical: 'MAX' };
      underlineRule.resize(c.width, underlineRule.height);
      underlineRule.x = 0;
      underlineRule.y = c.height - underlineRule.height;
    }
    // The wash covers the whole box — it is the tab's fill in the widgets, not
    // a layer over part of it. Sized here for the rule's reason: the member's
    // width is the hugged one and its height only exists after the resize.
    if (stateWash) {
      stateWash.constraints = { horizontal: 'STRETCH', vertical: 'STRETCH' };
      stateWash.resize(c.width, c.height);
      stateWash.x = 0;
      stateWash.y = 0;
    }
    // The focus pose wears TWO nodes, not a stroke on the box. A stroke has no
    // offset, so the `align` gap between the tab and its ring could not be
    // drawn at all — see `clickableFocusRing` above. The
    // shared `focusRing` draws the band at `-(align - borderWidth)` and the
    // ring at `-align`, which is the pair the designer drew and the pair both
    // widgets already build (`Clickable` composes `FocusOutline`, whose
    // `ringOffset` + `ringWidth` are this same 2 and 2).
    //
    // Built last, for the reason the rule and the wash are sized last: the
    // insets are measured from a box that does not have its height until the
    // resize above, and both layers pin STRETCH×STRETCH to it. Last also puts
    // them at the end of the child order, which is where the pair belongs —
    // band directly before ring, above everything they outline.
    //
    // `corner` is the box's own: `pill` rounds its indicator at
    // `activeIndicatorRadius` (6 → band 8, ring 10), and `underline` rounds
    // nothing (0 → band 2, ring 4) — it has no corner field because the
    // widgets draw that variant's indicator as `Border(bottom:)`, which has no
    // corners to state.
    if (state === 'focus') {
      focusRing(c, lk, {
        outline: clickable.focusOutlineStyle,
        color: colorData(clickable.focusOutlineStyle.borderColor),
        corner: pill ? f.activeIndicatorRadius.topLeft : null,
        width: c.width,
        height: c.height,
        visible: true,
      });
    }
  }
  const set = mount.finish();
  // After `finish()`, on the set — the only moment the owner exists (the
  // `Filter` / `FocusOutline` shape). `Label` and `Show count` are the
  // designer's own properties, adopted by name+type. `Count` is the one of
  // hers this builder does not declare: a parent TEXT property cannot drive a
  // nested instance's text, so the count reaches the badge through the
  // exposed instance's own `Child`, and her existing `Count` definition stays
  // on her set until she removes it (`defineProp` never removes) — see the
  // header.
  const labelProp = defineProp(set, 'Label', 'TEXT', '개요');
  for (const node of labels) bindTextProp(node, labelProp);
  // `Show count` — BOOLEAN, default `false`: the resting pose is the bare
  // label the set drew, and a property that changed the default rendering on
  // adoption would move every instance already placed. Bound to each badge
  // instance's `visible`; the gap beside it is the row's `itemSpacing`, which
  // a hidden child stops billing on its own. The badge itself is composed,
  // bound and exposed here rather than in the loop — the set is the ancestor
  // both writes need (`composeCountBadge`).
  const showCountProp = defineProp(set, 'Show count', 'BOOLEAN', false);
  for (let i = 0; i < labelRows.length; i++) {
    const row = labelRows[i];
    const badge = composeCountBadge(page, row, showCountProp);
    // Before the close box, which the loop already placed: label → badge → ×.
    row.insertChild(row.children.indexOf(closeBoxes[i]), badge);
  }
  // `Show close` — the name `TabPaneTab` gives the same `CoreTabItem.onClose`
  // slot. BOOLEAN, default `false`: the resting tab is the one the docs
  // default draws, with no close.
  const showCloseProp = defineProp(set, 'Show close', 'BOOLEAN', false);
  for (const box of closeBoxes) bindVisibleProp(box, showCloseProp);
  // `defaultSetLayout` over `vStackSet` — see the note at Breadcrumb's return.
  return set;
}

function buildTabs(page: PageNode, lk: VarLookup): ComponentSetNode {
  const f = TABS.fields;
  const variantData = new Map(Object.entries(TABS.variants.defaultsByVariant));
  const sizeData = new Map(Object.entries(TABS.sizes.defaultsBySize));
  // `Size` is enumerated here rather than arriving through `axisSpecsOf`.
  // The reader promotes `axes.size` only for a `CoreComponentSize` getter, and
  // the 2026-09-14 redesign narrowed this one to a Tabs-owned `CoreTabsSize`,
  // which lands in `axes.other` — the same place `CoreChipSize` and
  // `CoreThemeControllerSize` land, and those builders enumerate their ladder
  // the same way. The bar keeps the axis because its tabs carry it: a member
  // composes `TabItem` at its own rung.
  const combos = enumerateAxisCombos([
    ...axisSpecsOf(TABS.axes),
    { axis: 'Size', values: [...sizeData.keys()] },
    { axis: 'Width', values: kTabsWidth },
  ]);
  // Inert on the live file, where the designer's set already carries these
  // four names; for a document holding only a loose `Tabs` COMPONENT it is
  // the resting pose — `CoreTabVariant.defaultVariant` is `pill`, and
  // `expand` defaults to `false`, i.e. `scroll`.
  const mount = mountSet(page, 'Tabs', combos, {
    adoptLooseAs: tabsVariantName('pill', 'scroll', 'md'),
  });
  // The tabs a toggle drives (ordinal > `kTabsAlwaysShown`), per ordinal,
  // across every member — bound to `Show tab N` after `finish()`, when the set
  // exists to own them.
  const toggledTabs: InstanceNode[][] = kTabsLabels.map(() => []);
  // Every `Tab N`, across every member — exposed after `finish()` (see there).
  const allTabs: InstanceNode[] = [];
  for (const comboName of combos) {
    const combo = parseVariantKey(comboName);
    const variant = variantData.get(combo['Variant']);
    if (!variant) throw new Error(`Tabs: no data for combo "${comboName}"`);
    const pill = combo['Variant'] === 'pill';
    const expand = combo['Width'] === 'fill';
    const c = mount.getOrCreate(comboName);
    // The frame around the bar. At `fill` it is bare — the bar IS the frame's
    // width. At `scroll` the PILL member carries the designer's inset
    // (`kTabsScrollInset`) around its track, the only chrome a member has of
    // its own; everything below it is the widget's. The UNDERLINE member is
    // bare at both widths: its inset is the ruled row's own padding (below),
    // so the rule spans the bar while the tabs sit inset — putting the inset
    // here drew the rule 288 wide inside a 320 member, where the designer's
    // divider spanned the whole 320.
    applyPanelCompChrome(
      c,
      'VERTICAL',
      lk,
      expand || !pill ? {} : { pl: kTabsScrollInset, pr: kTabsScrollInset },
    );
    // The underline row's own inset at `scroll` — the same 16 the pill member
    // carries on its frame, moved one node down so the row's bottom stroke
    // (a frame draws its stroke on its bounds, outside its padding) stays the
    // member's full width. `undefined` at `fill` and for the pill, whose row
    // padding is `tabBarPadding` below.
    const rowInset = !pill && !expand ? kTabsScrollInset : undefined;
    // The pill track at `scroll` hugs its tabs (`tabs.dart` — `mainAxisSize:
    // .min`, and the note on the row below), so the member hugs too; the
    // preview width is for the members whose row FILLs it (#4805).
    // g7-preview-only: demo bar width — `tabs.dart` sizes its row by `mainAxisSize` (`.max` when `expand`, else `.min`) and takes its extent from the parent's constraints, so no CoreTabsStyle field states one; the canvas has to pick a width for the tab row and its underline to FILL.
    if (expand || !pill) lockWidth(c, 320);
    // `tabBarPadding` is the PILL variant's alone. Both widgets say so in the
    // same shape: `tabs.dart` puts `Padding(padding: resolved.tabBarPadding)`
    // inside the pill branch only (the underline branch wraps the row bare in
    // a bottom-bordered `DecoratedBox`), and the Web resolver emits
    // `raw['padding'] = tabBarPadding` inside `if (variant == .pill)` only.
    // Applying it to the underline bar put 8px above and 8px below it —
    // 16px Core states there and neither platform paints. It is applied at
    // BOTH widths — the widget pads the track whether or not it expands —
    // where the designer's scroll members carried only the 16 inset above;
    // the stated 2 wins over the drawn 0, and the inset is kept beside it.
    const barPad = pill ? variant.tabBarPadding : null;
    const row = panel('row', 'HORIZONTAL', lk, {
      pl: barPad?.l ?? rowInset, pr: barPad?.r ?? rowInset, pt: barPad?.t, pb: barPad?.b,
      // `tabSpacing` is the bar-level inter-tab gap (`Row(spacing:)`), at
      // both widths — `tabs.dart` bills it whenever the row has more than one
      // child, expanded or not. The variant row states it (`pill` 2,
      // `underline` 20); the flat default is the last resort for a variant
      // row that states none, the order `resolveTabs` folds them in.
      gap: dimVal(optField<number | Dim>(variant, 'tabSpacing') ?? f.tabSpacing),
      // The pill variant's bar is itself a rounded track the pills sit in;
      // the underline variant's bar is bare (the rule lives on each tab).
      //
      // `containerRadius` (8), NOT the pill's own `activeIndicatorRadius`
      // (6). They are two fields and the widget reads them at two nodes:
      // the bar is `DecoratedBox(decoration: BoxDecoration(color:
      // backgroundColor, borderRadius: containerRadius))` and each pill is
      // `AnimatedContainer(decoration: BoxDecoration(… borderRadius:
      // activeIndicatorRadius))`. Reading the pill's value at the bar drew
      // the track at half the stated rounding and left `containerRadius`
      // stated by Core and painted nowhere — and because the two numbers
      // are both on the radius ladder the binding landed, so the node
      // named `Primitives/radius/4` as the source of a corner the design
      // system puts at 8.
      radius: pill ? f.containerRadius.topLeft : undefined,
    });
    // The same `BoxDecoration` also carries the track's fill, and without
    // it the rounding above is invisible: a transparent box has no corner
    // to look at. `variant.backgroundColor` is the pill row's own field
    // (surface-container); the underline variant has no fill at all, which
    // is why this is keyed on the variant rather than always painted.
    //
    // `optField` because only one of the two variant rows carries the key —
    // `variant` is the union of both, so `variant.backgroundColor` does not
    // type-check (see data.ts on the dispatch-table union).
    // The pill track is a content surface on both platforms (`tabs_style.dart`
    // reads `theme.surfaceFor(.content)` for `pill`; the Web twin marks the
    // pill bar `webSurfaceMarkerFor(.content)`). The underline bar paints no
    // fill and is no surface.
    if (pill) {
      applySurfaceMaterial(row, lk, colorData(optField<Color>(variant, 'backgroundColor')), 'content', {
        radius: f.containerRadius.topLeft,
      });
    }
    // Both variants' bars cast nothing at rest and take the cast a style
    // contributes (`resolveInjectedCast` around the tab bar; the bar's
    // `kControlShadowRestMarker`).
    addControlShadow(row, lk);
    // The underline variant's bar is NOT bare. `tabs.dart` wraps the row in
    // `DecoratedBox(border: Border(bottom: BorderSide(color: borderColor,
    // width: borderWidth)))`, and the Web twin puts `border-b` plus that width
    // on the same `role="tablist"` div. It is the tab↔content separator across
    // the whole bar — a different edge from each tab's own bottom border, which
    // is drawn at `activeIndicatorThickness` (2) and is the moving indicator.
    // Core states two thickness fields because there are two rules; drawing
    // only the indicator left this one painted nowhere and the bar read as
    // though the tabs floated over the content.
    //
    // Figma strokes all four sides, so the other three weights go to zero —
    // structure (the edge does not exist), not a design value hardcoded. Same
    // shape as `WindowPanel`'s title bar.
    //
    // `optField` for the colour for the reason the fill above gives: only the
    // `underline` row of the dispatch table carries `borderColor`.
    if (!pill) {
      borderData(
        row,
        lk,
        colorData(optField<Color>(variant, 'borderColor')),
        f.borderWidth,
      );
      row.strokeTopWeight = 0;
      row.strokeLeftWeight = 0;
      row.strokeRightWeight = 0;
      row.setBoundVariable('strokeBottomWeight', lk.stroke(dimVal(f.borderWidth)));
    }
    c.appendChild(row);
    // `expand` is `mainAxisSize: .max` with every tab in an `Expanded` — the
    // bar fills the frame and the tabs share it. Without it the row is `.min`
    // and hugs the tabs, each of which hugs its label — the sizing a fresh
    // frame and an instance of a hugging component already have, so the pill
    // track writes nothing at `scroll`. The underline's rule is the other
    // shape: `tabs.dart` draws it on the `DecoratedBox` AROUND the row, and
    // that box spans the parent's width at BOTH `expand` values (the row
    // hugs inside it, at the reading-direction start); the Web twin puts
    // `w-full` on the ruled `role="tablist"` div in both states. So the
    // ruled row FILLs the member at `scroll` too — the rule spans the bar's
    // full 320, the way the designer's divider did on her scroll members —
    // and only the tabs inside it keep hugging, inset by the row's own
    // padding (`rowInset`) rather than the member's, so the inset moves the
    // tabs and never the rule.
    if (expand || !pill) row.layoutSizingHorizontal = 'FILL';
    for (let i = 0; i < kTabsLabels.length; i++) {
      const ordinal = i + 1;
      // `TabItem` is the designer's own component — composed rather than
      // drawn, so an edit to its padding / radius / per-state colour reaches
      // this bar the way an `Icon` or `Divider` change already does. The
      // first tab is the current one, the way `selectedIndex` rests at 0;
      // the other axes rest (see `tabItemVariantName`).
      const tab = instanceOf(
        page,
        'TabItem',
        tabItemVariantName(combo['Variant'], i === 0, combo['Size']),
      );
      // The designer's instance names. The instances themselves are minted fresh
      // each run (the member was reset above); the name is kept so the canvas
      // reads the same way she drew it.
      tab.name = `Tab ${ordinal}`;
      setTabItemLabel(tab, kTabsLabels[i]);
      row.appendChild(tab);
      allTabs.push(tab);
      if (expand) tab.layoutSizingHorizontal = 'FILL';
      // Bound to the BOOLEAN below, and hidden at rest exactly when that
      // BOOLEAN defaults off, so the node and the property's default say the
      // same thing (`Filter`'s fourth segment). Both come from the same two
      // constants. A tab shown at rest needs no write: a fresh instance is
      // already visible.
      if (ordinal > kTabsAlwaysShown) {
        if (ordinal > kTabsShownAtRest) tab.visible = false;
        toggledTabs[i].push(tab);
      }
    }
  }
  const set = mount.finish();
  // Properties AFTER `finish()`, on the set. `Show tab 4` / `Show tab 5` /
  // `Show tab 6` are the designer's own, adopted by name+type, so their keys
  // and every instance override stay. `Show tab 3` is new: without it a bar
  // could not drop to two tabs.
  //
  // Defaults follow the resting pose, the three tabs the set draws: `Show tab
  // 3` on, 4–6 off. A default that changed the resting rendering would move
  // every instance already placed. That is why 4–6 default off, and the same
  // reasoning gives tab 3 the opposite value.
  //
  // Panel order: on a document that already has 4–6, `Show tab 3` is added
  // last and most likely lands after them (not measured on the live file).
  // The plugin API has no reorder. Recreating 4–6 to fix the order would mint
  // new keys and orphan the overrides on them, so it stays put and a designer
  // drags it up once.
  //
  // The labels are not properties of this set. Each tab's copy is its
  // `TabItem` instance's `Label`, overridden per tab above, which is where
  // `CoreTabItem.label` lives in the code too. So every `Tab N` is EXPOSED:
  // a placed Tabs then lists each tab's own `Label` and `Show count` one level
  // in, the way Fab's pills surface their Button's label — without it the tab
  // copy and the per-tab count were reachable only by drilling into the bar,
  // and redeclaring them here would be a second home for a value `TabItem`
  // already owns. After `finish()` and the binds, because Figma rejects the
  // flag on an instance with no component ancestor (`exposeAll`).
  for (let i = kTabsAlwaysShown; i < kTabsLabels.length; i++) {
    const ordinal = i + 1;
    const prop = defineProp(set, `Show tab ${ordinal}`, 'BOOLEAN', ordinal <= kTabsShownAtRest);
    for (const tab of toggledTabs[i]) bindVisibleProp(tab, prop);
  }
  exposeAll(allTabs);
  // `defaultSetLayout` over `vStackSet` — see the note at Breadcrumb's return.
  return set;
}

// ─── StepItem ────────────────────────────────────────────────────────────────

// Data-driven from coui_core STEP_ITEM: the status-independent row (`minHeight`,
// `padding`, the two gaps, the glyph's size, the two type roles) are the flat
// `fields`, and what a status changes — the colour of the glyph, of the title
// and of the trailing note — is one row of `variants.defaultsByStatus`, read
// through the Status axis so a fifth status Core adds paints itself.
//
// One axis, `Status`, because the row's whole look is the status: the widget
// takes `status` and nothing else that changes chrome (`StepItem` has no
// hover / focus / disabled — a step row reports where a step stands, it is not
// pressed). The set's default member is the one `CoreStepStatus.defaultStatus`
// names.
//
// The row is `Icon · Gap · Expanded(title) · [Gap · trailing]`, drawn as an
// outer row (glyph, then the text body) and an inner row (title, then the
// note). Two rows rather than one because the widget states TWO gaps —
// `iconTitleGapStyle` between the glyph and the title, `titleTrailingGapStyle`
// between the title and the note — and an auto-layout frame has one
// `itemSpacing`. A hidden note takes its gap with it, which is the widget's
// `if (note != null) …`.
//
// The glyph is the status's own and is not a swap slot: `CoreStepStatus.glyph`
// answers it once for both platforms ("the glyph is the status's identity, not
// a chrome choice, so it has no override slot"), and a swappable glyph would
// let a canvas say a `done` row wears a cross. The vocabulary is spelled here
// because the exporter carries the statuses and not their glyphs; a status
// this table does not know throws, so a fifth status fails the harness on the
// machine that added it and never reaches a canvas with a wrong circle.
//
// The title is one line that ends in an ellipsis rather than wrapping
// (`maxLines: 1`, `overflow: ellipsis`) — the truncation is set on the node, so
// a long `Title` is cut the way the widget cuts it.
//
// `Title` and `Trailing` are TEXT properties and `Show trailing` a BOOLEAN. The
// note is `String?` in the contract — absent draws nothing — and the set shows
// it at rest, the way MenuItem shows `Show shortcut`: the note is the cell the
// status colours exist for (three of the four rows differ from their neighbour
// only there), so a set that rested without it would draw four rows whose third
// text tier no member shows.
const kStepItemTitle = '계정 정보';
const kStepItemTrailing = '완료';
// `CoreStepStatus.defaultStatus` — a row nobody has reached. The exporter does
// not carry an enum's default member for an `axes.other` enum, so the name is
// spelled once here, next to the Dart constant it mirrors.
export const kStepItemDefaultStatus = 'todo';
// `CoreStepStatus.glyph`, per status.
export const kStepStatusGlyphs: Readonly<Record<string, string>> = {
  done: 'circle-check',
  current: 'circle-dot',
  todo: 'circle',
  failed: 'circle-x',
};
function stepStatusGlyph(status: string): string {
  const glyph = kStepStatusGlyphs[status];
  if (glyph === undefined) {
    throw new Error(
      `StepItem: no glyph for status "${status}". Add it to \`kStepStatusGlyphs\` ` +
        'in navigation.ts with the Lucide icon `CoreStepStatus.glyph` returns for it ' +
        '(coui_core/lib/src/component/contracts/steps/step_status.dart), and to ' +
        `\`gen-icons.ts\`'s ICON_NAMES. Known: ${Object.keys(kStepStatusGlyphs).join(', ')}.`,
    );
  }
  return glyph;
}

// `CoreStepsVariant.list` — the one `Steps` layout that is always vertical.
const kStepsListVariant = 'list';
// `Steps.vertical`'s constructor default.
const kStepsDefaultVertical = 'true';
// The width the horizontal numbered member is drawn at. A horizontal `Steps`
// takes the width of what hosts it and its connectors fill what the circles
// leave, so the preview needs a width to show them filling. A preview choice,
// not a Style value — nothing in `CoreStepsStyle` states it.
const kStepsHorizontalPreviewWidth = 600;
// The copy each status shows in the list member — a name and the note at the
// end of the row, the shape a pipeline run takes (`CoreStepData.title` /
// `.trailing`). Preview copy, not a Style value.
const kStepsListCopy: Readonly<Record<string, { title: string; trailing: string }>> = {
  done: { title: '의존성 설치', trailing: '12초' },
  current: { title: '테스트 실행', trailing: '41초' },
  todo: { title: '배포', trailing: '대기 중' },
  failed: { title: '린트', trailing: '종료 코드 1' },
};

function stepStatusMembers(builder: string): readonly string[] {
  const status = STEPS.axes.other.find((o) => o.enum === 'CoreStepStatus');
  if (!status) {
    throw new Error(
      `${builder}: CoreStepStatus is gone from the exported \`steps.axes.other\` — the ` +
        'canvas draws a Status that nothing in the contract now backs.',
    );
  }
  return status.members;
}

function buildStepItem(page: PageNode, lk: VarLookup): ComponentSetNode {
  const f = STEP_ITEM.fields;
  // One axis, so `planAxisGrid` has no grid to read and `defaultSetLayout`'s
  // lead is not honoured: the set wraps in the order its members were made.
  // The member in the top-left corner is the one Figma hands a new instance,
  // and that has to be the status the code rests on — so it is made first.
  const allStatuses = stepStatusMembers('StepItem');
  if (!allStatuses.includes(kStepItemDefaultStatus)) {
    throw new Error(
      `StepItem: \`kStepItemDefaultStatus\` is "${kStepItemDefaultStatus}" but ` +
        `CoreStepStatus makes ${JSON.stringify(allStatuses)}.`,
    );
  }
  const statuses = [kStepItemDefaultStatus, ...allStatuses.filter((s) => s !== kStepItemDefaultStatus)];
  const rows = new Map(Object.entries(STEP_ITEM.variants.defaultsByStatus));
  const names = statuses.map((s) => composeVariantName([['Status', s]]));
  const mount = mountSet(page, 'StepItem', names);
  const titleText = textStyleData(f.titleStyle);
  const trailingText = textStyleData(f.trailingStyle);
  const titles: TextNode[] = [];
  const trailings: TextNode[] = [];
  for (let i = 0; i < statuses.length; i++) {
    const status = statuses[i];
    const row = rows.get(status);
    if (!row) {
      throw new Error(
        `StepItem: \`step_item.variants.defaultsByStatus\` has no \`${status}\` row — ` +
          'the Status axis names a status the style does not colour.',
      );
    }
    const c = mount.getOrCreate(names[i]);
    applyPanelCompChrome(c, 'HORIZONTAL', lk, {
      pl: f.padding.l,
      pr: f.padding.r,
      pt: f.padding.t,
      pb: f.padding.b,
      gap: f.iconTitleGapStyle.size,
    });
    c.counterAxisAlignItems = 'CENTER';
    // `ConstrainedBox(minHeight:)`. The row's own height, not a rung of the
    // control ladder, so it binds the PRIMITIVE size and a density axis does not
    // move it (its padding and gap still do) — `lk.controlHeightOrNull` would
    // bind the density row that 32 also is on the ladder.
    const minHeight = dimVal(f.minHeight);
    c.minHeight = minHeight;
    const minHeightVar = lk.sizeOrNull(minHeight);
    if (minHeightVar) c.setBoundVariable('minHeight', minHeightVar);
    // A row takes the width of the list that hosts it, so the set draws it at a
    // width that shows the note pinned to the row's end.
    // g7-preview-only: the hosting list's width, 240 — room for a row in a card.
    lockWidth(c, 240);

    c.appendChild(
      makeIcon(
        stepStatusGlyph(status),
        lk,
        glyphOpts(lk, colorData(row.iconStyle.color), f.iconStyle.size, 'size'),
      ),
    );

    const body = panel('body', 'HORIZONTAL', lk, { gap: f.titleTrailingGapStyle.size });
    body.counterAxisAlignItems = 'CENTER';
    c.appendChild(body);
    body.layoutSizingHorizontal = 'FILL';

    const title = makeLabel(
      kStepItemTitle,
      lk,
      typographyColorOpts(lk, titleText, colorData(row.titleStyle.color)),
    );
    title.name = 'title';
    body.appendChild(title);
    title.layoutSizingHorizontal = 'FILL';
    title.textTruncation = 'ENDING';
    title.maxLines = 1;
    titles.push(title);

    const trailing = makeLabel(
      kStepItemTrailing,
      lk,
      typographyColorOpts(lk, trailingText, colorData(row.trailingStyle.color)),
    );
    trailing.name = 'trailing';
    body.appendChild(trailing);
    trailings.push(trailing);
  }
  const set = mount.finish();
  const titleProp = defineProp(set, 'Title', 'TEXT', kStepItemTitle);
  for (const t of titles) bindTextProp(t, titleProp);
  const showTrailingProp = defineProp(set, 'Show trailing', 'BOOLEAN', true);
  const trailingProp = defineProp(set, 'Trailing', 'TEXT', kStepItemTrailing);
  for (const t of trailings) {
    bindVisibleProp(t, showTrailingProp);
    bindTextProp(t, trailingProp);
  }
  defaultSetLayout(set, { Status: kStepItemDefaultStatus });
  return set;
}

// ─── Steps ───────────────────────────────────────────────────────────────────

// Data-driven from coui_core STEPS.fields. The circle fill and the
// connector's fill are separate colour fields — `activeIndicatorColor` for a
// completed or current circle, `indicatorColor` plus the ring
// (`indicatorBorderColor` / `indicatorBorderWidth`) for an upcoming one;
// `activeConnectorColor` for the connector leaving a completed step and
// `connectorColor` for every other one. The CHECK glyph's size is the real
// resolver's own formula (`checkIconStyle` = `indicatorSize *
// iconSizeRatio`, see `steps_style.dart`), not a guessed literal.
//
// A step is an indicator AND the copy beside it, and this builder used to draw
// only the indicator. `_buildContent` is not optional decoration: every step
// renders `Text(item.title, style: (isCurrent ? currentTitleTextStyle :
// titleTextStyle).copyWith(color: titleColor))` and, when the caller supplied
// one, `Text(item.description!, style: descriptionTextStyle.copyWith(color:
// descriptionColor))`. Omitting them left `titleStyle` (titleSmall, 16) and
// `descriptionStyle` (bodySmall, 13) stated by the data and absent from the
// canvas — a picture of a progress bar rather than of Steps. The text slots
// (`titleStyle`, the current step's `currentTitleStyle` overlay,
// `descriptionStyle`) and the two content colours are all real CoreStepsStyle
// fields.
//
// The number inside a circle reads `labelStyle` too, not the check icon's size.
// `_buildIndicatorCircle` branches on completion: the check is an `Icon` sized
// by `checkIconStyle`, the number is a `Text` styled by `labelTextStyle`
// (labelLarge + w700). Sizing the number by the icon formula only ever agreed by
// arithmetic — 28 × 0.5 and labelLarge's 14 are the same number today, and a
// change to either token would have separated them silently.
//
// Structure follows `_buildHorizontal`: a `Row` of per-step `Column`s, each
// holding an indicator `Row` (circle, then the connector for every step but the
// last) above its content. The outer `Row` has NO `spacing` — what separates two
// steps is the connector plus the two `indicatorConnectorGapStyle` gaps around
// it, all of which sit inside the indicator row, so binding a gap on the root as
// well would add a fourth space no field states.
//
// ─── Both orientations, because two fields only exist in one of them ────────
//
// `Steps` takes `vertical: bool` and branches on it (`_buildVertical` /
// `_buildHorizontal`), and only the horizontal branch was drawn. That left two
// stated values with no node to live on:
//
//   · `stepPadding` (bottom 32) is the VERTICAL layout's per-step inset —
//     `Padding(padding: i < last ? stepPadding : .zero)` around the content of
//     each step. `stepPaddingHorizontal` (top 12 / end 16) is the other
//     branch's, and they are separate fields precisely because a column of
//     steps needs room BELOW each one where a row needs it beside.
//   · `indicatorContentGapStyle` (20) is `Gap(gapStyle:
//     indicatorContentGapStyle)` between the indicator column and the copy —
//     and it appears in `_buildVertical` ONLY. The horizontal branch stacks
//     content under the indicator row with no gap widget between them, so
//     there was nowhere in a horizontal-only preview for this field to be.
//
// So the `Vertical` axis is not a second picture of the same thing: it is the
// only place two of this component's fields exist at all. `Stepper` gained a
// layout axis for the identical reason (see VARIANT_RENAMES) — a role stated by
// Core and reachable only through the branch nobody drew.
//
// The axis is named for the contract field (`Steps(vertical: …)`) and is boolean
// for the same reason the state axes in this file are: the widget's knob is a
// `bool`, not an orientation enum (`Stepper.orientation` IS an enum, which is
// why its axis reads differently).
//
// ─── The Variant axis, and the list member ──────────────────────────────────
//
// `Steps(variant:)` is `CoreStepsVariant`: `numbered` is everything above, and
// `list` stacks a `StepItem` per step — a status glyph, a one-line name, a note
// pinned to the end — with no circle, no connector and no description. The axis
// is read from `steps.axes.variant`; the builder draws the two layouts it
// knows (`drawStepsList` is the list) and a member Core adds gets the numbered
// drawing, so a third layout has to be taught here before it can be right.
//
// The set is THREE members, not four: `list` is always vertical and ignores
// `vertical`, so `Variant=list, Vertical=false` would be a second picture of
// `Variant=list, Vertical=true`. The set is therefore sparse on `Vertical`,
// which is not a promoted axis (G10 counts `Variant`, not `Vertical`).
//
// The members the set had before the axis are `Vertical=false|true`; they are
// the numbered layout, and `VARIANT_RENAMES` carries them onto
// `Variant=numbered, Vertical=…` so their keys — and every instance placed from
// them — survive.
//
// The numbered members draw a fourth step, a FAILED one: `CoreStepStatus.failed`
// is a state a step states (`CoreStepData.status`), its circle is
// `failedIndicatorColor` with a cross in `failedLabelColor`, and with no node
// that wore them both fields were stated by Core and absent from the canvas.
//
// Shape change: this was a single COMPONENT and is now a COMPONENT_SET, which
// Figma cannot convert in place — see the `Steps` entry in
// `STRUCTURAL_MIGRATIONS` (`src/renames.ts`), without which the old node stays
// on the page as a same-named duplicate.
//
// The vertical branch's last step keeps the full `stepPadding`, exactly as the
// horizontal one keeps the full `stepPaddingHorizontal` (see the note at the end
// of this comment): the widget's `EdgeInsets.zero` for that one step is written
// in `steps.dart`, not in the Style, so `components.json` does not carry it and
// writing it here would be a pixel this builder invented.
//
// No state axes: CoreStepsStyle carries no clickable/disabled/hover/focus
// chrome at all (its `activeIndicatorColor`/`activeLabelColor` are step
// PROGRESS, not interaction state, and are already rendered inline — the
// completed step is drawn completed).
//
// The middle step wears the SAME indicator colours as the completed one, and
// that is the widget's own split rather than a missing state: `isActive =
// isCompleted || isCurrent`, so `_buildIndicatorCircle` fills both from
// `activeIndicatorColor` and labels both from `activeLabelColor`; what separates
// them is the check icon vs the step number. An outlined middle circle (no fill,
// a primary border, a primary glyph) stood here on the reading that there is a
// third "current-but-outlined" state — there is none, and the widget's
// `BoxDecoration` carries no border at all, so those were invented pixels
// rather than unstated ones.
//
// The connector's own rendered length (24) is this static preview's layout
// choice, not a Style default (#3755 OQ-2) — the real one is `Expanded`, which
// has no static width. The circle's round shape is a non-field —
// same as RadioGroup's indicator shape (form.ts) — and carries its reason at the
// call site.
//
// Every step's content carries the full `stepPaddingHorizontal`, including the
// last. The widget gives the last step a trailing inset of zero, but that zero
// is `CoreEdgeInsets.directional`'s omitted `end` inside `steps_style.dart` —
// a resolver-derived value the exporter never sees, so `components.json` does
// not state it. Writing it here would be a pixel this builder invented, which
// is the thing it is being converted away from; the cost is 16px of extra room
// past the last step in the preview.
function buildSteps(page: PageNode, lk: VarLookup): ComponentSetNode {
  const f = STEPS.fields;
  // The members: every `CoreStepsVariant` × the numbered layout's two
  // orientations, except that the list has one. `list` is always vertical and
  // ignores `vertical` (`Steps(variant: list, vertical: false)` draws the same
  // column), so a `Variant=list, Vertical=false` member would be a second
  // picture of the first — three members, not four.
  const variantAxis = STEPS.axes.variant;
  const members: { variant: string; vertical: boolean }[] = [];
  for (const variant of variantAxis.members) {
    if (variant === kStepsListVariant) {
      members.push({ variant: variant, vertical: true });
      continue;
    }
    members.push({ variant: variant, vertical: false });
    members.push({ variant: variant, vertical: true });
  }
  const memberName = (m: { variant: string; vertical: boolean }): string =>
    composeVariantName([
      ['Variant', m.variant],
      ['Vertical', m.vertical ? 'true' : 'false'],
    ]);
  const mount = mountSet(page, 'Steps', members.map(memberName));
  const checkGlyphSize = dimVal(f.indicatorSize) * dimVal(f.iconSizeRatio);
  const labelText = textStyleData(f.labelStyle);
  const titleText = textStyleData(f.titleStyle);
  // The current step's title merges `currentTitleStyle` (Bold) onto
  // `titleStyle` (SemiBold) the way both resolvers do.
  const currentTitleText = mergeTextStyleData(titleText, textStyleData(f.currentTitleStyle));
  const descText = textStyleData(f.descriptionStyle);
  // `title` / `description` are `CoreStepData` fields — the caller's copy, like
  // every other string in this file. The three used here are the ones the
  // `Steps` doc comment itself walks through.
  type StepKind = 'done' | 'current' | 'todo' | 'failed';
  const steps: {
    kind: StepKind;
    glyph?: string;
    icon?: string;
    fill: ColorData | null;
    fg: ColorData;
    /** The ring of an upcoming indicator; the others draw none. */
    ring?: { color: ColorData | null; width: number | Dim };
    titleColor: ColorData | null;
    title: string;
    description: string;
  }[] = [
    {
      kind: 'done',
      icon: 'check',
      fill: colorData(f.activeIndicatorColor),
      fg: colorData(f.activeLabelColor)!,
      titleColor: colorData(f.titleColor),
      title: '계정 만들기',
      description: '이메일과 비밀번호',
    },
    // Current (not-yet-complete) step — the SAME two colours as the completed
    // one, because `_buildIndicatorCircle` keys its fill on `isActive` and
    // `isActive = isCompleted || isCurrent` (steps.dart). Only the CHILD differs:
    // `isCompleted` picks the check icon, everything else the step number.
    {
      kind: 'current',
      glyph: '2',
      fill: colorData(f.activeIndicatorColor),
      fg: colorData(f.activeLabelColor)!,
      titleColor: colorData(f.titleColor),
      title: '이메일 인증',
      description: '받은편지함을 확인해 주세요',
    },
    // An upcoming step: the page's own fill inside a ring, a quiet number and
    // a quiet title — it reads as not yet reached, where the two above are.
    {
      kind: 'todo',
      glyph: '3',
      fill: colorData(f.indicatorColor),
      fg: colorData(f.inactiveLabelColor)!,
      ring: { color: colorData(f.indicatorBorderColor), width: f.indicatorBorderWidth },
      titleColor: colorData(f.inactiveTitleColor),
      title: '프로필 완성',
      description: '이름과 사진',
    },
    // A step that ran and stopped — `CoreStepStatus.failed`, which a step states
    // through `CoreStepData.status` and no index can mean. Its circle is the
    // `failedIndicatorColor` fill with the cross (`CoreStepStatus.indicatorGlyph`)
    // in `failedLabelColor`, sized as the check is (`failedIconStyle` is
    // `checkIconStyle` recoloured). It is drawn as a fourth step rather than
    // swapped into the third: the third is the not-reached sample, and a failed
    // step is a state in its own right, so replacing either would take a state
    // off the canvas to make room for one. Its title is the full-strength one —
    // only an upcoming step reads quiet.
    {
      kind: 'failed',
      icon: 'x',
      fill: colorData(f.failedIndicatorColor),
      fg: colorData(f.failedLabelColor)!,
      titleColor: colorData(f.titleColor),
      title: '게시',
      description: '빌드 실패',
    },
  ];
  // One step's indicator circle — identical in both orientations
  // (`_buildIndicatorCircle` takes no orientation argument).
  const makeCircle = (s: (typeof steps)[number]): FrameNode => {
    // `CoreStepsStyle.indicatorBorderRadius` (same field-promotion Stepper's
    // ring got for the same RULE D reason) — the indicator is still a
    // literal circle by default (`steps.dart#_buildIndicatorCircle`'s
    // `shape: BoxShape.circle`), but a caller override now reaches this
    // node the same way `indicatorSize` already did.
    const circle = panel('circle', 'HORIZONTAL', lk, {
      radius: f.indicatorBorderRadius.topLeft,
    });
    circle.primaryAxisAlignItems = 'CENTER';
    circle.counterAxisAlignItems = 'CENTER';
    if (s.fill) fillData(circle, lk, s.fill);
    // The ring of an upcoming indicator — `inactiveIndicatorContainerStyle`'s
    // `borderColor` / `borderWidth`. A frame's stroke sits INSIDE, so the
    // circle stays `indicatorSize` square, as the widget's box does.
    if (s.ring) borderData(circle, lk, s.ring.color, s.ring.width);
    circle.appendChild(
      s.icon
        ? makeIcon(s.icon, lk, glyphOpts(lk, s.fg, checkGlyphSize))
        : makeLabel(s.glyph!, lk, typographyColorOpts(lk, labelText, s.fg)),
    );
    bindSize(circle, lk, f.indicatorSize, f.indicatorSize);
    return circle;
  };

  // The copy beside (vertical) or below (horizontal) the indicator —
  // `_buildContent` is also orientation-blind; only the inset around it differs,
  // and that inset is a different FIELD per orientation rather than a different
  // value of one.
  const makeContent = (s: (typeof steps)[number], inset: PadData): FrameNode => {
    const content = autoFrame('content', 'VERTICAL');
    // The inset is passed straight through to `bindPad`, which is the one place
    // a logical `start`/`end` becomes Figma's physical left/right.
    bindPad(content, lk, inset);
    const titleOpts = typographyColorOpts(
      lk,
      s.kind === 'current' ? currentTitleText : titleText,
      s.titleColor,
    );
    const title = makeLabel(s.title, lk, titleOpts);
    title.name = 'title';
    content.appendChild(title);
    const description = makeLabel(
      s.description,
      lk,
      typographyColorOpts(lk, descText, colorData(f.descriptionColor)),
    );
    description.name = 'description';
    content.appendChild(description);
    return content;
  };

  // The connector leaving step `s` — a Divider that FILLS the room its host
  // leaves (`Expanded(child: Divider(...))`), not a rule of a length this
  // builder picked. The one leaving a completed step is the filled-in
  // `activeConnectorColor`; every other one keeps `connectorColor`.
  const makeConnector = (
    host: FrameNode,
    s: (typeof steps)[number],
    vertical: boolean,
  ): InstanceNode =>
    hostedDivider(page, lk, host, {
      vertical,
      color: colorData(s.kind === 'done' ? f.activeConnectorColor : f.connectorColor),
      forwarded: { thickness: f.connectorThickness },
    });

  // `variant: list` — `Column(stretch)` of `StepItem`, one per status. The rows
  // are INSTANCES of the `StepItem` set, not rectangles that resemble it: the
  // widget composes `StepItem(stepItemStyle: style.stepItemStyle)` and the row's
  // look is its own (`step_item` states it; `steps.stepItemStyle` is the partial
  // the list lays under every row, empty today, so there is nothing to restate
  // on the instance — see `figma_unread_fields_allowlist.json`). Each row takes
  // the copy a build run would show: a name and the note pinned to the end.
  const listStatuses = stepStatusMembers('Steps');
  const drawStepsList = (c: ComponentNode, rows: InstanceNode[]): void => {
    // A list takes the width of the column that hosts it, so the set draws it at
    // a width that shows each note pinned to the row's end — the same 240 the
    // `StepItem` set draws a row at.
    // g7-preview-only: the hosting column's width, 240 — the StepItem set's own.
    lockWidth(c, 240);
    for (let i = 0; i < listStatuses.length; i++) {
      const status = listStatuses[i];
      const row = instanceOf(
        page,
        'StepItem',
        bestVariantName(page, 'StepItem', { Status: status }),
      );
      row.name = `Step ${i + 1}`;
      c.appendChild(row);
      row.layoutSizingHorizontal = 'FILL';
      const copy = kStepsListCopy[status] ?? { title: `Step ${i + 1}`, trailing: '' };
      setInstanceTextNamed(row, 'Title', copy.title);
      setInstanceTextNamed(row, 'Trailing', copy.trailing);
      rows.push(row);
    }
  };
  // The list member's rows, collected so each can be exposed once the set exists.
  const listRows: InstanceNode[] = [];
  for (const o of members) {
    const c = mount.getOrCreate(memberName(o));
    applyPanelCompChrome(c, o.vertical ? 'VERTICAL' : 'HORIZONTAL', lk, {});
    if (o.variant === kStepsListVariant) {
      drawStepsList(c, listRows);
      continue;
    }
    if (!o.vertical) {
      // `Row(crossAxisAlignment: .start)` — a step with a two-line description
      // must not drag its neighbour's indicator down with it.
      c.counterAxisAlignItems = 'MIN';
      // The row has a width of its own, so the connectors have room to fill.
      // g7-preview-only: the hosting row's width, 600 — the width the copy draws it at.
      lockWidth(c, kStepsHorizontalPreviewWidth);
    }
    for (let i = 0; i < steps.length; i++) {
      const s = steps[i];
      const last = i === steps.length - 1;
      if (o.vertical) {
        // `_buildVertical`: `Row(min, stretch) [Column[circle, Gap, Expanded(
        // Divider(vertical)), Gap], Gap(indicatorContentGapStyle),
        // Padding(stepPadding, content)]`. The row carries the
        // indicator↔content gap as its `itemSpacing`: it has exactly those two
        // children, so the widget's single `Gap` between them and an auto-layout
        // spacing are the same distance in the same place.
        const row = panel('step', 'HORIZONTAL', lk, {
          gap: f.indicatorContentGapStyle.size,
        });
        row.counterAxisAlignItems = 'MIN';
        // The two `Gap`s around the connector: one is the column's spacing, the
        // other the padding under the line, so the line is 4 short of the step's
        // bottom whatever the step's height is. The last step has no connector
        // and so neither.
        const indicatorColumn = panel('indicator', 'VERTICAL', lk, {
          gap: f.indicatorConnectorGapStyle.size,
          ...(last ? {} : { pb: f.indicatorConnectorGapStyle.size }),
        });
        indicatorColumn.counterAxisAlignItems = 'CENTER';
        row.appendChild(indicatorColumn);
        row.appendChild(makeContent(s, f.stepPadding));
        c.appendChild(row);
        indicatorColumn.appendChild(makeCircle(s));
        if (!last) {
          // `Expanded` — the column stretches to the step's height and the line
          // takes what the circle and the two gaps leave. A hugging column would
          // size to the circle and the line would have nothing to fill.
          indicatorColumn.layoutSizingVertical = 'FILL';
          makeConnector(indicatorColumn, s, true);
        }
        continue;
      }
      // `_buildHorizontal`: `Expanded(Column[Row[circle, Gap, Expanded(Divider),
      // Gap], content])` — every step but the last shares the row, and the line
      // inside each takes what its circle and the two gaps leave. The last step
      // hugs; nothing follows it.
      const column = autoFrame('step', 'VERTICAL');
      c.appendChild(column);
      if (!last) column.layoutSizingHorizontal = 'FILL';
      // `indicatorConnectorGapHorizontalStyle` is the distance either side of
      // the line; the last step has no line, so its row keeps the base gap the
      // vertical column states (a single child has no distance to speak of).
      const rowGap = last
        ? f.indicatorConnectorGapStyle.size
        : f.indicatorConnectorGapHorizontalStyle.size;
      const indicatorRow = panel('indicator', 'HORIZONTAL', lk, {
        gap: rowGap,
        ...(last ? {} : { pr: f.indicatorConnectorGapHorizontalStyle.size }),
      });
      indicatorRow.counterAxisAlignItems = 'CENTER';
      column.appendChild(indicatorRow);
      if (!last) indicatorRow.layoutSizingHorizontal = 'FILL';
      indicatorRow.appendChild(makeCircle(s));
      if (!last) makeConnector(indicatorRow, s, false);
      column.appendChild(makeContent(s, f.stepPaddingHorizontal));
    }
  }
  const set = mount.finish();
  // The list's rows surface on a placed Steps, the way Tabs surfaces each
  // `TabItem`: a row's `Title`, `Trailing` and `Status` are its own properties,
  // and without the flag they were reachable only by drilling into the list.
  // After `finish()` because Figma rejects the flag on an instance with no
  // component ancestor (`exposeAll`).
  exposeAll(listRows);
  // The member a freshly placed instance holds is the code's default —
  // `Steps(variant: numbered, vertical: true)`.
  defaultSetLayout(set, {
    Variant: variantAxis.default ?? members[0].variant,
    Vertical: kStepsDefaultVertical,
  });
  return set;
}

// ─── Link ────────────────────────────────────────────────────────────────────

// Data-driven from coui_core LINK: `variants.defaultsByVariant` (the text and
// underline colour of each `CoreLinkVariant`, read through the Variant axis so a
// third member Core adds paints itself) and the flat `labelStyle` /
// `clickableStyle` fields.
//
// Axes: Variant (the contract's `CoreLinkVariant`) × Underline (the widget's
// `underline` flag — an axis of its own, because "muted with an underline" has to
// be sayable) × Focus (`clickableStyle.focusOutlineStyle`, on the root — the
// Link's clickable box, whose radius comes from `clickableStyle.borderRadius`).
//
// There is no Disabled axis: the widget has no disabled state at all (no
// `enabled`, nothing forwarded to the `Clickable`), so a Disabled member drew a
// state the code cannot reach. There is no Hover / Pressed axis either — a link
// shows `interactionTextDecoration` while hovered, pressed or focused, and the
// picture is the same in all three, so Focus (which also has a ring) stands for
// them and a member that renders identically is not added. A Focus member is
// therefore underlined whatever its `Underline` says.
//
// The underline is a 1px bar inside the label's own box, just above its bottom
// edge, not a flow child under it. The widget draws the FONT's underline — it
// sits inside the text box, so the member's height does not grow with it — and
// Figma's text underline cannot stand in: `textDecoration` is a property of the
// TEXT node, and the `Child` property binds one text across every member, so it
// would underline all eight. The bar is therefore a stand-in for a line the font
// owns; its real thickness and position are the font's.
//
// Component property: `child` (`W?`) is the caller's label widget, and this
// builder fills it with a text node — so it becomes a TEXT property whose
// default is the placeholder copy already shown. Declared on the SET (after
// `finish()`, when the members have a parent), because `addComponentProperty`
// on a set member throws; every variant's label binds the same id.
//
// The property carries the SLOT's name (`Child`), not a description of what the
// demo happens to put in it (`Label`). A property name that does not match a
// contract member is not that member's affordance — it reads in the panel as an
// extra knob the component invented, and nothing then connects the words a
// designer edits to `Link(child: …)`. Every other builder that exposes a `child`
// text node names it `Child` for the same reason.
//
// TEXT, not INSTANCE_SWAP: the node this slot renders as is text. Swapping it
// would need a `Text` component in the REGISTRY, which the owner decided
// against — so TEXT is the ceiling here, and it is a real one (the words are
// the whole of what this slot shows).
//
// No BOOLEAN paired with it, unlike the optional slots elsewhere that can be
// turned off. `W?` here does not mean "may render nothing": `link.dart` resolves
// it as `child ?? Text(href)`, so passing null substitutes the href as the label
// rather than removing the node. A visibility toggle would put a state on the
// canvas — an empty Link — that the widget has no way to reach.
// (It would also silently destroy the binding above: `bindVisibleProp` and
// `bindTextProp` each assign `componentPropertyReferences` whole, so the second
// call on one node drops the first one's key.)

// The stand-in underline: its thickness, and how far it sits above the bottom
// of the label's box. Canvas approximations of the font's own line (about 1.2
// thick, about 1.9 below the baseline at 16px), not design values — see above.
const kLinkUnderlineBarThickness = 1;
const kLinkUnderlineBarInset = 2;
// The glyphs the two icon slots show when turned on — what the docs' example
// passes (a link glyph before, an external-link glyph after). Display copy for
// the preview, not chrome: the slots are `W?` in the code and empty by default.
const kLinkLeadingGlyph = 'link-2';
const kLinkTrailingGlyph = 'external-link';

function buildLink(page: PageNode, lk: VarLookup): ComponentSetNode {
  const f = LINK.fields;
  const clickable = f.clickableStyle;
  const label = textStyleData(f.labelStyle);
  const variantRows = new Map(Object.entries(LINK.variants.defaultsByVariant));
  // What a link shows while hovered, pressed or focused.
  const revealsUnderline = f.interactionTextDecoration.choice === 'underline';
  const kinds = LINK.axes.variant?.members ?? [];
  const axes: StateAxis[] = ['Focus'];
  const combos = stateCombos(axes);
  const memberName = (kind: string, underlined: boolean, flags: StateFlags): string =>
    variantName(`Variant=${kind}, Underline=${underlined}`, stateSuffix(axes, flags));
  const names: string[] = [];
  for (const kind of kinds) {
    for (const underlined of [false, true]) {
      for (const flags of combos) names.push(memberName(kind, underlined, flags));
    }
  }
  const mount = mountSet(page, 'Link', names);
  // The icon slots' swap defaults, read before the members are drawn so the
  // glyphs land at `iconStyle.size` (see `IconOpts.fromVariant`).
  const leadingSwap = iconSwapDefault(page, 'Link', 'Leading', iconMainId(page));
  const trailingSwap = iconSwapDefault(page, 'Link', 'Trailing', iconMainId(page));
  const leadingSlots: { holder: FrameNode; content: InstanceNode }[] = [];
  const trailingSlots: { holder: FrameNode; content: InstanceNode }[] = [];
  const labels: TextNode[] = [];
  let firstComp: ComponentNode | null = null;
  for (const kind of kinds) {
    const row = variantRows.get(kind);
    if (!row) throw new Error(`Link: no data for variant "${kind}"`);
    for (const underlined of [false, true]) {
      for (const flags of combos) {
        const c = mount.getOrCreate(memberName(kind, underlined, flags));
        if (!firstComp) firstComp = c;
        // The whole Link is a `Clickable` in the widget. It is a wrapper with no
        // chrome of its own beyond what `clickableStyle` resolves to, and a
        // Figma instance cannot host the child it wraps, so there is no node to
        // instantiate — the radius and the Focus ring below ARE that
        // Clickable's resolved chrome, drawn on this root.
        // The gap is the label ↔ icon one; with both slots off (the default)
        // there is nothing for it to space.
        applyPanelCompChrome(c, 'HORIZONTAL', lk, {
          radius: clickable.borderRadius.topLeft,
          gap: f.iconLabelGapStyle.size,
        });
        // The row centres its icons on the label, as `Row` does on Flutter and
        // `items-center` on Web.
        c.counterAxisAlignItems = 'CENTER';
        // One optional icon slot: the holder carries `Show …` (the slot being
        // absent — the widget's `null`), the glyph inside it the swap. The
        // icon takes the variant's text colour, which is what an icon with no
        // colour of its own does in the code.
        const iconSlot = (
          slot: 'leading' | 'trailing',
          glyph: string,
          fromVariant: ComponentNode | null,
        ): { holder: FrameNode; content: InstanceNode } => {
          const icon = makeIcon(glyph, lk, {
            ...glyphOpts(lk, colorData(row.color), f.iconStyle.size, 'size'),
            fromVariant,
          });
          // The cell states its step by name, as the designer's copy does
          // (#6579): `iconStyle.size` is a `CoreIconSize` step, so a token
          // edit reaches the slot instead of stopping at a typed 16.
          const iconSize = lk.iconSizeOrNull(dimVal(f.iconStyle.size));
          if (iconSize) {
            icon.setBoundVariable('width', iconSize);
            icon.setBoundVariable('height', iconSize);
          }
          const holder = autoFrame(slot, 'HORIZONTAL');
          icon.name = `${slot} content`;
          holder.appendChild(icon);
          c.appendChild(holder);
          // Off at rest, matching the BOOLEAN's default.
          holder.visible = false;
          return { holder, content: icon };
        };
        leadingSlots.push(iconSlot('leading', kLinkLeadingGlyph, leadingSwap.variant));
        // The label and its underline share a box, so the bar runs under the
        // words only — the underline is the label's text decoration, not the
        // row's, on both platforms.
        const labelBox = autoFrame('label', 'HORIZONTAL');
        c.appendChild(labelBox);
        const text = makeLabel(
          '자세히 보기',
          lk,
          textLabelOpts(lk, label, colorData(row.color)),
        );
        labelBox.appendChild(text);
        labels.push(text);
        let bar: RectangleNode | null = null;
        if (underlined || (flags.Focus && revealsUnderline)) {
          bar = figma.createRectangle();
          bar.name = 'underline';
          bar.resize(Math.max(text.width, 1), kLinkUnderlineBarThickness);
          fillData(bar, lk, colorData(row.underlineColor));
          labelBox.appendChild(bar);
        }
        // Pinned once the label has settled the hugged box: the bar rides the
        // box's width and its bottom edge, so a longer `Child` carries it along.
        if (bar) {
          bar.layoutPositioning = 'ABSOLUTE';
          bar.constraints = { horizontal: 'STRETCH', vertical: 'MAX' };
          bar.resize(labelBox.width, kLinkUnderlineBarThickness);
          bar.x = 0;
          bar.y = labelBox.height - kLinkUnderlineBarInset;
        }
        trailingSlots.push(iconSlot('trailing', kLinkTrailingGlyph, trailingSwap.variant));
        // Last, once the label (and the bar) have settled the hugged box the
        // ring is measured from.
        if (flags.Focus) clickableFocusRing(c, lk, clickable);
      }
    }
  }
  const set = mount.finish();
  if (firstComp) {
    const childProp = defineProp(propertyOwner(firstComp), 'Child', 'TEXT', '자세히 보기');
    for (const text of labels) bindTextProp(text, childProp);
  }
  // The two `W?` slots, off by default like the code. Defined on the set after
  // `finish()`, one definition for every member.
  const showLeadingProp = defineProp(set, 'Show leading', 'BOOLEAN', false);
  const leadingProp = defineProp(set, 'Leading', 'INSTANCE_SWAP', leadingSwap.id);
  for (const s of leadingSlots) {
    bindVisibleProp(s.holder, showLeadingProp);
    bindSwapProp(s.content, leadingProp);
  }
  const showTrailingProp = defineProp(set, 'Show trailing', 'BOOLEAN', false);
  const trailingProp = defineProp(set, 'Trailing', 'INSTANCE_SWAP', trailingSwap.id);
  for (const s of trailingSlots) {
    bindVisibleProp(s.holder, showTrailingProp);
    bindSwapProp(s.content, trailingProp);
  }
  vStackSet(set);
  return set;
}

// ─── Menubar ─────────────────────────────────────────────────────────────────

// Data-driven from coui_core MENUBAR.fields (barPadding / barBorderRadius /
// barBorderWidth) + `variants.defaultsByVariant` (bar background / border
// colour, per member — the `standard` entry carries the same two values the flat
// `barBackgroundColor`/`barBorderColor` fields do, and the table is read through
// the Variant axis so a second member Core adds paints itself), plus
// `menuOffset` as the bar→panel gap (it is the popover offset the widget passes:
// `_placement.toPopoverOffset(menuOffset)`).
//
// #4036 (C4a) — the semantic prefix is `menubar.axes`': one Variant member
// (`standard`), no Size/State/Enabled, so the enumeration is one combination and
// this set has exactly one member. The loose COMPONENT is adopted as
// `Variant=standard`, which is what it rendered. `CoreMenubarEntryKind` is
// recorded under `axes.other` and deliberately not promoted (seed spec §4-2).
//
// Composes `Menu`: an open menubar menu is `_MenubarPanel`, which is a `Menu`
// — "`Menu` owns the whole item-row renderer (panel `Popup`, the
// `Button(variant: menu)` rows, dividers, shortcuts)" (menubar.dart). So the
// open dropdown is a `Menu` instance, and the root is a vertical wrapper
// holding [bar, open menu] the way `DropdownMenu`'s builder holds
// [trigger, panel] — a portal has no Figma equivalent, and a preview that
// showed only the closed bar would tell a designer this component has no menu.
//
// The panel's own chrome is NOT repainted here. `menuPanelStyle` is a nested
// `CorePopupStyle` slot forwarded whole into `Menu`'s own `menuStyle`, and the
// child's resolver is what finishes it — reaching in from the parent would be
// the second source `core/style-contract.md` forbids.
//
// Its SHADOW in particular needs no forwarding, and that is checked rather than
// assumed: `menuPanelStyle.boxShadow` is layer-for-layer `Popup`'s own default
// (y4/blur8/spread-2 at 6% over y2/blur4/-1 at 4%), `Menu` composes a `Popup`,
// and `buildPopup` paints it — so the two shadow layers this component states
// are already on the canvas through the child. (Where a parent's value does
// diverge, it has to be forwarded onto the instance — see NavigationMenu's
// panel, whose stack is deeper than Popup's. Two fields of this slot diverge
// and are still un-forwarded: `borderWidth` 0 vs Popup's 1, `minWidth` 160 vs
// 128.)
//
// Composes `Button`: the trigger is `Button(variant: .menubar, buttonStyle:
// resolved.triggerButtonStyle, child: Text(menu.label, style:
// resolved.labelTextStyle))` in the widget — a real composed child, not a box
// that resembles one — so each trigger is a `Button` INSTANCE. That is also why
// this builder has no state axes: every state Menubar carries (`triggerButton
// Style.focusOutlineStyle`, and the resting/hover/open fills the Dart source
// attributes to "the variant owns" them) belongs to that Button, and painting
// it here would be a second source for the child's own chrome.
//
// The open menu hangs from the first trigger, so File is the trigger whose menu
// is open. The widget forces `WidgetState.selected` onto it and swaps in
// `openTriggerButtonStyle` / `openLabelTextStyle`, so the canvas asks `Button`
// for its `State=selected` member (the fill is the `menubar` variant row's, not
// repainted here) and draws File's label with the open slot's weight over the
// resting one — the other triggers rest at the resting label.
//
// The bar has no inter-trigger gap, and there is nothing here to state one
// with: `menubar.dart` lays the triggers out as `Row(mainAxisSize: .min,
// crossAxisAlignment: .center, children: triggers)` — no `spacing:` — and the
// Web bar is `flex flex-row items-center` with no `gap` utility, so adjacent
// triggers sit flush and their own `triggerButtonStyle` padding is what
// separates the labels. A literal 2 stood here; bar-level padding / radius /
// colours are the only bar chrome CoreMenubarStyle exposes, and none of them is
// a gap. Omitting `gap` leaves the frame's itemSpacing at 0, which is the
// widget's answer.
function buildMenubar(page: PageNode, lk: VarLookup): ComponentSetNode {
  const f = MENUBAR.fields;
  const variantData = new Map(Object.entries(MENUBAR.variants.defaultsByVariant));
  const combos = enumerateAxisCombos(axisSpecsOf(MENUBAR.axes));
  const mount = mountSet(page, 'Menubar', combos, { adoptLooseAs: 'Variant=standard' });
  for (const comboName of combos) {
    const combo = parseVariantKey(comboName);
    const variant = variantData.get(combo['Variant']);
    if (!variant) throw new Error(`Menubar: no data for combo "${comboName}"`);
    const c = mount.getOrCreate(comboName);
    // The root is the [bar, open menu] wrapper, so the bar's own chrome is on
    // the `bar` child below — painting it here would put the bar's fill and
    // hairline around the dropdown too.
    applyPanelCompChrome(c, 'VERTICAL', lk, { gap: f.menuOffset });
    // The panel hangs from the anchor's leading edge, not from the bar's centre.
    c.counterAxisAlignItems = 'MIN';
    // No `gap` — the triggers sit flush, see the header note.
    const bar = panel('bar', 'HORIZONTAL', lk, {
      radius: f.barBorderRadius.topLeft,
      pl: f.barPadding.l,
      pr: f.barPadding.r,
      pt: f.barPadding.t,
      pb: f.barPadding.b,
    });
    bar.counterAxisAlignItems = 'CENTER';
    // A floating surface on both platforms (`menubar_style.dart` reads
    // `theme.surfaceFor(.functional)`; the Web twin marks the bar
    // `webSurfaceMarkerFor(.functional)`), casting nothing at rest — so it takes
    // the cast a style contributes on both (`resolveInjectedCast`;
    // `kControlShadowRestMarker`).
    applySurfaceMaterial(bar, lk, colorData(variant.barBackgroundColor), 'functional', {
      radius: f.barBorderRadius.topLeft,
    });
    borderData(bar, lk, colorData(variant.barBorderColor), f.barBorderWidth);
    addControlShadow(bar, lk);
    // The label an open trigger wears is the resting label with the open slot's
    // overlay laid on it (`openTriggerButtonStyle.labelStyle`: the weight) —
    // the order `resolveMenubar` merges them in.
    const restingLabel = textStyleData(f.labelTextStyle);
    const openLabel = mergeTextStyleData(
      restingLabel,
      textStyleData(f.openTriggerButtonStyle.labelStyle),
    );
    const items = ['File', 'Edit', 'View'];
    for (let index = 0; index < items.length; index++) {
      const item = items[index];
      // The panel below hangs from the first trigger, so File is the one whose
      // menu is open — the selected state, the way the widget forces it.
      const open = index === 0;
      // `Button(buttonStyle: resolved.triggerButtonStyle)` — the trigger's inset and
      // corner are Menubar's, and the instance was rendering Button's own `md` row
      // instead: 16/8 where the bar states 12/4, so every trigger on the canvas was
      // wider and taller than the app draws it.
      //
      // The padding comes from the CONSTANT and the corner from the nested slot,
      // because that is where each one is. `defaultTriggerButtonStyle` is built from
      // two class-level consts (`defaultItemPadding` / `defaultItemBorderRadius`)
      // and the exporter resolved the corner into the slot while routing the inset
      // to `constants` — one value, one place, and the place differs.
      bar.appendChild(
        composedButton(
          page,
          lk,
          item,
          open ? openLabel : restingLabel,
          {
            padding: MENUBAR.constants.itemPadding,
            borderRadius: f.triggerButtonStyle.borderRadius,
          },
          open,
        ),
      );
    }
    c.appendChild(bar);
    // The open menu — see the header note on `_MenubarPanel`.
    const menuPanel = instanceOf(page, 'Menu', bestVariantName(page, 'Menu', { Size: kMenuRestingSize }));
    // `menuPanelStyle`, forwarded into the composed `Menu` — the bar states the
    // open panel's stroke, and the instance was keeping `Menu`'s own.
    applyForwardedPanelStyle(menuPanel, lk, {
      borderWidth: f.menuPanelStyle.borderWidth,
      borderColor: colorData(f.menuPanelStyle.borderColor),
    });
    c.appendChild(menuPanel);
  }
  // `defaultSetLayout` over `vStackSet` — see the note at Breadcrumb's return.
  return mount.finish();
}

// ─── NavigationBarItem ────────────────────────────────────────────────────────

// The designer authored this as its own component set (state: Default /
// hover / selected / disabled) rather than a shape `buildNavigationBar`
// draws inline. Composing it back — `buildNavigationBar` instances this
// component per destination instead of drawing an equivalent frame by
// hand — is what keeps a future Generate from overwriting the structure
// the designer built with a look-alike this file invents; the exact
// state-name spelling (`Default` capitalised, the rest lower-case)
// matches the authored member names so `mountSet`'s loose-node adoption
// finds them instead of minting duplicates.
//
// The set is the widget `NavigationBarItem` (Flutter · Web) — the destination
// `NavigationBar` composes, public so a sidebar can be assembled outside the
// bar. Its contract (`CoreNavigationBarItemContract`) has no Style of its own:
// the chrome slot is the bar's `CoreNavigationBarStyle`, so the set is
// data-driven from the same `NAVIGATION_BAR.fields` a destination reads
// inside the bar. The set's properties and the widget's fields correspond
// one to one except where the designer named a canvas toggle for what the
// code takes as a slot — `Show count` is `badge`, `Show mark` is
// `selectionMark: dot`, `Show icon` is whether `icon` is given (the docs page
// keeps the full table). Those names are the designer's and stay.
// `hoverBackgroundColor` / `selectedLabelTextStyle` /
// `labelTextStyle` / `disabledLabelTextStyle` / `itemPadding` /
// `itemRadius` / `itemMinHeight` / `labelSpacing` / `iconStyle` /
// `selectedBackgroundColor` are the exact fields `buildNavigationBar`'s own
// per-state branch already reads, each through the mode's density
// (`navDensity`).
//
// `Label=end` is the sidebar's row — the sidebar's default label position,
// and the only shape that puts a label there — so it draws the sidebar's
// cell: 36 tall, an 18px glyph, the `labelLarge` role, and the selected face
// the sidebar paints. The stacked and icon-only members are the bar's and
// the rail's, which state the same item density (the rail differs only in
// the gap between items) and paint no selected face.
//
// `Show count` composes the destination's `badge` where the widget puts it:
// at the far end of a sidebar row, over the icon's top-end corner in the
// bar and the rail (the widget's composed `Indicator`, offset by
// `badgeIndicatorStyle`). The badge is the count docs and examples hand the
// slot — `Badge(form: count, tone: info, variant: filled, size: xs)`.
const kNavigationCountBadgeTone = 'info';
// g7-preview-only: the demo width of a sidebar — the composed sidebar member and a sidebar row (less its padding) share it; no CoreNavigationBarStyle field states a sidebar width.
const kNavSidebarPreviewWidth = 240;

// ─── The density a layout mode draws its items at ───────────────────────────
//
// `CoreNavigationBarStyle.defaultsByMode` states one cell per mode, and every
// cell but `spacing` is optional: a cell the mode leaves out falls through to
// the flat field of the same name. Both resolvers read it in that order —
// per-instance field, then the mode cell, then the flat default — and this is
// that order for a picture with no per-instance field. Read through
// `optField`, because a cell only the sidebar states is not on the bar's and
// the rail's entries (the reading `defaultsByVariant` partials take).
type NavMode = keyof typeof NAVIGATION_BAR.variants.defaultsByMode;
interface NavPad {
  l: Dim;
  t: Dim;
  r: Dim;
  b: Dim;
}
interface NavDensity {
  padding: NavPad;
  itemPadding: NavPad;
  itemMinHeight: Dim;
  /** The widest a destination grows along the bar, or null for no cap. */
  itemMaxWidth: number | null;
  iconSize: Dim;
  labelSpacing: Dim;
  /** The mode's label role partial, or null when the mode keeps the flat one. */
  labelRole: TextLeaf | null;
  selectedBackgroundColor: Color;
  /** The mode's own face, or null when the mode keeps the variant's. */
  backgroundColor: Color | null;
}
function navDensity(mode: NavMode): NavDensity {
  const f = NAVIGATION_BAR.fields;
  const cell = NAVIGATION_BAR.variants.defaultsByMode[mode];
  return {
    padding: optField<NavPad>(cell, 'padding') ?? f.padding,
    itemPadding: optField<NavPad>(cell, 'itemPadding') ?? f.itemPadding,
    itemMinHeight: optField<Dim>(cell, 'itemMinHeight') ?? f.itemMinHeight,
    // `double.infinity` arrives as `{ unbounded: true }` — no cap, null.
    itemMaxWidth: boundOrNull(optField<Dim>(cell, 'itemMaxWidth') ?? f.itemMaxWidth),
    iconSize: optField<{ size?: Dim }>(cell, 'iconStyle')?.size ?? f.iconStyle.size,
    labelSpacing: optField<Dim>(cell, 'labelSpacing') ?? f.labelSpacing,
    labelRole: optField<TextLeaf>(cell, 'labelTextStyle') ?? null,
    selectedBackgroundColor:
      optField<Color>(cell, 'selectedBackgroundColor') ?? f.selectedBackgroundColor,
    backgroundColor: optField<Color>(cell, 'backgroundColor') ?? null,
  };
}
// A per-state label leaf with the mode's role laid over it — `CoreTextStyle
// .merge` on the leaves, before the role's metrics are filled in: the role
// moves, and a weight the state states (the selected 600) stays.
function navLabelText(state: TextLeaf, role: TextLeaf | null) {
  return textStyleData(role == null ? state : mergeStatedText(state, role));
}
// `CoreTextStyle.merge` on the exported leaves — the right side wins on every
// field it states and leaves the left's where it states nothing. An exported
// partial carries the fields its Core constructor left out as explicit nulls
// (the `color` indicator's selected label is `role: null`, `fontWeight`,
// `color`), and a plain spread let that null erase the base's `labelSmall`, so
// the canvas fell back to the 14 / 160% text face (#5740).
function mergeStatedText(base: TextLeaf, over: TextLeaf): TextLeaf {
  const stated = Object.fromEntries(
    Object.entries(over as unknown as Record<string, unknown>).filter(([, v]) => v != null),
  );
  return { ...base, ...stated } as TextLeaf;
}
// The disabled destination's icon tone — `disabledIconStyle`, laid over the
// resting icon so only its colour moves.
function navDisabledIconColor(): Color {
  return NAVIGATION_BAR.fields.disabledIconStyle.color;
}
// The glyph's tone in an item's state: the resting `iconStyle.color` across
// rest / hover / selected, and the disabled tone for a disabled item. One
// answer for the item set that draws the glyph and the bar that swaps and
// repaints it.
function navItemIconColor(state: NavItemState): Color {
  return state === 'disabled' ? navDisabledIconColor() : NAVIGATION_BAR.fields.iconStyle.color;
}

// How the selected destination is marked — `CoreNavigationSelectionIndicator`
// (#5740, #6358, #6393). Both take the selected colour on the icon and the
// label; `fill` also paints a face on the selected destination's whole tile,
// `color` paints none. On hover `fill` lays the wash, `color` darkens the
// foreground.
type NavIndicator = keyof typeof NAVIGATION_BAR.variants.defaultsByIndicator;
interface NavIndicatorCell {
  selectedBackgroundColor: Color | null;
  selectedLabel: TextLeaf | null;
  selectedIconColor: Color | null;
  hoverForegroundColor: Color | null;
  stateLayer: { hover: number; focus: number } | null;
  // The dimmed face of a selected, disabled destination.
  disabledSelectedBackgroundColor: Color | null;
}
function navIndicator(indicator: NavIndicator): NavIndicatorCell {
  const cell = NAVIGATION_BAR.variants.defaultsByIndicator[indicator];
  return {
    selectedBackgroundColor: optField<Color>(cell, 'selectedBackgroundColor') ?? null,
    selectedLabel: optField<TextLeaf>(cell, 'selectedLabelTextStyle') ?? null,
    selectedIconColor: optField<{ color?: Color }>(cell, 'selectedIconStyle')?.color ?? null,
    hoverForegroundColor: optField<Color>(cell, 'hoverForegroundColor') ?? null,
    stateLayer: optField<{ hover: number; focus: number }>(cell, 'stateLayer') ?? null,
    disabledSelectedBackgroundColor:
      optField<Color>(cell, 'disabledSelectedBackgroundColor') ?? null,
  };
}
// The mode's own indicator — `CoreNavigationBarMode.defaultIndicator`: colour
// for the bar, a tile for the rail and the sidebar.
function navModeIndicator(mode: NavMode): NavIndicator {
  return mode === 'bar' ? 'color' : 'fill';
}
// Whether the indicator darkens a hovered destination's foreground — the
// transparent sentinel keeps the resting one.
function navHoverForeground(cell: NavIndicatorCell): Color | null {
  // The indicator's cell first, then the flat field — whose transparent
  // default says "hover keeps the resting colour".
  const hover = cell.hoverForegroundColor ?? NAVIGATION_BAR.fields.hoverForegroundColor;
  return hover != null && paintsFill(colorData(hover)) ? hover : null;
}
// The glyph's tone for a destination: disabled first, then the indicator's
// selected tone, then the hover foreground the indicator states, then the
// resting tone. One answer for the item set and the bar that repaints the
// composed glyph.
function navDestinationIconColor(
  state: NavItemState,
  selected: boolean,
  indicator: NavIndicator,
): Color {
  const f = NAVIGATION_BAR.fields;
  if (state === 'disabled') return navDisabledIconColor();
  const cell = navIndicator(indicator);
  if (selected) return cell.selectedIconColor ?? f.selectedIconStyle.color;
  if (state === 'hover') return navHoverForeground(cell) ?? f.iconStyle.color;
  return f.iconStyle.color;
}
// The destination's interaction rung — R1 names in R1 order (`state-axis.ts`).
// Every rung is one the widget SELECTS chrome for (`_NavigationDestination`'s
// branch: disabled → selected → pressed → focused → hovered → rest), and each
// pointer rung is one weight of `stateLayer` over the bar.
//
// The rest rung was the designer's `Default` until #4552; `VARIANT_RENAMES`
// carries those members to `enabled` so they keep their keys, and
// `NavigationBar` asks for the new name.
//
// No `pressed`. Core does state a pressed weight now (`stateLayer.pressed`),
// but the canvas's pressed members were retired on the designer's word that
// the library does not use that pose (`RETIRED_VARIANTS`), and bringing it
// back is hers to decide — not a side effect of the focus rung.
const kNavItemStates = stateAxis(['enabled', 'hover', 'focus', 'disabled']);
type NavItemState = (typeof kNavItemStates)[number];

// The composed `Indicator`'s offset for a bar / rail badge —
// `badgeIndicatorStyle`.
function navBadgeOffset(): Dim {
  return NAVIGATION_BAR.fields.badgeIndicatorStyle.offset;
}

// The selection mark — `Badge(form: .dot, badgeStyle: selectionMarkStyle)` over
// a destination's content (`CoreNavigationSelectionMark.dot`). Composed from the
// Badge set at the step whose dot is the mark's size, so the instance keeps the
// step's bound size; a mark off every step resizes the instance instead. The
// colour is the slot's, repointed onto the dot's material layer where the dot
// has one (painted on the root it would sit under that layer and never show).
function composeSelectionMark(page: PageNode, lk: VarLookup, dimmed = false): InstanceNode {
  const f = NAVIGATION_BAR.fields;
  // A selected, disabled destination keeps the dot, dimmed — the same dot
  // under `disabledSelectionMarkStyle` (#5740).
  const style = dimmed
    ? {
        ...f.selectionMarkStyle,
        ...Object.fromEntries(
          Object.entries(f.disabledSelectionMarkStyle).filter(([, v]) => v != null),
        ),
      }
    : f.selectionMarkStyle;
  const size = dimVal(style.dotSize);
  const step = Object.entries(COMPONENTS.badge.sizes.defaultsBySize).find(
    ([, row]) => dimVal(row.dotSize) === size,
  )?.[0];
  const dot = instanceOf(
    page,
    'Badge',
    bestVariantName(page, 'Badge', {
      Tone: kBadgeDefaultTone,
      Variant: COMPONENTS.badge.axes.variant.default,
      Size: step ?? COMPONENTS.badge.axes.size.members[0],
      Style: 'dot',
    }),
  );
  dot.name = 'selection mark';
  if (step == null) dot.resize(size, size);
  const color = colorData(style.backgroundColor);
  if (!repointSurfaceMaterial(dot, lk, color, null)) fillData(dot, lk, color);
  return dot;
}

// The notification dot — `Badge(form: .dot, badgeStyle: notificationDotStyle)`
// over a destination's icon (`showDot`). Composed from the Badge set at the step
// whose dot is the dot's size, the colour repointed onto the dot the way the
// selection mark is.
function composeNotificationDot(page: PageNode, lk: VarLookup): InstanceNode {
  const style = NAVIGATION_BAR.fields.notificationDotStyle;
  const size = dimVal(style.dotSize);
  const step = Object.entries(COMPONENTS.badge.sizes.defaultsBySize).find(
    ([, row]) => dimVal(row.dotSize) === size,
  )?.[0];
  const dot = instanceOf(
    page,
    'Badge',
    bestVariantName(page, 'Badge', {
      Tone: kBadgeDefaultTone,
      Variant: COMPONENTS.badge.axes.variant.default,
      Size: step ?? COMPONENTS.badge.axes.size.members[0],
      Style: 'dot',
    }),
  );
  dot.name = 'dot';
  if (step == null) dot.resize(size, size);
  const color = colorData(style.backgroundColor);
  if (!repointSurfaceMaterial(dot, lk, color, null)) fillData(dot, lk, color);
  return dot;
}

function buildNavigationBarItem(page: PageNode, lk: VarLookup): ComponentSetNode {
  const f = NAVIGATION_BAR.fields;
  const sidebarDensity = navDensity('sidebar');
  const barDensity = navDensity('bar');
  // Three axes, all backed by the exported contract rather than literals.
  //
  // `Selected` is its own axis, not a `State` member. Selection is not a
  // pose a pointer puts an item in and takes it out of — an item is
  // selected while hovered, and while disabled — so folding it into
  // `State` made those combinations unnameable. The canvas had it as a
  // separate axis from the start; this is the builder catching up.
  //
  // `Label` splits what the canvas carried as a third "orientation":
  // icon-only is not a direction, it is the absence of a label, and the
  // contract already says so (`CoreNavigationLabelMode.none` — "No item
  // shows a label (icon-only)"). Position and presence are two questions
  // and the code asks them separately, so the canvas axis that answered
  // both at once becomes two here.
  //
  // `State` is the rungs the widget selects a face for (#4552). The pointer
  // rungs are one ink — `stateLayerColor` — at the weights `stateLayer`
  // states (hover / focus), laid over the bar the way both resolvers
  // `alphaBlend` it (`washed()`); rest and disabled carry no layer at all,
  // which is the weight 0 the issue measured missing. A
  // `hoverBackgroundColor` with any alpha is the escape hatch that wins over
  // the layer outright, so a stated swap paints instead. `focus` also wears
  // the `Clickable` ring the destination is wrapped in — on, as the pose; on
  // every other rung the same ring is drawn hidden behind `Show focus ring`
  // (R3), for the focused-while-selected pose a `State` value cannot name.
  const labelMode = NAVIGATION_BAR.axes.other.find(
    (o) => o.enum === 'CoreNavigationLabelMode',
  );
  const labelPos = NAVIGATION_BAR.axes.other.find(
    (o) => o.enum === 'CoreNavigationLabelPosition',
  );
  if (!labelMode || !labelPos) {
    throw new Error(
      'NavigationBarItem: CoreNavigationLabelMode / LabelPosition are gone ' +
        'from the exported axes — the canvas has Label axes that nothing in ' +
        'the contract now backs.',
    );
  }
  const states = kNavItemStates;
  // `bottom` stacks the label under the icon, `end` sets it beside — the
  // two the canvas drew as "vertical" and "horizontal". `top` / `start`
  // exist in the contract and no member draws them, so they are not
  // enumerated: an axis member is a drawing, not a possibility.
  const positions = ['bottom', 'end'] as const;
  const names: string[] = [];
  // `Indicator` (#5740) — `fill` draws every placement; `color` is the bar's
  // indicator, and the bar stacks its label under the icon, so `color` draws
  // that one placement (the designer's `NavigationBarItem(리디자인)`).
  for (const pos of positions) {
    for (const state of states) {
      for (const selected of ['false', 'true'] as const) {
        names.push(`Label=${pos}, State=${state}, Selected=${selected}, Indicator=fill`);
      }
    }
  }
  // Icon-only has no label to place, so it is one member per state /
  // selection rather than one per position — a `Label=none` drawn twice
  // would be the same picture under two names.
  for (const state of states) {
    for (const selected of ['false', 'true'] as const) {
      names.push(`Label=none, State=${state}, Selected=${selected}, Indicator=fill`);
    }
  }
  for (const state of states) {
    for (const selected of ['false', 'true'] as const) {
      names.push(`Label=bottom, State=${state}, Selected=${selected}, Indicator=color`);
    }
  }
  // The glyph is drawn from the `Icon` default, so the bind leaves it at
  // `iconStyle.size` (see `IconOpts.fromVariant`).
  const iconSwap = iconSwapDefault(page, 'NavigationBarItem', 'Icon', iconMainId(page));
  const mount = mountSet(page, 'NavigationBarItem', names, {
    adoptLooseAs: 'Label=bottom, State=enabled, Selected=false, Indicator=fill',
  });
  const iconNodes: InstanceNode[] = [];
  const labelNodes: TextNode[] = [];
  // What `Show icon` hides — the glyph of a member that also has a label (an
  // icon-only member keeps its glyph: there would be nothing left to draw).
  const iconHolders: SceneNode[] = [];
  // What `Show mark` shows — the dot over a stacked member's content.
  const marks: InstanceNode[] = [];
  // Where `Show count` hangs the badge once the set exists — the far end of
  // a sidebar row, or the frame that is exactly the bar / rail icon's box.
  const rowEnds: FrameNode[] = [];
  const iconAnchors: FrameNode[] = [];
  // What `Show dot` shows — the notification dot over a stacked member's icon.
  const dotAnchors: FrameNode[] = [];
  const stateLayers: { item: FrameNode; layer: RectangleNode }[] = [];
  const rings: FocusRingNodes[] = [];
  for (const name of names) {
    const parsed = parseVariantKey(name);
    const state = parsed['State'] as NavItemState;
    const selected = parsed['Selected'] === 'true';
    const labelPlacement = parsed['Label'];
    const indicator = parsed['Indicator'] as NavIndicator;
    const cell = navIndicator(indicator);
    const sidebarRow = labelPlacement === 'end';
    // Selected and disabled, the selection stays, dimmed — the widget's
    // `disabledSelected` (#5740): the tile in the disabled area tone, the
    // label in the disabled tone at the selected weight.
    const disabledSelected = selected && state === 'disabled';
    const d = sidebarRow ? sidebarDensity : barDensity;
    const c = mount.getOrCreate(name);
    // The member hugs the one item it holds. A recycled node keeps whatever
    // size its last generation left it with, and with no layout of its own
    // nothing pulls it back — which is how the `Label=end` / `Label=none`
    // members sat at 56 tall around a 64-tall item for a whole generation,
    // and why every rail destination composed from them overlapped the next
    // by 4px. Hugging makes the wrapper a function of the item again.
    applyPanelCompChrome(c, 'VERTICAL', lk, {});
    c.counterAxisAlignItems = 'CENTER';
    // A stacked item lays the selection mark over its content, so its own gap
    // is the mark's; the icon-and-label gap moves onto the content inside it.
    const item = panel('item', sidebarRow ? 'HORIZONTAL' : 'VERTICAL', lk, {
      gap: sidebarRow ? d.labelSpacing : f.selectionMarkGapStyle.size,
      radius: f.itemRadius.topLeft,
      pl: d.itemPadding.l,
      pr: d.itemPadding.r,
      pt: d.itemPadding.t,
      pb: d.itemPadding.b,
    });
    item.primaryAxisAlignItems = 'CENTER';
    item.counterAxisAlignItems = 'CENTER';
    // An icon-only stacked destination paints its own, shorter floor
    // (`iconOnlyItemMinHeight` × `iconOnlyItemMinWidth`, 64 × 40); its 48
    // pointer target (`touchTargetSize`) is hit testing in code and draws
    // nothing, so the canvas shows the painted box.
    const iconOnly = labelPlacement === 'none';
    const minHeight = iconOnly ? f.iconOnlyItemMinHeight : d.itemMinHeight;
    item.minHeight = dimVal(minHeight);
    item.setBoundVariable('minHeight', lk.size(dimVal(minHeight)));
    if (iconOnly) {
      item.minWidth = dimVal(f.iconOnlyItemMinWidth);
      item.setBoundVariable('minWidth', lk.size(dimVal(f.iconOnlyItemMinWidth)));
    }
    // The widget's branch order: disabled first (the idle face, no layer),
    // then selection (the tile's face), then the pointer. The state layer is laid over whatever the item paints — a
    // selected item that is hovered or focused keeps its selection and still
    // takes the layer.
    const pointer = state === 'hover' || state === 'focus';
    const hoverSwap = colorData(f.hoverBackgroundColor);
    const swapped = paintsFill(hoverSwap);
    if (state !== 'disabled') {
      // The indicator's face sits above the mode cell's (`defaultsByIndicator`
      // between the merged field and `defaultsByMode` in both resolvers) —
      // the whole tile, stacked or a row (#6358); `color` states a
      // transparent face, which paints none (#6393).
      const face = cell.selectedBackgroundColor ?? d.selectedBackgroundColor;
      if (selected) fillData(item, lk, colorData(face));
      else if (pointer && swapped) fillData(item, lk, hoverSwap);
    } else if (disabledSelected) {
      // The dimmed face — the indicator's, then the flat no-fill.
      const face = colorData(
        cell.disabledSelectedBackgroundColor ?? f.disabledSelectedBackgroundColor,
      );
      if (paintsFill(face)) fillData(item, lk, face);
    }
    // The state layer — a rect at child 0 of the item box, under the icon and
    // the label, as wide and tall as the box and rounded with it. Its ink is
    // the bound `stateLayerColor` token; its strength is the rung's weight,
    // bound to the `opacity/<n>` step that holds it, so a token change
    // follows on the canvas and a drift shows in the variable panel.
    const ramp = cell.stateLayer ?? f.stateLayer;
    const layerWeight =
      !pointer || swapped ? null : state === 'focus' ? ramp.focus : ramp.hover;
    let stateLayer: RectangleNode | null = null;
    if (layerWeight != null && layerWeight > 0) {
      stateLayer = figma.createRectangle();
      stateLayer.name = 'state layer';
      bindRadiusN(stateLayer, lk, f.itemRadius.topLeft);
      fillData(stateLayer, lk, colorData(f.stateLayerColor));
      bindLayerOpacity(stateLayer, lk, layerWeight);
    }
    // Disabled outranks the selection's colour: a disabled item reads in the
    // disabled tone whether or not it is the current one — the current one
    // keeps the selected weight — and the resting style is what selection
    // lifts from.
    let text = navLabelText(f.labelTextStyle, d.labelRole);
    const hoverForeground = navHoverForeground(cell);
    if (disabledSelected) {
      text = navLabelText(f.disabledSelectedLabelTextStyle, d.labelRole);
    } else if (state === 'disabled') {
      text = navLabelText(f.disabledLabelTextStyle, d.labelRole);
    } else if (selected) {
      const stated =
        cell.selectedLabel == null
          ? f.selectedLabelTextStyle
          : mergeStatedText(f.selectedLabelTextStyle, cell.selectedLabel);
      text = navLabelText(stated, d.labelRole);
    } else if (state === 'hover' && hoverForeground != null) {
      // The `color` indicator darkens the foreground on hover instead of
      // laying a wash.
      text = navLabelText({ ...f.labelTextStyle, color: hoverForeground }, d.labelRole);
    }
    // The selected icon takes the indicator's colour (#5740); disabled and
    // the `color` indicator's hover follow their own tones.
    const icon = makeIcon('house', lk, {
      ...glyphOpts(
        lk,
        colorData(navDestinationIconColor(state, selected, indicator))!,
        d.iconSize,
        'size',
      ),
      fromVariant: iconSwap.variant,
    });
    iconNodes.push(icon);
    const label =
      labelPlacement === 'none' ? null : makeLabel('홈', lk, textLabelOpts(lk, text));
    if (label) labelNodes.push(label);
    if (sidebarRow) {
      // A sidebar row is a full-width target: the face spans it, the icon +
      // label group keeps the start edge, and the count takes the far end —
      // the widget's `Row(children: [Expanded(group), badge])`.
      const content = panel('content', 'HORIZONTAL', lk, { gap: d.labelSpacing });
      content.counterAxisAlignItems = 'CENTER';
      content.appendChild(icon);
      if (label) content.appendChild(label);
      item.appendChild(content);
      item.primaryAxisAlignItems = 'SPACE_BETWEEN';
      rowEnds.push(item);
      if (label) iconHolders.push(icon);
    } else {
      // The `Indicator`'s box is the icon's box, so the badge anchors to the
      // glyph rather than to the stack of glyph and caption.
      // Every stacked destination keeps its icon in a box of its own
      // (`iconAnchorPadding`) so the destinations keep their width whichever
      // one is selected; the selected face is the whole tile, not this box.
      const pad = f.iconAnchorPadding;
      const anchor = panel('iconAnchor', 'HORIZONTAL', lk, {
        pl: pad.l,
        pr: pad.r,
        pt: pad.t,
        pb: pad.b,
      });
      anchor.primaryAxisAlignItems = 'CENTER';
      anchor.counterAxisAlignItems = 'CENTER';
      anchor.clipsContent = false;
      anchor.appendChild(icon);
      dotAnchors.push(anchor);
      // The selection mark over the content — the widget's
      // `Column([dot, Gap(selectionMarkGapStyle), inner])`. A row has no top to
      // put it on, so only a stacked member draws one (`marksAt`). Hidden as
      // the pose, as the bar's `selectionMark` defaults to `none`; on every
      // member it keeps its room so labels stay level across a bar, and only
      // the selected one shows it — the widget fades the others to 0. A
      // selected, disabled destination shows it dimmed (`disabledContent`).
      const mark = composeSelectionMark(page, lk, disabledSelected);
      mark.opacity = selected ? 1 : 0;
      mark.visible = false;
      marks.push(mark);
      item.appendChild(mark);
      const content = panel('content', 'VERTICAL', lk, { gap: d.labelSpacing });
      content.primaryAxisAlignItems = 'CENTER';
      content.counterAxisAlignItems = 'CENTER';
      content.clipsContent = false;
      content.appendChild(anchor);
      if (label) content.appendChild(label);
      item.appendChild(content);
      item.clipsContent = false;
      c.clipsContent = false;
      iconAnchors.push(anchor);
      if (label) iconHolders.push(anchor);
    }
    c.appendChild(item);
    if (stateLayer) {
      // `insertChild` first, then pin: `pinInFlow` takes the node out of the
      // item's flow where it already is, so the icon and label keep their
      // places and the layer spans the box (STRETCH × STRETCH).
      item.insertChild(0, stateLayer);
      pinInFlow(item, stateLayer);
      stateLayer.constraints = { horizontal: 'STRETCH', vertical: 'STRETCH' };
      stateLayer.resize(Math.max(1, item.width), Math.max(1, item.height));
      stateLayer.x = 0;
      stateLayer.y = 0;
      stateLayers.push({ item, layer: stateLayer });
    }
    if (sidebarRow) {
      // A row the sidebar stretches to its width: the wrapper takes the
      // sidebar's demo row width so the face and the far-end count read as
      // they do in the bar, and an instance stretched in a bar still
      // stretches the row (the item fills it).
      lockWidth(
        c,
        kNavSidebarPreviewWidth -
          dimVal(sidebarDensity.padding.l) -
          dimVal(sidebarDensity.padding.r),
      );
      item.layoutSizingHorizontal = 'FILL';
    } else {
      // A stacked destination is the whole cell the bar gives it: the
      // `Clickable` the widget wraps it in spans its share (`Expanded` in the
      // bar, the rail's stretched column), so the tile — and with it the
      // state layer, the selected face and the ring around it — is the
      // cell's width, not the glyph-and-caption it holds. The member keeps
      // the width its item hugs to, so the set draws the designed tile; an
      // instance stretched in a bar's cell stretches the item with it, the
      // same way the sidebar row above does.
      lockWidth(c, item.width);
      item.layoutSizingHorizontal = 'FILL';
    }
    // The ring — the `Clickable` the destination is wrapped in (its
    // `clickableStyle.focusOutlineStyle` over its corner). Around the member,
    // which hugs the one item box it holds, after the box has its settled
    // width. Visible as the `focus` pose; hidden everywhere else and bound to
    // `Show focus ring` after `finish()`.
    rings.push(
      focusRing(c, lk, {
        outline: f.clickableStyle.focusOutlineStyle,
        color: focusOutlineRingColor(f.clickableStyle.focusOutlineStyle),
        corner: f.clickableStyle.borderRadius.topLeft,
        width: c.width,
        height: c.height,
        visible: state === 'focus',
      }),
    );
  }
  // The layer was sized before the sidebar row took its width; re-span it to
  // the settled box.
  for (const { item, layer } of stateLayers) {
    layer.resize(Math.max(1, item.width), Math.max(1, item.height));
  }
  const set = mount.finish();
  rowSet(set);
  // The set already carries a `Label` TEXT property — the designer's, and
  // the one `setInstanceLabel` writes each destination's caption into. It
  // had no reader: the text layer is rebuilt every generation and nothing
  // bound it back, so every composed bar wrote "Home" into a property no
  // node consumed and kept showing the placeholder. Binding here is what
  // makes the property the caption, on every member that has a label.
  const labelProp = defineProp(set, 'Label', 'TEXT', '홈');
  for (const n of labelNodes) bindTextProp(n, labelProp);
  // After `finish()`: until `combineAsVariants` has run, a fresh variant's
  // parent is still the page, so `propertyOwner` would answer with the
  // variant and each member would grow its own copy of the property (the
  // same ordering `Stat`'s own icon-swap property follows).
  const iconProp = defineProp(set, 'Icon', 'INSTANCE_SWAP', iconSwap.id);
  for (const n of iconNodes) bindSwapProp(n, iconProp);
  // `Show icon` — on, as a destination states its icon; off is the bare-label
  // tab (`CoreNavigationBarItem.destination(icon: null, label: …)`).
  const showIconProp = defineProp(set, 'Show icon', 'BOOLEAN', true);
  for (const n of iconHolders) bindVisibleProp(n, showIconProp);
  // `Show mark` — off, as `CoreNavigationSelectionMark.defaultSelectionMark`
  // is `none`. Turned on across a bar's destinations it is the bar's `dot`.
  const showMarkProp = defineProp(set, 'Show mark', 'BOOLEAN', false);
  for (const n of marks) bindVisibleProp(n, showMarkProp);
  // `Show count` — off, as a destination with no `badge` renders none. The
  // badge joins after `finish()` for the same reason as the properties above.
  const showCountProp = defineProp(set, 'Show count', 'BOOLEAN', false);
  const showFocusProp = defineShowFocusRing(set);
  for (const ring of rings) bindShowFocusRing(ring, showFocusProp);
  for (const row of rowEnds) {
    composeCountBadge(page, row, showCountProp, kNavigationCountBadgeTone);
  }
  const badgeOffset = dimVal(navBadgeOffset());
  const anchorPad = NAVIGATION_BAR.fields.iconAnchorPadding;
  for (const anchor of iconAnchors) {
    const badge = composeCountBadge(page, anchor, showCountProp, kNavigationCountBadgeTone);
    // The `Indicator` places its item on the icon's top-end corner, `offset`
    // in from both edges — a negative offset pulls it out over the corner.
    // The icon sits inside the anchor's own inset, so the corner is that far
    // in. Pinned (through a holder — Figma refuses the pin on an instance) to
    // that corner, out of the anchor's flow so the anchor stays the glyph.
    pinAbsolute(
      anchor,
      badge,
      anchor.width - dimVal(anchorPad.r) - badge.width - badgeOffset,
      dimVal(anchorPad.t) + badgeOffset,
      { horizontal: 'MAX', vertical: 'MIN' },
    );
  }
  // `Show dot` — off, as `showDot` defaults to false. The notification dot
  // (`notificationDotStyle`) on the icon's top-end corner, offset by
  // `notificationDotIndicatorStyle`.
  const showDotProp = defineProp(set, 'Show dot', 'BOOLEAN', false);
  const dotOffset = dimVal(NAVIGATION_BAR.fields.notificationDotIndicatorStyle.offset);
  for (const anchor of dotAnchors) {
    const dot = composeNotificationDot(page, lk);
    pinAbsolute(
      anchor,
      dot,
      anchor.width - dimVal(anchorPad.r) - dot.width - dotOffset,
      dimVal(anchorPad.t) + dotOffset,
      { horizontal: 'MAX', vertical: 'MIN' },
    );
    dot.visible = false;
    bindVisibleProp(dot, showDotProp);
  }
  return set;
}

// ─── NavigationBar (bottom nav) ──────────────────────────────────────────────

// Data-driven from coui_core: NAVIGATION_BAR.fields (padding / barRadius /
// barMargin / itemSpacing /
// itemPadding / itemRadius / labelSpacing / iconStyle / selectedBackgroundColor
// / hoverBackgroundColor / selectedLabelTextStyle / labelTextStyle /
// disabledLabelTextStyle / sectionLabelTextStyle / clickableStyle) +
// variants.defaultsByVariant (background). The variant table is keyed off the
// ENUMERATED axis rather than read at a hardcoded name, so the axis appears in
// the variant name and a second variant added to Core shows up on the canvas by
// itself.
//
// #4036 (C4a) — `navigation_bar.axes` carries one Variant member (`standard`)
// and no Size/State/Enabled, so the four-axis enumeration is one combination and
// the poses qualify it; the loose COMPONENT is adopted as that combination at
// rest, keeping its key. The six `CoreNavigation*` enums the component also
// declares live under `axes.other` and are recorded without promotion (seed spec
// §4-2).
//
// State axes: Hover (hoverBackgroundColor), Disabled (disabledLabelTextStyle +
// clickableStyle.disabledOpacity), Focus (clickableStyle.focusOutlineStyle.
// borderColor). Selection is not an axis — a nav bar always has exactly one
// selected destination, so it is rendered inline (the first item) from
// selectedBackgroundColor + selectedLabelTextStyle.
//
// Composes `NavigationBarItem` + `Icon` + `Divider` + `Tooltip`: `build`'s
// switch over `CoreNavigationBarItem.kind` renders a `divider` entry as
// `_NavigationDividerLine` (a `Divider` fed the resolved `dividerStyle`), an
// `item` entry as the `NavigationBarItem` widget (the designer's own
// `NavigationBarItem` component — see its own header note above), which wraps
// a label-less destination in `Tooltip`. All are instances rather than drawn
// shapes.
//
// ─── Two nodes, and the docked-edge hairline ─────────────────────────────
//
// The root used to be the bar, carrying a literal radius(16) and a literal
// `outline` stroke, both on the reading that this component has no bar-level
// chrome field. It has three — `barRadius`, `barMargin` and `barBorderColor`
// / `barBorderWidth` — and reading them contradicts both literals:
//
//   · `barRadius` is `CoreBorderRadius.zero`. The widget's box is
//     `Container(decoration: BoxDecoration(color: backgroundColor,
//     borderRadius: resolved.barRadius))`, so the bar is SQUARE, and 16 was a
//     rounding the widget does not draw on either platform.
//   · The `outline` stroke drawn here is real, but it used to be chrome this
//     builder invented with no field behind it. `barBorderColor` /
//     `barBorderWidth` now name exactly this hairline — the same
//     docked/floating split `Dock`'s own `borderColor` already states, drawn
//     only while `barMargin` is zero (see `borderData` call below).
//   · `barMargin` is the outside inset that detaches a floating bar, and
//     padding cannot express it — so, exactly as in `Dock` above, the root is
//     now a margin wrapper and a child `bar` frame carries the fill, corners and
//     `padding`. That nesting is also what the widget has: `padding` is on the
//     `SingleChildScrollView` INSIDE the bar's box, not on the box.
//
// Both bar insets are zero today, so the corners stay square and the
// hairline stays drawn — which is the widget's picture at rest.
//
// Icon size traces to CoreIconSize (`via`), not CoreFontSize —
// glyphOpts(..., 'size') binds the correct scale.
function buildNavigationBar(page: PageNode, lk: VarLookup): ComponentSetNode {
  const f = NAVIGATION_BAR.fields;
  const clickable = f.clickableStyle;
  const variantData = new Map(Object.entries(NAVIGATION_BAR.variants.defaultsByVariant));
  // `Mode` is the contract's `CoreNavigationBarMode`, read from the exported
  // axes rather than spelled here — the same guard `Footer` puts on its
  // `Layout`: a canvas axis nothing in the contract backs is a lie the
  // builder would keep telling after the enum went away.
  const modeAxis = NAVIGATION_BAR.axes.other.find(
    (o) => o.enum === 'CoreNavigationBarMode',
  );
  if (!modeAxis) {
    throw new Error(
      'NavigationBar: CoreNavigationBarMode is gone from the exported axes — ' +
        'the canvas has a Mode axis that nothing in the contract now backs.',
    );
  }
  const axes: StateAxis[] = ['Hover', 'Disabled', 'Focus'];
  const members = poseMembers(NAVIGATION_BAR.axes, axes, [
    { axis: 'Mode', values: modeAxis.members },
  ]);
  const mount = mountSet(
    page,
    'NavigationBar',
    members.map((m) => m.name),
    {
      adoptLooseAs:
        'Variant=standard, Mode=bar, Hover=false, Disabled=false, Focus=false',
    },
  );
  // Per-state text (role + colour) now lives entirely inside the composed
  // `NavigationBarItem` instance below — this builder no longer resolves
  // it for a destination, only for the non-destination `label` kind.
  const sectionText = textStyleData(f.sectionLabelTextStyle);
  // The header's own inset — not the item's.
  const sectionPad: NavPad = f.sectionLabelPadding;
  // The `footer` slot — a caller-supplied widget inside the bar's chrome,
  // after the items at the end of the main axis. Drawn as the slot
  // stand-in behind `Show footer` (off, as a bar with no footer renders
  // none) and a `Footer` swap, collected per member and bound after
  // `finish()`.
  const footerHolders: FrameNode[] = [];
  const footerContents: InstanceNode[] = [];
  // The `header` slot (#5740) — the same kind of caller widget at the START of
  // the main axis: the top of a rail or sidebar (the app's logo), the leading
  // end of the bar. Behind `Show header` (off, as a bar with no header renders
  // none) and a `Header` swap.
  const headerHolders: FrameNode[] = [];
  const headerContents: InstanceNode[] = [];
  // `house` / `search` / `heart` are the widget's own; `menu` is the plugin's
  // pick for a slot the code leaves to the caller.
  //
  // `CoreNavigationBarItem.kind` is a four-way (`item` / `label` / `divider` /
  // `gap`) that `build` switches on, so the entry list is the switch's input
  // here too — a `divider` entry renders `_NavigationDividerLine`, a `label`
  // entry renders `_NavigationSectionLabel`, and the running `destinationIndex`
  // (below) counts only `item` entries, exactly as the widget does.
  //
  // Three of the four kinds appear. `gap` is the one left out, and not by
  // oversight: `Gap(gapStyle: item.gapStyle)` reads a `CoreGapStyle` the CALLER
  // hands to `CoreNavigationBarItem.gap(size)` — there is no
  // CoreNavigationBarStyle field behind it, so any spacer drawn here would be a
  // size this builder invented rather than one the data states.
  //
  // The `label` kind was the missing one before this, and it was the only route
  // to `sectionLabelTextStyle`: `_NavigationSectionLabel` is
  // `Padding(padding: itemPadding, child: Text(item.label ?? '', style:
  // sectionLabelTextStyle))`, and with no `label` entry in this list that field
  // — labelSmall, 12px, semibold, on-surface-variant — was stated by the data
  // and drawn nowhere. The destinations draw the same 12px role, so the
  // semibold weight is the only thing that sets a section caption apart, and
  // without a `label` entry the picture had no caption to set apart.
  //
  // The fixture is per shape, and each is the picture the designer drew for
  // it (#5740 decision 2). The rail is simple: its destinations, a divider,
  // and "More" as one more labelled destination — no section caption and no
  // resting tooltip bubble. The code API is unchanged: a rail still takes
  // `label` entries and a tooltip on an icon-only destination; the rail
  // example just does not show them, because a tooltip drawn at rest is a
  // state the rail never sits in.
  //
  // The sidebar (`@Deprecated`, off the canvas — Sidebar replaces it) keeps
  // the fuller fixture while it is still drawn: a `label` entry (the only
  // route to `sectionLabelTextStyle`) and an icon-only "More" with a
  // `tooltip` (the one shape in which `_NavigationDestination` composes
  // `Tooltip`: `tooltip != null && tooltip.isNotEmpty && !renderLabel`).
  //
  // The bar is the docs default example (four labelled destinations,
  // `labelMode: all`, equal shares edge to edge).
  //
  // `ordinal` is the `Show item N` a destination answers to when it is not
  // simply its position (see the spare below).
  type Entry =
    | { kind: 'item'; icon: string; label?: string; tooltip?: string; ordinal?: number }
    | { kind: 'label'; label: string }
    | { kind: 'divider' };
  // The rail's destinations, then the divider and "More". The spare keeps
  // the fourth seat and answers to `Show item 5` in every mode
  // (`kSpareDestination`); "More", the fourth destination shown at rest,
  // answers to 4.
  const railEntries: Entry[] = [
    { kind: 'item', icon: 'house', label: '홈' },
    { kind: 'item', icon: 'search', label: '검색' },
    { kind: 'item', icon: 'heart', label: '저장됨' },
    { kind: 'item', icon: 'inbox', label: '받은편지함', ordinal: 5 },
    { kind: 'divider' },
    { kind: 'item', icon: 'menu', label: '더보기', ordinal: 4 },
  ];
  const sidebarEntries: Entry[] = [
    { kind: 'label', label: '둘러보기' },
    { kind: 'item', icon: 'house', label: '홈' },
    { kind: 'item', icon: 'search', label: '검색' },
    { kind: 'item', icon: 'heart', label: '저장됨' },
    // The spare. `items` is a `List<W>` and Figma has no property for a
    // list's length, so a count cannot be an axis without multiplying every
    // other axis by three. It is a BOOLEAN instead — the shape `Filter`
    // already uses for its segments — and this destination is the one that
    // ships off, which is why the resting picture is unchanged.
    //
    // It sits with the labelled group rather than last for two reasons: the
    // divider below would be stranded at the bar's edge if the node after it
    // vanished, and the tooltip demo has to stay last (see the note above).
    //
    // So its seat and its ordinal part here. The spare is `Show item 5` in
    // every mode (`kSpareDestination`) — but the bar's fifth seat is its
    // last, and here the last seat is the tooltip demo, which has to stay
    // drawn at rest or the `Tooltip` it composes leaves the canvas. The spare
    // keeps the fourth seat and answers to 5; "More", the fourth destination
    // shown at rest, answers to 4.
    { kind: 'item', icon: 'inbox', label: '받은편지함', ordinal: 5 },
    { kind: 'divider' },
    { kind: 'item', icon: 'menu', tooltip: '더보기', ordinal: 4 },
  ];
  // The docs example's four (`house` / `search` / `bell`, then `heart` where
  // the example has a profile glyph the plugin's icon set does not carry),
  // then the spare in the fifth seat — `Show item N` is one property set for
  // the whole component set, so the ordinal that ships off has to be the
  // same one in every mode (the rail and the sidebar map it above).
  const barEntries: Entry[] = [
    { kind: 'item', icon: 'house', label: '홈' },
    { kind: 'item', icon: 'search', label: '검색' },
    { kind: 'item', icon: 'bell', label: '알림' },
    { kind: 'item', icon: 'heart', label: '저장됨' },
    { kind: 'item', icon: 'inbox', label: '받은편지함' },
  ];
  // Every destination gets a `Show item N`; this is the ordinal whose default
  // is off. Named rather than inlined so the one asymmetry in an otherwise
  // uniform property set says why it exists. Four tabs at rest — the count a
  // bottom bar ships with; three is `Show item 4` off, five is `Show item 5`
  // on.
  const kSpareDestination = 5;
  const destinationsByOrdinal = new Map<number, SceneNode[]>();
  const recordDestination = (ordinal: number, node: SceneNode): void => {
    const seen = destinationsByOrdinal.get(ordinal);
    if (seen) seen.push(node);
    else destinationsByOrdinal.set(ordinal, [node]);
  };
  for (const member of members) {
    const flags = member.flags;
    const combo = parseVariantKey(member.prefix);
    const variant = variantData.get(combo['Variant']);
    if (!variant) throw new Error(`NavigationBar: no data for combo "${member.name}"`);
    const c = mount.getOrCreate(member.name);
    // The shape. Everything below that differs between the three is what the
    // widget itself switches on `mode` — direction, the item's label variant,
    // the divider's orientation — read from the same field the widget reads.
    const mode = combo['Mode'] as keyof typeof NAVIGATION_BAR.variants.defaultsByMode;
    const vertical = mode !== 'bar';
    const along: 'HORIZONTAL' | 'VERTICAL' = vertical ? 'VERTICAL' : 'HORIZONTAL';
    // The horizontal bar's root is the margin wrapper: no chrome of its own,
    // `barMargin` as its padding. A vertical bar's root is the chrome itself
    // (below), so a designer sizes it in one step — see `chrome`.
    applyPanelCompChrome(c, along, lk, {});
    if (!vertical) bindPad(c, lk, f.barMargin);
    if (flags.Disabled) c.opacity = dimVal(clickable.disabledOpacity);
    // Before the items: a FILL child needs its parent fixed on that axis, and
    // that now holds twice over — the bar fills the wrapper, the items fill
    // the bar. `panel()` hugs both axes, so locking only the wrapper left the
    // bar hugging: destinations written FILL packed at intrinsic width against
    // the start (the same refusal horizontal Steps settles by fixing the row
    // before its connectors FILL).
    //
    // No field states any of these extents. The bar fills the available width
    // from a `LayoutBuilder` and scrolls past it; the vertical modes are
    // content-sized on Flutter and parent-sized on Web. The canvas has to pick
    // one per shape for the bar and its destinations to FILL, and the two
    // vertical numbers are the designer's own (72 / 240) since nothing in the
    // code prefers another.
    // g7-preview-only: demo extents per mode — bar width, rail width (the sidebar's is `kNavSidebarPreviewWidth`); no CoreNavigationBarStyle field states any of them.
    const previewWidth = mode === 'bar' ? 360 : mode === 'rail' ? 72 : kNavSidebarPreviewWidth;
    lockWidth(c, previewWidth);
    // `itemSpacing` is the mode cell's `spacing` (`defaultsByMode`), and the
    // member IS a mode, so the row is read straight from the data: 0 for the
    // bar (destinations pack edge to edge), `space8` for the rail, `space2`
    // for the sidebar. Passed as the `Dim` it arrives as, so the binding
    // travels with it.
    const itemGap = NAVIGATION_BAR.variants.defaultsByMode[mode].spacing;
    // The padding is the mode's too — the sidebar states its own (16 above
    // and below, 12 at the sides), the bar and the rail fall through to the
    // flat one. So is the glyph step each destination is swapped to
    // (`density.iconSize`, below).
    const density = navDensity(mode);
    const barPad = density.padding;
    // The bar's destinations stop at the mode's `itemMaxWidth` (#6406) and
    // the width left over is split on both sides — Flutter's capped cells in
    // a centred `Row`, Web's `max-width` on each `flex-1` cell in a
    // `justify-center` `<nav>`. Only the horizontal bar shares its axis out
    // as cells; a rail or sidebar destination spans its column.
    const destinationCap = vertical ? null : density.itemMaxWidth;
    const capDestination = (cell: FrameNode | InstanceNode): void => {
      if (destinationCap == null) return;
      cell.maxWidth = destinationCap;
      cell.setBoundVariable('maxWidth', lk.size(destinationCap));
    };
    // The bar's bottom is the padding the mode states and nothing more. A
    // docked bar adds the device's bottom safe area at run time (Flutter
    // `MediaQuery.paddingOf`, Web `env(safe-area-inset-bottom)`), and the
    // canvas draws no device — so it draws Core's value (#5740).
    //
    // Where the chrome lands differs by axis. The horizontal bar's chrome is
    // `bar`, inside the margin wrapper. A vertical bar's chrome is the
    // component root: face, trailing line, corners and padding on the root,
    // the rows in a hugging `bar` at the top and the footer after it, pushed
    // to the far edge by SPACE_BETWEEN. So a rail pinned to a screen draws its
    // face and line to the bottom with the rows on top and the footer at the
    // bottom (Flutter spans a tight height, Web is parent-sized), and set back
    // to HUG it shrinks to its rows in one step — no child FILLs the axis the
    // root hugs. `bar` FILL inside a fixed root drew the same picture, but HUG
    // on the instance alone then left it at the pinned height (canvas
    // measurement, 2026-11-17). The canvas draws the docked case, where
    // `barMargin` is zero, so the vertical root states no margin.
    const bar = vertical
      ? panel('bar', along, lk, { gap: itemGap })
      : panel('bar', along, lk, {
          pl: barPad.l,
          pr: barPad.r,
          pt: barPad.t,
          pb: barPad.b,
          gap: itemGap,
        });
    const chrome: FrameNode | ComponentNode = vertical ? c : bar;
    if (vertical) {
      bindPad(c, lk, barPad);
      c.primaryAxisAlignItems = 'SPACE_BETWEEN';
    }
    statedRadius(chrome, lk, f.barRadius.topLeft);
    // A floating surface on both platforms (`navigation_bar_style.dart` reads
    // `theme.surfaceFor(.functional)`; the Web twin marks the bar
    // `webSurfaceMarkerFor(.functional)`).
    // The face is the mode cell's when it states one (the bottom bar's
    // `surface`), else the variant's chrome tier — the order both resolvers
    // read it in.
    applySurfaceMaterial(
      chrome,
      lk,
      colorData(density.backgroundColor ?? variant.backgroundColor),
      'functional',
      { radius: statedCorner(f.barRadius.topLeft) },
    );
    // Drawn because `barMargin` is zero here — the docked case. See the
    // header note on why the widget (and `Dock`'s own hairline) makes
    // this conditional. One edge, the one facing the content: the top of
    // the horizontal bar, the trailing edge of a rail or sidebar — the
    // `BorderDirectional(top:)` / `BorderDirectional(end:)` the Flutter
    // resolver builds and the `border-top` / `border-inline-end` Web emits.
    // The canvas draws left-to-right, so the trailing edge is the right.
    borderData(
      chrome,
      lk,
      colorData(f.barBorderColor),
      f.barBorderWidth,
      vertical ? { right: true } : { top: true },
    );
    // The horizontal bar's line lies over its top padding instead of adding
    // to it — `barHairline` (a foreground decoration) on Flutter, a
    // `border-top` the top padding gives back on Web — so the bar is
    // `padding + item` tall with or without the line. The vertical modes
    // lay their trailing line out as a border, as both widgets do.
    chrome.strokesIncludedInLayout = vertical;
    c.appendChild(bar);
    // The bar's own axis, not a second preview number: same extent as the
    // wrapper so a FILL bar is a definite box, then FILL again so a consumer
    // stretching the instance still stretches the track (lockWidth alone
    // would pin the bar at the preview and leave leftover empty).
    lockWidth(bar, previewWidth);
    bar.layoutSizingHorizontal = 'FILL';
    // `CoreNavigationAlignment.defaultAlignment` is `center`; it has nothing
    // to place while the destinations fill the row, and places the leftover
    // once their cap stops them short of the edges.
    if (!vertical) bar.primaryAxisAlignItems = 'CENTER';
    const headerHolder = autoFrame('header', along);
    const headerContent = slotStandIn(page, 'header content', 'rectangular');
    headerHolder.appendChild(headerContent);
    bar.appendChild(headerHolder);
    if (vertical) {
      headerHolder.layoutSizingHorizontal = 'FILL';
      headerContent.layoutSizingHorizontal = 'FILL';
    }
    headerHolder.visible = false;
    headerHolders.push(headerHolder);
    headerContents.push(headerContent);
    let destinationIndex = 0;
    for (const entry of mode === 'sidebar' ? sidebarEntries : mode === 'rail' ? railEntries : barEntries) {
      if (entry.kind === 'divider') {
        // `_NavigationDividerLine`: a `Divider` whose orientation is the bar's
        // CROSS axis — a vertical rule in the horizontal bar, a horizontal one
        // in a rail or sidebar — inset by half the bar's `itemSpacing` on the
        // layout wrapper around it, along the bar's own axis.
        const halfGap = dimVal(itemGap) / 2;
        if (vertical) {
          const inset = panel('divider', 'VERTICAL', lk, { pt: halfGap, pb: halfGap });
          // Spans the bar, the way a horizontal `Divider` in a stretched
          // column does — the filling rule, not a stated length.
          hostedDivider(page, lk, inset, {
            forwarded: {
              color: colorData(f.dividerColor),
              thickness: f.dividerThickness,
            },
          });
          bar.appendChild(inset);
          inset.layoutSizingHorizontal = 'FILL';
          continue;
        }
        const inset = panel('divider', 'HORIZONTAL', lk, { pl: halfGap, pr: halfGap });
        inset.counterAxisAlignItems = 'CENTER';
        inset.appendChild(
          composedDivider(page, lk, {
            horizontal: false,
            length: 24,
            thickness: f.dividerThickness,
            color: colorData(f.dividerColor),
          }),
        );
        bar.appendChild(inset);
        continue;
      }
      if (entry.kind === 'label') {
        // `_NavigationSectionLabel`: `sectionLabelPadding` on a wrapper, one
        // text node inside it — more room above than below, so the header
        // binds to the group it opens. Not a destination — it takes no
        // radius, no background and no `destinationIndex`, because the
        // widget's switch does not give it any of the three.
        const section = panel('sectionLabel', 'HORIZONTAL', lk, {
          pl: sectionPad.l,
          pr: sectionPad.r,
          pt: sectionPad.t,
          pb: sectionPad.b,
        });
        section.counterAxisAlignItems = 'CENTER';
        section.appendChild(
          makeLabel(entry.label, lk, textLabelOpts(lk, sectionText)),
        );
        bar.appendChild(section);
        if (vertical) section.layoutSizingHorizontal = 'FILL';
        continue;
      }
      const it = entry;
      const i = destinationIndex;
      destinationIndex += 1;
      const ordinal = it.ordinal ?? i + 1;
      const selected = i === 0;
      const hovered = flags.Hover && i === 1;
      // `NavigationBarItem` is the designer's own component (see its header
      // note) — composed here rather than drawn, so a future edit to its
      // padding / radius / per-state colour reaches this bar the same way
      // an `Icon` or `Divider` change already does. The mutually-exclusive
      // state variant (`enabled` / `hover` / `focus` / `disabled`)
      // collapses this pose model's two independent flags — but selection is
      // its own axis, so the two are named separately instead of collapsed
      // into one member. That is the whole reason the axis moved: an item is
      // selected WHILE disabled (the `disabled` member that is `Selected=true`
      // keeps its selection mark, dimmed), and one axis could not say both.
      // The focused destination is the item's `focus` rung, so it lays the
      // 8 % layer both widgets lay under the ring (Flutter's tile wash, Web's
      // scoped `:focus-visible` rule). A disabled destination takes no focus.
      const focused = flags.Focus && selected && !flags.Disabled;
      const stateName = flags.Disabled
        ? 'disabled'
        : focused
          ? 'focus'
          : hovered
            ? 'hover'
            : 'enabled';
      // The label variant is what the widget's own defaults resolve to for
      // this shape (`_labelMode` / `_labelPosition` in `navigation_bar.dart`):
      // the sidebar labels every item at the end (`defaultSidebarMode = all`,
      // `defaultSidebarPosition = end`); the bar and the rail label every
      // destination under its icon (`defaultBarMode` / `defaultRailMode =
      // all`, #5740).
      const labelVariant = mode === 'sidebar' ? 'end' : 'bottom';
      const indicator = navModeIndicator(mode as NavMode);
      const item = instanceOf(
        page,
        'NavigationBarItem',
        `Label=${labelVariant}, State=${stateName}, Selected=${selected}, Indicator=${indicator}`,
      );
      // Swaps the glyph two levels deep — `setSlotIcon`'s `glyph` argument
      // reaches through the outer `Icon` INSTANCE_SWAP into the icon's own
      // nested glyph swap, the same path `form-pickers.ts`'s eye-dropper
      // slot already uses. Without it every composed destination would
      // show whichever glyph `buildNavigationBarItem` happened to draw.
      //
      // Swapped to the step the MEMBER's mode states (the sidebar's cell is
      // 18, the bar's and the rail's are the flat 24 — the size the item's own
      // builder draws that placement's glyph at), not the set's default and
      // not the flat field: a swap lands the variant it names, so a step read
      // from the flat `iconStyle` would write 24 over the sidebar row's 18.
      //
      // Repainted in the item's STATE tone after the swap (`navItemIconColor`:
      // the resting `iconStyle.color`, or `disabledIconStyle.color` for a
      // disabled destination), not left to Figma's override carry-over from the
      // item's `house`: that carry-over reaches only same-named leaves, so it
      // held while every destination glyph had no more leaves than `house` — a
      // condition nothing here guarded.
      setSlotIcon(
        item,
        'Icon',
        iconMainIdAt(page, dimVal(density.iconSize)),
        it.icon,
        glyphPaint(
          lk,
          glyphOpts(
            lk,
            colorData(
              navDestinationIconColor(stateName, selected, indicator),
            ),
            density.iconSize,
            'size',
          ),
        ),
      );
      if (it.label != null) {
        setInstanceLabel(item, it.label);
      } else {
        // The designer's states all carry a label; an icon-only
        // destination hides it rather than showing placeholder copy no real
        // icon-only item would have. The label is the text the set's `Label`
        // property writes — not the first text in the tree: the count badge
        // hangs over the icon ahead of it and carries text of its own, and
        // hiding that left the "Label" placeholder showing (#5740).
        for (const labelNode of instanceLabelNodes(item)) labelNode.visible = false;
      }
      // Focus is a fourth, independent axis the designer's states do not
      // model (a ring can land on any of the four), so the ring is drawn here
      // rather than taken from the item's own set.
      //
      // It needs a frame to hang from: the ring and its band are two absolute
      // children pinned STRETCH to the box they outline, and an instance takes
      // no children. So the focused destination sits in a hugging wrapper that
      // is exactly its box — the same shape the tooltip anchor below uses for
      // the same refusal — and the pair pins to the wrapper. The wrapper is
      // what `Show item N` hides, so the ring leaves with the item it rings.
      //
      // Drawn after both FILLs: the ring is measured from the settled box, and
      // the destination's width only exists once the bar has shared its track.
      // The bar is a frame, which clips — it has to let the ring stand outside
      // the destination's edge.
      //
      // `focused`, not `flags.Focus`: on a `Disabled=true` member every
      // destination is disabled, and neither widget lets a disabled
      // destination take focus — Flutter's `Clickable` hands `enabled: false`
      // to its `FocusableActionDetector`, Web's leaves the `tabindex` off. A
      // ring there names a pose no app reaches, so the member draws as its
      // `Focus=false` twin.
      if (focused) {
        // The `focus` member wears its own ring around the member; the bar
        // rings the cell itself (a ring inside an instance is not the
        // member's own pair), so the member's pair is hidden on this instance.
        for (const n of item.findAll(
          (k) => k.name === 'focus ring' || k.name === 'focus offset',
        )) {
          n.visible = false;
        }
        const focusHost = autoFrame('focusHost', along);
        focusHost.appendChild(item);
        bar.appendChild(focusHost);
        focusHost.layoutSizingHorizontal = 'FILL';
        item.layoutSizingHorizontal = 'FILL';
        capDestination(focusHost);
        bar.clipsContent = false;
        chrome.clipsContent = false;
        clickableFocusRing(focusHost, lk, clickable);
        recordDestination(ordinal, focusHost);
        continue;
      }
      if (it.tooltip == null) {
        bar.appendChild(item);
        item.layoutSizingHorizontal = 'FILL';
        capDestination(item);
        recordDestination(ordinal, item);
        continue;
      }
      // `content = Tooltip(message: tooltip, child: content)` — the widget
      // wraps this destination because it renders no label. A Figma instance
      // cannot take a child, so the bubble is stacked above the anchor
      // instead of enclosing it; both nodes are still the two the widget
      // composes, and the anchor is the Tooltip's `child` by position.
      const anchored = autoFrame('tooltipAnchor');
      anchored.counterAxisAlignItems = 'CENTER';
      const bubble = instanceOf(page, 'Tooltip');
      setInstanceLabel(bubble, it.tooltip);
      anchored.appendChild(bubble);
      anchored.appendChild(item);
      bar.appendChild(anchored);
      anchored.layoutSizingHorizontal = 'FILL';
      item.layoutSizingHorizontal = 'FILL';
      capDestination(anchored);
      // The wrapper, not the instance — hiding this destination has to take
      // its bubble with it, and the bubble is the wrapper's other child.
      recordDestination(ordinal, anchored);
    }
    // The footer, last along the bar's own axis — the bottom of a rail or
    // sidebar, the trailing end of the horizontal bar — in every mode, because
    // the slot is the contract's for all of them. A rail or sidebar stretches
    // it across the bar's width (`crossAxisAlignment: .stretch`); the
    // horizontal bar's row gives it its own width and the destinations share
    // the rest. Hidden at rest, a hidden child takes no room in the row, so
    // the edge-to-edge destination row the docs example draws is unchanged
    // until `Show footer` turns the slot on.
    // A vertical bar's footer is the root's last child, after `bar`, so
    // SPACE_BETWEEN puts it on the far edge of a pinned rail and a hugging
    // root still wraps it. Its top inset is the mode's spacing — the gap the
    // widget's column keeps between the items and the footer — because
    // SPACE_BETWEEN drops `itemSpacing` when the root hugs (canvas
    // measurement, 2026-11-17).
    const footerHolder = vertical
      ? panel('footer', along, lk, { pt: itemGap })
      : autoFrame('footer', along);
    const footerContent = slotStandIn(page, 'footer content', 'rectangular');
    footerHolder.appendChild(footerContent);
    (vertical ? c : bar).appendChild(footerHolder);
    if (vertical) {
      footerHolder.layoutSizingHorizontal = 'FILL';
      footerContent.layoutSizingHorizontal = 'FILL';
    }
    footerHolder.visible = false;
    footerHolders.push(footerHolder);
    footerContents.push(footerContent);
  }
  // `defaultSetLayout` over `vStackSet` — see the note at Breadcrumb's return.
  const set = mount.finish();
  // After `finish()`, for the reason `NavigationBarItem`'s own icon property
  // states: until the members are combined, `propertyOwner` answers with the
  // variant and each member would grow its own copy.
  for (const ordinal of [...destinationsByOrdinal.keys()].sort((a, b) => a - b)) {
    const prop = defineProp(
      set,
      `Show item ${ordinal}`,
      'BOOLEAN',
      ordinal !== kSpareDestination,
    );
    for (const node of destinationsByOrdinal.get(ordinal) ?? []) {
      bindVisibleProp(node, prop);
    }
  }
  const showHeaderProp = defineProp(set, 'Show header', 'BOOLEAN', false);
  for (const holder of headerHolders) bindVisibleProp(holder, showHeaderProp);
  const headerProp = defineProp(
    set,
    'Header',
    'INSTANCE_SWAP',
    slotStandInDefault(page, 'rectangular'),
  );
  for (const content of headerContents) bindSwapProp(content, headerProp);
  const showFooterProp = defineProp(set, 'Show footer', 'BOOLEAN', false);
  for (const holder of footerHolders) bindVisibleProp(holder, showFooterProp);
  const footerProp = defineProp(
    set,
    'Footer',
    'INSTANCE_SWAP',
    slotStandInDefault(page, 'rectangular'),
  );
  for (const content of footerContents) bindSwapProp(content, footerProp);
  return set;
}

// ─── NavigationMenu ──────────────────────────────────────────────────────────

// Data-driven from coui_core: NAVIGATION_MENU.fields (triggerPadding /
// triggerBorderRadius / triggerSpacing / chevronIconStyle) + the `Button` md
// row's `iconLabelGapStyle` + variants.defaultsByVariant
// (background + border), the table keyed off the ENUMERATED axis rather than
// read at a hardcoded name.
//
// #4036 (C4a) — `navigation_menu.axes` carries one Variant member (`standard`)
// and no Size/State/Enabled, so the four-axis enumeration is one combination and
// the Hover pose qualifies it. The loose COMPONENT is adopted as that
// combination at rest — never at `Hover=true`: a resting pose is what a static
// node rendered, and adopting the hovered member would hand every existing
// instance a fill the widget only paints under a pointer.
//
// Composes `Button` + `Icon`: the widget's trigger is `Button(variant:
// .menubar, trailing: chevron, buttonStyle: resolved.triggerButtonStyle, child:
// Text(item.label, …))` with `Icon(LucideIcons.chevronDown, iconStyle:
// resolved.chevronIconStyle)` as that Button's `trailing` — both are real
// composed children, so both are instances here.
//
// The chevron sits NEXT TO the Button instance inside a trigger frame rather
// than inside it: Figma cannot append a child to an instance, so the faithful
// home for it is a `trailing` INSTANCE_SWAP property on `Button` itself, which
// that component's own builder owns. The trigger frame carries the trigger's
// own chrome — the inset (`triggerButtonStyle.padding`, or the directional
// `contentTriggerButtonStyle.padding` for a trigger that owns a dropdown: 12 at
// the start, 8 at the end where the chevron sits), the corner, the label →
// chevron gap, and the fill. The Flutter widget hands the same inset to the
// composed Button, which has one padding of its own; the canvas draws it once,
// on the frame, and holds the Button instance's own at nothing.
//
// The fill is the open trigger's (`openTriggerButtonStyle.backgroundColor`,
// the hover colour, on the first trigger — the one the panel hangs from) and,
// in the Hover pose, a pointer's (`triggerHoverColor`, on the last).
//
// Composes `Popup`: the open dropdown is `_buildPanel`'s `Popup(popupStyle:
// resolved.panelStyle, children: [content])` — "the dropdown box is the
// unified `Popup` (no self-painted `Container`/`DecoratedBox`)"
// (navigation_menu.dart). The root is a vertical wrapper holding
// [bar, open panel], the same shape `DropdownMenu`'s builder uses for
// [trigger, panel]: a portal has no Figma equivalent, and a preview showing
// only the closed bar would claim this component has no dropdown.
//
// `panelStyle` is a nested `CorePopupStyle` slot forwarded whole, so every
// field where THIS component's value equals `Popup`'s own default is the
// child's to draw and is not repainted here — reaching in to restate one would
// be the second source `core/style-contract.md` forbids ("자식 default 에 reach
// 하지 마라").
//
// `boxShadow` is not one of those, and reading the rule as "never touch the
// instance" left it on the floor. The same rule says the parent forwards the
// fields that DIVERGE ("발산하는 override 만") — and this panel's elevation
// diverges: `panelStyle.boxShadow` is y8/blur16/spread-3 at 7% over
// y4/blur6/spread-2 at 4%, while `Popup`'s own default (which its builder does
// paint) is y4/blur8/-2 at 6% over y2/blur4/-1 at 4%. Un-forwarded, the
// instance renders the child's shallower stack and a dropdown the widget floats
// well clear of the page sits nearly flush with it.
//
// An instance's `effects` is one of the overrides Figma models, the same way
// `bindRadiusN` accepts an `InstanceNode` so a composing component can state a
// corner its child rests at another value. The tint comes from
// `panelStyle.shadowBaseColor` (Semantic/color/shadow), so the stack retints
// with the theme instead of being a baked black.
//
// The rest of the diverging fields are forwarded the same way —
// `applyForwardedPanelStyle` states the inset (16 vs `Popup`'s 4), the corner
// (the panel role, 12) and the minimum width (256 vs 128) on the instance.
//
// ─── The fills, and how far each reaches ────────────────────────────────────
//
// Two fills, one colour (surface-container, `triggerHoverColor`):
//
//   · The OPEN trigger's. The panel this preview draws open hangs from the
//     bar's leading edge, so the FIRST trigger is the open one, and it keeps the
//     fill while its dropdown is open — in every pose, because open is not a
//     pose. The widget states it through `openTriggerButtonStyle` (the
//     `backgroundColor` it adds to a content trigger), not through the
//     `menubar` variant's own selected fill, which is a stronger surface step
//     shared with `Menubar`.
//   · A pointer's, in the Hover pose. A pointer is in one place, and it lands
//     on the LAST trigger — the one without a chevron, which is the shape a
//     link / action takes. `triggerHoverColor` is the flat field the Web
//     `<a href>` link trigger paints on its own box; a `Button` trigger states
//     the same colour as `triggerButtonStyle.hoverBackgroundColor`, which is why
//     the two chevroned triggers here do not also take a hover fill.
//
// Reach, stated rather than implied: Flutter resolves `triggerHoverColor` into
// `ResolvedNavigationMenu` and then never reads it — a `Button` trigger takes
// its hover fill from its own style. Link is one of the three item kinds the
// widget documents (content / link / action) and this preview models two —
// every trigger here is a composed `Button` — so the pose paints the field on
// the frame that stands for the link's box without yet drawing the link's own
// contents.
//
// `triggerButtonStyle.focusOutlineStyle` is NOT an axis, for the reason that
// used to be claimed for the hover half too: it is a nested `CoreButtonStyle`
// slot, so it is `Button`'s state — and Flutter passes `disableFocusOutline:
// true` on this trigger besides, so the ring is suppressed here for parity.
//
// Shape change: this was a single COMPONENT and is now a COMPONENT_SET, which
// Figma cannot convert in place — see the `NavigationMenu` entry in
// `STRUCTURAL_MIGRATIONS` (`src/renames.ts`), without which the old node stays
// on the page as a same-named duplicate.
//
// ─── The bar has no box, and the box it had was the panel's ─────────────────
//
// The bar carried a fill, a hairline, a literal radius(8) and a literal
// padding(4,4,4,4) on the reading that "the root container has no padding/radius
// field of its own". It has none because the widget's bar has no box: `build`
// returns `Row(mainAxisSize: .min, crossAxisAlignment: .center, spacing:
// resolved.triggerSpacing)` wrapped in `Semantics`, and the Web bar is
// `flex flex-row items-center` with an inline `gap` and nothing else — no
// background, no border, no corners, no inset. `triggerSpacing` is the one bar-
// level value there is, and it is already read below.
//
// Where the box came from is the more useful part: the two colours were
// `defaultsByVariant`, which is a `Map<CoreNavigationMenuVariant,
// CorePopupStyle>` — the PANEL's per-variant chrome, as its own Core doc says
// ("Per-variant panel chrome … carrying only the variant-divergent background +
// border colours … raw-forwarded to the composed `Popup`"). And the two literals
// are `Popup`'s own defaults to the number (radius 8, padding 4 on all sides).
// So the bar was a copy of the dropdown, drawn one node too high.
//
// The panel's own builder paints what it owns, so only the variant's border
// is forwarded onto the instance (below), exactly as the shadow above is:
// `backgroundColor` IS `Popup`'s default (surface-bright), and restating it
// would be the reach `core/style-contract.md` forbids; `borderColor` is the
// variant table's outline-variant, the same line `Popup` states.
function buildNavigationMenu(page: PageNode, lk: VarLookup): ComponentSetNode {
  const f = NAVIGATION_MENU.fields;
  const triggerTextStyle = textStyleData(f.triggerTextStyle);
  // Same admission as a newly drawn label: a style may only carry the role
  // when every stated metric agrees with it. The Core role owns the style.
  const triggerRole = textLabelOpts(lk, triggerTextStyle).role;
  const variantData = new Map(Object.entries(NAVIGATION_MENU.variants.defaultsByVariant));
  const axes: StateAxis[] = ['Hover'];
  const members = poseMembers(NAVIGATION_MENU.axes, axes);
  const mount = mountSet(page, 'NavigationMenu', members.map((m) => m.name), {
    adoptLooseAs: 'Variant=standard, Hover=false',
  });
  const items: { label: string; submenu: boolean }[] = [
    { label: '제품', submenu: true },
    { label: '솔루션', submenu: true },
    { label: '요금', submenu: false },
  ];
  for (const member of members) {
    const flags = member.flags;
    const combo = parseVariantKey(member.prefix);
    const variant = variantData.get(combo['Variant']);
    if (!variant) throw new Error(`NavigationMenu: no data for combo "${member.name}"`);
    const c = mount.getOrCreate(member.name);
    applyPanelCompChrome(c, 'VERTICAL', lk, { gap: f.menuOffset });
    // The panel hangs from the anchor's leading edge, not from the bar's centre.
    c.counterAxisAlignItems = 'MIN';
    // `triggerSpacing` is the only bar-level value — no box of any kind, see the
    // header note on where the one it used to have came from.
    const bar = panel('bar', 'HORIZONTAL', lk, {
      gap: f.triggerSpacing,
    });
    bar.counterAxisAlignItems = 'CENTER';
    for (let i = 0; i < items.length; i++) {
      const it = items[i];
      // The trigger whose dropdown is open is the first — the panel below
      // hangs from its leading edge — and it keeps the hover fill while open
      // (`openTriggerButtonStyle`). The trigger a pointer is on in the Hover
      // pose is the last, the one without a chevron.
      const open = it.submenu && i === 0;
      const hovered = flags.Hover && i === items.length - 1;
      // A trigger that owns a dropdown carries its own inset (end side 8,
      // start side 12); one without takes the plain 12 / 12.
      const inset = (it.submenu ? f.contentTriggerButtonStyle : f.triggerButtonStyle).padding;
      const trigger = panel('trigger', 'HORIZONTAL', lk, {
        radius: f.triggerBorderRadius.topLeft,
        gap: f.triggerButtonStyle.iconLabelGapStyle.size,
      });
      // `start`/`end` — the inset is a statement about reading order.
      bindPad(trigger, lk, inset);
      trigger.counterAxisAlignItems = 'CENTER';
      if (open) fillData(trigger, lk, colorData(f.openTriggerButtonStyle.backgroundColor));
      // The hover fill: `triggerHoverColor` paints the link's own box on Web
      // and `triggerButtonStyle.hoverBackgroundColor` states the same colour
      // for a `Button` trigger.
      if (hovered) fillData(trigger, lk, colorData(f.triggerHoverColor));
      // The corner of `triggerButtonStyle`, forwarded — and the inset held at
      // nothing, because the frame above already spends it: the widget has one
      // padding (the Button's own), so the canvas draws it once, on the frame.
      const button = composedButton(page, lk, it.label, triggerTextStyle, {
        borderRadius: f.triggerButtonStyle.borderRadius,
        padding: NAVIGATION_MENU_BUTTON_NO_INSET,
      });
      trigger.appendChild(button);
      // The instance's copied label never went through makeLabel. Forwarding
      // metrics alone drops its textStyleId; queue the parent's admitted role
      // for the usual post-build attach, leaving Button's main untouched.
      if (triggerRole != null) {
        for (const label of ownTextNodes(button)) queueTextStyleAttach(label, triggerRole);
      }
      if (it.submenu) {
        const chevron = makeIcon(
          'chevron-down',
          lk,
          glyphOpts(lk, colorData(f.chevronIconStyle.color), f.chevronIconStyle.size, 'size'),
        );
        // Both runtimes turn the open disclosure through half a turn. Rotate
        // before append so auto-layout places the rotated 16×16 bounds; Figma's
        // rotation itself is about the node origin, not its centre.
        if (open) chevron.rotation = 180;
        trigger.appendChild(chevron);
      }
      bar.appendChild(trigger);
    }
    c.appendChild(bar);
    // The open dropdown — see the header note on `_buildPanel`, and on the one
    // field of `panelStyle` this component states differently from `Popup`.
    // `panelStyle`, forwarded into the composed `Popup` — the menu states the
    // dropdown's inset, corner and minimum width, and the instance was keeping
    // `Popup`'s own. The inset is `panelStyle.padding` = 16, the `Padding=content`
    // member; a one-off inset would still be written onto the instance.
    const dropdown = popupInstance(page, f.panelStyle.padding);
    applyForwardedPanelStyle(dropdown, lk, {
      padding: popupPaddingOverride(f.panelStyle.padding),
      borderRadius: f.panelStyle.borderRadius,
      minWidth: f.panelStyle.minWidth,
    });
    setShadow(
      dropdown,
      f.panelStyle.boxShadow,
      lk,
      colorData(f.panelStyle.shadowBaseColor),
    );
    // The per-variant panel border — the variant table's own colour, forwarded
    // onto the instance for the same reason the shadow above is.
    borderData(dropdown, lk, colorData(variant.borderColor));
    // The open dropdown holds the example links rather than the stand-in
    // (#6473): an open menu with a dashed box inside reads as empty. Written
    // on the composed `Popup`'s own `Content` slot — the caller's `content`.
    setInstanceSwapNamed(dropdown, 'Content', exampleMainId(page, kNavigationMenuExample));
    c.appendChild(dropdown);
  }
  // `defaultSetLayout` over `vStackSet` — see the note at Breadcrumb's return.
  return mount.finish();
}

// ─── Dock ────────────────────────────────────────────────────────────────────

// Data-driven from coui_core: DOCK.fields' barMargin / backgroundColor /
// borderColor / activeColor / inactiveColor / activeLabelStyle /
// inactiveLabelStyle / itemIconLabelGapStyle / indicatorColor /
// clickableStyle, and DOCK.sizes.defaultsBySize's per-size padding /
// barRadius / itemSpacing / itemWidth / iconStyle.size / indicatorRadius /
// indicatorPadding (the redesign of #6463 made all of them per size).
//
// Composes `Icon`: each app tile IS an icon (its dimension comes from
// `iconStyle.size` — an icon-style field), so it is an `Icon` instance rather
// than a coloured square standing in for one. Its colour comes from
// `activeColor`/`inactiveColor`, which is also why the dock's selection is
// rendered inline (one active app) rather than as an axis — a dock always has
// exactly one foreground app.
//
// State axes: Disabled (clickableStyle.disabledOpacity) and Focus
// (clickableStyle.focusOutlineStyle.borderColor, on the active app's tile —
// whose radius is clickableStyle.borderRadius, the real Clickable's).
//
// ─── Two nodes, because the bar has an inside and an outside ────────────────
//
// The root used to BE the bar, and that left `barMargin` with nowhere to go.
// `dock.dart` wraps its `Container` around the row and hands it BOTH insets:
// `padding` moves the apps within the bar and `margin` moves the bar itself off
// the edge it would otherwise sit flush against ("padding cannot stand in for
// it, because padding moves the items and leaves the bar's own box where it
// was" — the Core field's own doc). Figma auto-layout has no per-child margin,
// so the outside inset needs a frame outside the bar to be the padding of. Hence
// root = margin wrapper (no fill of its own), child `bar` = the fill / hairline /
// corners / padding.
//
// `barMargin` is `CoreEdgeInsets.zero` today; a margin the design ever sets
// detaches the bar here too instead of being silently absent.
//
// The line goes round the whole bar on both platforms (`Border.all` / an
// inline `border-width`): the bar is rounded at every size, and a line on one
// edge of a rounded box has nowhere to end.
//
// ─── Labels ─────────────────────────────────────────────────────────────────
//
// `md`/`lg`/`xl` render one, `xs`/`sm` do not — `CoreDockStyle.labelVisibleFor`
// is `size != .xs && size != .sm`, a static predicate rather than a field, so
// the size names are read from it rather than from the export (which carries
// fields, not that method). It is the same kind of branch as the variant
// switches elsewhere in this file, not a chrome literal.
//
// Drawing them is what makes `activeLabelStyle` (labelXs + SemiBold +
// on-surface) and `inactiveLabelStyle` (labelXs + Medium + on-surface-variant)
// exist on the canvas, and `itemIconLabelGapStyle` the gap between icon and
// words. The label states its own colour — the active icon is primary and its
// name the body colour — so `textLabelOpts` (the style's colour wins) is the
// helper, with the icon's colour only as the fallback.
//
// The tile is a COLUMN for the same reason: `_DockItem` is `Column(center, min)
// [IconTheme(icon), Gap, Text]`, so a row would put the label beside the icon.
//
// The inter-app gap is `itemSpacing`: the widgets pack the apps that far
// apart and centre them in the bar (`Row(center, spacing:)` /
// `justify-center` + `column-gap`), so the bar here hugs its apps with the
// same gap.
//
// Nothing clips: the plate overhangs the icon and the focus ring the tile, and
// neither widget clips the bar or the tile.
//
// ─── Shadow ─────────────────────────────────────────────────────────────────
//
// The bar casts `boxShadow` (`CoreShadow.md`) on `shadowBaseColor`, linked to
// the file's `shadow/md` effect style, and the style's rim on its material
// layer — both widgets name the rim beside a stated shadow
// (`resolveSurfaceRim` / `--coui-surface-rim`). The cast sits on the bar node
// and the material one layer down, because linking an effect style replaces a
// node's effects outright. A Disabled member casts nothing — the canvas pose
// the designer decided (#6463); the widgets have no disabled state of their
// own to draw it from.
async function buildDock(page: PageNode, lk: VarLookup): Promise<ComponentSetNode> {
  const f = DOCK.fields;
  const clickable = f.clickableStyle;
  const activeLabel = textStyleData(f.activeLabelStyle);
  const inactiveLabel = textStyleData(f.inactiveLabelStyle);
  const sizes = Object.entries(DOCK.sizes.defaultsBySize);
  const axes: StateAxis[] = ['Disabled', 'Focus'];
  const combos = stateCombos(axes);
  const names: string[] = [];
  for (const [zn] of sizes) {
    for (const flags of combos) {
      names.push(variantName(`Size=${zn}`, stateSuffix(axes, flags)));
    }
  }
  const mount = mountSet(page, 'Dock', names);
  const apps: { icon: string; label: string }[] = [
    { icon: 'house', label: '홈' },
    { icon: 'search', label: '검색' },
    { icon: 'inbox', label: '받은편지함' },
    { icon: 'calendar', label: '캘린더' },
    { icon: 'image', label: '사진' },
  ];
  for (const [zn, sz] of sizes) {
    // `CoreDockStyle.labelVisibleFor(size)` — see the header note.
    const showLabel = zn !== 'xs' && zn !== 'sm';
    const pad = sz.padding;
    // A fixed cell where the size gives one (`itemWidth`), the icon's own
    // width otherwise.
    const cellWidth = 'itemWidth' in sz ? sz.itemWidth : null;
    for (const flags of combos) {
      const c = mount.getOrCreate(variantName(`Size=${zn}`, stateSuffix(axes, flags)));
      // The margin wrapper: no chrome of its own, `barMargin` as its padding.
      applyPanelCompChrome(c, 'HORIZONTAL', lk, {});
      bindPad(c, lk, f.barMargin);
      c.counterAxisAlignItems = 'CENTER';
      // Above and below, the widgets keep the larger of the padding and the
      // plate's reach (`CoreDockStyle.rowInsetFor`); the size rows' padding is
      // the larger at every size, so the padding is the inset drawn.
      const bar = panel('bar', 'HORIZONTAL', lk, {
        pl: pad.l, pr: pad.r, pt: pad.t, pb: pad.b,
        gap: sz.itemSpacing,
      });
      statedRadius(bar, lk, sz.barRadius.topLeft);
      bar.counterAxisAlignItems = 'CENTER';
      bar.clipsContent = false;
      // A floating surface on both platforms (`dock_style.dart` reads
      // `theme.surfaceFor(.functional)`; the Web twin marks the bar
      // `webSurfaceMarkerFor(.functional)`).
      const casts = !flags.Disabled;
      applySurfaceMaterial(bar, lk, colorData(f.backgroundColor), 'functional', {
        radius: statedCorner(sz.barRadius.topLeft),
        rim: casts,
      });
      if (casts) {
        setShadow(bar, f.boxShadow, lk, colorData(f.shadowBaseColor));
        await linkShadowStyle(bar, f.boxShadow, `Dock/${zn} bar`);
      }
      // All round — see the header note. The width is the style's
      // `borderWidth`, the same field both resolvers read.
      borderData(bar, lk, colorData(f.borderColor), f.borderWidth);
      c.appendChild(bar);
      if (flags.Disabled) c.opacity = dimVal(clickable.disabledOpacity);
      for (let i = 0; i < apps.length; i++) {
        const active = i === 0;
        // Each app tile is a `Clickable` in the widget — a pure wrapper, and a
        // Figma instance cannot take the child it wraps, so nothing is
        // instantiated. Its resolved chrome is this frame's radius plus the
        // Focus ring below and the Disabled opacity on the root.
        //
        // VERTICAL and gapped: the tile is `Column [icon, Gap, Text]`.
        const app = panel('app', 'VERTICAL', lk, {
          radius: clickable.borderRadius.topLeft,
          gap: f.itemIconLabelGapStyle.size,
        });
        app.primaryAxisAlignItems = 'CENTER';
        app.counterAxisAlignItems = 'CENTER';
        app.clipsContent = false;
        const foreground = colorData(active ? f.activeColor : f.inactiveColor);
        const iconOpts: IconOpts = glyphOpts(lk, foreground, sz.iconStyle.size, 'size');
        // `sm`'s 22 is off the icon ladder by a recorded design decision
        // (`CoreDockStyle.smIconSize`), so its rescale is not reported as drift.
        // Matched on the exported constant, not on 22, so a different
        // off-ladder size here would still be reported.
        if (dimVal(sz.iconStyle.size) === dimVal(DOCK.constants.smIconSize)) iconOpts.statedOffLadder = true;
        const iconNode = makeIcon(apps[i].icon, lk, iconOpts);
        app.appendChild(iconNode);
        if (showLabel) {
          app.appendChild(
            makeLabel(
              apps[i].label,
              lk,
              textLabelOpts(lk, active ? activeLabel : inactiveLabel, foreground),
            ),
          );
        }
        bar.appendChild(app);
        if (cellWidth != null) {
          // The cell's fixed width (`SizedBox(width: itemWidth)` /
          // inline `width`), so a long name wraps inside it.
          lockWidth(app, cellWidth);
          const width = dimVal(cellWidth);
          if (lk.sizeOrNull(width)) app.setBoundVariable('width', lk.size(width));
        }
        if (active) {
          // The landed plate. `dock.dart` stacks it BEHIND the active item's
          // icon row — `Stacks(clipBehavior: .none, [Position(-indicatorPadding)
          // → DecoratedBox(indicatorColor, indicatorRadius), iconRow])`, the
          // row being the icon's height across the cell's width — and the
          // stack sizes to the row, so the tile's own box is exactly what it
          // is without a plate and the plate overhangs the row by the padding
          // on every side. Child 0 of the tile, pinned, offset by the negative
          // inset.
          //
          // `Stacks` itself is not composed: it is a layout primitive with no
          // chrome of its own, and a Figma instance cannot take the children
          // it wraps (the `Clickable` exclusion, for the same reason). The
          // bar's OTHER stack — `Stacks(fit: .expand, [Position.fill →
          // LiquidMorphClip, Row])` — is the flight fill that exists only
          // while the pill travels between items; the spring settles and it
          // is gone, so a still canvas has no such overlap to draw.
          const overhang = sz.indicatorPadding;
          const pill = figma.createRectangle();
          pill.name = 'indicator';
          fillData(pill, lk, colorData(f.indicatorColor));
          bindRadiusN(pill, lk, sz.indicatorRadius.topLeft);
          // Read ONCE, before the plate goes in: the read flushes the tile's
          // layout (icon + label shaped) and every dimension comes from that
          // one flush. An absolute child does not change the hug, so the box
          // stays true after the insert.
          const row = { width: app.width, top: iconNode.y, height: iconNode.height };
          // `insertChild` first, then pin — `pinAbsolute` appends, so pinning
          // and then moving to index 0 would reparent the same node twice.
          app.insertChild(0, pill);
          pinInFlow(app, pill);
          sizePin(
            pill,
            row.width + dimVal(overhang.l) + dimVal(overhang.r),
            row.height + dimVal(overhang.t) + dimVal(overhang.b),
          );
          pill.x = -dimVal(overhang.l);
          pill.y = row.top - dimVal(overhang.t);
          // STRETCH on both axes, like every pinned layer: the plate keeps its
          // reach past the icon row as the designer resizes the tile.
          pill.constraints = { horizontal: 'STRETCH', vertical: 'STRETCH' };
        }
        // After the plate, so the pair ends the tile's child order, above
        // everything the tile draws.
        if (active && flags.Focus) {
          clickableFocusRing(app, lk, clickable);
        }
      }
    }
  }
  return mount.finish();
}

// ─── Registry ────────────────────────────────────────────────────────────────

export const NAVIGATION_BUILDERS: RegistryEntry[] = [
  { section: 'Navigation', name: 'Breadcrumb', build: buildBreadcrumb, needs: ['Icon'] },
  { section: 'Navigation', name: 'Pagination', build: buildPagination, needs: ['Icon'] },
  {
    section: 'Navigation',
    name: 'TabItem',
    sizing: { height: 'fixed', why: 'tabs.dart 가 항목을 resolved.itemHeight 로 고정(SizedBox height); 폭은 라벨을 hug' },
    build: buildTabItem,
    // Its chrome is a fragment of `CoreTabsStyle` — `CoreTabItem` is a data
    // value with no Style of its own, so its stated values live under the
    // bar's slug. `dataFields` is what this builder reads from it (through
    // `f`, the variant row and the size row) — the bar's own chrome
    // (`containerRadius` / `borderWidth` / `tabSpacing` / swipe / transition)
    // is not the item's to match, and compared against the whole record the
    // item would be asked for values it has no reason to paint.
    dataSlug: 'tabs',
    dataFields: [
      'activeContentColor',
      'activeFontWeight',
      'activeIndicatorColor',
      'activeIndicatorRadius',
      'activeIndicatorThickness',
      'clickableStyle',
      'closeButtonStyle',
      'closeIconStyle',
      'contentTextStyle',
      'disabledContentColor',
      'disabledIndicatorColor',
      'hoverStateLayerColor',
      'inactiveContentColor',
      'inactiveFontWeight',
      'itemHeight',
      'labelBadgeGapStyle',
      'pressedStateLayerColor',
      'sizeRungIsTrack',
      'tabBarPadding',
      'tabPadding',
    ],
    // The count badge it composes after its label (`CoreTabItem.badge`).
    needs: ['Badge'],
  },
  { section: 'Navigation', name: 'Tabs', build: buildTabs, needs: ['TabItem'] },
  { section: 'Navigation', name: 'StepItem', build: buildStepItem, needs: ['Icon'] },
  { section: 'Navigation', name: 'Steps', build: buildSteps, needs: ['Divider', 'Icon', 'StepItem'] },
  { section: 'Navigation', name: 'Link', build: buildLink },
  { section: 'Navigation', name: 'Menubar', build: buildMenubar, needs: ['Button', 'Menu'] },
  {
    section: 'Navigation',
    name: 'NavigationBarItem',
    build: buildNavigationBarItem,
    // `Badge` — the count `Show count` composes (`CoreNavigationBarItem.badge`).
    needs: ['Badge', 'Icon'],
    // Its chrome is a fragment of `CoreNavigationBarStyle` — there is no
    // separate `CoreNavigationBarItemStyle` contract, so its stated
    // values live under the parent's own slug. `dataFields` is what this
    // builder reads from it — through `f` and through the helpers it calls
    // (`navDisabledIconColor`, `navBadgeOffset`), which is where
    // `disabledIconStyle` and `badgeIndicatorStyle` are read — and the
    // per-mode cell fields it paints (`iconStyle` / `itemMinHeight` /
    // `itemPadding` / `labelSpacing` / `labelTextStyle` /
    // `selectedBackgroundColor`, each named like the flat field it overrides).
    // The bar's chrome (`bar*` / `divider*` / `padding` /
    // `sectionLabelTextStyle`) is drawn by `buildNavigationBar` and compared
    // there.
    dataSlug: 'navigation_bar',
    dataFields: [
      'badgeIndicatorStyle',
      'disabledIconStyle',
      'disabledLabelTextStyle',
      'hoverBackgroundColor',
      'iconStyle',
      'itemMinHeight',
      // The painted floor of an icon-only destination (`Label=none`).
      'iconOnlyItemMinHeight',
      'iconOnlyItemMinWidth',
      'itemPadding',
      'itemRadius',
      'labelSpacing',
      'labelTextStyle',
      'selectedBackgroundColor',
      'selectedLabelTextStyle',
      // The destination's own state chrome (#4552): the layer's ink and
      // weights, and the `Clickable` ring the `focus` rung wears.
      'stateLayer',
      'stateLayerColor',
      'clickableStyle',
      // The selection mark `Show mark` draws — the slot of the dot and the
      // gap under it.
      'selectionMarkStyle',
      'selectionMarkGapStyle',
      'disabledSelectionMarkStyle',
      // The icon box a stacked destination keeps its glyph in.
      'iconAnchorPadding',
      // A selected, disabled destination keeps its mark, dimmed (#5740): the
      // face on the tile and the label at the selected weight.
      'disabledSelectedBackgroundColor',
      'disabledSelectedLabelTextStyle',
    ],
  },
  {
    section: 'Navigation',
    name: 'NavigationBar',
    build: buildNavigationBar,
    // The slot stand-in draws the `footer` slot.
    needs: ['Divider', 'Icon', 'NavigationBarItem', 'Tooltip', kSlotStandInComponent],
  },
  {
    section: 'Navigation',
    name: 'NavigationMenu',
    build: buildNavigationMenu,
    needs: ['Button', 'Icon', 'Popup', kNavigationMenuExample],
  },
  { section: 'Navigation', name: 'Dock', build: buildDock, needs: ['Icon'] },
];
