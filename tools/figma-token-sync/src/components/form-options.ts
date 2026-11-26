/// <reference types="@figma/plugin-typings" />

import {
  RegistryEntry,
  VarLookup,
  applyPanelCompChrome,
  autoFrame,
  bestVariantName,
  bindRadiusN,
  bindSwapProp,
  bindTextProp,
  bindVisibleProp,
  borderData,
  defineProp,
  fillData,
  iconMainId,
  iconSwapDefault,
  instanceOf,
  lockWidth,
  makeIcon,
  makeLabel,
  mountSet,
  pinAbsolute,
  setInstanceBoolNamed,
  setInstanceTextNamed,
  sizePin,
  typographyColorOpts,
  withAlpha,
} from '../helpers';
import type { ColorData, IconOpts } from '../helpers';
import { enumerateAxisAssignments } from '../axis-combos';
import { stateAxis } from '../state-axis';
import { COMPONENTS } from '../data';
import { colorData, dimVal, mergeTextStyleData, textStyleData } from '../compat/v1';

// ─── OptionItem ──────────────────────────────────────────────────────────────
//
// One row of a choice list — `[ leading ] [ label / description ] [ mark ]`.
// The mark is the chosen state: a `check` glyph on the single-select row that
// is selected (and nothing on the others), a `Checkbox` at `lg` on every
// multiple-select row.
//
// ```text
// OptionItem  State=enabled | pressed | disabled × Selection × Selected   (HORIZONTAL · card)
//   card            minHeight · borderRadius · border by state · fill by state · padding
//   ├─ pressed face   absolute, measured from the inside of the border:
//   │                 `pressedBackgroundOutset` past each side, `pressedBackgroundInset`
//   │                 short of the top and bottom                       ← State=pressed only
//   ├─ leading        Icon                                              ← `Show leading`
//   ├─ text           VERTICAL · gap descriptionGapStyle
//   │    ├─ label     labelTextStyle (selected: the selection's own ink + weight)
//   │    └─ description                                                 ← `Show description`
//   └─ mark           single → `check` Icon, drawn on the selected row
//                     multiple → `Checkbox` Size=lg, Checked = the row's Selected
// ```
//
// The row is a bordered card, `minHeight` tall at least. At rest it draws
// `borderColor` at `borderWidth` and no fill; a chosen row fills with
// `selectedBackgroundColor` and draws `selectedBorderColor` at
// `selectedBorderWidth`; a chosen row that is disabled fills with
// `disabledSelectedBackgroundColor` under the RESTING border. The padding is
// measured from the card's outer edge — a Figma stroke sits inside and takes no
// layout, the way both platforms draw it.
//
// The pressed face is the first child: it paints over the card's fill and under
// the content. Children paint over their parent's stroke, so the face is pinned
// inside the border (the border's width in from each side) rather than over it.
const OPTION_ITEM = COMPONENTS.option_item;
const OPTION_LIST = COMPONENTS.option_list;
const kOptionItemName = 'OptionItem';
const kOptionItemStates = stateAxis(['enabled', 'pressed', 'disabled']);
const kOptionItemSelectedValues = ['false', 'true'] as const;
// The copy the nodes open on.
const kOptionItemLabelCopy = '옵션';
const kOptionItemDescriptionCopy = '설명';
// `Checkbox` is a labelled control; the row's label is the row's own, so the
// composed box draws no label of its own.
const kOptionItemCheckboxSize = 'lg';

// `IconOpts` from a token colour — the glyphs here are all token-painted.
function optionIconOpts(lk: VarLookup, cd: ColorData, size: number): IconOpts {
  if (cd.color == null) {
    throw new Error('OptionItem: an icon colour has to be a token, not a raw argb.');
  }
  return { size: size, colorVar: lk.sem(cd.color), opacity: cd.opacity, argb: cd.argb };
}

