import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

void main() {
  group('CoreOptionItemStyle', () {
    test('the card is 12 above and below, 16 at the sides, 52 tall', () {
      expect(
        CoreOptionItemStyle.defaultPadding,
        const CoreEdgeInsets.symmetric(
          horizontal: CoreSpace.space16,
          vertical: CoreSpace.space12,
        ),
      );
      expect(CoreOptionItemStyle.defaultMinHeight, 52);
      expect(CoreOptionItemStyle.defaultSpacing, CoreSpace.space12);
      expect(
        CoreOptionItemStyle.defaultDescriptionGapStyle.size,
        CoreSpace.space4,
      );
    });

    test('the card: corner 12, outline-variant 1 at rest', () {
      expect(
        CoreOptionItemStyle.defaultBorderRadius,
        const CoreBorderRadius.all(CoreRadius.radius12),
      );
      expect(
        CoreOptionItemStyle.defaultBorderColor,
        const CoreColor.token(CoreColors.outlineVariant),
      );
      expect(CoreOptionItemStyle.defaultBorderWidth, CoreStrokeWidth.stroke1);
    });

    test('a chosen card: primary 1.5 on surface-container-low', () {
      expect(
        CoreOptionItemStyle.defaultSelectedBorderColor,
        const CoreColor.token(CoreColors.primary),
      );
      expect(
        CoreOptionItemStyle.defaultSelectedBorderWidth,
        CoreStrokeWidth.stroke1_5,
      );
      expect(
        CoreOptionItemStyle.defaultSelectedBackgroundColor,
        const CoreColor.token(CoreColors.surfaceContainerLow),
      );
      expect(
        CoreOptionItemStyle.defaultDisabledSelectedBackgroundColor,
        const CoreColor.token(CoreColors.surfaceContainer),
      );
    });

    test('the label is bodyLarge at Medium, the role line box kept', () {
      final label = CoreOptionItemStyle.defaultLabelTextStyle;
      expect(label.token, CoreTextStyles.bodyLarge);
      expect(label.fontWeight, CoreFontWeight.medium);
      expect(label.lineHeight, isNull);
      expect(label.lineHeightPx, isNull);
    });

    test('glyphs are 20, the check is the accent colour', () {
      expect(CoreOptionItemStyle.defaultLeadingIconStyle.size, 20);
      expect(CoreOptionItemStyle.defaultCheckIconStyle.size, 20);
      expect(
        CoreOptionItemStyle.defaultCheckIconStyle.color,
        const CoreColor.token(CoreColors.primary),
      );
    });

    test('a disabled row reads the disabled-content slot', () {
      expect(
        CoreOptionItemStyle.defaultDisabledForegroundColor,
        const CoreColor.token(CoreColors.disabledContent),
      );
    });

    test('the pressed face is opaque surface-container-high inside', () {
      expect(
        CoreOptionItemStyle.defaultPressedBackgroundColor,
        const CoreColor.token(CoreColors.surfaceContainerHigh),
      );
      expect(CoreOptionItemStyle.defaultStateLayer.pressed, 1);
      expect(CoreOptionItemStyle.defaultStateLayer.isAscending, isTrue);
      expect(
        CoreOptionItemStyle.defaultPressedBackgroundBorderRadius,
        const CoreBorderRadius.all(CoreRadius.radius12),
      );
      expect(CoreOptionItemStyle.defaultPressedBackgroundOutset, 0);
      expect(CoreOptionItemStyle.defaultPressedBackgroundInset, 0);
      // The face's stated corner is the card's, so inside the border it is
      // concentric with the border's inner curve.
      expect(
        CoreOptionItemStyle.defaultPressedBackgroundBorderRadius,
        CoreOptionItemStyle.defaultBorderRadius,
      );
    });

    test('a chosen label is accent for single, ink for multiple', () {
      final single = CoreOptionItemStyle
          .defaultsBySelection[CoreOptionItemSelection.single]!
          .selectedLabelTextStyle!;
      final multiple = CoreOptionItemStyle
          .defaultsBySelection[CoreOptionItemSelection.multiple]!
          .selectedLabelTextStyle!;
      expect(single.color, const CoreColor.token(CoreColors.primary));
      expect(multiple.color, const CoreColor.token(CoreColors.onSurface));
      expect(single.fontWeight, CoreFontWeight.semiBold);
      expect(multiple.fontWeight, CoreFontWeight.semiBold);
    });

    test('the composed Clickable neither shrinks nor dims the row', () {
      expect(CoreOptionItemStyle.defaultClickableStyle.pressedScale, 1);
      expect(CoreOptionItemStyle.defaultClickableStyle.disabledOpacity, 1);
    });

    test('every selection has a default entry', () {
      for (final selection in CoreOptionItemSelection.values) {
        expect(CoreOptionItemStyle.defaultsBySelection[selection], isNotNull);
      }
      expect(
        CoreOptionItemSelection.defaultSelection,
        CoreOptionItemSelection.single,
      );
    });

    test('merge: the other style wins field by field', () {
      const base = CoreOptionItemStyle(
        spacing: 4,
        labelTextStyle: CoreTextStyle(fontWeight: CoreFontWeight.bold),
      );
      const other = CoreOptionItemStyle(
        padding: CoreEdgeInsets.all(2),
        labelTextStyle: CoreTextStyle(
          color: CoreColor.token(CoreColors.primary),
        ),
      );
      final merged = base.merge(other);
      expect(merged.spacing, 4);
      expect(merged.padding, const CoreEdgeInsets.all(2));
      expect(merged.labelTextStyle!.fontWeight, CoreFontWeight.bold);
      expect(
        merged.labelTextStyle!.color,
        const CoreColor.token(CoreColors.primary),
      );
      expect(base.merge(null), same(base));
    });

    test('copyWith and equality cover the fields', () {
      const a = CoreOptionItemStyle(spacing: 1, pressedBackgroundInset: 3);
      expect(a.copyWith(), a);
      expect(a.copyWith(spacing: 2), isNot(a));
      expect(a.copyWith().hashCode, a.hashCode);
      expect(a.copyWith(pressedBackgroundOutset: 1), isNot(a));
    });

    test('the card fields merge, copy and compare', () {
      const base = CoreOptionItemStyle(minHeight: 40, borderWidth: 2);
      const other = CoreOptionItemStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius4),
        borderColor: CoreColor.token(CoreColors.outline),
        selectedBackgroundColor: CoreColor.token(CoreColors.surface),
        selectedBorderColor: CoreColor.token(CoreColors.error),
        selectedBorderWidth: 3,
        disabledSelectedBackgroundColor: CoreColor.token(
          CoreColors.surfaceContainerHigh,
        ),
      );
      final merged = base.merge(other);
      expect(merged.minHeight, 40);
      expect(merged.borderWidth, 2);
      expect(merged.borderRadius, other.borderRadius);
      expect(merged.borderColor, other.borderColor);
      expect(merged.selectedBackgroundColor, other.selectedBackgroundColor);
      expect(merged.selectedBorderColor, other.selectedBorderColor);
      expect(merged.selectedBorderWidth, 3);
      expect(
        merged.disabledSelectedBackgroundColor,
        other.disabledSelectedBackgroundColor,
      );
      expect(merged.copyWith(), merged);
      expect(merged.copyWith().hashCode, merged.hashCode);
      for (final changed in [
        merged.copyWith(minHeight: 1),
        merged.copyWith(borderRadius: CoreBorderRadius.zero),
        merged.copyWith(borderColor: const CoreColor.token(CoreColors.primary)),
        merged.copyWith(borderWidth: 9),
        merged.copyWith(
          selectedBackgroundColor: const CoreColor.token(CoreColors.primary),
        ),
        merged.copyWith(
          selectedBorderColor: const CoreColor.token(CoreColors.primary),
        ),
        merged.copyWith(selectedBorderWidth: 9),
        merged.copyWith(
          disabledSelectedBackgroundColor: const CoreColor.token(
            CoreColors.primary,
          ),
        ),
      ]) {
        expect(changed, isNot(merged));
      }
    });
  });

  group('CoreOptionListStyle', () {
    test('rows stand 8 apart', () {
      expect(CoreOptionListStyle.defaultSpacing, CoreSpace.space8);
    });

    test('merge · copyWith · equality', () {
      const a = CoreOptionListStyle(spacing: 4);
      expect(const CoreOptionListStyle().merge(a), a);
      expect(a.merge(const CoreOptionListStyle()), a);
      expect(a.copyWith(spacing: 6), const CoreOptionListStyle(spacing: 6));
      expect(a.hashCode, const CoreOptionListStyle(spacing: 4).hashCode);
    });
  });

  group('CoreComponentTheme', () {
    test('carries the option slots', () {
      const theme = CoreComponentTheme(
        optionItem: CoreOptionItemTheme(
          style: CoreOptionItemStyle(spacing: 1),
        ),
        optionList: CoreOptionListTheme(style: CoreOptionListStyle(spacing: 2)),
      );
      expect(theme.copyWith().optionItem, theme.optionItem);
      expect(theme.copyWith().optionList, theme.optionList);
      expect(
        theme.copyWith(optionItem: const CoreOptionItemTheme()),
        isNot(theme),
      );
      expect(
        theme.copyWith(optionList: const CoreOptionListTheme()),
        isNot(theme),
      );
    });
  });
}
