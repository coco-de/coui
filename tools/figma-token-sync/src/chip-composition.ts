/// <reference types="@figma/plugin-typings" />

// Shared drawing operations: dependencies point here, never through a registry builder.
import {
  ColorData,
  VarLookup,
  glyphOpts,
  iconMainIdAt,
  alignSlotIconMode,
  iconVariantById,
  glyphPaint,
  setIconGlyph,
} from './helpers';
import { colorData, dimVal, Color, Dim } from './compat/v1';
import { COMPONENTS } from './data';
export const CHIP = COMPONENTS.chip;

/** The inset that centres a `side` glyph in a `w × h` box. A derived offset,
 *  written as the number it is — it names no spacing step. */
export function setCentringInset(cell: FrameNode, w: number, h: number, side: number): void {
  const x = (w - side) / 2;
  const y = (h - side) / 2;
  cell.paddingLeft = x;
  cell.paddingRight = x;
  cell.paddingTop = y;
  cell.paddingBottom = y;
}

/**
 * Restates the close affordance of a composed `Chip` instance at the box and
 * glyph its host forwards (`chipStyle.closeButtonStyle.width` / `height`,
 * `chipStyle.closeIconStyle.size`) — `ChipInput`'s 16 box around a 12 glyph,
 * against the `sm` row's 18 around 16.
 *
 * Shared with `buildChip` so node names and the layout of the
 * cell have one source: the cell hugs its glyph (`iconButton`'s `hug`), so the
 * box moves through the two things an instance may override — which variant
 * the glyph is, and the cell's inset — and the button behind it follows on
 * STRETCH. Nothing here resizes a node inside the instance.
 *
 * Throws when the chip carries no close cell, or one that does not hug: the
 * Chip main predates the hugging cell, and the forward would land nowhere.
 */
export function forwardChipCloseBox(
  chip: InstanceNode,
  page: PageNode,
  lk: VarLookup,
  o: {
    glyphSize: number | Dim;
    width: number | Dim;
    height: number | Dim;
    /// The member the host instanced — the glyph is painted in that member's
    /// resting foreground, the ink `buildChip` paints its own close with.
    member: { Color: string; Emphasis: string; Variant: string; Selected: string };
  },
): void {
  const cells = chip.findAll((n) => n.type === 'FRAME' && n.name === kChipCloseName);
  const cell = cells.length > 0 ? (cells[0] as FrameNode) : null;
  if (cell == null || cell.layoutMode === 'NONE') {
    throw new Error(
      `forwardChipCloseBox: ${chip.name} has no hugging '${kChipCloseName}' cell — ` +
        'regenerate Chip before the set that composes it.',
    );
  }
  const glyph = cell.children[cell.children.length - 1];
  if (glyph == null || glyph.type !== 'INSTANCE') {
    throw new Error(`forwardChipCloseBox: the '${kChipCloseName}' cell of ${chip.name} holds no glyph.`);
  }
  const side = dimVal(o.glyphSize);
  const target = iconVariantById(iconMainIdAt(page, side));
  if (target == null) {
    throw new Error(`forwardChipCloseBox: no Icon variant for ${side}.`);
  }
  const colour = (CHIP.variants.defaultsByColor as Record<string, Parameters<typeof chipTableColors>[0]>)[
    o.member.Color
  ];
  if (colour == null) throw new Error(`forwardChipCloseBox: no Chip colour row "${o.member.Color}".`);
  const { fg } = chipTableColors(
    colour,
    o.member.Selected === 'true',
    false,
    o.member.Emphasis as ChipEmphasis,
    o.member.Variant === 'filled',
  );
  glyph.swapComponent(target);
  setIconGlyph(glyph, _kChipCloseGlyph, glyphPaint(lk, glyphOpts(lk, fg, side, 'size')));
  alignSlotIconMode(glyph, side, 1);
  setCentringInset(cell, dimVal(o.width), dimVal(o.height), side);
}

/** The close cell's name — the node `forwardChipCloseBox` restates. */
export const kChipCloseName = 'close';

/** The close glyph — `Icon(LucideIcons.x)` in `chip.dart`. */
export const _kChipCloseGlyph = 'x';
// The key's node — named so a parent forwarding a `CoreChipStyle` can tell the
// key from the label it sits beside (`ChipInput`'s pills).
export const kChipPrefixLabelName = 'prefix label';
export type ChipEmphasis = 'low' | 'high';

// `chip_style.dart`'s table branch, in the resolver's own precedence order:
// disabled wins over selected, selected over resting, and `emphasis` picks the
// register inside the two enabled branches. The selected border is the
// selected fill (Web parity: `border-${variantStyle.selectedBg}`). The
// unselected + low border is authored once on the style rather than per
// colour; its label is the row's `lowUnselectedFg`, neutral on every row. The
// `filled` variant swaps the unselected fill and border for the style's grey
// and its mirror, at either emphasis.
export function chipTableColors(
  v: {
    lowUnselectedFg: Color;
    disabledBg: Color;
    disabledSelectedBg: Color;
    disabledFg: Color;
    disabledBorderColor: Color;
    selectedBg: Color;
    selectedFg: Color;
    lowSelectedBg: Color;
    lowSelectedFg: Color;
    unselectedBg: Color;
    unselectedFg: Color;
    borderColor: Color;
  },
  selected: boolean,
  disabled: boolean,
  emphasis: ChipEmphasis,
  filled: boolean,
): { bg: ColorData | null; fg: ColorData | null; border: ColorData | null } {
  const low = emphasis === 'low';
  if (disabled) {
    // Two rows: the selected chip keeps a filled container with NO border
    // (`disabledSelectedBorderColor` — the transparent sentinel, which
    // `borderData` reads as "draw no stroke"), the unselected one sits on
    // the surface behind a hairline — the resolver's `!enabled` branch,
    // selected-aware. Not "border = fill": a stroke in the fill colour is
    // still a stroke on the canvas, and the designer's copy has none.
    return {
      bg: colorData(selected ? v.disabledSelectedBg : v.disabledBg),
      fg: colorData(v.disabledFg),
      border: colorData(
        selected ? CHIP.fields.disabledSelectedBorderColor : v.disabledBorderColor,
      ),
    };
  }
  if (selected) {
    const fill = low ? v.lowSelectedBg : v.selectedBg;
    return {
      bg: colorData(fill),
      fg: colorData(low ? v.lowSelectedFg : v.selectedFg),
      border: colorData(fill),
    };
  }
  // The label does not depend on the variant: it is the emphasis's neutral.
  const fg = colorData(low ? v.lowUnselectedFg : v.unselectedFg);
  if (filled) {
    // One grey for both channels — the border is the fill, so the chip reads
    // as a single shape with no outline. Read off the field, not restated.
    const fill = colorData(CHIP.fields.filledUnselectedBackgroundColor);
    return { bg: fill, fg, border: fill };
  }
  return {
    bg: colorData(v.unselectedBg),
    // Low states no colour: the row's neutral label on the shared quiet
    // hairline — that is what keeps low under high.
    fg,
    border: colorData(low ? CHIP.fields.lowUnselectedBorderColor : v.borderColor),
  };
}
