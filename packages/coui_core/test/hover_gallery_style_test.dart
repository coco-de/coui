// Tests for CoreHoverGalleryStyle.
// ignore_for_file: avoid_redundant_argument_values

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

const _kDurationFast = Duration(milliseconds: 150);
const _kDurationSlow = Duration(milliseconds: 400);

void main() {
  group('CoreHoverGalleryStyle', () {
    test('chain — design system → theme.style → widget', () {
      const designSystem = CoreHoverGalleryStyle(
        height: 300,
        borderRadius: CoreBorderRadius.all(16),
        animationDuration: _kDurationFast,
      );
      const themeStyle = CoreHoverGalleryStyle(height: 200);
      const widgetStyle = CoreHoverGalleryStyle(
        animationDuration: _kDurationSlow,
      );

      final effective = designSystem.merge(themeStyle).merge(widgetStyle);

      expect(effective.height, 200);
      expect(effective.borderRadius, const CoreBorderRadius.all(16));
      expect(effective.animationDuration, _kDurationSlow);
    });

    test('equality + copyWith', () {
      const a = CoreHoverGalleryStyle(
        height: 300,
        borderRadius: CoreBorderRadius.all(16),
      );
      const b = CoreHoverGalleryStyle(
        height: 300,
        borderRadius: CoreBorderRadius.all(16),
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);

      final copy = a.copyWith(animationDuration: _kDurationFast);
      expect(copy.animationDuration, _kDurationFast);
      expect(copy.height, 300);
      expect(copy.borderRadius, const CoreBorderRadius.all(16));
    });
  });

  group('CoreHoverGalleryTheme passes through style', () {
    test('CoreHoverGalleryTheme', () {
      const style = CoreHoverGalleryStyle(height: 400);
      const theme = CoreHoverGalleryTheme(style: style);
      expect(theme.style, style);
    });
  });
}
