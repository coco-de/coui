/// <reference types="@figma/plugin-typings" />

// ─── Sidebar family ──────────────────────────────────────────────────────────
//
// Seven sets drawn from the seven Core styles (`CoreSidebar*Style`): the row,
// the rail destination, the section label, the header, the search trigger,
// the expandable group and the sidebar that composes them. Every value is read
// from `components.json`; the only numbers below are positions computed from
// those values.
//
// The axes are the code's: `Level` is `CoreSidebarItemLevel` (top / nested),
// `Type` is `CoreSidebarType` (standard / twoPane / collapsed) and the header's
// `Variant` is `CoreSidebarHeaderVariant` (plain / card). `Selected` and
// `Expanded` are value states on their own axes (R2); `State` is the
// interaction rung the widgets pick a wash for (R1).

import {
  RegistryEntry,
  VarLookup,
  autoFrame,
  bestVariantName,
  bindLayerOpacity,
  bindPad,
  bindRadiusN,
  bindSize,
  bindSpaceField,
  bindSwapProp,
  bindTextProp,
  bindVisibleProp,
  borderData,
  composeCountBadge,
  defaultSetLayout,
  defineProp,
  exposeSlot,
  fillData,
  focusOutlineRingColor,
  focusRing,
  glyphOpts,
  glyphPaint,
  iconMainId,
  iconMainIdAt,
  iconSwapDefault,
  instanceOf,
  kSlotStandInComponent,
  lockWidth,
  mainComponentIdOf,
  makeIcon,
  makeLabel,
  mint,
  mountSet,
  paintsFill,
  pinAbsolute,
  pinInFlow,
  setInstanceBoolNamed,
  setInstanceTextNamed,
  setSlotIcon,
  slotStandIn,
  slotStandInDefault,
  textLabelOpts,
} from '../helpers';
import type { FocusRingNodes } from '../helpers';
import { bindShowFocusRing, defineShowFocusRing, stateAxis } from '../state-axis';
import { Color, Dim, TextLeaf, colorData, dimVal, textStyleData } from '../compat/v1';
import { COMPONENTS } from '../data';
import { enumerateAxisAssignments } from '../axis-combos';
import {
  kBadgeDefaultTone,
  kCountBadgeForm,
  kCountBadgeSize,
  kCountBadgeVariant,
} from '../instance-reach';

const SIDEBAR = COMPONENTS.sidebar;
const SIDEBAR_ITEM = COMPONENTS.sidebar_item;
const SIDEBAR_RAIL_ITEM = COMPONENTS.sidebar_rail_item;
const SIDEBAR_SECTION = COMPONENTS.sidebar_section;
const SIDEBAR_HEADER = COMPONENTS.sidebar_header;
const SIDEBAR_SEARCH = COMPONENTS.sidebar_search;
const SIDEBAR_GROUP = COMPONENTS.sidebar_group;

const kRowStates = stateAxis(['enabled', 'hover', 'focus', 'disabled']);
type RowState = (typeof kRowStates)[number];
const kSearchStates = stateAxis(['enabled', 'hover', 'focus']);
type SearchState = (typeof kSearchStates)[number];

// The width a row takes inside the standard panel — the panel's own width less
// the body's start and end insets, the space `Column(crossAxisAlignment:
// .stretch)` hands each row.
function rowWidth(): number {
  const row = SIDEBAR.variants.defaultsByType.standard;
  return dimVal(row.panelWidth) - dimVal(row.bodyPadding.l) - dimVal(row.bodyPadding.r);
}

// The wash weight a rung lays over a row — `stateLayer.hover / focus` of the
// ink `stateLayerColor`, the value both resolvers `withValues(alpha:)` it at.
// Rest and disabled carry none.
function washWeight(
  state: RowState | SearchState,
  layer: { hover: number; focus: number },
): number | null {
  if (state === 'hover') return layer.hover;
  if (state === 'focus') return layer.focus;
  return null;
}

// The wash itself: a rect at child 0 spanning the box, rounded with it.
function addWash(
  host: ComponentNode,
  lk: VarLookup,
  ink: Color,
  weight: number,
  corner: Dim,
): RectangleNode {
  const wash = figma.createRectangle();
  wash.name = 'state layer';
  bindRadiusN(wash, lk, corner);
  fillData(wash, lk, colorData(ink));
  bindLayerOpacity(wash, lk, weight);
  host.insertChild(0, wash);
  pinInFlow(host, wash);
  wash.constraints = { horizontal: 'STRETCH', vertical: 'STRETCH' };
  wash.resize(Math.max(1, host.width), Math.max(1, host.height));
  wash.x = 0;
  wash.y = 0;
  return wash;
}

function ringOf(
  host: ComponentNode,
  lk: VarLookup,
  outline: { align: Dim; borderWidth: Dim; borderColor: Color; ringOpacity: Dim },
  corner: Dim,
  visible: boolean,
): FocusRingNodes {
  return focusRing(host, lk, {
    outline,
    color: focusOutlineRingColor(outline),
    corner,
    width: host.width,
    height: host.height,
    visible,
  });
}

function dotNode(lk: VarLookup, color: Color, size: Dim): EllipseNode {
  const dot = figma.createEllipse();
  dot.name = 'dot';
  bindSize(dot, lk, size, size);
  fillData(dot, lk, colorData(color));
  return dot;
}

// Surfaces a composed part in the panel, so a designer edits its caption,
// glyph and toggles from the parent — the way the widget's slot takes any
// widget. Figma refuses this on some hosts; the part then stays reachable by
// selecting it.
function exposeParts(host: ComponentNode): void {
  for (const n of host.findAll((x) => x.type === 'INSTANCE')) {
    const inst = n as InstanceNode;
    if (inst.parent && inst.parent.type === 'INSTANCE') continue;
    try {
      inst.isExposedInstance = true;
    } catch {
      // Left reachable by direct selection.
    }
  }
}

// ─── SidebarItem ─────────────────────────────────────────────────────────────

