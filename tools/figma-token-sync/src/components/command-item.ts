/// <reference types="@figma/plugin-typings" />

import { RegistryEntry } from '../helpers';

import { COMMAND, CommandSize, kCommandSizes, COMMAND_ITEM_NAME } from '../command-preview';
import { iconOpts } from '../overlay-composition';
import { existingComponentOrSet } from '../identity';
import {
  ChromeOpts,
  VarLookup,
  applyPanelCompChrome,
  autoFrame,
  pinAbsolute,
  sizePin,
  bindRadiusN,
  bindSwapProp,
  bindTextProp,
  bindVisibleProp,
  defineProp,
  fillData,
  iconMainIdAt,
  iconSwapDefault,
  lockWidth,
  makeIcon,
  makeLabel,
  mountSet,
  typographyColorOpts,
} from '../helpers';
import { stateAxis } from '../state-axis';
import { colorData, dimVal, textStyleData } from '../compat/v1';
const kCommandItemStates = stateAxis(['enabled', 'hover', 'pressed', 'disabled']);
type CommandItemState = (typeof kCommandItemStates)[number];

// Nov9 Leading reset contract: Icon/Size=16, independent of the displayed
// sm/md/lg itemIconStyle ladder. This is the property's reset, not row chrome.
const kCommandItemLeadingResetSize = 16;

