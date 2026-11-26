// Tests for CoreColorPickerStyle (Epic #1302 — Story #1314b).

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

const double _kFontLabel = 14;
const double _kFontTitle = 18;
const int _kWeightSemiBold = CoreFontWeight.semiBold;
const int _kWeightRegular = CoreFontWeight.regular;
const _kColorOnSurface = CoreColor.token(CoreColors.onSurface);
const _kColorError = CoreColor.token(CoreColors.error);
const _kColorPrimary = CoreColor.token(CoreColors.primary);

void main() {
  group('CoreColorPickerStyle.merge', () {
    test('null other returns this', () {
      const a = CoreColorPickerStyle(
        labelStyle: CoreTextStyle(fontSize: _kFontLabel),
      );
      expect(identical(a.merge(null), a), isTrue);
    });

    test('chain — design system → theme.style → widget', () {
      const designSystem = CoreColorPickerStyle(
        labelStyle: CoreTextStyle(
          fontSize: _kFontLabel,
          fontWeight: _kWeightRegular,
          color: _kColorOnSurface,
        ),
      );
      const themeStyle = CoreColorPickerStyle(
        labelStyle: CoreTextStyle(fontWeight: _kWeightSemiBold),
      );
      const widgetStyle = CoreColorPickerStyle(
        errorStyle: CoreTextStyle(color: _kColorError),
      );

      final effective = designSystem.merge(themeStyle).merge(widgetStyle);

      expect(effective.labelStyle?.fontSize, _kFontLabel);
      expect(effective.labelStyle?.fontWeight, _kWeightSemiBold);
      expect(effective.labelStyle?.color, _kColorOnSurface);
      expect(effective.errorStyle?.color, _kColorError);
    });

    test('right-most non-null wins on each field', () {
      const a = CoreColorPickerStyle(
        labelStyle: CoreTextStyle(fontSize: _kFontLabel),
        descriptionStyle: CoreTextStyle(fontSize: _kFontLabel),
      );
      const b = CoreColorPickerStyle(
        labelStyle: CoreTextStyle(fontSize: _kFontTitle),
      );
      const c = CoreColorPickerStyle(
        descriptionStyle: CoreTextStyle(fontSize: _kFontTitle),
      );

      final result = a.merge(b).merge(c);

      expect(result.labelStyle?.fontSize, _kFontTitle);
      expect(result.descriptionStyle?.fontSize, _kFontTitle);
    });

    test('popoverStyle / dialogStyle / swatchButtonStyle / hexInputStyle '
        'merge recursively', () {
      const base = CoreColorPickerStyle(
        popoverStyle: CorePopoverStyle(
          panelStyle: CorePopupStyle(borderRadius: CoreBorderRadius.all(8)),
          placementOffset: 8,
        ),
        dialogStyle: CoreDialogStyle(
          panelBorderRadius: CoreBorderRadius.all(12),
        ),
        swatchButtonStyle: CoreButtonStyle(
          padding: CoreEdgeInsets.symmetric(horizontal: 8),
        ),
        hexInputStyle: CoreTextFieldStyle(
          padding: CoreEdgeInsets.symmetric(horizontal: 12),
        ),
      );
      const override = CoreColorPickerStyle(
        popoverStyle: CorePopoverStyle(placementOffset: 12),
        swatchButtonStyle: CoreButtonStyle(
          padding: CoreEdgeInsets.symmetric(horizontal: 16),
        ),
      );
      final merged = base.merge(override);
      expect(
        merged.popoverStyle?.panelStyle?.borderRadius,
        const CoreBorderRadius.all(8),
      );
      expect(merged.popoverStyle?.placementOffset, 12);
      expect(
        merged.dialogStyle?.panelBorderRadius,
        const CoreBorderRadius.all(12),
      );
      expect(
        merged.swatchButtonStyle?.padding,
        const CoreEdgeInsets.symmetric(horizontal: 16),
      );
      expect(
        merged.hexInputStyle?.padding,
        const CoreEdgeInsets.symmetric(horizontal: 12),
      );
    });

    test('recentSwatchClickableStyle merges recursively', () {
      const base = CoreColorPickerStyle(
        recentSwatchClickableStyle: CoreClickableStyle(pressedScale: 1),
      );
      const override = CoreColorPickerStyle(
        recentSwatchClickableStyle: CoreClickableStyle(disabledOpacity: 0.3),
      );
      final merged = base.merge(override);
      expect(merged.recentSwatchClickableStyle?.pressedScale, 1);
      expect(merged.recentSwatchClickableStyle?.disabledOpacity, 0.3);
    });

    test('null nested style on base inherits from override', () {
      const base = CoreColorPickerStyle();
      const override = CoreColorPickerStyle(
        swatchButtonStyle: CoreButtonStyle(
          backgroundColor: _kColorPrimary,
          padding: CoreEdgeInsets.symmetric(horizontal: 16),
        ),
      );
      final merged = base.merge(override);
      expect(
        merged.swatchButtonStyle?.padding,
        const CoreEdgeInsets.symmetric(horizontal: 16),
      );
      expect(merged.swatchButtonStyle?.backgroundColor, _kColorPrimary);
    });
  });

  group('CoreColorPickerStyle equality', () {
    test('same fields → equal', () {
      const a = CoreColorPickerStyle(
        labelStyle: CoreTextStyle(fontSize: _kFontLabel),
      );
      const b = CoreColorPickerStyle(
        labelStyle: CoreTextStyle(fontSize: _kFontLabel),
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('different hexInputStyle → not equal', () {
      const a = CoreColorPickerStyle(
        hexInputStyle: CoreTextFieldStyle(
          padding: CoreEdgeInsets.symmetric(horizontal: 8),
        ),
      );
      const b = CoreColorPickerStyle(
        hexInputStyle: CoreTextFieldStyle(
          padding: CoreEdgeInsets.symmetric(horizontal: 12),
        ),
      );
      expect(a, isNot(equals(b)));
    });
  });

  group('CoreColorPickerStyle.copyWith', () {
    test('only-supplied fields override', () {
      const base = CoreColorPickerStyle(
        labelStyle: CoreTextStyle(fontSize: _kFontLabel),
      );
      final copy = base.copyWith(
        errorStyle: const CoreTextStyle(color: _kColorError),
      );
      expect(copy.labelStyle?.fontSize, _kFontLabel);
      expect(copy.errorStyle?.color, _kColorError);
    });

    test('preserves nested popoverStyle when not specified', () {
      const base = CoreColorPickerStyle(
        popoverStyle: CorePopoverStyle(placementOffset: 12),
      );
      final copy = base.copyWith(
        labelStyle: const CoreTextStyle(fontSize: _kFontLabel),
      );
      expect(copy.labelStyle?.fontSize, _kFontLabel);
      expect(copy.popoverStyle?.placementOffset, 12);
    });
  });

  group('CoreColorPickerTheme', () {
    test('style passes through', () {
      const style = CoreColorPickerStyle(
        swatchButtonStyle: CoreButtonStyle(
          padding: CoreEdgeInsets.symmetric(horizontal: 16),
        ),
      );
      const theme = CoreColorPickerTheme(style: style);
      expect(theme.style, style);
    });

    test('null style', () {
      const theme = CoreColorPickerTheme();
      expect(theme.style, isNull);
    });

    test('equality', () {
      const a = CoreColorPickerTheme(
        style: CoreColorPickerStyle(
          popoverStyle: CorePopoverStyle(placementOffset: 12),
        ),
      );
      const b = CoreColorPickerTheme(
        style: CoreColorPickerStyle(
          popoverStyle: CorePopoverStyle(placementOffset: 12),
        ),
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });
  });

  group('CoreColorPickerStyle redesigned defaults', () {
    test('geometry follows the confirmed spec', () {
      expect(
        CoreColorPickerStyle.defaultSaturationValueBorderRadius.topLeft,
        8,
      );
      expect(CoreColorPickerStyle.defaultSliderHeight, 8);
      expect(CoreColorPickerStyle.defaultPickMarkerSize, 18);
      expect(CoreColorPickerStyle.defaultPickMarkerBorderWidth, 3);
      expect(CoreColorPickerStyle.defaultSwatchSize, 32);
      expect(CoreColorPickerStyle.defaultSwatchBorderRadius.topLeft, 6);
      expect(CoreColorPickerStyle.defaultPopoverSpacing, 16);
      expect(
        CoreColorPickerStyle.defaultPopoverStyle.panelStyle?.borderRadius,
        const CoreBorderRadius.all(CoreRadius.radius14),
      );
      expect(CoreColorPickerStyle.defaultRecentSwatchSize, 20);
      expect(CoreColorPickerStyle.defaultRecentSwatchBorderRadius.topLeft, 6);
      expect(CoreColorPickerStyle.defaultRecentColumns, 10);
      // One row of recentColumns swatches fits the popover content width.
      const row =
          CoreColorPickerStyle.defaultRecentColumns *
              CoreColorPickerStyle.defaultRecentSwatchSize +
          (CoreColorPickerStyle.defaultRecentColumns - 1) *
              CoreColorPickerStyle.defaultRecentSwatchSpacing;
      expect(row <= CoreColorPickerStyle.defaultPopoverWidth, isTrue);
    });

    test('the field trigger follows the redesign (#6462)', () {
      expect(CoreColorPickerStyle.defaultTriggerMinWidth, 184);
      expect(
        CoreColorPickerStyle.defaultTriggerPadding,
        const CoreEdgeInsets.directional(start: 4, top: 4, end: 12, bottom: 4),
      );
      expect(CoreColorPickerStyle.defaultTriggerSpacing, 10);
      expect(CoreColorPickerStyle.defaultTriggerBorderRadius.topLeft, 10);
      expect(CoreColorPickerStyle.defaultTriggerBorderWidth, 1);
      expect(
        CoreColorPickerStyle.defaultTriggerBackgroundColor,
        const CoreColor.token(CoreColors.surface),
      );
      expect(
        CoreColorPickerStyle.defaultTriggerBorderColor,
        const CoreColor.token(CoreColors.outlineVariant),
      );
      expect(
        CoreColorPickerStyle.defaultTriggerValueTextStyle.token,
        CoreTextStyles.labelMedium,
      );
      expect(
        CoreColorPickerStyle.defaultTriggerPlaceholderTextStyle.token,
        CoreTextStyles.bodySmall,
      );
      expect(CoreColorPickerStyle.defaultTriggerChevronIconStyle.size, 16);
      expect(CoreColorPickerStyle.defaultCompareSwatchSize, 24);
      expect(CoreColorPickerStyle.defaultCompareBorderRadius.topLeft, 6);
      expect(CoreColorPickerStyle.defaultInlinePanelStyle.boxShadow, isEmpty);
      expect(
        CoreColorPickerContract.defaultPromptMode,
        CoreColorPickerPromptMode.popover,
      );
      expect(
        CoreColorPickerContract.defaultModeInputSize,
        CoreComponentSize.sm,
      );
    });

    test('the redesign fields merge, copy and compare', () {
      const a = CoreColorPickerStyle(
        triggerMinWidth: 200,
        inlinePanelStyle: CorePopupStyle(minWidth: 10),
      );
      const b = CoreColorPickerStyle(
        triggerSpacing: 6,
        inlinePanelStyle: CorePopupStyle(maxWidth: 400),
      );
      final merged = a.merge(b);
      expect(merged.triggerMinWidth, 200);
      expect(merged.triggerSpacing, 6);
      expect(merged.inlinePanelStyle?.minWidth, 10);
      expect(merged.inlinePanelStyle?.maxWidth, 400);
      expect(a.copyWith(compareSwatchSize: 30).compareSwatchSize, 30);
      expect(a, isNot(a.copyWith(recentTitleGapStyle: const CoreGapStyle())));
      expect(a.hashCode, a.copyWith().hashCode);
    });

    test('empty swatch dashes are the shared dashed-border pattern', () {
      expect(
        CoreColorPickerStyle.defaultEmptySwatchDashLength,
        CoreDashedBorder.dashLength,
      );
      expect(
        CoreColorPickerStyle.defaultEmptySwatchDashSpacing,
        CoreDashedBorder.dashGap,
      );
    });

    test('new fields merge, copy and compare', () {
      const a = CoreColorPickerStyle(
        pickMarkerSize: 20,
        modeTabsStyle: CoreToggleGroupStyle(),
      );
      const b = CoreColorPickerStyle(
        pickMarkerBorderWidth: 3,
        sliderBorderRadius: CoreBorderRadius.all(CoreRadius.radius8),
        emptySwatchDashLength: 4,
      );
      final merged = a.merge(b);
      expect(merged.pickMarkerSize, 20);
      expect(merged.pickMarkerBorderWidth, 3);
      expect(merged.sliderBorderRadius, b.sliderBorderRadius);
      expect(merged.emptySwatchDashLength, 4);
      expect(merged.modeTabsStyle, isNotNull);
      expect(merged.copyWith(pickMarkerSize: 12).pickMarkerSize, 12);
      expect(merged == a.merge(b), isTrue);
      expect(merged.hashCode, a.merge(b).hashCode);
      expect(merged == a, isFalse);
    });
    test('handle defaults: white rings of 3 on both handles, xs shadow', () {
      expect(
        CoreColorPickerStyle.defaultPickMarkerBorderColor.argb,
        0xFFFFFFFF,
      );
      expect(CoreColorPickerStyle.defaultPickMarkerBorderColor.token, isNull);
      expect(CoreColorPickerStyle.defaultPickMarkerShadow, CoreShadow.xs);
      // The hue handle wears the same white 3 ring as the saturation handle.
      expect(
        CoreColorPickerStyle.defaultHueMarkerBorderColor.argb,
        0xFFFFFFFF,
      );
      expect(CoreColorPickerStyle.defaultHueMarkerBorderWidth, 3);
    });

    test('hue / shadow handle fields merge, copy and compare', () {
      const a = CoreColorPickerStyle(hueMarkerBorderWidth: 2);
      const b = CoreColorPickerStyle(
        pickMarkerShadow: CoreShadow.none,
        hueMarkerBorderColor: CoreColor(0xFF445566),
      );
      final merged = a.merge(b);
      expect(merged.hueMarkerBorderWidth, 2);
      expect(merged.pickMarkerShadow, CoreShadow.none);
      expect(merged.hueMarkerBorderColor!.argb, 0xFF445566);
      expect(merged.copyWith(hueMarkerBorderWidth: 5).hueMarkerBorderWidth, 5);
      expect(merged == a.merge(b), isTrue);
      expect(merged.hashCode, a.merge(b).hashCode);
      expect(
        merged == merged.copyWith(pickMarkerShadow: CoreShadow.xs),
        isFalse,
      );
    });
  });
}