function buildSidebarItem(page: PageNode, lk: VarLookup): ComponentSetNode {
  const f = SIDEBAR_ITEM.fields;
  const levels = new Map(Object.entries(SIDEBAR_ITEM.variants.defaultsByLevel));
  const levelAxis = SIDEBAR_ITEM.axes.other.find((o) => o.enum === 'CoreSidebarItemLevel');
  if (!levelAxis) {
    throw new Error('SidebarItem: CoreSidebarItemLevel is gone from the exported axes.');
  }
  const members = enumerateAxisAssignments([
    { axis: 'State' as const, values: kRowStates },
    { axis: 'Level' as const, values: levelAxis.members },
    { axis: 'Selected' as const, values: ['false', 'true'] },
  ]);
  const leadSwap = iconSwapDefault(page, 'SidebarItem', 'Leading', iconMainId(page));
  const trailSwap = iconSwapDefault(page, 'SidebarItem', 'Trailing', iconMainId(page));
  const mount = mountSet(
    page,
    'SidebarItem',
    members.map((m) => m.name),
  );
  const labels: TextNode[] = [];
  const leads: InstanceNode[] = [];
  const trails: InstanceNode[] = [];
  const dots: EllipseNode[] = [];
  const rows: ComponentNode[] = [];
  const rings: FocusRingNodes[] = [];
  for (const m of members) {
    const level = levels.get(m.values['Level']);
    if (!level) throw new Error(`SidebarItem: no level row for "${m.name}"`);
    const state = m.values['State'] as RowState;
    // Disabled outranks selection — a disabled row is never the current place.
    const selected = m.values['Selected'] === 'true' && state !== 'disabled';
    const c = mount.getOrCreate(m.name);
    c.layoutMode = 'HORIZONTAL';
    c.primaryAxisSizingMode = 'AUTO';
    c.counterAxisSizingMode = 'AUTO';
    c.counterAxisAlignItems = 'CENTER';
    c.fills = [];
    bindPad(c, lk, f.padding);
    bindSpaceField(c, 'itemSpacing', lk, dimVal(f.contentSpacing));
    bindRadiusN(c, lk, f.borderRadius.topLeft);
    const height = dimVal(level.minHeight);
    c.minHeight = height;
    const step = lk.sizeOrNull(height);
    if (step) c.setBoundVariable('minHeight', step);
    const face = colorData(selected ? f.selectedBackgroundColor : f.backgroundColor);
    if (paintsFill(face)) fillData(c, lk, face);

    const iconColor =
      state === 'disabled'
        ? f.disabledIconStyle.color
        : selected
          ? f.selectedIconStyle.color
          : f.iconStyle.color;
    const lead = makeIcon('house', lk, {
      ...glyphOpts(lk, colorData(iconColor), f.iconStyle.size, 'size'),
      fromVariant: leadSwap.variant,
    });
    lead.name = 'leading';
    c.appendChild(lead);
    leads.push(lead);

    // The level states the role; the state lays its colour (and the selected
    // weight) over it — `CoreTextStyle.merge`, role from the later leaf.
    const stateLeaf: TextLeaf =
      state === 'disabled' ? f.disabledLabelStyle : selected ? f.selectedLabelStyle : f.labelStyle;
    const label = makeLabel(
      '대시보드',
      lk,
      textLabelOpts(lk, textStyleData({ ...stateLeaf, ...level.labelStyle })),
    );
    label.name = 'label';
    c.appendChild(label);
    labels.push(label);

    const dot = dotNode(lk, f.dotColor, f.dotSize);
    dot.visible = false;
    c.appendChild(dot);
    dots.push(dot);

    // A disabled row's trailing glyph takes the row's disabled ink, the same
    // `disabledContent` its label and leading glyph wear; left at the resting
    // `onSurfaceSubtle` it read as the one live part of a dead row. Disabled
    // outranks selection, so there is no selected trailing ink.
    const trailColor =
      state === 'disabled' ? f.disabledTrailingIconStyle.color : f.trailingIconStyle.color;
    const trail = makeIcon('chevron-right', lk, {
      ...glyphOpts(lk, colorData(trailColor), f.trailingIconStyle.size, 'size'),
      fromVariant: trailSwap.variant,
    });
    trail.name = 'trailing';
    trail.visible = false;
    c.appendChild(trail);
    trails.push(trail);

    lockWidth(c, rowWidth());
    label.layoutSizingHorizontal = 'FILL';
    const weight = state === 'disabled' ? null : washWeight(state, f.stateLayer);
    if (weight != null && weight > 0) {
      addWash(c, lk, f.stateLayerColor, weight, f.borderRadius.topLeft);
    }
    rows.push(c);
    rings.push(
      ringOf(c, lk, f.clickableStyle.focusOutlineStyle, f.borderRadius.topLeft, state === 'focus'),
    );
  }
  const set = mount.finish();
  const labelProp = defineProp(set, 'Label', 'TEXT', '대시보드');
  for (const t of labels) bindTextProp(t, labelProp);
  const leadProp = defineProp(set, 'Leading', 'INSTANCE_SWAP', leadSwap.id);
  for (const n of leads) bindSwapProp(n, leadProp);
  const trailProp = defineProp(set, 'Trailing', 'INSTANCE_SWAP', trailSwap.id);
  for (const n of trails) bindSwapProp(n, trailProp);
  const showLead = defineProp(set, 'Show leading', 'BOOLEAN', true);
  for (const n of leads) bindVisibleProp(n, showLead);
  const showTrail = defineProp(set, 'Show trailing', 'BOOLEAN', false);
  for (const n of trails) bindVisibleProp(n, showTrail);
  const showDot = defineProp(set, 'Show dot', 'BOOLEAN', false);
  for (const n of dots) bindVisibleProp(n, showDot);
  // The count sits after the dot and before the trailing glyph, the widget's
  // `Row` order; the badge is appended last, so the trailing glyph moves after it.
  const showCount = defineProp(set, 'Show count', 'BOOLEAN', false);
  const countVariant = bestVariantName(page, 'Badge', {
    Tone: kBadgeDefaultTone,
    Variant: kCountBadgeVariant,
    Size: kCountBadgeSize,
    Style: kCountBadgeForm,
  });
  const countProp = defineProp(
    set, 'Count', 'INSTANCE_SWAP', mainComponentIdOf(page, 'Badge', countVariant),
  );
  for (let i = 0; i < rows.length; i++) {
    const badge = composeCountBadge(page, rows[i], showCount);
    bindSwapProp(badge, countProp);
    rows[i].appendChild(trails[i]);
    // The ring stays the last child — it paints over the row it surrounds.
    rows[i].appendChild(rings[i].band);
    rows[i].appendChild(rings[i].ring);
  }
  const showRing = defineShowFocusRing(set);
  for (const ring of rings) bindShowFocusRing(ring, showRing);
  defaultSetLayout(set, { Level: levelAxis.members[0], State: 'enabled', Selected: 'false' });
  return set;
}

