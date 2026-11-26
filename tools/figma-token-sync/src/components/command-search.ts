/// <reference types="@figma/plugin-typings" />

import { RegistryEntry } from '../helpers';

import { kCommandSearchCopy } from '../command-composition';
import { iconOpts, mainId } from '../overlay-composition';
import {
  FocusRingNodes,
  VarLookup,
  applyPanelCompChrome,
  pinAbsolute,
  bindPad,
  bindRadiusN,
  bindSwapProp,
  bindTextProp,
  bindVisibleProp,
  defineProp,
  fillData,
  focusRing,
  iconMainId,
  iconSwapDefault,
  instanceOf,
  lockWidth,
  makeIcon,
  makeLabel,
  mountSet,
  typographyColorOpts,
  withAlpha,
  exposeAll,
  setInstanceTextNamed,
} from '../helpers';
import { bindShowFocusRing, defineShowFocusRing, stateAxis } from '../state-axis';
import { colorData, dimVal, textStyleData } from '../compat/v1';
import { COMPONENTS } from '../data';
// ─── CommandSearch ───────────────────────────────────────────────────────────

// The trigger an app bar places to open the palette — `command_search.dart`'s
// tree, member for member:
//
// ```text
// CommandSearch (component — HORIZONTAL: face · corner · directional insets ·
//                seat gap · the size row's height)
//   ├─ state layer  // pinned STRETCH — stateLayerColor at the ramp's weight
//   ├─ leading      // Icon instance — `Leading` swap, the search glyph
//   ├─ hint         // text, FILL — `Hint` TEXT
//   ├─ shortcut     // Kbd instance, exposed — `Show shortcut` · `Shortcut` swap
//   └─ focus ring   // the composed `Clickable`'s ring, on the trigger's corner
// ```
//
// The face carries no stroke. The trigger is a button, not an input — the
// glyph, the hint and the key cap are what say it is there — so a border here
// would draw a boundary neither widget draws.
//
// The wash is a pinned layer rather than a second fill for the reason
// `buildMenuItem` records: the state layer stacks over the face, it does not
// replace it. Its colour is `stateLayerColor` (`onSurface`), not the trigger's
// own quieter ink, so the wash reads as the layer every other control paints.
//
// The shortcut is a `Kbd` INSTANCE because the docs and the app hand the
// widget's `shortcut` slot a `Kbd` — the trigger draws none of the cap's chrome
// itself. Exposed, so a designer retypes the key on the instance's own
// `KeyContent`. A disabled member leaves the cap as it is, as both widgets do:
// the trigger does not repaint a widget its caller handed it.
const COMMAND_SEARCH = COMPONENTS.command_search;
const COMMAND_SEARCH_NAME = 'CommandSearch';
// The key cap's copy — the convention the docs show.
const kCommandSearchShortcutCopy = '⌘K';
const kCommandSearchSizes = ['sm', 'md', 'lg'] as const;
const kCommandSearchStates = stateAxis(['enabled', 'hover', 'focus', 'pressed', 'disabled']);
type CommandSearchSize = (typeof kCommandSearchSizes)[number];
type CommandSearchState = (typeof kCommandSearchStates)[number];