function buildOptionItem(page: PageNode, lk: VarLookup): ComponentSetNode {
  const f = OPTION_ITEM.fields;
  const selectionAxis = OPTION_ITEM.axes.other.find((o) => o.enum === 'CoreOptionItemSelection');
  if (!selectionAxis) {
    throw new Error(
      'OptionItem: CoreOptionItemSelection is gone from the exported axes — the canvas has a ' +
        'Selection axis that nothing in the contract now backs.',
    );
  }
  const selectionRows = new Map(Object.entries(OPTION_ITEM.variants.defaultsBySelection));
  const members = enumerateAxisAssignments([
    { axis: 'State', values: [...kOptionItemStates] },
    { axis: 'Selection', values: [...selectionAxis.members] },
    { axis: 'Selected', values: [...kOptionItemSelectedValues] },
  ]);
  const leadingSwap = iconSwapDefault(page, kOptionItemName, 'Leading', iconMainId(page));
  const mount = mountSet(page, kOptionItemName, members.map((m) => m.name));

  const baseLabel = textStyleData(f.labelTextStyle);
  const baseDescription = textStyleData(f.descriptionTextStyle);
  const disabledForeground = colorData(f.disabledForegroundColor)!;
  const outset = dimVal(f.pressedBackgroundOutset);
  const inset = dimVal(f.pressedBackgroundInset);
  const cardRadius = f.borderRadius.topLeft;

  const labelNodes: TextNode[] = [];
  const descriptionNodes: TextNode[] = [];
  const leadingNodes: InstanceNode[] = [];
  const faces: { face: RectangleNode; host: ComponentNode; dx: number; dy: number }[] = [];

  for (const { name: comboName, values } of members) {
    const selection = values.Selection;
    const selected = values.Selected === 'true';
    const state = values.State;
    const disabled = state === 'disabled';
    const selectionRow = selectionRows.get(selection);
    if (!selectionRow) {
      throw new Error(
        `OptionItem: \`option_item.variants.defaultsBySelection\` has no \`${selection}\` row`,
      );
    }

    // The label rests in its own ink; a chosen row takes the selection's ink and
    // weight; a disabled row says so in its ink — a chosen disabled row keeps
    // the chosen weight.
    const labelStyle = selected
      ? mergeTextStyleData(baseLabel, textStyleData(selectionRow.selectedLabelTextStyle))
      : baseLabel;
    const labelInk = disabled ? disabledForeground : labelStyle.color!;
    const descriptionInk = disabled ? disabledForeground : baseDescription.color!;
    // The glyph rests in the UNSELECTED label's ink, as the widget resolves it.
    const leadingInk = disabled ? disabledForeground : baseLabel.color!;

    const c = mount.getOrCreate(comboName);
    applyPanelCompChrome(c, 'HORIZONTAL', lk, {
      pl: f.padding.l,
      pr: f.padding.r,
      pt: f.padding.t,
      pb: f.padding.b,
      gap: f.spacing,
    });
    c.counterAxisAlignItems = 'CENTER';
    c.clipsContent = false;
    // `minHeight` — a floor, not a height: a row with a description grows past it.
    c.minHeight = dimVal(f.minHeight);
    bindRadiusN(c, lk, cardRadius);
    // A chosen row fills and draws the accent border; a chosen row that is
    // disabled keeps its fill but returns to the resting border.
    const accentBorder = selected && !disabled;
    const fill = !selected
      ? null
      : disabled
        ? colorData(f.disabledSelectedBackgroundColor)
        : colorData(f.selectedBackgroundColor);
    fillData(c, lk, fill);
    const borderWidth = accentBorder ? f.selectedBorderWidth : f.borderWidth;
    borderData(
      c,
      lk,
      colorData(accentBorder ? f.selectedBorderColor : f.borderColor),
      borderWidth,
    );
    c.strokeAlign = 'INSIDE';
    // g7-preview-only: a row's width is its list's; OptionList's preview is 350 wide.
    lockWidth(c, 350);

    // The face is the first child, so every other layer paints over it.
    const face = figma.createRectangle();
    face.name = 'pressed face';
    fillData(
      face,
      lk,
      state === 'pressed' ? withAlpha(colorData(f.pressedBackgroundColor), f.stateLayer.pressed) : null,
    );
    face.visible = state === 'pressed';
    // Concentric with the border's inner curve: the stated corner less the
    // border in effect (11 at rest, 10.5 chosen). Off the radius scale, so a
    // literal derived from the two exported fields — not a bound variable.
    face.cornerRadius = Math.max(dimVal(f.pressedBackgroundBorderRadius.topLeft) - dimVal(borderWidth), 0);
    // From the inside of the border: the border's width in, less the outset.
    const dx = dimVal(borderWidth) - outset;
    const dy = dimVal(borderWidth) + inset;
    face.resize(Math.max(c.width - 2 * dx, 1), Math.max(c.height - 2 * dy, 1));
    pinAbsolute(c, face, dx, dy, { horizontal: 'STRETCH', vertical: 'STRETCH' });
    faces.push({ face: face, host: c, dx: dx, dy: dy });

    const leading = makeIcon('circle-dashed', lk, {
      ...optionIconOpts(lk, leadingInk, dimVal(f.leadingIconStyle.size)),
      fromVariant: leadingSwap.variant,
    });
    leading.name = 'leading';
    leading.visible = false;
    c.appendChild(leading);
    leadingNodes.push(leading);

    const text = autoFrame('text', 'VERTICAL');
    text.itemSpacing = dimVal(f.descriptionGapStyle.size);
    c.appendChild(text);
    text.layoutSizingHorizontal = 'FILL';

    const label = makeLabel(kOptionItemLabelCopy, lk, typographyColorOpts(lk, labelStyle, labelInk));
    label.name = 'label';
    text.appendChild(label);
    label.layoutSizingHorizontal = 'FILL';
    labelNodes.push(label);

    const description = makeLabel(
      kOptionItemDescriptionCopy,
      lk,
      typographyColorOpts(lk, baseDescription, descriptionInk),
    );
    description.name = 'description';
    description.visible = false;
    text.appendChild(description);
    description.layoutSizingHorizontal = 'FILL';
    descriptionNodes.push(description);

    if (selection === 'multiple') {
      // The box is the `Checkbox` component, composed: `Checked` follows the
      // row, a disabled row composes the disabled box, and its own label is off.
      const box = instanceOf(
        page,
        'Checkbox',
        bestVariantName(page, 'Checkbox', {
          Size: kOptionItemCheckboxSize,
          State: disabled ? 'disabled' : 'enabled',
          Checked: selected ? 'true' : 'false',
        }),
      );
      box.name = 'mark';
      setInstanceBoolNamed(box, 'Show label', false);
      c.appendChild(box);
    } else {
      // The chosen single row wears the check; the others have no mark at all.
      const check = makeIcon('check', lk, {
        ...optionIconOpts(
          lk,
          disabled ? disabledForeground : colorData(f.checkIconStyle.color)!,
          dimVal(f.checkIconStyle.size),
        ),
      });
      check.name = 'mark';
      check.visible = selected;
      c.appendChild(check);
    }
  }

  const set = mount.finish();
  // The faces are sized AFTER the row has settled — see `buildMenuItem`'s wash.
  for (const { face, host, dx, dy } of faces) {
    sizePin(face, Math.max(host.width - 2 * dx, 1), Math.max(host.height - 2 * dy, 1));
  }
  const labelProp = defineProp(set, 'Label', 'TEXT', kOptionItemLabelCopy);
  for (const n of labelNodes) bindTextProp(n, labelProp);
  const showDescriptionProp = defineProp(set, 'Show description', 'BOOLEAN', false);
  const descriptionProp = defineProp(set, 'Description', 'TEXT', kOptionItemDescriptionCopy);
  for (const n of descriptionNodes) {
    bindVisibleProp(n, showDescriptionProp);
    bindTextProp(n, descriptionProp);
  }
  const showLeadingProp = defineProp(set, 'Show leading', 'BOOLEAN', false);
  const leadingProp = defineProp(set, 'Leading', 'INSTANCE_SWAP', leadingSwap.id);
  for (const n of leadingNodes) {
    bindVisibleProp(n, showLeadingProp);
    bindSwapProp(n, leadingProp);
  }
  return set;
}