// ─── SidebarRailItem ─────────────────────────────────────────────────────────

function buildSidebarRailItem(page: PageNode, lk: VarLookup): ComponentSetNode {
  const f = SIDEBAR_RAIL_ITEM.fields;
  const members = enumerateAxisAssignments([
    { axis: 'State' as const, values: kRowStates },
    { axis: 'Selected' as const, values: ['false', 'true'] },
  ]);
  const swap = iconSwapDefault(page, 'SidebarRailItem', 'Icon', iconMainId(page));
  const mount = mountSet(
    page,
    'SidebarRailItem',
    members.map((m) => m.name),
  );
  const icons: InstanceNode[] = [];
  const hosts: ComponentNode[] = [];
  const rings: FocusRingNodes[] = [];
  const tooltipHolders: SceneNode[] = [];
  const tooltips: InstanceNode[] = [];
  for (const m of members) {
    const state = m.values['State'] as RowState;
    const selected = m.values['Selected'] === 'true' && state !== 'disabled';
    const c = mount.getOrCreate(m.name);
    c.layoutMode = 'HORIZONTAL';
    c.primaryAxisSizingMode = 'FIXED';
    c.counterAxisSizingMode = 'FIXED';
    c.primaryAxisAlignItems = 'CENTER';
    c.counterAxisAlignItems = 'CENTER';
    c.fills = [];
    c.clipsContent = false;
    bindSize(c, lk, f.size, f.size);
    bindRadiusN(c, lk, f.borderRadius.topLeft);
    const face = colorData(selected ? f.selectedBackgroundColor : f.backgroundColor);
    if (paintsFill(face)) fillData(c, lk, face);
    const iconColor =
      state === 'disabled'
        ? f.disabledIconStyle.color
        : selected
          ? f.selectedIconStyle.color
          : f.iconStyle.color;
    const icon = makeIcon('house', lk, {
      ...glyphOpts(lk, colorData(iconColor), f.iconStyle.size, 'size'),
      fromVariant: swap.variant,
    });
    icon.name = 'icon';
    c.appendChild(icon);
    icons.push(icon);
    const weight = state === 'disabled' ? null : washWeight(state, f.stateLayer);
    if (weight != null && weight > 0) {
      addWash(c, lk, f.stateLayerColor, weight, f.borderRadius.topLeft);
    }
    hosts.push(c);
    rings.push(
      ringOf(c, lk, f.clickableStyle.focusOutlineStyle, f.borderRadius.topLeft, state === 'focus'),
    );
    // Flutter displays a right-positioned Tooltip only on interaction. A
    // hidden, absolutely positioned instance keeps the rest pose unchanged
    // and lets the designer inspect that overlay without faking its chrome.
    const tooltip = instanceOf(page, 'Tooltip', bestVariantName(page, 'Tooltip', { Position: 'right' }));
    tooltip.name = 'tooltip';
    setInstanceTextNamed(tooltip, 'TooltipChild', '홈');
    const holder = pinAbsolute(c, tooltip,
      dimVal(f.size) + dimVal(COMPONENTS.tooltip.fields.placementOffset),
      (dimVal(f.size) - tooltip.height) / 2,
      { horizontal: 'MAX', vertical: 'CENTER' });
    holder.visible = false;
    tooltipHolders.push(holder);
    tooltips.push(tooltip);
  }
  const set = mount.finish();
  const iconProp = defineProp(set, 'Icon', 'INSTANCE_SWAP', swap.id);
  for (const n of icons) bindSwapProp(n, iconProp);
  // The unread dot — `Position(top: dotSize, right: dotSize)` in the widget.
  const showDot = defineProp(set, 'Show dot', 'BOOLEAN', false);
  const inset = dimVal(f.dotSize);
  for (let i = 0; i < hosts.length; i++) {
    const c = hosts[i];
    const dot = dotNode(lk, f.dotColor, f.dotSize);
    pinAbsolute(c, dot, c.width - inset - dimVal(f.dotSize), inset, {
      horizontal: 'MAX',
      vertical: 'MIN',
    });
    dot.visible = false;
    bindVisibleProp(dot, showDot);
    // The ring stays the last child — it paints over the box it surrounds.
    c.appendChild(rings[i].band);
    c.appendChild(rings[i].ring);
  }
  const showRing = defineShowFocusRing(set);
  for (const ring of rings) bindShowFocusRing(ring, showRing);
  const showTooltip = defineProp(set, 'Show tooltip', 'BOOLEAN', false);
  for (const holder of tooltipHolders) bindVisibleProp(holder, showTooltip);
  exposeSlot(tooltips, 'TooltipChild', 'TEXT');
  defaultSetLayout(set, { State: 'enabled', Selected: 'false' });
  return set;
}

// ─── SidebarSection ──────────────────────────────────────────────────────────

function buildSidebarSection(page: PageNode, lk: VarLookup): ComponentNode {
  const f = SIDEBAR_SECTION.fields;
  const c = mint(page, 'SidebarSection');
  c.layoutMode = 'HORIZONTAL';
  c.primaryAxisSizingMode = 'AUTO';
  c.counterAxisSizingMode = 'AUTO';
  c.counterAxisAlignItems = 'CENTER';
  c.fills = [];
  bindPad(c, lk, f.padding);
  bindSpaceField(c, 'itemSpacing', lk, dimVal(f.contentSpacing));
  const label = makeLabel('프로젝트', lk, textLabelOpts(lk, textStyleData(f.labelStyle)));
  label.name = 'label';
  c.appendChild(label);
  const swap = iconSwapDefault(page, 'SidebarSection', 'Action', iconMainId(page));
  const action = makeIcon('plus', lk, {
    ...glyphOpts(lk, colorData(f.actionIconStyle.color), f.actionIconStyle.size, 'size'),
    fromVariant: swap.variant,
  });
  action.name = 'action';
  action.visible = false;
  c.appendChild(action);
  lockWidth(c, rowWidth());
  label.layoutSizingHorizontal = 'FILL';
  bindTextProp(label, defineProp(c, 'Label', 'TEXT', '프로젝트'));
  bindSwapProp(action, defineProp(c, 'Action', 'INSTANCE_SWAP', swap.id));
  bindVisibleProp(action, defineProp(c, 'Show action', 'BOOLEAN', false));
  return c;
}

