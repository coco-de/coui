// Tests for CoreJoinStyle.
// ignore_for_file: avoid_redundant_argument_values

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

void main() {
  group('CoreJoinStyle', () {
    test('null other returns this on merge', () {
      const a = CoreJoinStyle(borderRadius: CoreBorderRadius.all(4));
      expect(identical(a.merge(null), a), isTrue);
    });

    test('chain — design system → theme.style → widget', () {
      const designSystem = CoreJoinStyle(borderRadius: CoreBorderRadius.all(4));
      const themeStyle = CoreJoinStyle(borderRadius: CoreBorderRadius.all(8));
      const widgetStyle = CoreJoinStyle(borderRadius: CoreBorderRadius.all(12));

      final effective = designSystem.merge(themeStyle).merge(widgetStyle);

      expect(effective.borderRadius, const CoreBorderRadius.all(12));
    });

    test('right-most non-null wins; null preserves base', () {
      const a = CoreJoinStyle(borderRadius: CoreBorderRadius.all(4));
      const b = CoreJoinStyle();
      final merged = a.merge(b);
      expect(merged.borderRadius, const CoreBorderRadius.all(4));
    });

    test('equality + copyWith', () {
      const a = CoreJoinStyle(borderRadius: CoreBorderRadius.all(4));
      const b = CoreJoinStyle(borderRadius: CoreBorderRadius.all(4));
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);

      final copy = a.copyWith(borderRadius: const CoreBorderRadius.all(16));
      expect(copy.borderRadius, const CoreBorderRadius.all(16));
    });
  });

  group('CoreJoinTheme passes through style', () {
    test('CoreJoinTheme', () {
      const style = CoreJoinStyle(borderRadius: CoreBorderRadius.all(12));
      const theme = CoreJoinTheme(style: style);
      expect(theme.style, style);
    });
  });
}
