// Tests for CoreSubfocusStyle.
// ignore_for_file: avoid_redundant_argument_values

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

const _kRadius8 = CoreBorderRadius.all(8);
const _kRadius2 = CoreBorderRadius.all(2);

void main() {
  group('CoreSubfocusStyle', () {
    test('chain — design system → theme.style → widget', () {
      const designSystem = CoreSubfocusStyle(focusRingRadius: _kRadius8);
      const widgetStyle = CoreSubfocusStyle(focusRingRadius: _kRadius2);

      final effective = designSystem.merge(widgetStyle);

      expect(effective.focusRingRadius, _kRadius2);
    });

    test('merge with null returns this', () {
      const a = CoreSubfocusStyle(focusRingRadius: _kRadius8);
      expect(a.merge(null), same(a));
    });

    test('equality + copyWith', () {
      const a = CoreSubfocusStyle(focusRingRadius: _kRadius8);
      const b = CoreSubfocusStyle(focusRingRadius: _kRadius8);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);

      final copy = a.copyWith(focusRingRadius: _kRadius2);
      expect(copy.focusRingRadius, _kRadius2);
    });

    test('design-system defaults', () {
      expect(
        CoreSubfocusStyle.defaultFocusRingRadius,
        const CoreBorderRadius.all(CoreRadius.radius4),
      );
      expect(
        CoreSubfocusStyle.defaultFocusRingWidth,
        CoreFocusOutlineStyle.defaultBorderWidth,
      );
    });
  });

  group('CoreSubfocusScopeTheme', () {
    test('passes through style', () {
      const style = CoreSubfocusStyle(focusRingRadius: _kRadius8);
      const theme = CoreSubfocusScopeTheme(style: style);
      expect(theme.style, style);
    });

    test('equality', () {
      const a = CoreSubfocusScopeTheme(
        style: CoreSubfocusStyle(focusRingRadius: _kRadius8),
      );
      const b = CoreSubfocusScopeTheme(
        style: CoreSubfocusStyle(focusRingRadius: _kRadius8),
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });
  });

  group('CoreSubfocusOrientation', () {
    test('default', () {
      expect(
        CoreSubfocusOrientation.defaultOrientation,
        CoreSubfocusOrientation.vertical,
      );
    });
  });
}