// ─── CommandItem ─────────────────────────────────────────────────────────────
//
// `Size(3) × Active(2) × State(4) × Lines(2)` = 48 — the designer's set,
// member for member. `Lines` is an axis rather than a `Show overline`
// boolean because a two-line row has a different floor (the overline plus its
// own title line) and a different label style: one-line rows read
// `labelStyle`, two-line rows read `itemTitleStyle` under `overlineStyle`
// (both body roles, Regular, the title one step above the description). A
// boolean cannot swap a text style.
//
// The row is `command.dart#_buildItem`, one to one:
//
// ```text
// item (HORIZONTAL · itemPadding · itemGapStyle · itemBorderRadius · minHeight)
//   ├─ state layer   // pinned full; the hover / pressed wash (itemHoverColor /
//   │                //   itemPressedColor), hidden at rest
//   ├─ leading       // Icon instance, `Show leading` (default ON)
//   ├─ text (VERTICAL)
//   │    ├─ overline  // Lines=2 only — overlineStyle
//   │    └─ title     // Child — labelStyle (Lines=1) / itemTitleStyle (Lines=2)
//   └─ shortcut      // `Show shortcut` — shortcutStyle
// ```
//
// Active is a FILL (`itemHighlightColor`, `surface-container`) — no accent
// bar — and the glyph rising from `itemIconStyle`'s `on-surface-variant` to
// `itemActiveIconStyle`'s `on-surface`. The wash stacks over the fill rather
// than replacing it, which is why it is a separate pinned layer and not a
// second fill on the row.
//
// Disabled rows read `itemDisabledForegroundColor` (`disabled-content`) on
// every text and the glyph — a token, not an alpha, so the row survives
// forced-colours mode.
//
// No focus ring: rows are not focus targets (`aria-activedescendant` carries
// the cursor from the search input), so `itemClickableStyle` draws none and
// this frame draws none.
function buildCommandItem(page: PageNode, lk: VarLookup): ComponentSetNode {
  const f = COMMAND.fields;
  const names: string[] = [];
  const poses: { size: CommandSize; active: boolean; state: CommandItemState; lines: 1 | 2 }[] = [];
  for (const size of kCommandSizes) {
    for (const active of [false, true]) {
      for (const state of kCommandItemStates) {
        for (const lines of [2, 1] as const) {
          poses.push({ size: size, active: active, state: state, lines: lines });
          names.push(`Size=${size}, Active=${active}, State=${state}, Lines=${lines}`);
        }
      }
    }
  }
  // Adopt the old builder-owned 24 default once, preserving the property key
  // and all instance/preferred choices. Later deliberate choices stay put.
  const leadingDefault = {
    id: iconMainIdAt(page, kCommandItemLeadingResetSize),
    replaces: iconMainIdAt(page, 24),
  };
  const existing = existingComponentOrSet(page, COMMAND_ITEM_NAME);
  if (existing) defineProp(existing, 'Leading', 'INSTANCE_SWAP', leadingDefault);
  const itemLeadingSwap = iconSwapDefault(page, COMMAND_ITEM_NAME, 'Leading', leadingDefault.id);
  const mount = mountSet(page, COMMAND_ITEM_NAME, names);

  const highlight = colorData(f.itemHighlightColor)!;
  const hoverWash = colorData(f.itemHoverColor)!;
  const pressedWash = colorData(f.itemPressedColor)!;
  // `itemTextStyle` owns the row label's colour (`on-surface`), with
  // `itemForegroundColor` as its fallback.
  const foreground = colorData(f.itemTextStyle.color ?? f.itemForegroundColor)!;
  // The glyph's own tint: `itemIconStyle` at rest, `itemActiveIconStyle`
  // merged over it on the keyboard cursor.
  const iconRest = colorData(f.itemIconStyle.color)!;
  const iconActive = colorData(f.itemActiveIconStyle.color ?? f.itemIconStyle.color)!;
  const disabledForeground = colorData(f.itemDisabledForegroundColor)!;
  const shortcutStyle = textStyleData(f.shortcutStyle);
  // The overline's role moves per size; its colour is the field-level default.
  const overlineColor = colorData(f.overlineStyle.color);

  const titleNodes: TextNode[] = [];
  const overlineNodes: TextNode[] = [];
  const shortcutNodes: TextNode[] = [];
  const leadingNodes: InstanceNode[] = [];
  const sizeRows = new Map(Object.entries(COMMAND.sizes.defaultsBySize));

  for (let i = 0; i < poses.length; i++) {
    const pose = poses[i];
    const sz = sizeRows.get(pose.size);
    if (!sz) throw new Error(`Command: \`command.sizes.defaultsBySize\` has no \`${pose.size}\` row`);
    const disabled = pose.state === 'disabled';
    const c = mount.getOrCreate(names[i]);
    const opts: ChromeOpts = {
      radius: f.itemBorderRadius.topLeft,
      pl: sz.itemPadding.l, pr: sz.itemPadding.r, pt: sz.itemPadding.t, pb: sz.itemPadding.b,
      gap: sz.itemGapStyle.size,
    };
    if (pose.active) {
      opts.bg = highlight.color!;
      opts.bgOp = highlight.opacity;
      opts.bgArgb = highlight.argb;
    }
    applyPanelCompChrome(c, 'HORIZONTAL', lk, opts);
    c.counterAxisAlignItems = 'CENTER';
    c.clipsContent = true;
    // g7-preview-only: a row's width is its list's; 340 is the preview column.
    lockWidth(c, 340);
    // `minHeight: itemMinHeight` — a floor, not a height. The two-line row
    // grows past it by its own text.
    c.minHeight = dimVal(sz.itemMinHeight);
    // A height on the control ladder binds its density row, which a density
    // moves on both platforms. The Command item rows (32 / 40 / 48) all sit
    // on the ladder; the primitive-size fallback is for an item minimum the
    // ladder does not name.
    const itemRow =
      lk.controlHeightOrNull(dimVal(sz.itemMinHeight)) ??
      lk.sizeOrNull(dimVal(sz.itemMinHeight));
    if (itemRow) c.setBoundVariable('minHeight', itemRow);

    // The wash — `Stacks[ wash Position.fill ]`, pressed over hover.
    const wash = figma.createRectangle();
    wash.name = 'state layer';
    const washColor = pose.state === 'pressed' ? pressedWash : hoverWash;
    fillData(wash, lk, pose.state === 'hover' || pose.state === 'pressed' ? washColor : null);
    wash.visible = pose.state === 'hover' || pose.state === 'pressed';
    bindRadiusN(wash, lk, f.itemBorderRadius.topLeft);
    wash.resize(c.width, Math.max(c.minHeight ?? 0, 1));
    pinAbsolute(c, wash, 0, 0, { horizontal: 'STRETCH', vertical: 'STRETCH' });

    const fg = disabled ? disabledForeground : foreground;

    // `IconTheme(size: itemIconStyle.size, color: <glyph tint>)` around the
    // caller's `item.icon` — the size is Command's, the tint the row state's.
    const iconTint = disabled ? disabledForeground : pose.active ? iconActive : iconRest;
    const leading = makeIcon('calendar', lk, {
      ...iconOpts(lk, iconTint, sz.itemIconStyle.size),
      fromVariant: itemLeadingSwap.variant,
    });
    leading.name = 'leading';
    // Shown, as `Show leading`'s default states.
    leading.visible = true;
    c.appendChild(leading);
    leadingNodes.push(leading);

    const text = autoFrame('text', 'VERTICAL');
    c.appendChild(text);
    text.layoutSizingHorizontal = 'FILL';
    if (pose.lines === 2) {
      const overline = makeLabel(
        '계정',
        lk,
        typographyColorOpts(
          lk,
          textStyleData(sz.overlineStyle),
          disabled ? disabledForeground : overlineColor,
        ),
      );
      overline.name = 'overline';
      text.appendChild(overline);
      overline.layoutSizingHorizontal = 'FILL';
      overlineNodes.push(overline);
    }
    const title = makeLabel(
      '프로필',
      lk,
      typographyColorOpts(lk, textStyleData(pose.lines === 2 ? sz.itemTitleStyle : sz.labelStyle), fg),
    );
    title.name = 'title';
    text.appendChild(title);
    title.layoutSizingHorizontal = 'FILL';
    titleNodes.push(title);

    const shortcut = makeLabel(
      'Ctrl+P',
      lk,
      typographyColorOpts(lk, shortcutStyle, disabled ? disabledForeground : shortcutStyle.color),
    );
    shortcut.name = 'shortcut';
    c.appendChild(shortcut);
    shortcutNodes.push(shortcut);

    // Sized again now the row has settled — the same flow-then-ABSOLUTE offset
    // as MenuItem's wash (#5609): both pins came out short by the row's
    // vertical padding (sm 40/48, md 42/54).
    sizePin(wash, c.width, c.height);
  }

  const set = mount.finish();
  const childProp = defineProp(set, 'Child', 'TEXT', '프로필');
  for (const n of titleNodes) bindTextProp(n, childProp);
  const overlineProp = defineProp(set, 'Overline', 'TEXT', '계정');
  for (const n of overlineNodes) bindTextProp(n, overlineProp);
  // Default ON — a row with a glyph is the palette's usual shape. The glyph
  // is the caller's `item.icon` in code, so the canvas draws `calendar` as a
  // stand-in; no code default exists.
  const showLeadingProp = defineProp(set, 'Show leading', 'BOOLEAN', true);
  const leadingProp = defineProp(set, 'Leading', 'INSTANCE_SWAP', leadingDefault);
  for (const n of leadingNodes) {
    bindVisibleProp(n, showLeadingProp);
    bindSwapProp(n, leadingProp);
  }
  const showShortcutProp = defineProp(set, 'Show shortcut', 'BOOLEAN', true);
  const shortcutProp = defineProp(set, 'Shortcut', 'TEXT', 'Ctrl+P');
  for (const n of shortcutNodes) {
    bindVisibleProp(n, showShortcutProp);
    bindTextProp(n, shortcutProp);
  }
  return set;
}

export const COMMAND_ITEM_BUILDERS: RegistryEntry[] = [
  {
    section: 'Overlay',
    name: 'CommandItem',
    build: buildCommandItem,
    // Its chrome is a fragment of `CoreCommandStyle` — `CoreCommandItem` is a
    // data value (label / icon / shortcut) with no Style of its own. The row
    // reads the palette's `item*` fields plus the three text roles it draws
    // itself; the panel's fields (`borderRadius`, `panelShadow`, `kbdStyle`, …)
    // are not its to match.
    dataSlug: 'command',
    dataFields: ['item*', 'labelStyle', 'overlineStyle', 'shortcutStyle'],
    needs: ['Icon'],
  },
];