function buildCommandSearch(page: PageNode, lk: VarLookup): ComponentSetNode {
  const f = COMMAND_SEARCH.fields;
  const names: string[] = [];
  const poses: { size: CommandSearchSize; state: CommandSearchState }[] = [];
  for (const size of kCommandSearchSizes) {
    for (const state of kCommandSearchStates) {
      poses.push({ size: size, state: state });
      names.push(`Size=${size}, State=${state}`);
    }
  }
  // Drawn from its swap default, so the property's first bind leaves the glyph
  // at the size row's size (see `IconOpts.fromVariant`).
  const leadingSwap = iconSwapDefault(page, COMMAND_SEARCH_NAME, 'Leading', iconMainId(page));
  const mount = mountSet(page, COMMAND_SEARCH_NAME, names);

  const sizeRows = new Map(Object.entries(COMMAND_SEARCH.sizes.defaultsBySize));
  const face = colorData(f.backgroundColor);
  const disabledFace = colorData(f.disabledBackgroundColor);
  const ink = colorData(f.foregroundColor)!;
  const disabledInk = colorData(f.disabledForegroundColor)!;
  const washColor = colorData(f.stateLayerColor);

  const hintNodes: TextNode[] = [];
  const leadingNodes: InstanceNode[] = [];
  const shortcutNodes: InstanceNode[] = [];
  const rings: FocusRingNodes[] = [];

  for (let i = 0; i < poses.length; i++) {
    const pose = poses[i];
    const sz = sizeRows.get(pose.size);
    if (!sz) {
      throw new Error(`CommandSearch: \`command_search.sizes.defaultsBySize\` has no \`${pose.size}\` row`);
    }
    const disabled = pose.state === 'disabled';
    const radius = sz.borderRadius.topLeft;

    const c = mount.getOrCreate(names[i]);
    applyPanelCompChrome(c, 'HORIZONTAL', lk, { radius: radius, gap: sz.contentGapStyle.size });
    // Directional insets — `bindPad` resolves start / end in one place.
    bindPad(c, lk, sz.padding);
    fillData(c, lk, disabled ? disabledFace : face);
    c.counterAxisAlignItems = 'CENTER';
    c.clipsContent = true;
    // g7-preview-only: the width is the parent's (an app bar's centre slot); 320 is the preview column.
    lockWidth(c, 320);
    // The size row's height. The widgets state a height; the size rows carry
    // no vertical inset and every seat is shorter than the row, so a floor
    // draws the same box while the root still hugs. Bound to the control row
    // a density moves, as on both platforms.
    c.minHeight = dimVal(sz.height);
    const row = lk.controlHeightOrNull(dimVal(sz.height));
    if (row) c.setBoundVariable('minHeight', row);
    const height = Math.max(c.minHeight ?? 0, 1);

    // The wash — hidden at rest and while disabled (an inert trigger that
    // shaded under the pointer would be promising something).
    const washWeight =
      pose.state === 'hover'
        ? f.stateLayer.hover
        : pose.state === 'focus'
          ? f.stateLayer.focus
          : pose.state === 'pressed'
            ? f.stateLayer.pressed
            : null;
    const wash = figma.createRectangle();
    wash.name = 'state layer';
    fillData(wash, lk, washWeight == null ? null : withAlpha(washColor, washWeight));
    wash.visible = washWeight != null;
    bindRadiusN(wash, lk, radius);
    wash.resize(c.width, height);
    pinAbsolute(c, wash, 0, 0, { horizontal: 'STRETCH', vertical: 'STRETCH' });

    const fg = disabled ? disabledInk : ink;
    const leading = makeIcon('search', lk, {
      ...iconOpts(lk, fg, sz.leadingIconStyle.size),
      fromVariant: leadingSwap.variant,
    });
    leading.name = 'leading';
    c.appendChild(leading);
    leadingNodes.push(leading);

    // The hint draws the palette's own placeholder copy until a designer
    // types over `Hint`.
    const hint = makeLabel(
      kCommandSearchCopy,
      lk,
      typographyColorOpts(lk, textStyleData(sz.hintTextStyle), fg),
    );
    hint.name = 'hint';
    c.appendChild(hint);
    hint.layoutSizingHorizontal = 'FILL';
    hintNodes.push(hint);

    const shortcut = instanceOf(page, 'Kbd');
    shortcut.name = 'shortcut';
    c.appendChild(shortcut);
    setInstanceTextNamed(shortcut, 'KeyContent', kCommandSearchShortcutCopy);
    shortcutNodes.push(shortcut);

    // The ring is measured from the settled box, so it is built last.
    rings.push(
      focusRing(c, lk, {
        outline: f.clickableStyle.focusOutlineStyle,
        color: colorData(f.clickableStyle.focusOutlineStyle.borderColor),
        corner: radius,
        width: c.width,
        height: height,
        // A focused trigger wears its ring — the state says so.
        visible: pose.state === 'focus',
      }),
    );
  }

  const set = mount.finish();
  exposeAll(shortcutNodes);
  const hintProp = defineProp(set, 'Hint', 'TEXT', kCommandSearchCopy);
  for (const n of hintNodes) bindTextProp(n, hintProp);
  const leadingProp = defineProp(set, 'Leading', 'INSTANCE_SWAP', leadingSwap.id);
  for (const n of leadingNodes) bindSwapProp(n, leadingProp);
  // Default ON — the shortcut hint is the convention the trigger is drawn with.
  // The seat is a `W?` slot, so it swaps like one: the `Kbd` main is only its
  // default, the way the docs fill it.
  const showShortcutProp = defineProp(set, 'Show shortcut', 'BOOLEAN', true);
  const shortcutProp = defineProp(set, 'Shortcut', 'INSTANCE_SWAP', mainId(page, 'Kbd'));
  for (const n of shortcutNodes) {
    bindVisibleProp(n, showShortcutProp);
    bindSwapProp(n, shortcutProp);
  }
  const showFocusId = defineShowFocusRing(set);
  for (const ring of rings) bindShowFocusRing(ring, showFocusId);
  return set;
}

export const COMMAND_SEARCH_BUILDERS: RegistryEntry[] = [
  { section: 'Overlay', name: 'CommandSearch', build: buildCommandSearch, needs: ['Icon', 'Kbd'] },
];
