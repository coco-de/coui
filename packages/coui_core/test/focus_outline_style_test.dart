// Tests for CoreFocusOutlineStyle.
// ignore_for_file: avoid_redundant_argument_values

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

const _kColorPrimary = CoreColor.token(CoreColors.primary);
const _kDurationFast = Duration(milliseconds: 150);
const _kDurationSlow = Duration(milliseconds: 400);

void main() {
  group('CoreFocusOutlineStyle', () {
    test('chain — design system → theme.style → widget', () {
      const designSystem = CoreFocusOutlineStyle(
        align: 4,
        borderRadius: CoreBorderRadius.all(8),
        borderColor: _kColorPrimary,
        borderWidth: 2,
        duration: _kDurationFast,
      );
      const themeStyle = CoreFocusOutlineStyle(align: 6);
      const widgetStyle = CoreFocusOutlineStyle(borderWidth: 3);

      final effective = designSystem.merge(themeStyle).merge(widgetStyle);

      expect(effective.align, 6);
      expect(effective.borderRadius, const CoreBorderRadius.all(8));
      expect(effective.borderColor, _kColorPrimary);
      expect(effective.borderWidth, 3);
      expect(effective.duration, _kDurationFast);
    });

    test('duration override on widget wins', () {
      const a = CoreFocusOutlineStyle(duration: _kDurationFast);
      const b = CoreFocusOutlineStyle(duration: _kDurationSlow);
      final merged = a.merge(b);
      expect(merged.duration, _kDurationSlow);
    });

    test('equality + copyWith', () {
      const a = CoreFocusOutlineStyle(
        align: 4,
        borderColor: _kColorPrimary,
      );
      const b = CoreFocusOutlineStyle(
        align: 4,
        borderColor: _kColorPrimary,
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);

      final copy = a.copyWith(borderWidth: 3);
      expect(copy.borderWidth, 3);
      expect(copy.align, 4);
      expect(copy.borderColor, _kColorPrimary);
    });
  });

  group('CoreFocusOutlineTheme passes through style', () {
    test('CoreFocusOutlineTheme', () {
      const style = CoreFocusOutlineStyle(borderWidth: 3);
      const theme = CoreFocusOutlineTheme(style: style);
      expect(theme.style, style);
    });
  });
}
