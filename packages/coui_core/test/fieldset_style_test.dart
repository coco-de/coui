// CoreFieldsetStyle — the size-keyed legend typography ladder (Figma "❖
// Fieldset", Size axis md/lg extended onto the shared six-tier
// CoreComponentSize scale), the disabled legend colour override, the
// variant-keyed box (filled · outlined · plain), the description line and
// the header gaps.

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

void main() {
  group('defaultsBySize', () {
    test('covers every CoreComponentSize member', () {
      expect(
        CoreFieldsetStyle.defaultsBySize.keys.toSet(),
        CoreComponentSize.values.toSet(),
      );
    });

    test('xs/sm/md read at the 16px (titleSmall) rung', () {
      for (final size in [
        CoreComponentSize.xs,
        CoreComponentSize.sm,
        CoreComponentSize.md,
      ]) {
        expect(
          CoreFieldsetStyle.defaultsBySize[size]!.legendTextStyle,
          CoreFieldsetStyle.defaultLegendTextStyle,
          reason: '$size should read at the 16px rung',
        );
      }
    });

    test('lg/xl/xl2 read at the 18px (titleMedium) rung', () {
      for (final size in [
        CoreComponentSize.lg,
        CoreComponentSize.xl,
        CoreComponentSize.xl2,
      ]) {
        expect(
          CoreFieldsetStyle.defaultsBySize[size]!.legendTextStyle,
          CoreFieldsetStyle.defaultLegendTextStyleLarge,
          reason: '$size should read at the 18px rung',
        );
      }
    });

    test('defaultSize is md', () {
      expect(CoreFieldsetStyle.defaultSize, CoreComponentSize.md);
    });
  });

  group('token values', () {
    test('defaultLegendTextStyle is titleSmall (16px), on-surface, no '
        "lineHeight overlay (role's own 140% is kept)", () {
      expect(
        CoreFieldsetStyle.defaultLegendTextStyle.token,
        CoreTextStyles.titleSmall,
      );
      expect(
        CoreFieldsetStyle.defaultLegendTextStyle.color!.token,
        CoreColors.onSurface,
      );
      expect(CoreFieldsetStyle.defaultLegendTextStyle.lineHeight, isNull);
      expect(CoreFieldsetStyle.defaultLegendTextStyle.fontWeight, isNull);
    });

    test('defaultLegendTextStyleLarge is titleMedium (18px), on-surface, no '
        'lineHeight overlay', () {
      expect(
        CoreFieldsetStyle.defaultLegendTextStyleLarge.token,
        CoreTextStyles.titleMedium,
      );
      expect(
        CoreFieldsetStyle.defaultLegendTextStyleLarge.color!.token,
        CoreColors.onSurface,
      );
      expect(
        CoreFieldsetStyle.defaultLegendTextStyleLarge.lineHeight,
        isNull,
      );
    });

    test('defaultDisabledLegendColor is disabled-content (canvas-literal '
        'decision, not the onSurfaceVariant convention)', () {
      expect(
        CoreFieldsetStyle.defaultDisabledLegendColor.token,
        CoreColors.disabledContent,
      );
    });

    test('defaultFieldSpacing is space16: label-less fields read as one '
        'group, and a form with label rows states space24 itself', () {
      expect(CoreFieldsetStyle.defaultFieldSpacing, CoreSpace.space16);
    });

    test('the header sits closer to the first field than the fields do to '
        'each other', () {
      expect(
        CoreFieldsetStyle.defaultHeaderFieldsGapStyle.size,
        CoreSpace.space12,
      );
      expect(
        CoreFieldsetStyle.defaultHeaderFieldsGapStyle.size,
        lessThan(CoreFieldsetStyle.defaultFieldSpacing),
      );
      expect(
        CoreFieldsetStyle.defaultLegendDescriptionGapStyle.size,
        CoreSpace.space4,
      );
    });

    test('the legend starts on the same line as the fields (no inset)', () {
      expect(CoreFieldsetStyle.defaultLegendPadding, CoreEdgeInsets.zero);
    });

    test('defaultDescriptionTextStyle is bodySmall in on-surface-variant', () {
      expect(
        CoreFieldsetStyle.defaultDescriptionTextStyle.token,
        CoreTextStyles.bodySmall,
      );
      expect(
        CoreFieldsetStyle.defaultDescriptionTextStyle.color!.token,
        CoreColors.onSurfaceVariant,
      );
    });
  });

  group('defaultsByVariant', () {
    test('covers every CoreFieldsetVariant member', () {
      expect(
        CoreFieldsetStyle.defaultsByVariant.keys.toSet(),
        CoreFieldsetVariant.values.toSet(),
      );
    });

    test('defaultVariant is filled', () {
      expect(CoreFieldsetVariant.defaultVariant, CoreFieldsetVariant.filled);
    });

    test('every row states the five box fields', () {
      for (final entry in CoreFieldsetStyle.defaultsByVariant.entries) {
        final row = entry.value;
        expect(row.padding, isNotNull, reason: '${entry.key} padding');
        expect(row.borderRadius, isNotNull, reason: '${entry.key} radius');
        expect(row.borderWidth, isNotNull, reason: '${entry.key} width');
        expect(row.backgroundColor, isNotNull, reason: '${entry.key} fill');
        expect(row.borderColor, isNotNull, reason: '${entry.key} edge');
      }
    });

    test(
      'filled: faint panel fill inside the hairline edge, surface corner',
      () {
        final row =
            CoreFieldsetStyle.defaultsByVariant[CoreFieldsetVariant.filled]!;
        expect(row.backgroundColor!.token, CoreColors.surfaceContainerLow);
        expect(row.borderColor!.token, CoreColors.outlineSubtle);
        expect(row.borderWidth, CoreStrokeWidth.stroke1);
        expect(
          row.borderRadius,
          const CoreBorderRadius.all(CoreRadiusRole.surface),
        );
        expect(row.padding, const CoreEdgeInsets.all(CoreSpace.space16));
      },
    );

    test('outlined: the same edge and corner as filled, no fill', () {
      final filled =
          CoreFieldsetStyle.defaultsByVariant[CoreFieldsetVariant.filled]!;
      final row =
          CoreFieldsetStyle.defaultsByVariant[CoreFieldsetVariant.outlined]!;
      expect(row.backgroundColor, CoreColor.transparent);
      expect(row.borderColor, filled.borderColor);
      expect(row.borderWidth, filled.borderWidth);
      expect(row.borderRadius, filled.borderRadius);
      expect(row.padding, filled.padding);
    });

    test('plain: no fill, no edge, no corner, no padding', () {
      final row =
          CoreFieldsetStyle.defaultsByVariant[CoreFieldsetVariant.plain]!;
      expect(row.backgroundColor, CoreColor.transparent);
      expect(row.borderColor, CoreColor.transparent);
      expect(row.borderWidth, CoreStrokeWidth.stroke0);
      expect(row.borderRadius, CoreBorderRadius.zero);
      expect(row.padding, CoreEdgeInsets.zero);
    });

    test(
      'the container edge is lighter than the fields edge (outline-variant)',
      () {
        // The container must never read stronger than what it holds.
        expect(
          CoreFieldsetStyle.defaultBorderColor.token,
          CoreColors.outlineSubtle,
        );
        expect(
          CoreFieldsetStyle.defaultBorderColor.token,
          isNot(CoreColors.outline),
        );
      },
    );
  });

  group('CoreFieldsetTheme', () {
    test('variantStyles take part in == and hashCode', () {
      const a = CoreFieldsetTheme(
        variantStyles: {
          CoreFieldsetVariant.plain: CoreFieldsetStyle(
            fieldSpacing: CoreSpace.space24,
          ),
        },
      );
      const same = CoreFieldsetTheme(
        variantStyles: {
          CoreFieldsetVariant.plain: CoreFieldsetStyle(
            fieldSpacing: CoreSpace.space24,
          ),
        },
      );
      const other = CoreFieldsetTheme(
        variantStyles: {
          CoreFieldsetVariant.plain: CoreFieldsetStyle(
            fieldSpacing: CoreSpace.space12,
          ),
        },
      );
      expect(a, same);
      expect(a.hashCode, same.hashCode);
      expect(a == other, isFalse);
      expect(a == const CoreFieldsetTheme(), isFalse);
    });
  });

  group('merge / copyWith / ==', () {
    test('null other returns this', () {
      const a = CoreFieldsetStyle(disabledLegendColor: CoreColor.transparent);
      expect(identical(a.merge(null), a), isTrue);
    });

    test('disabledLegendColor: right-most non-null wins', () {
      const base = CoreFieldsetStyle(
        disabledLegendColor: CoreColor.transparent,
      );
      const over = CoreFieldsetStyle(
        disabledLegendColor: CoreColor.token(CoreColors.error),
      );
      expect(base.merge(over).disabledLegendColor!.token, CoreColors.error);
      expect(over.merge(base).disabledLegendColor, CoreColor.transparent);
    });

    test('description fields: merge right-most wins, nested gap merges '
        'recursively, copyWith and == carry them', () {
      const base = CoreFieldsetStyle(
        descriptionTextStyle: CoreTextStyle.token(CoreTextStyles.bodySmall),
        legendDescriptionGapStyle: CoreGapStyle(size: CoreSpace.space4),
        headerFieldsGapStyle: CoreGapStyle(size: CoreSpace.space12),
      );
      const over = CoreFieldsetStyle(
        headerFieldsGapStyle: CoreGapStyle(size: CoreSpace.space8),
      );
      final merged = base.merge(over);
      expect(merged.headerFieldsGapStyle!.size, CoreSpace.space8);
      expect(merged.legendDescriptionGapStyle!.size, CoreSpace.space4);
      expect(merged.descriptionTextStyle!.token, CoreTextStyles.bodySmall);

      final copy = base.copyWith(
        legendDescriptionGapStyle: const CoreGapStyle(size: CoreSpace.space8),
      );
      expect(copy.legendDescriptionGapStyle!.size, CoreSpace.space8);
      expect(copy.headerFieldsGapStyle!.size, CoreSpace.space12);
      expect(base == copy, isFalse);
      expect(base.hashCode, isNot(copy.hashCode));
    });

    test('copyWith replaces only disabledLegendColor; == compares it', () {
      const a = CoreFieldsetStyle(fieldSpacing: CoreSpace.space16);
      final b = a.copyWith(
        disabledLegendColor: const CoreColor.token(CoreColors.error),
      );
      expect(b.fieldSpacing, CoreSpace.space16);
      expect(b.disabledLegendColor!.token, CoreColors.error);
      expect(a == b, isFalse);
      expect(a.hashCode, isNot(b.hashCode));
    });
  });
}
