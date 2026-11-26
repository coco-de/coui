// The radio item's description line and the `card` variant's tile — the
// fields they add, the size rows that state them, and the size layer
// `CoreRadioGroupStyle.sizeDefaultsFor` hands both resolvers.

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

const _compact = CoreRadioGroupStyle(
  tilePadding: CoreEdgeInsets.symmetric(
    vertical: CoreSpace.space10,
    horizontal: CoreSpace.space12,
  ),
);

void main() {
  group('description defaults', () {
    test("the foreground is the quieter one, the gap is Checkbox's 2", () {
      expect(
        CoreRadioGroupStyle.defaultDescriptionStyle.color,
        const CoreColor.token(CoreColors.onSurfaceVariant),
      );
      expect(
        CoreRadioGroupStyle.defaultLabelDescriptionGapStyle.size,
        CoreSpace.space2,
      );
      expect(
        CoreRadioGroupStyle.defaultLabelDescriptionGapStyle,
        CoreCheckboxStyle.defaultLabelDescriptionGapStyle,
      );
    });

    test('each size states the description by role, one step under the '
        'label', () {
      const roles = {
        CoreComponentSize.xs: CoreTextStyles.bodyXs,
        CoreComponentSize.sm: CoreTextStyles.bodyXs,
        CoreComponentSize.md: CoreTextStyles.bodySmall,
        CoreComponentSize.lg: CoreTextStyles.bodyMedium,
        CoreComponentSize.xl: CoreTextStyles.bodyMedium,
        CoreComponentSize.xl2: CoreTextStyles.bodyMedium,
      };
      for (final MapEntry(key: size, value: role) in roles.entries) {
        final description =
            CoreRadioGroupStyle.defaultsBySize[size]!.descriptionStyle!;
        expect(description.token, role, reason: '$size');
        // A role, never a bare size: the role's tracking and line box come
        // with it only when no `fontSize` overlays it.
        expect(description.fontSize, isNull, reason: '$size');
        // Never larger than the label beside it.
        final label = CoreRadioGroupStyle.defaultsBySize[size]!.labelStyle!;
        final roleSize = role.read(CoreTypography.coui).fontSize!;
        expect(roleSize, lessThanOrEqualTo(label.fontSize!), reason: '$size');
      }
    });
  });

  group('card defaults', () {
    test("the variant table carries card with the default row's ring", () {
      final card =
          CoreRadioGroupStyle.defaultsByVariant[CoreRadioGroupVariant.card]!;
      final plain = CoreRadioGroupStyle
          .defaultsByVariant[CoreRadioGroupVariant.defaultVariant]!;
      expect(card.activeColor, plain.activeColor);
      expect(card.borderColor, plain.borderColor);
      expect(card.uncheckedBackground, plain.uncheckedBackground);
      expect(card.disabledActiveColor, plain.disabledActiveColor);
      expect(card.disabledBorderColor, plain.disabledBorderColor);
      expect(card.disabledBackgroundColor, plain.disabledBackgroundColor);
      expect(card.disabledForegroundColor, plain.disabledForegroundColor);
      expect(
        CoreRadioGroupStyle.defaultsByVariant.keys,
        containsAll(CoreRadioGroupVariant.values),
      );
    });

    test('tile colours and widths', () {
      expect(
        CoreRadioGroupStyle.defaultTileBorderWidth,
        CoreStrokeWidth.stroke1,
      );
      // One rung heavier when selected — drawn inward, so nothing moves.
      expect(
        CoreRadioGroupStyle.defaultTileSelectedBorderWidth,
        CoreStrokeWidth.stroke2,
      );
      expect(
        CoreRadioGroupStyle.defaultTileBackgroundColor,
        const CoreColor.token(CoreColors.surface),
      );
      expect(
        CoreRadioGroupStyle.defaultTileSelectedBackgroundColor,
        const CoreColor.token(CoreColors.primaryContainer),
      );
      expect(
        CoreRadioGroupStyle.defaultTileBorderColor,
        const CoreColor.token(CoreColors.outlineVariant),
      );
      expect(
        CoreRadioGroupStyle.defaultTileSelectedBorderColor,
        const CoreColor.token(CoreColors.primary),
      );
    });

    test('the table covers every size with four rows', () {
      final table = CoreRadioGroupStyle.cardDefaultsBySize;
      expect(table.keys.toSet(), CoreComponentSize.values.toSet());
      // Under md uses the compact row; lg, xl and xl2 each have their own.
      expect(table[CoreComponentSize.xs], table[CoreComponentSize.md]);
      expect(table[CoreComponentSize.sm], table[CoreComponentSize.md]);
      expect(table[CoreComponentSize.md], isNot(table[CoreComponentSize.lg]));
      expect(table[CoreComponentSize.lg], isNot(table[CoreComponentSize.xl]));
      expect(table[CoreComponentSize.xl], isNot(table[CoreComponentSize.xl2]));
    });

    test('xl row — padding 16 all round, corner 16, title-small, title → '
        'description 2', () {
      final xl = CoreRadioGroupStyle.cardDefaultsBySize[CoreComponentSize.xl]!;
      expect(xl.tilePadding, const CoreEdgeInsets.all(CoreSpace.space16));
      expect(
        xl.tileBorderRadius,
        const CoreBorderRadius.all(CoreRadius.radius16),
      );
      expect(xl.labelStyle?.token, CoreTextStyles.titleSmall);
      expect(xl.labelStyle?.fontWeight, isNull);
      expect(xl.descriptionStyle?.token, CoreTextStyles.bodySmall);
      expect(xl.labelDescriptionGapStyle?.size, CoreSpace.space2);
      // The indicator and the gaps stay the roomy row's.
      final lg = CoreRadioGroupStyle.cardDefaultsBySize[CoreComponentSize.lg]!;
      expect(xl.indicatorSize, lg.indicatorSize);
      expect(xl.indicatorLabelGapStyle, lg.indicatorLabelGapStyle);
      expect(xl.itemSpacing, lg.itemSpacing);
    });

    test('xl2 row — one rung over xl on every ladder xl moved on', () {
      final xl2 =
          CoreRadioGroupStyle.cardDefaultsBySize[CoreComponentSize.xl2]!;
      expect(xl2.tilePadding, const CoreEdgeInsets.all(CoreSpace.space20));
      expect(
        xl2.tileBorderRadius,
        const CoreBorderRadius.all(CoreRadius.radius20),
      );
      expect(xl2.labelStyle?.token, CoreTextStyles.titleMedium);
      expect(xl2.descriptionStyle?.token, CoreTextStyles.bodyMedium);
      expect(xl2.labelDescriptionGapStyle?.size, CoreSpace.space2);
    });

    test('no larger size steps under a smaller one — padding, corner and '
        'type grow or hold from md to xl2', () {
      const order = [
        CoreComponentSize.md,
        CoreComponentSize.lg,
        CoreComponentSize.xl,
        CoreComponentSize.xl2,
      ];
      double font(CoreTextStyle style) {
        final rendered = CoreRadioGroupStyle.defaultLabelStyle.merge(style);
        return rendered.fontSize ??
            rendered.token!.read(CoreTypography.coui).fontSize!;
      }

      for (var i = 1; i < order.length; i++) {
        final a = CoreRadioGroupStyle.cardDefaultsBySize[order[i - 1]]!;
        final b = CoreRadioGroupStyle.cardDefaultsBySize[order[i]]!;
        final reason = '${order[i - 1]} → ${order[i]}';
        for (final (pa, pb) in [
          (a.tilePadding!.top, b.tilePadding!.top),
          (a.tilePadding!.left, b.tilePadding!.left),
          (a.tileBorderRadius!.topLeft, b.tileBorderRadius!.topLeft),
          (font(a.labelStyle!), font(b.labelStyle!)),
          (font(a.descriptionStyle!), font(b.descriptionStyle!)),
        ]) {
          expect(pb, greaterThanOrEqualTo(pa), reason: reason);
        }
      }
    });

    test('compact row — padding 10 · 12, corner 10, gaps 8, label-large', () {
      final md = CoreRadioGroupStyle.cardDefaultsBySize[CoreComponentSize.md]!;
      expect(md.tilePadding, _compact.tilePadding);
      expect(
        md.tileBorderRadius,
        const CoreBorderRadius.all(CoreRadius.radius10),
      );
      expect(md.indicatorSize, CoreSize.size18);
      expect(md.indicatorBorderWidth, CoreStrokeWidth.stroke1);
      expect(md.selectedIndicatorBorderWidth, CoreStrokeWidth.stroke5);
      expect(md.indicatorLabelGapStyle?.size, CoreSpace.space8);
      expect(md.itemSpacing, CoreSpace.space8);
      expect(md.labelStyle?.token, CoreTextStyles.labelLarge);
      expect(md.labelStyle?.fontSize, isNull);
      expect(md.labelStyle?.fontWeight, isNull);
      expect(md.descriptionStyle?.token, CoreTextStyles.bodyXs);
      expect(md.labelDescriptionGapStyle?.size, CoreSpace.space4);
    });

    test("roomy row — padding 12 · 14, panel corner, gaps 12, label-xl at "
        "the role's weight", () {
      final lg = CoreRadioGroupStyle.cardDefaultsBySize[CoreComponentSize.lg]!;
      expect(
        lg.tilePadding,
        const CoreEdgeInsets.symmetric(
          vertical: CoreSpace.space12,
          horizontal: CoreSpace.space14,
        ),
      );
      expect(
        lg.tileBorderRadius,
        const CoreBorderRadius.all(CoreRadiusRole.panel),
      );
      expect(lg.indicatorSize, CoreSize.size18);
      expect(lg.indicatorBorderWidth, CoreStrokeWidth.stroke1);
      expect(lg.selectedIndicatorBorderWidth, CoreStrokeWidth.stroke5);
      expect(lg.indicatorLabelGapStyle?.size, CoreSpace.space12);
      expect(lg.itemSpacing, CoreSpace.space12);
      expect(lg.labelStyle?.token, CoreTextStyles.labelXl);
      expect(lg.labelStyle?.fontWeight, isNull);
      expect(lg.labelStyle?.fontSize, isNull);
      expect(lg.descriptionStyle?.token, CoreTextStyles.bodySmall);
      expect(lg.labelDescriptionGapStyle?.size, CoreSpace.space4);
    });

    test('every card text entry is a role with no size overlay', () {
      for (final row in CoreRadioGroupStyle.cardDefaultsBySize.values) {
        for (final text in [row.labelStyle!, row.descriptionStyle!]) {
          expect(text.token, isNotNull);
          expect(text.fontSize, isNull);
        }
      }
    });
  });

  group('sizeDefaultsFor', () {
    test('a plain group reads the size row as it is', () {
      for (final size in CoreComponentSize.values) {
        expect(
          CoreRadioGroupStyle.sizeDefaultsFor(
            CoreRadioGroupVariant.defaultVariant,
            size,
          ),
          CoreRadioGroupStyle.defaultsBySize[size],
        );
      }
    });

    test('a card lays its row over the size row', () {
      final layer = CoreRadioGroupStyle.sizeDefaultsFor(
        CoreRadioGroupVariant.card,
        CoreComponentSize.xs,
      );
      // The tile's indicator, not the 12 px `xs` ring.
      expect(layer.indicatorSize, CoreSize.size18);
      expect(layer.selectedIndicatorBorderWidth, CoreStrokeWidth.stroke5);
      // What the card row does not restate stays the size row's.
      expect(
        layer.innerDotSize,
        CoreRadioGroupStyle.defaultsBySize[CoreComponentSize.xs]!.innerDotSize,
      );
      expect(layer.tilePadding, _compact.tilePadding);
    });

    // The size rows state their label as a bare `fontSize`, and a merge keeps
    // an earlier `fontSize` under a later role — the tile's title would draw
    // at the row's size. The layer replaces the slot instead.
    test("the card title replaces the size row's label, it does not "
        'inherit its size', () {
      final md = CoreRadioGroupStyle.sizeDefaultsFor(
        CoreRadioGroupVariant.card,
        CoreComponentSize.md,
      );
      expect(md.labelStyle?.token, CoreTextStyles.labelLarge);
      expect(md.labelStyle?.fontSize, isNull);
      final lg = CoreRadioGroupStyle.sizeDefaultsFor(
        CoreRadioGroupVariant.card,
        CoreComponentSize.lg,
      );
      // The size row says 16 here; the title is 15 / 500.
      expect(
        CoreRadioGroupStyle
            .defaultsBySize[CoreComponentSize.lg]!
            .labelStyle
            ?.fontSize,
        CoreFontSize.s16,
      );
      expect(lg.labelStyle?.token, CoreTextStyles.labelXl);
      expect(lg.labelStyle?.fontSize, isNull);
      expect(lg.labelStyle?.fontWeight, isNull);
      final rendered = CoreRadioGroupStyle.defaultLabelStyle.merge(
        lg.labelStyle,
      );
      expect(rendered.token?.read(CoreTypography.coui).fontSize, 15);
      expect(rendered.fontSize, isNull);
      expect(lg.descriptionStyle?.token, CoreTextStyles.bodySmall);
    });
  });

  group('new fields ride merge / copyWith / ==', () {
    const description = CoreTextStyle.token(
      CoreTextStyles.bodyXs,
      color: CoreColor.token(CoreColors.error),
    );
    const full = CoreRadioGroupStyle(
      descriptionStyle: description,
      labelDescriptionGapStyle: CoreGapStyle(size: CoreSpace.space6),
      tilePadding: CoreEdgeInsets.all(CoreSpace.space4),
      tileBorderRadius: CoreBorderRadius.all(CoreRadius.radius4),
      tileBorderWidth: CoreStrokeWidth.stroke2,
      tileSelectedBorderWidth: CoreStrokeWidth.stroke3,
      tileBackgroundColor: CoreColor.token(CoreColors.surface),
      tileSelectedBackgroundColor: CoreColor.token(CoreColors.primary),
      tileBorderColor: CoreColor.token(CoreColors.outline),
      tileSelectedBorderColor: CoreColor.token(CoreColors.error),
    );

    test('merge — right side wins, nested slots merge recursively', () {
      const base = CoreRadioGroupStyle(
        descriptionStyle: CoreTextStyle(fontWeight: CoreFontWeight.semiBold),
        tileBorderWidth: CoreStrokeWidth.stroke1,
      );
      final merged = base.merge(full);
      expect(merged.tilePadding, full.tilePadding);
      expect(merged.tileBorderRadius, full.tileBorderRadius);
      expect(merged.tileBorderWidth, CoreStrokeWidth.stroke2);
      expect(merged.tileSelectedBorderWidth, CoreStrokeWidth.stroke3);
      expect(merged.tileBackgroundColor, full.tileBackgroundColor);
      expect(
        merged.tileSelectedBackgroundColor,
        full.tileSelectedBackgroundColor,
      );
      expect(merged.tileBorderColor, full.tileBorderColor);
      expect(merged.tileSelectedBorderColor, full.tileSelectedBorderColor);
      expect(merged.labelDescriptionGapStyle?.size, CoreSpace.space6);
      // The base's weight survives the override's role + colour.
      expect(merged.descriptionStyle?.token, CoreTextStyles.bodyXs);
      expect(merged.descriptionStyle?.fontWeight, CoreFontWeight.semiBold);
      // A null side keeps the other.
      expect(full.merge(const CoreRadioGroupStyle()), full);
    });

    test('copyWith replaces only what it is given', () {
      final copy = full.copyWith(
        tileBorderWidth: CoreStrokeWidth.stroke4,
        tileSelectedBorderColor: const CoreColor.token(CoreColors.success),
      );
      expect(copy.tileBorderWidth, CoreStrokeWidth.stroke4);
      expect(
        copy.tileSelectedBorderColor,
        const CoreColor.token(CoreColors.success),
      );
      expect(copy.descriptionStyle, description);
      expect(copy.tilePadding, full.tilePadding);
      expect(copy.tileBackgroundColor, full.tileBackgroundColor);
      expect(full.copyWith(), full);
    });

    test('== and hashCode see every new field', () {
      final variants = <CoreRadioGroupStyle>[
        full.copyWith(
          descriptionStyle: const CoreTextStyle.token(
            CoreTextStyles.bodySmall,
          ),
        ),
        full.copyWith(
          labelDescriptionGapStyle: const CoreGapStyle(size: CoreSpace.space8),
        ),
        full.copyWith(tilePadding: const CoreEdgeInsets.all(CoreSpace.space8)),
        full.copyWith(
          tileBorderRadius: const CoreBorderRadius.all(CoreRadius.radius8),
        ),
        full.copyWith(tileBorderWidth: CoreStrokeWidth.stroke3),
        full.copyWith(tileSelectedBorderWidth: CoreStrokeWidth.stroke4),
        full.copyWith(
          tileBackgroundColor: const CoreColor.token(CoreColors.error),
        ),
        full.copyWith(
          tileSelectedBackgroundColor: const CoreColor.token(CoreColors.error),
        ),
        full.copyWith(tileBorderColor: const CoreColor.token(CoreColors.error)),
        full.copyWith(
          tileSelectedBorderColor: const CoreColor.token(CoreColors.primary),
        ),
      ];
      for (final variant in variants) {
        expect(variant, isNot(full));
        expect(variant.hashCode, isNot(full.hashCode));
      }
      expect(
        const CoreRadioGroupStyle(
          tileBorderWidth: CoreStrokeWidth.stroke2,
        ).hashCode,
        const CoreRadioGroupStyle(
          tileBorderWidth: CoreStrokeWidth.stroke2,
        ).hashCode,
      );
    });
  });
}