// ─── SidebarHeader ───────────────────────────────────────────────────────────

function buildSidebarHeader(page: PageNode, lk: VarLookup): ComponentSetNode {
  const f = SIDEBAR_HEADER.fields;
  const variants = new Map(Object.entries(SIDEBAR_HEADER.variants.defaultsByVariant));
  const axis = SIDEBAR_HEADER.axes.variant;
  if (!axis) throw new Error('SidebarHeader: CoreSidebarHeaderVariant is gone from the axes.');
  const members = enumerateAxisAssignments([{ axis: 'Variant' as const, values: axis.members }]);
  const leadSwap = iconSwapDefault(page, 'SidebarHeader', 'Leading', iconMainId(page));
  const trailSwap = iconSwapDefault(page, 'SidebarHeader', 'Trailing', iconMainId(page));
  const mount = mountSet(
    page,
    'SidebarHeader',
    members.map((m) => m.name),
  );
  const titles: TextNode[] = [];
  const subtitles: TextNode[] = [];
  const leads: InstanceNode[] = [];
  const trails: InstanceNode[] = [];
  const washes: RectangleNode[] = [];
  for (const m of members) {
    const row = variants.get(m.values['Variant']);
    if (!row) throw new Error(`SidebarHeader: no variant row for "${m.name}"`);
    const c = mount.getOrCreate(m.name);
    c.layoutMode = 'HORIZONTAL';
    c.primaryAxisSizingMode = 'AUTO';
    c.counterAxisSizingMode = 'AUTO';
    c.counterAxisAlignItems = 'CENTER';
    c.fills = [];
    bindPad(c, lk, f.padding);
    bindSpaceField(c, 'itemSpacing', lk, dimVal(f.contentSpacing));
    bindRadiusN(c, lk, f.borderRadius.topLeft);
    const face = colorData(row.backgroundColor);
    if (paintsFill(face)) fillData(c, lk, face);
    const border = 'borderColor' in row ? colorData(row.borderColor) : null;
    if (border) {
      borderData(c, lk, border, f.borderWidth);
      c.strokeAlign = 'INSIDE';
    }
    const lead = makeIcon('folder', lk, {
      ...glyphOpts(lk, colorData(f.titleStyle.color), f.trailingIconStyle.size, 'size'),
      fromVariant: leadSwap.variant,
    });
    lead.name = 'leading';
    c.appendChild(lead);
    leads.push(lead);
    const texts = autoFrame('text', 'VERTICAL');
    const title = makeLabel('워크스페이스', lk, textLabelOpts(lk, textStyleData(f.titleStyle)));
    title.name = 'title';
    const subtitle = makeLabel('디자인팀', lk, textLabelOpts(lk, textStyleData(f.subtitleStyle)));
    subtitle.name = 'subtitle';
    texts.appendChild(title);
    texts.appendChild(subtitle);
    c.appendChild(texts);
    titles.push(title);
    subtitles.push(subtitle);
    const trail = makeIcon('chevron-down', lk, {
      ...glyphOpts(lk, colorData(f.trailingIconStyle.color), f.trailingIconStyle.size, 'size'),
      fromVariant: trailSwap.variant,
    });
    trail.name = 'trailing';
    c.appendChild(trail);
    trails.push(trail);
    lockWidth(c, rowWidth());
    texts.layoutSizingHorizontal = 'FILL';
    // Flutter layers its interaction wash behind the row in Stacks. Keep the
    // hover pose inspectable without changing either existing resting variant.
    const wash = addWash(c, lk, f.stateLayerColor, f.stateLayer.hover, f.borderRadius.topLeft);
    wash.visible = false;
    washes.push(wash);
  }
  const set = mount.finish();
  const titleProp = defineProp(set, 'Title', 'TEXT', '워크스페이스');
  for (const t of titles) bindTextProp(t, titleProp);
  const subtitleProp = defineProp(set, 'Subtitle', 'TEXT', '디자인팀');
  for (const t of subtitles) bindTextProp(t, subtitleProp);
  const showSubtitle = defineProp(set, 'Show subtitle', 'BOOLEAN', true);
  for (const t of subtitles) bindVisibleProp(t, showSubtitle);
  const leadProp = defineProp(set, 'Leading', 'INSTANCE_SWAP', leadSwap.id);
  for (const n of leads) bindSwapProp(n, leadProp);
  const trailProp = defineProp(set, 'Trailing', 'INSTANCE_SWAP', trailSwap.id);
  for (const n of trails) bindSwapProp(n, trailProp);
  const showTrail = defineProp(set, 'Show trailing', 'BOOLEAN', true);
  for (const n of trails) bindVisibleProp(n, showTrail);
  const showHover = defineProp(set, 'Show hover layer', 'BOOLEAN', false);
  for (const wash of washes) bindVisibleProp(wash, showHover);
  defaultSetLayout(set, { Variant: axis.default });
  return set;
}

// ─── SidebarSearch ───────────────────────────────────────────────────────────

