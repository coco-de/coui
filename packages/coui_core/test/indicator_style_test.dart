// Tests for CoreIndicatorStyle.
// ignore_for_file: avoid_redundant_argument_values

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

void main() {
  group('CoreIndicatorStyle', () {
    test('default — null offset', () {
      const style = CoreIndicatorStyle();
      expect(style.offset, isNull);
    });

    test('chain — design system → theme.style → widget', () {
      const designSystem = CoreIndicatorStyle(offset: 0);
      const themeStyle = CoreIndicatorStyle(offset: 4);
      const widgetStyle = CoreIndicatorStyle(offset: 8);

      final effective = designSystem.merge(themeStyle).merge(widgetStyle);

      expect(effective.offset, 8);
    });

    test('merge — null fields preserved from receiver', () {
      const base = CoreIndicatorStyle(offset: 4);
      final merged = base.merge(const CoreIndicatorStyle());

      expect(merged.offset, 4);
    });

    test('equality + copyWith', () {
      const a = CoreIndicatorStyle(offset: 4);
      const b = CoreIndicatorStyle(offset: 4);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);

      final copy = a.copyWith(offset: 12);
      expect(copy.offset, 12);
    });

    test('defaultOffset constant', () {
      expect(CoreIndicatorStyle.defaultOffset, 0);
    });
  });

  group('CoreIndicatorTheme passes through style', () {
    test('style slot carries CoreIndicatorStyle with offset', () {
      const theme = CoreIndicatorTheme(
        style: CoreIndicatorStyle(offset: 6),
      );
      expect(theme.style?.offset, 6);
    });

    test('new style prop carries CoreIndicatorStyle', () {
      const style = CoreIndicatorStyle(offset: 6);
      const theme = CoreIndicatorTheme(style: style);
      expect(theme.style, style);
    });

    test('equality', () {
      const a = CoreIndicatorTheme(style: CoreIndicatorStyle(offset: 4));
      const b = CoreIndicatorTheme(style: CoreIndicatorStyle(offset: 4));
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });
  });

  group('CoreIndicatorStyle ring', () {
    test('defaults — 2 px, the page surface', () {
      expect(CoreIndicatorStyle.defaultRingWidth, CoreStrokeWidth.stroke2);
      expect(
        CoreIndicatorStyle.defaultRingColor,
        const CoreColor.token(CoreColors.surface),
      );
    });

    test('merge — ring fields chain like offset', () {
      const base = CoreIndicatorStyle(ringWidth: 2);
      const patch = CoreIndicatorStyle(ringWidth: 3);
      expect(base.merge(patch).ringWidth, 3);
      expect(base.merge(const CoreIndicatorStyle()).ringWidth, 2);
      expect(
        base.copyWith(ringColor: const CoreColor.token(CoreColors.primary)),
        isNot(base),
      );
    });
  });
}
