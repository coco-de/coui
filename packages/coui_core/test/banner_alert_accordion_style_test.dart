// Tests for CoreBannerStyle / CoreAlertStyle / CoreAccordionStyle
// (Epic #1302 — Story #1319).
// ignore_for_file: avoid_redundant_argument_values

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

const double _kFontLabel = 14;
const double _kFontTitle = 18;
const int _kWeightSemiBold = CoreFontWeight.semiBold;
const int _kWeightRegular = CoreFontWeight.regular;
const _kColorOnSurface = CoreColor.token(CoreColors.onSurface);
const _kColorPrimary = CoreColor.token(CoreColors.primary);
const _kColorSurface = CoreColor.token(CoreColors.surface);

void main() {
  group('CoreBannerStyle', () {
    test('null other returns this on merge', () {
      const a = CoreBannerStyle(backgroundColor: _kColorPrimary);
      expect(identical(a.merge(null), a), isTrue);
    });

    test('chain — design system → theme.style → widget', () {
      const designSystem = CoreBannerStyle(
        backgroundColor: _kColorSurface,
        padding: CoreEdgeInsets.symmetric(horizontal: 8),
        titleStyle: CoreTextStyle(
          fontSize: _kFontLabel,
          fontWeight: _kWeightRegular,
          color: _kColorOnSurface,
        ),
      );
      const themeStyle = CoreBannerStyle(
        titleStyle: CoreTextStyle(fontWeight: _kWeightSemiBold),
      );
      const widgetStyle = CoreBannerStyle(
        padding: CoreEdgeInsets.symmetric(horizontal: 12),
      );
      final effective = designSystem.merge(themeStyle).merge(widgetStyle);
      expect(effective.backgroundColor, _kColorSurface);
      expect(effective.titleStyle?.fontSize, _kFontLabel);
      expect(effective.titleStyle?.fontWeight, _kWeightSemiBold);
      expect(
        effective.padding,
        const CoreEdgeInsets.symmetric(horizontal: 12),
      );
    });

    test('actionButtonStyle / closeButtonStyle merge separately', () {
      const a = CoreBannerStyle(
        actionButtonStyle: CoreButtonStyle(
          padding: CoreEdgeInsets.symmetric(horizontal: 8),
        ),
        closeButtonStyle: CoreButtonStyle(
          padding: CoreEdgeInsets.symmetric(horizontal: 4),
        ),
      );
      const b = CoreBannerStyle(
        actionButtonStyle: CoreButtonStyle(
          padding: CoreEdgeInsets.symmetric(horizontal: 12),
        ),
      );
      final merged = a.merge(b);
      expect(
        merged.actionButtonStyle?.padding,
        const CoreEdgeInsets.symmetric(horizontal: 12),
      );
      expect(
        merged.closeButtonStyle?.padding,
        const CoreEdgeInsets.symmetric(horizontal: 4),
      );
    });

    test('iconStyle / descriptionStyle merge recursively', () {
      const base = CoreBannerStyle(
        descriptionStyle: CoreTextStyle(fontSize: _kFontLabel),
        iconStyle: CoreIconStyle(size: 16),
      );
      const override = CoreBannerStyle(
        descriptionStyle: CoreTextStyle(fontSize: _kFontTitle),
      );
      final merged = base.merge(override);
      expect(merged.iconStyle?.size, 16);
      expect(merged.descriptionStyle?.fontSize, _kFontTitle);
    });

    test('equality + copyWith preserves nested', () {
      const a = CoreBannerStyle(
        titleStyle: CoreTextStyle(fontSize: _kFontLabel),
        actionButtonStyle: CoreButtonStyle(
          padding: CoreEdgeInsets.symmetric(horizontal: 8),
        ),
      );
      const b = CoreBannerStyle(
        titleStyle: CoreTextStyle(fontSize: _kFontLabel),
        actionButtonStyle: CoreButtonStyle(
          padding: CoreEdgeInsets.symmetric(horizontal: 8),
        ),
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      final copy = a.copyWith(
        padding: const CoreEdgeInsets.symmetric(horizontal: 12),
      );
      expect(
        copy.padding,
        const CoreEdgeInsets.symmetric(horizontal: 12),
      );
      expect(copy.titleStyle?.fontSize, _kFontLabel);
      expect(
        copy.actionButtonStyle?.padding,
        const CoreEdgeInsets.symmetric(horizontal: 8),
      );
    });
  });

  group('CoreAlertStyle', () {
    const kColorOutline = CoreColor.token(CoreColors.outline);
    test('chain — design system → theme.style → widget', () {
      const designSystem = CoreAlertStyle(
        backgroundColor: _kColorSurface,
        titleStyle: CoreTextStyle(
          fontSize: _kFontLabel,
          color: _kColorOnSurface,
        ),
      );
      const themeStyle = CoreAlertStyle(
        titleStyle: CoreTextStyle(fontWeight: _kWeightSemiBold),
      );
      const widgetStyle = CoreAlertStyle(
        actionButtonStyle: CoreButtonStyle(
          padding: CoreEdgeInsets.symmetric(horizontal: 16),
        ),
      );
      final effective = designSystem.merge(themeStyle).merge(widgetStyle);
      expect(effective.backgroundColor, _kColorSurface);
      expect(effective.titleStyle?.fontSize, _kFontLabel);
      expect(effective.titleStyle?.fontWeight, _kWeightSemiBold);
      expect(
        effective.actionButtonStyle?.padding,
        const CoreEdgeInsets.symmetric(horizontal: 16),
      );
    });

    test('null nested style on base inherits from override', () {
      const base = CoreAlertStyle();
      const override = CoreAlertStyle(
        closeButtonStyle: CoreButtonStyle(
          padding: CoreEdgeInsets.symmetric(horizontal: 4),
        ),
      );
      final merged = base.merge(override);
      expect(
        merged.closeButtonStyle?.padding,
        const CoreEdgeInsets.symmetric(horizontal: 4),
      );
    });

    test('equality', () {
      const a = CoreAlertStyle(
        backgroundColor: _kColorSurface,
        borderColor: kColorOutline,
      );
      const b = CoreAlertStyle(
        backgroundColor: _kColorSurface,
        borderColor: kColorOutline,
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });
  });

  group('CoreAccordionStyle', () {
    const kColorOutline = CoreColor.token(CoreColors.outline);
    test('chain — design system → theme.style → widget', () {
      const designSystem = CoreAccordionStyle(
        backgroundColor: _kColorSurface,
        triggerStyle: CoreButtonStyle(
          padding: CoreEdgeInsets.symmetric(horizontal: 12),
        ),
        contentTextStyle: CoreTextStyle(fontSize: _kFontLabel),
        chevronIconStyle: CoreIconStyle(size: 16),
      );
      const themeStyle = CoreAccordionStyle(
        triggerStyle: CoreButtonStyle(
          padding: CoreEdgeInsets.symmetric(horizontal: 16),
        ),
      );
      const widgetStyle = CoreAccordionStyle(
        contentTextStyle: CoreTextStyle(fontSize: _kFontTitle),
      );
      final effective = designSystem.merge(themeStyle).merge(widgetStyle);
      expect(effective.backgroundColor, _kColorSurface);
      expect(
        effective.triggerStyle?.padding,
        const CoreEdgeInsets.symmetric(horizontal: 16),
      );
      expect(effective.contentTextStyle?.fontSize, _kFontTitle);
      expect(effective.chevronIconStyle?.size, 16);
    });

    test('flat divider/itemSpacing fields override', () {
      const a = CoreAccordionStyle(
        itemSpacing: 4,
        dividerColor: kColorOutline,
        dividerThickness: 1,
      );
      const b = CoreAccordionStyle(dividerThickness: 2);
      final merged = a.merge(b);
      expect(merged.dividerColor, kColorOutline);
      expect(merged.dividerThickness, 2);
      expect(merged.itemSpacing, 4);
    });

    test('copyWith preserves nested triggerStyle when not specified', () {
      const base = CoreAccordionStyle(
        triggerStyle: CoreButtonStyle(
          padding: CoreEdgeInsets.symmetric(horizontal: 12),
        ),
      );
      final copy = base.copyWith(itemSpacing: 8);
      expect(copy.itemSpacing, 8);
      expect(
        copy.triggerStyle?.padding,
        const CoreEdgeInsets.symmetric(horizontal: 12),
      );
    });

    test('equality + different chevronIconStyle → not equal', () {
      const a = CoreAccordionStyle(
        chevronIconStyle: CoreIconStyle(size: 16),
      );
      const b = CoreAccordionStyle(
        chevronIconStyle: CoreIconStyle(size: 20),
      );
      expect(a, isNot(equals(b)));
    });
  });

  group('Themes pass through style', () {
    test('CoreBannerTheme', () {
      const style = CoreBannerStyle(backgroundColor: _kColorPrimary);
      const theme = CoreBannerTheme(style: style);
      expect(theme.style, style);
    });

    test('CoreAlertTheme', () {
      const style = CoreAlertStyle(backgroundColor: _kColorSurface);
      const theme = CoreAlertTheme(style: style);
      expect(theme.style, style);
    });

    test('CoreAccordionTheme', () {
      const style = CoreAccordionStyle(itemSpacing: 4);
      const theme = CoreAccordionTheme(style: style);
      expect(theme.style, style);
    });
  });
}
