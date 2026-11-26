// Tests for CoreStatStyle's defaults.

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

void main() {
  group('defaults', () {
    test('padding is 20 down, 24 across', () {
      expect(
        CoreStatStyle.defaultPadding,
        const CoreEdgeInsets.symmetric(horizontal: 24, vertical: 20),
      );
    });

    test('the sections are 10 apart', () {
      expect(CoreStatStyle.defaultContentGapStyle.size, 10);
    });

    test('the unit sits 4 after the value', () {
      expect(CoreStatStyle.defaultValueUnitGapStyle.size, CoreSpace.space4);
    });

    test('the value is headlineLarge, the label bodyMedium (Regular)', () {
      expect(
        CoreStatStyle.defaultValueTextStyle.token,
        CoreTextStyles.headlineLarge,
      );
      expect(
        CoreStatStyle.defaultLabelTextStyle.token,
        CoreTextStyles.bodyMedium,
      );
    });

    test('the unit is titleMedium a weight down; the description '
        'bodySmall', () {
      // The weight is a component overlay on the role, not a different
      // role: the token survives so both resolvers still read the role.
      expect(
        CoreStatStyle.defaultUnitTextStyle.token,
        CoreTextStyles.titleMedium,
      );
      expect(
        CoreStatStyle.defaultUnitTextStyle.fontWeight,
        CoreFontWeight.medium,
      );
      expect(CoreStatStyle.defaultUnitTextStyle.fontSize, isNull);
      expect(
        CoreStatStyle.defaultDescriptionTextStyle.token,
        CoreTextStyles.bodySmall,
      );
    });

    test('an absent value reads as an em dash', () {
      expect(CoreStatContract.defaultEmptyValue, '\u{2014}');
    });
  });

  group('variants', () {
    test('outlined is the default, filled stays', () {
      expect(CoreStatVariant.defaultVariant, CoreStatVariant.outlined);
      expect(CoreStatVariant.values, [
        CoreStatVariant.outlined,
        CoreStatVariant.filled,
      ]);
      expect(
        CoreStatStyle.defaultsByVariant.keys,
        containsAll(CoreStatVariant.values),
      );
    });

    test('filled is a surfaceContainerLow face with no line', () {
      final filled = CoreStatStyle.defaultsByVariant[CoreStatVariant.filled]!;
      expect(filled.backgroundColor.token, CoreColors.surfaceContainerLow);
      expect(filled.borderWidth, 0);
      // Transparent, not a token: a token border at width 0 still lets
      // Flutter's OutlinedContainer draw its hairline fallback.
      expect(filled.borderColor, CoreColor.transparent);
    });

    test('outlined is the page face with a 1px outline-variant', () {
      final outlined =
          CoreStatStyle.defaultsByVariant[CoreStatVariant.outlined]!;
      expect(outlined.backgroundColor.token, CoreColors.surface);
      expect(outlined.borderColor.token, CoreColors.outlineVariant);
      expect(outlined.borderWidth, CoreStrokeWidth.stroke1);
    });
  });

  group('colours', () {
    test('a change reads in the container-text colours, not the fills', () {
      expect(
        CoreStatStyle.defaultPositiveColor,
        const CoreColor.token(CoreColors.onSuccessContainer),
      );
      expect(
        CoreStatStyle.defaultNegativeColor,
        const CoreColor.token(CoreColors.onErrorContainer),
      );
      expect(
        CoreStatStyle.defaultNeutralColor,
        const CoreColor.token(CoreColors.onSurfaceVariant),
      );
    });

    test('unit and empty value are the second tier, description the '
        'third', () {
      expect(
        CoreStatStyle.defaultUnitColor,
        const CoreColor.token(CoreColors.onSurfaceVariant),
      );
      expect(
        CoreStatStyle.defaultEmptyValueColor,
        const CoreColor.token(CoreColors.onSurfaceVariant),
      );
      expect(
        CoreStatStyle.defaultDescriptionColor,
        const CoreColor.token(CoreColors.onSurfaceSubtle),
      );
    });
  });

  group('value semantics of the new slots', () {
    const patch = CoreStatStyle(
      valueUnitGapStyle: CoreGapStyle(size: CoreSpace.space8),
      unitColor: CoreColor.token(CoreColors.primary),
      emptyValueColor: CoreColor.token(CoreColors.error),
      descriptionColor: CoreColor.token(CoreColors.onSurface),
      unitTextStyle: CoreTextStyle.token(CoreTextStyles.titleSmall),
      descriptionTextStyle: CoreTextStyle.token(CoreTextStyles.labelSmall),
    );

    test('merge carries every new slot', () {
      final merged = const CoreStatStyle().merge(patch);
      expect(merged.valueUnitGapStyle, patch.valueUnitGapStyle);
      expect(merged.unitColor, patch.unitColor);
      expect(merged.emptyValueColor, patch.emptyValueColor);
      expect(merged.descriptionColor, patch.descriptionColor);
      expect(merged.unitTextStyle, patch.unitTextStyle);
      expect(merged.descriptionTextStyle, patch.descriptionTextStyle);
    });

    test('merge keeps the base where the patch is silent', () {
      final merged = patch.merge(const CoreStatStyle(labelColor: .transparent));
      expect(merged.unitColor, patch.unitColor);
      expect(merged.descriptionTextStyle, patch.descriptionTextStyle);
    });

    test('copyWith carries every new slot', () {
      final copied = const CoreStatStyle().copyWith(
        valueUnitGapStyle: patch.valueUnitGapStyle,
        unitColor: patch.unitColor,
        emptyValueColor: patch.emptyValueColor,
        descriptionColor: patch.descriptionColor,
        unitTextStyle: patch.unitTextStyle,
        descriptionTextStyle: patch.descriptionTextStyle,
      );
      expect(copied, patch);
      expect(copied.hashCode, patch.hashCode);
    });

    test('each new slot takes part in equality', () {
      final variants = <CoreStatStyle>[
        const CoreStatStyle(
          valueUnitGapStyle: CoreGapStyle(size: CoreSpace.space8),
        ),
        const CoreStatStyle(unitColor: CoreColor.token(CoreColors.primary)),
        const CoreStatStyle(
          emptyValueColor: CoreColor.token(CoreColors.primary),
        ),
        const CoreStatStyle(
          descriptionColor: CoreColor.token(CoreColors.primary),
        ),
        const CoreStatStyle(
          unitTextStyle: CoreTextStyle.token(CoreTextStyles.titleSmall),
        ),
        const CoreStatStyle(
          descriptionTextStyle: CoreTextStyle.token(CoreTextStyles.labelSmall),
        ),
      ];
      for (final style in variants) {
        expect(style, isNot(const CoreStatStyle()));
      }
    });
  });

  group('sizes', () {
    test('md keeps the card the library has always drawn', () {
      final md = CoreStatStyle.defaultsBySize[CoreComponentSize.md]!;
      expect(md.padding, CoreStatStyle.defaultPadding);
      expect(md.contentGapStyle, CoreStatStyle.defaultContentGapStyle);
      expect(md.valueTextStyle, CoreStatStyle.defaultValueTextStyle);
    });

    test('sm is 14 / 16 padded with a 4 row gap', () {
      final sm = CoreStatStyle.defaultsBySize[CoreComponentSize.sm]!;
      expect(
        sm.padding,
        const CoreEdgeInsets.symmetric(
          horizontal: CoreSpace.space16,
          vertical: CoreSpace.space14,
        ),
      );
      expect(sm.contentGapStyle!.size, CoreSpace.space4);
    });

    test('sm text: Regular label/description, titleLarge role figure', () {
      final sm = CoreStatStyle.defaultsBySize[CoreComponentSize.sm]!;
      expect(sm.labelTextStyle!.token, CoreTextStyles.bodySmall);
      expect(sm.descriptionTextStyle!.token, CoreTextStyles.bodyXs);
      expect(sm.valueTextStyle!.token, CoreTextStyles.titleLarge);
      // The role as the scale states it — a weight overlay splits the
      // figure from its role and leaves the canvas label without a style.
      expect(
        sm.valueTextStyle,
        const CoreTextStyle.token(CoreTextStyles.titleLarge),
      );
      expect(sm.valueTextStyle!.fontWeight, isNull);
      expect(sm.unitTextStyle!.token, CoreTextStyles.labelXl);
      expect(sm.changeTextStyle!.token, CoreTextStyles.labelSmall);
    });
  });
}