// ─── OptionList ──────────────────────────────────────────────────────────────
//
// `OptionList(children: [OptionItem, …])` — the cards stacked in one column with
// `spacing` between them (8). The set offers 3 to 6 rows; the first is the
// chosen one, the way a single-select list opens.
//
// ```text
// OptionList  Count=3 | 4 | 5 | 6   (VERTICAL · gap spacing)
//   └─ item × Count   OptionItem Selection=single, Selected=true on the first
// ```
const kOptionListCounts = ['3', '4', '5', '6'] as const;

function buildOptionList(page: PageNode, lk: VarLookup): ComponentSetNode {
  const f = OPTION_LIST.fields;
  const members = enumerateAxisAssignments([{ axis: 'Count', values: [...kOptionListCounts] }]);
  const mount = mountSet(page, 'OptionList', members.map((m) => m.name));
  for (const { name: comboName, values } of members) {
    const c = mount.getOrCreate(comboName);
    applyPanelCompChrome(c, 'VERTICAL', lk, { gap: f.spacing });
    // g7-preview-only: a list's width is its sheet's; the preview is 350 wide.
    lockWidth(c, 350);
    const count = Number(values.Count);
    for (let i = 0; i < count; i++) {
      const row = instanceOf(
        page,
        kOptionItemName,
        bestVariantName(page, kOptionItemName, {
          Selection: 'single',
          Selected: i === 0 ? 'true' : 'false',
          State: 'enabled',
        }),
      );
      row.name = 'item';
      setInstanceTextNamed(row, 'Label', `${kOptionItemLabelCopy} ${i + 1}`);
      c.appendChild(row);
      row.layoutSizingHorizontal = 'FILL';
    }
  }
  return mount.finish();
}

export const FORM_OPTIONS: RegistryEntry[] = [
  {
    section: 'Form',
    name: 'OptionItem',
    build: buildOptionItem,
    needs: ['Icon', 'Checkbox'],
  },
  { section: 'Form', name: 'OptionList', build: buildOptionList, needs: ['OptionItem'] },
];
