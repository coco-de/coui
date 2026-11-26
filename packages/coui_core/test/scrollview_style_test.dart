// Tests for CoreScrollViewInterceptorStyle.
// ignore_for_file: avoid_redundant_argument_values

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

void main() {
  group('CoreScrollViewInterceptorStyle', () {
    test('chain — design system → theme.style → widget', () {
      const designSystem = CoreScrollViewInterceptorStyle(
        dragSpeed: 0.02,
        maxScrollSpeed: 10,
      );
      const themeStyle = CoreScrollViewInterceptorStyle(dragSpeed: 0.05);
      const widgetStyle = CoreScrollViewInterceptorStyle(maxScrollSpeed: 20);

      final effective = designSystem.merge(themeStyle).merge(widgetStyle);

      expect(effective.dragSpeed, 0.05);
      expect(effective.maxScrollSpeed, 20);
    });

    test('merge with null returns this', () {
      const a = CoreScrollViewInterceptorStyle(dragSpeed: 0.02);
      expect(a.merge(null), same(a));
    });

    test('equality + copyWith', () {
      const a = CoreScrollViewInterceptorStyle(
        dragSpeed: 0.02,
        maxScrollSpeed: 10,
      );
      const b = CoreScrollViewInterceptorStyle(
        dragSpeed: 0.02,
        maxScrollSpeed: 10,
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);

      final copy = a.copyWith(maxScrollSpeed: 20);
      expect(copy.maxScrollSpeed, 20);
      expect(copy.dragSpeed, 0.02);
    });

    test('design-system defaults', () {
      expect(CoreScrollViewInterceptorStyle.defaultDragSpeed, 0.02);
      expect(CoreScrollViewInterceptorStyle.defaultMaxScrollSpeed, 10);
      expect(CoreScrollViewInterceptorStyle.cubicPower, 3);
    });
  });

  group('CoreScrollViewInterceptorTheme', () {
    test('passes through style', () {
      const style = CoreScrollViewInterceptorStyle(dragSpeed: 0.05);
      const theme = CoreScrollViewInterceptorTheme(style: style);
      expect(theme.style, style);
    });

    test('equality', () {
      const a = CoreScrollViewInterceptorTheme(
        style: CoreScrollViewInterceptorStyle(dragSpeed: 0.05),
      );
      const b = CoreScrollViewInterceptorTheme(
        style: CoreScrollViewInterceptorStyle(dragSpeed: 0.05),
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });
  });
}