function buildSidebarSearch(page: PageNode, lk: VarLookup): ComponentSetNode {
  const f = SIDEBAR_SEARCH.fields;
  const members = enumerateAxisAssignments([{ axis: 'State' as const, values: kSearchStates }]);
  const mount = mountSet(
    page,
    'SidebarSearch',
    members.map((m) => m.name),
  );
  const placeholders: TextNode[] = [];
  const shortcuts: InstanceNode[] = [];
  const rings: FocusRingNodes[] = [];
  for (const m of members) {
    const state = m.values['State'] as SearchState;
    const c = mount.getOrCreate(m.name);
    c.layoutMode = 'HORIZONTAL';
    c.primaryAxisSizingMode = 'AUTO';
    c.counterAxisSizingMode = 'AUTO';
    c.counterAxisAlignItems = 'CENTER';
    c.fills = [];
    bindPad(c, lk, f.padding);
    bindSpaceField(c, 'itemSpacing', lk, dimVal(f.contentSpacing));
    bindRadiusN(c, lk, f.borderRadius.topLeft);
    const height = dimVal(f.minHeight);
    c.minHeight = height;
    const step = lk.sizeOrNull(height);
    if (step) c.setBoundVariable('minHeight', step);
    fillData(c, lk, colorData(f.backgroundColor));
    borderData(c, lk, colorData(f.borderColor), f.borderWidth);
    c.strokeAlign = 'INSIDE';
    const icon = makeIcon('search', lk, glyphOpts(lk, colorData(f.iconStyle.color), f.iconStyle.size, 'size'));
    icon.name = 'icon';
    c.appendChild(icon);
    const text = makeLabel('검색', lk, textLabelOpts(lk, textStyleData(f.placeholderStyle)));
    text.name = 'placeholder';
    c.appendChild(text);
    placeholders.push(text);
    // Flutter composes Kbd only when a non-empty shortcut is supplied.
    // Keep it hidden by default while exposing the real child's key controls.
    const shortcut = instanceOf(page, 'Kbd');
    shortcut.name = 'shortcut';
    shortcut.visible = false;
    c.appendChild(shortcut);
    shortcuts.push(shortcut);
    lockWidth(c, rowWidth());
    text.layoutSizingHorizontal = 'FILL';
    const weight = washWeight(state, f.stateLayer);
    if (weight != null && weight > 0) {
      addWash(c, lk, f.stateLayerColor, weight, f.borderRadius.topLeft);
    }
    rings.push(
      ringOf(c, lk, f.clickableStyle.focusOutlineStyle, f.borderRadius.topLeft, state === 'focus'),
    );
  }
  const set = mount.finish();
  const placeholderProp = defineProp(set, 'Placeholder', 'TEXT', '검색');
  for (const t of placeholders) bindTextProp(t, placeholderProp);
  const showShortcut = defineProp(set, 'Show shortcut', 'BOOLEAN', false);
  for (const shortcut of shortcuts) bindVisibleProp(shortcut, showShortcut);
  exposeSlot(shortcuts, 'KeyContent', 'TEXT');
  const showRing = defineShowFocusRing(set);
  for (const ring of rings) bindShowFocusRing(ring, showRing);
  defaultSetLayout(set, { State: 'enabled' });
  return set;
}

// ─── SidebarGroup ────────────────────────────────────────────────────────────

// A composed `SidebarItem` row at its resting pose, its caption written in.
function itemInstance(page: PageNode, level: string, label: string, selected = false): InstanceNode {
  const row = instanceOf(
    page,
    'SidebarItem',
    bestVariantName(page, 'SidebarItem', {
      Level: level,
      State: 'enabled',
      Selected: selected ? 'true' : 'false',
    }),
  );
  setInstanceTextNamed(row, 'Label', label);
  return row;
}

// The designer's scaffold for this family (#5738) is the sample the composed
// sets show: its copy, its glyphs, its count and dot. The rows take any
// leading widget and any caption, so none of this is a default of the code —
// it is what a designer reads the composition against, side by side with the
// scaffold. Values still come from the styles; only the content is the scaffold's.
interface SidebarSampleRow {
  label: string;
  glyph: string;
  selected?: boolean;
  count?: string;
  dot?: boolean;
  trailing?: string;
}

const kSampleDestinations: readonly SidebarSampleRow[] = [
  { label: '대시보드', glyph: 'layout-dashboard', selected: true },
  { label: '받은 함', glyph: 'inbox', count: '3' },
  { label: '작업 보드', glyph: 'kanban' },
  { label: '알림', glyph: 'bell', dot: true },
];
const kSampleManageSection = '관리';
const kSampleManage: SidebarSampleRow = { label: '멤버 · 권한', glyph: 'users' };
const kSampleGroup: SidebarSampleRow = { label: '설정', glyph: 'settings' };
const kSampleGroupChildren = ['일반', '결제', '알림'];
const kSampleProjectsSection = '프로젝트';
const kSampleProjects: readonly SidebarSampleRow[] = [
  { label: '프로젝트 A', glyph: 'folder' },
  { label: '프로젝트 B', glyph: 'folder' },
  { label: '새 프로젝트', glyph: 'plus' },
];
const kSampleHelp: SidebarSampleRow = { label: '도움말', glyph: 'life-buoy', trailing: 'external-link' };
const kSampleWorkspace = { title: '워크스페이스', subtitle: '팀 · 관리자', glyph: 'terminal', trailing: 'chevrons-up-down' };
const kSampleUser = { title: '사용자 이름', subtitle: 'name@company.com', trailing: 'chevrons-up-down' };
const kSamplePanelTitle = '작업 보드';
const kSampleSearch = '검색';
// The rail's destinations — the scaffold selects the board in both rail types.
const kSampleRail: readonly { glyph: string; selected?: boolean; dot?: boolean }[] = [
  { glyph: 'house' },
  { glyph: 'inbox', dot: true },
  { glyph: 'kanban', selected: true },
  { glyph: 'chart-column' },
  { glyph: 'users' },
];

// A composed row dressed as one scaffold destination: its glyph in the leading
// slot, painted the way the row paints it (`selectedIconStyle` when selected),
// its count in the composed badge and its unread dot.
function sampleItem(page: PageNode, lk: VarLookup, level: string, s: SidebarSampleRow): InstanceNode {
  const f = SIDEBAR_ITEM.fields;
  const row = itemInstance(page, level, s.label, s.selected ?? false);
  const ink = s.selected ? f.selectedIconStyle.color : f.iconStyle.color;
  setSlotIcon(
    row,
    'Leading',
    iconMainIdAt(page, dimVal(f.iconStyle.size)),
    s.glyph,
    glyphPaint(lk, glyphOpts(lk, colorData(ink), f.iconStyle.size, 'size')),
  );
  if (s.count) {
    setInstanceBoolNamed(row, 'Show count', true);
    const badge = descendantInstance(row, 'badge');
    if (!badge) {
      throw new Error(`Sidebar sample "${s.label}": the row composes no count badge.`);
    }
    setInstanceTextNamed(badge, 'Child', s.count);
  }
  if (s.dot) setInstanceBoolNamed(row, 'Show dot', true);
  if (s.trailing) {
    setSlotIcon(
      row,
      'Trailing',
      iconMainIdAt(page, dimVal(f.trailingIconStyle.size)),
      s.trailing,
      glyphPaint(lk, glyphOpts(lk, colorData(f.trailingIconStyle.color), f.trailingIconStyle.size, 'size')),
    );
  }
  return row;
}

// The composed instance named `name` under `root`, walked by hand: the badge
// is an exposed instance inside the row instance, one level or more down.
function descendantInstance(root: SceneNode, name: string): InstanceNode | null {
  if (!('children' in root)) return null;
  for (const child of root.children) {
    if (child.type === 'INSTANCE' && child.name === name) return child;
    const found = descendantInstance(child, name);
    if (found) return found;
  }
  return null;
}

