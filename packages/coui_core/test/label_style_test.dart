// Tests for CoreLabelStyle.
// ignore_for_file: avoid_redundant_argument_values

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

const _kColorOnSurface = CoreColor.token(CoreColors.onSurface);
const _kColorError = CoreColor.token(CoreColors.error);
const _kFontLabel = 14.0;
const _kFontTitle = 18.0;
const int _kWeightSemiBold = CoreFontWeight.semiBold;

void main() {
  group('CoreLabelStyle', () {
    test('chain — design system → theme.style → widget', () {
      const designSystem = CoreLabelStyle(
        iconStyle: CoreIconStyle(size: 16),
        iconLabelGapStyle: CoreGapStyle(size: 6),
        labelRequiredGapStyle: CoreGapStyle(size: 4),
        disabledOpacity: 0.7,
        requiredColor: _kColorError,
        textStyle: CoreTextStyle(
          fontSize: _kFontLabel,
          color: _kColorOnSurface,
        ),
      );
      const themeStyle = CoreLabelStyle(iconStyle: CoreIconStyle(size: 20));
      const widgetStyle = CoreLabelStyle(
        textStyle: CoreTextStyle(fontWeight: _kWeightSemiBold),
      );

      final effective = designSystem.merge(themeStyle).merge(widgetStyle);

      expect(effective.iconStyle?.size, 20);
      expect(effective.iconLabelGapStyle?.size, 6);
      expect(effective.labelRequiredGapStyle?.size, 4);
      expect(effective.disabledOpacity, 0.7);
      expect(effective.requiredColor, _kColorError);
      expect(effective.textStyle?.fontSize, _kFontLabel);
      expect(effective.textStyle?.color, _kColorOnSurface);
      expect(effective.textStyle?.fontWeight, _kWeightSemiBold);
    });

    test('textStyle merges recursively', () {
      const base = CoreLabelStyle(
        textStyle: CoreTextStyle(fontSize: _kFontLabel),
      );
      const override = CoreLabelStyle(
        textStyle: CoreTextStyle(fontSize: _kFontTitle),
      );
      final merged = base.merge(override);
      expect(merged.textStyle?.fontSize, _kFontTitle);
    });

    test('equality + copyWith', () {
      const a = CoreLabelStyle(
        iconStyle: CoreIconStyle(size: 16),
        requiredColor: _kColorError,
      );
      const b = CoreLabelStyle(
        iconStyle: CoreIconStyle(size: 16),
        requiredColor: _kColorError,
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);

      final copy = a.copyWith(iconLabelGapStyle: const CoreGapStyle(size: 8));
      expect(copy.iconLabelGapStyle?.size, 8);
      expect(copy.iconStyle?.size, 16);
      expect(copy.requiredColor, _kColorError);
    });
  });

  group('CoreLabelTheme passes through style', () {
    test('CoreLabelTheme', () {
      const style = CoreLabelStyle(iconStyle: CoreIconStyle(size: 20));
      const theme = CoreLabelTheme(style: style);
      expect(theme.style, style);
    });
  });
}