function sampleSection(page: PageNode, label: string, action: boolean): InstanceNode {
  const section = instanceOf(page, 'SidebarSection');
  setInstanceTextNamed(section, 'Label', label);
  if (action) setInstanceBoolNamed(section, 'Show action', true);
  return section;
}

function sampleHeader(
  page: PageNode,
  lk: VarLookup,
  variant: string,
  copy: { title: string; subtitle: string; glyph?: string; trailing: string },
): InstanceNode {
  const f = SIDEBAR_HEADER.fields;
  const header = instanceOf(page, 'SidebarHeader', bestVariantName(page, 'SidebarHeader', { Variant: variant }));
  setInstanceTextNamed(header, 'Title', copy.title);
  setInstanceTextNamed(header, 'Subtitle', copy.subtitle);
  const step = iconMainIdAt(page, dimVal(f.trailingIconStyle.size));
  if (copy.glyph) {
    setSlotIcon(header, 'Leading', step, copy.glyph,
      glyphPaint(lk, glyphOpts(lk, colorData(f.titleStyle.color), f.trailingIconStyle.size, 'size')));
  }
  setSlotIcon(header, 'Trailing', step, copy.trailing,
    glyphPaint(lk, glyphOpts(lk, colorData(f.trailingIconStyle.color), f.trailingIconStyle.size, 'size')));
  return header;
}

function buildSidebarGroup(page: PageNode, lk: VarLookup): ComponentSetNode {
  const f = SIDEBAR_GROUP.fields;
  const levels = SIDEBAR_ITEM.axes.other.find((o) => o.enum === 'CoreSidebarItemLevel')?.members;
  if (!levels || levels.length < 2) {
    throw new Error('SidebarGroup: CoreSidebarItemLevel no longer names a nested level.');
  }
  const [top, nested] = levels;
  const members = enumerateAxisAssignments([
    { axis: 'Expanded' as const, values: ['true', 'false'] },
  ]);
  const mount = mountSet(
    page,
    'SidebarGroup',
    members.map((m) => m.name),
  );
  const chevronStep = iconMainIdAt(page, dimVal(f.chevronIconStyle.size));
  const headers: InstanceNode[] = [];
  for (const m of members) {
    const expanded = m.values['Expanded'] === 'true';
    const c = mount.getOrCreate(m.name);
    c.layoutMode = 'VERTICAL';
    c.primaryAxisSizingMode = 'AUTO';
    c.counterAxisSizingMode = 'AUTO';
    c.fills = [];
    if (expanded) bindSpaceField(c, 'itemSpacing', lk, dimVal(f.childrenSpacing));
    // The toggle row is a `SidebarItem` whose trailing glyph is the chevron.
    const header = sampleItem(page, lk, top, kSampleGroup);
    headers.push(header);
    setInstanceBoolNamed(header, 'Show trailing', true);
    setSlotIcon(
      header,
      'Trailing',
      chevronStep,
      expanded ? 'chevron-down' : 'chevron-right',
      glyphPaint(
        lk,
        glyphOpts(lk, colorData(f.chevronIconStyle.color), f.chevronIconStyle.size, 'size'),
      ),
    );
    c.appendChild(header);
    lockWidth(c, rowWidth());
    header.layoutSizingHorizontal = 'FILL';
    if (!expanded) {
      exposeParts(c);
      continue;
    }
    const kids = autoFrame('children', 'VERTICAL');
    bindPad(kids, lk, f.childrenPadding);
    bindSpaceField(kids, 'itemSpacing', lk, dimVal(f.childrenSpacing));
    c.appendChild(kids);
    kids.layoutSizingHorizontal = 'FILL';
    for (const label of kSampleGroupChildren) {
      const row = itemInstance(page, nested, label);
      setInstanceBoolNamed(row, 'Show leading', false);
      kids.appendChild(row);
      row.layoutSizingHorizontal = 'FILL';
    }
    // The tree line — `PositionedDirectional(start: treeLineInset, top: 0,
    // bottom: 0, width: treeLineWidth)` behind the nested rows.
    const line = figma.createRectangle();
    line.name = 'tree line';
    fillData(line, lk, colorData(f.treeLineColor));
    line.resize(dimVal(f.treeLineWidth), Math.max(1, kids.height));
    pinAbsolute(kids, line, dimVal(f.treeLineInset), 0, {
      horizontal: 'MIN',
      vertical: 'STRETCH',
    });
    kids.insertChild(0, line);
    exposeParts(c);
  }
  const set = mount.finish();
  // Keep the existing nested SidebarItem properties; fail rather than silently
  // claiming the parent exposes a label or leading swap that no longer exists.
  exposeSlot(headers, 'Label', 'TEXT');
  exposeSlot(headers, 'Leading', 'INSTANCE_SWAP');
  defaultSetLayout(set, { Expanded: 'true' });
  return set;
}

// ─── Sidebar ─────────────────────────────────────────────────────────────────

function railItemInstance(
  page: PageNode,
  lk: VarLookup,
  s: { glyph: string; selected?: boolean; dot?: boolean },
): InstanceNode {
  const f = SIDEBAR_RAIL_ITEM.fields;
  const item = instanceOf(
    page,
    'SidebarRailItem',
    bestVariantName(page, 'SidebarRailItem', {
      State: 'enabled',
      Selected: s.selected ? 'true' : 'false',
    }),
  );
  const ink = s.selected ? f.selectedIconStyle.color : f.iconStyle.color;
  setSlotIcon(item, 'Icon', iconMainIdAt(page, dimVal(f.iconStyle.size)), s.glyph,
    glyphPaint(lk, glyphOpts(lk, colorData(ink), f.iconStyle.size, 'size')));
  if (s.dot) setInstanceBoolNamed(item, 'Show dot', true);
  return item;
}

function buildSidebar(page: PageNode, lk: VarLookup): ComponentSetNode {
  const f = SIDEBAR.fields;
  const types = new Map(Object.entries(SIDEBAR.variants.defaultsByType));
  const typeAxis = SIDEBAR.axes.other.find((o) => o.enum === 'CoreSidebarType');
  if (!typeAxis) throw new Error('Sidebar: CoreSidebarType is gone from the exported axes.');
  const levels = SIDEBAR_ITEM.axes.other.find((o) => o.enum === 'CoreSidebarItemLevel')?.members ?? [];
  const top = levels[0];
  const members = enumerateAxisAssignments([{ axis: 'Type' as const, values: typeAxis.members }]);
  const mount = mountSet(
    page,
    'Sidebar',
    members.map((m) => m.name),
  );
  const headers: InstanceNode[] = [];
  const searches: InstanceNode[] = [];
  const helps: InstanceNode[] = [];
  const users: InstanceNode[] = [];
  const railHeaderHolders: FrameNode[] = [];
  const railHeaders: InstanceNode[] = [];
  const railFooterHolders: FrameNode[] = [];
  const railFooters: InstanceNode[] = [];
  const footerHolders: FrameNode[] = [];
  const footers: InstanceNode[] = [];
  const emptyBottoms: FrameNode[] = [];
  const actionHolders: FrameNode[] = [];
  const actions: InstanceNode[] = [];
  const panelTitles: TextNode[] = [];
  for (const m of members) {
    const type = m.values['Type'];
    const row = types.get(type);
    if (!row) throw new Error(`Sidebar: no type row for "${m.name}"`);
    const hasRail = type !== 'standard';
    const hasPanel = type !== 'collapsed';
    const c = mount.getOrCreate(m.name);
    c.layoutMode = 'HORIZONTAL';
    c.primaryAxisSizingMode = 'AUTO';
    c.counterAxisSizingMode = 'AUTO';
    c.counterAxisAlignItems = 'MIN';
    c.fills = [];
    const edge = colorData(f.borderColor);
    let rail: FrameNode | null = null;
    if (hasRail) {
      rail = autoFrame('rail', 'VERTICAL');
      rail.counterAxisAlignItems = 'CENTER';
      bindPad(rail, lk, f.railPadding);
      bindSpaceField(rail, 'itemSpacing', lk, dimVal(f.railSpacing));
      fillData(rail, lk, colorData(row.railBackgroundColor));
      const railHeaderHolder = autoFrame('rail header', 'HORIZONTAL');
      const railHeader = slotStandIn(page, 'rail header content', 'rectangular');
      const railContentWidth = Math.max(1,
        dimVal(f.railWidth) - dimVal(f.railPadding.l) - dimVal(f.railPadding.r));
      railHeader.resize(railContentWidth, railHeader.height);
      railHeaderHolder.appendChild(railHeader);
      railHeaderHolder.visible = false;
      rail.appendChild(railHeaderHolder);
      railHeaderHolders.push(railHeaderHolder);
      railHeaders.push(railHeader);
      for (const s of kSampleRail) rail.appendChild(railItemInstance(page, lk, s));
      const railFooterHolder = autoFrame('rail footer', 'HORIZONTAL');
      const railFooter = slotStandIn(page, 'rail footer content', 'rectangular');
      railFooter.resize(railContentWidth, railFooter.height);
      railFooterHolder.appendChild(railFooter);
      railFooterHolder.visible = false;
      rail.appendChild(railFooterHolder);
      railFooterHolders.push(railFooterHolder);
      railFooters.push(railFooter);
      c.appendChild(rail);
      lockWidth(rail, f.railWidth);
      if (!hasPanel) borderData(rail, lk, edge, f.borderWidth, { right: true });
    }
    if (hasPanel) {
      const panelFrame = autoFrame('panel', 'VERTICAL');
      fillData(panelFrame, lk, colorData(f.backgroundColor));
      borderData(panelFrame, lk, edge, f.borderWidth, { right: true });
      const topFrame = autoFrame('top', 'VERTICAL');
      bindPad(topFrame, lk, row.topPadding);
      bindSpaceField(topFrame, 'itemSpacing', lk, dimVal(f.topSpacing));
      if (type === 'standard') {
        const header = sampleHeader(page, lk, 'plain', kSampleWorkspace);
        topFrame.appendChild(header);
        headers.push(header);
      } else {
        const title = makeLabel(kSamplePanelTitle, lk, textLabelOpts(lk, textStyleData(f.panelTitleStyle)));
        title.name = 'panel title';
        panelTitles.push(title);
        const titleRow = autoFrame('panel title row', 'HORIZONTAL');
        bindPad(titleRow, lk, f.panelTitlePadding);
        bindSpaceField(titleRow, 'itemSpacing', lk, dimVal(f.panelTitleSpacing));
        titleRow.appendChild(title);
        const actionHolder = autoFrame('panel action', 'HORIZONTAL');
        const action = slotStandIn(page, 'panel action content', 'circular');
        actionHolder.appendChild(action);
        actionHolder.visible = false;
        titleRow.appendChild(actionHolder);
        actionHolders.push(actionHolder);
        actions.push(action);
        topFrame.appendChild(titleRow);
      }
      const search = instanceOf(page, 'SidebarSearch', bestVariantName(page, 'SidebarSearch', { State: 'enabled' }));
      setInstanceTextNamed(search, 'Placeholder', kSampleSearch);
      setInstanceBoolNamed(search, 'Show shortcut', true);
      topFrame.appendChild(search);
      searches.push(search);
      const body = autoFrame('body', 'VERTICAL');
      bindPad(body, lk, row.bodyPadding);
      bindSpaceField(body, 'itemSpacing', lk, dimVal(f.bodySpacing));
      for (const s of kSampleDestinations) body.appendChild(sampleItem(page, lk, top, s));
      body.appendChild(sampleSection(page, kSampleManageSection, false));
      body.appendChild(sampleItem(page, lk, top, kSampleManage));
      body.appendChild(instanceOf(page, 'SidebarGroup', bestVariantName(page, 'SidebarGroup', { Expanded: 'true' })));
      body.appendChild(sampleSection(page, kSampleProjectsSection, true));
      for (const s of kSampleProjects) body.appendChild(sampleItem(page, lk, top, s));
      panelFrame.appendChild(topFrame);
      panelFrame.appendChild(body);
      const bottom = autoFrame('bottom', 'VERTICAL');
      bindPad(bottom, lk, f.bottomPadding);
      bindSpaceField(bottom, 'itemSpacing', lk, dimVal(f.bottomSpacing));
      const footerHolder = autoFrame('footer', 'HORIZONTAL');
      const footer = slotStandIn(page, 'footer content', 'rectangular');
      footerHolder.appendChild(footer);
      footerHolder.visible = false;
      bottom.appendChild(footerHolder);
      footerHolders.push(footerHolder);
      footers.push(footer);
      if (type === 'standard') {
        const help = sampleItem(page, lk, top, kSampleHelp);
        bottom.appendChild(help);
        helps.push(help);
        const user = sampleHeader(page, lk, 'card', kSampleUser);
        bottom.appendChild(user);
        users.push(user);
      } else {
        // No other bottom content in the two-pane sample: avoid empty padding
        // until the optional footer itself is enabled.
        bottom.visible = false;
        emptyBottoms.push(bottom);
      }
      panelFrame.appendChild(bottom);
      c.appendChild(panelFrame);
      lockWidth(panelFrame, row.panelWidth);
      for (const part of panelFrame.children) {
        if (part.type !== 'FRAME') continue;
        part.layoutSizingHorizontal = 'FILL';
        for (const kid of part.children) {
          if ('layoutSizingHorizontal' in kid) kid.layoutSizingHorizontal = 'FILL';
        }
      }
    }
    if (rail) rail.layoutSizingVertical = 'FILL';
    exposeParts(c);
  }
  const set = mount.finish();
  // These sample instances occupy arbitrary Widget? slots in the contract.
  // Preserve each existing default, while permitting the slot to be swapped.
  const header = defineProp(set, 'Header', 'INSTANCE_SWAP',
    mainComponentIdOf(page, 'SidebarHeader', bestVariantName(page, 'SidebarHeader', { Variant: 'plain' })));
  const search = defineProp(set, 'Search', 'INSTANCE_SWAP',
    mainComponentIdOf(page, 'SidebarSearch', bestVariantName(page, 'SidebarSearch', { State: 'enabled' })));
  const help = defineProp(set, 'Help', 'INSTANCE_SWAP',
    mainComponentIdOf(page, 'SidebarItem', bestVariantName(page, 'SidebarItem', { Level: top, State: 'enabled', Selected: 'false' })));
  const user = defineProp(set, 'User', 'INSTANCE_SWAP',
    mainComponentIdOf(page, 'SidebarHeader', bestVariantName(page, 'SidebarHeader', { Variant: 'card' })));
  for (const node of headers) bindSwapProp(node, header);
  for (const node of searches) bindSwapProp(node, search);
  for (const node of helps) bindSwapProp(node, help);
  for (const node of users) bindSwapProp(node, user);
  const showHeader = defineProp(set, 'Show header', 'BOOLEAN', true);
  const showSearch = defineProp(set, 'Show search', 'BOOLEAN', true);
  const showHelp = defineProp(set, 'Show help', 'BOOLEAN', true);
  const showUser = defineProp(set, 'Show user', 'BOOLEAN', true);
  for (const node of headers) { node.visible = true; bindVisibleProp(node, showHeader); }
  for (const node of searches) { node.visible = true; bindVisibleProp(node, showSearch); }
  for (const node of helps) { node.visible = true; bindVisibleProp(node, showHelp); }
  for (const node of users) { node.visible = true; bindVisibleProp(node, showUser); }
  const showRailHeader = defineProp(set, 'Show rail header', 'BOOLEAN', false);
  const railHeader = defineProp(set, 'Rail header', 'INSTANCE_SWAP', slotStandInDefault(page, 'rectangular'));
  for (const node of railHeaderHolders) bindVisibleProp(node, showRailHeader);
  for (const node of railHeaders) bindSwapProp(node, railHeader);
  const showRailFooter = defineProp(set, 'Show rail footer', 'BOOLEAN', false);
  const railFooter = defineProp(set, 'Rail footer', 'INSTANCE_SWAP', slotStandInDefault(page, 'rectangular'));
  for (const node of railFooterHolders) bindVisibleProp(node, showRailFooter);
  for (const node of railFooters) bindSwapProp(node, railFooter);
  const showFooter = defineProp(set, 'Show footer', 'BOOLEAN', false);
  const footer = defineProp(set, 'Footer', 'INSTANCE_SWAP', slotStandInDefault(page, 'rectangular'));
  for (const node of [...footerHolders, ...emptyBottoms]) bindVisibleProp(node, showFooter);
  for (const node of footers) bindSwapProp(node, footer);
  const showPanelAction = defineProp(set, 'Show panel action', 'BOOLEAN', false);
  const panelAction = defineProp(set, 'Panel action', 'INSTANCE_SWAP', slotStandInDefault(page, 'circular'));
  for (const node of actionHolders) bindVisibleProp(node, showPanelAction);
  for (const node of actions) bindSwapProp(node, panelAction);
  // The sample is native text; expose its content without claiming that a
  // TEXT property implements the contract's arbitrary-widget title slot.
  const panelTitle = defineProp(set, 'Panel title', 'TEXT', kSamplePanelTitle);
  for (const node of panelTitles) bindTextProp(node, panelTitle);
  defaultSetLayout(set, { Type: typeAxis.members[0] });
  return set;
}

// ─── Registry ────────────────────────────────────────────────────────────────

export const SIDEBAR_BUILDERS: RegistryEntry[] = [
  { section: 'Navigation', name: 'SidebarItem', build: buildSidebarItem, needs: ['Badge', 'Icon'] },
  {
    section: 'Navigation',
    name: 'SidebarRailItem',
    sizing: { width: 'fixed', height: 'fixed', why: '레일 목적지는 정사각 칸 — sidebar_rail_item.dart 가 SizedBox.square(resolved.size) 로 양 축을 고정하고 아이콘은 그 가운데에 놓인다' },
    build: buildSidebarRailItem,
    needs: ['Icon', 'Tooltip'],
  },
  { section: 'Navigation', name: 'SidebarSection', build: buildSidebarSection, needs: ['Icon'] },
  { section: 'Navigation', name: 'SidebarHeader', build: buildSidebarHeader, needs: ['Icon'] },
  { section: 'Navigation', name: 'SidebarSearch', build: buildSidebarSearch, needs: ['Icon', 'Kbd'] },
  {
    section: 'Navigation',
    name: 'SidebarGroup',
    build: buildSidebarGroup,
    needs: ['Icon', 'SidebarItem'],
  },
  {
    section: 'Navigation',
    name: 'Sidebar',
    build: buildSidebar,
    needs: [kSlotStandInComponent, 'SidebarGroup', 'SidebarHeader', 'SidebarItem', 'SidebarRailItem', 'SidebarSearch', 'SidebarSection'],
  },
];
