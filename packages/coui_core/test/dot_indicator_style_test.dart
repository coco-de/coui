// Tests for CoreDotIndicatorStyle.
// ignore_for_file: avoid_redundant_argument_values

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

const _kColorPrimary = CoreColor.token(CoreColors.primary);
const _kColorOutline = CoreColor.token(CoreColors.outline);
const _kColorSurface = CoreColor.token(CoreColors.surface);

void main() {
  group('CoreDotIndicatorStyle', () {
    test('active length participates in style composition and equality', () {
      const theme = CoreDotIndicatorStyle(activeLength: 14);
      const override = CoreDotIndicatorStyle(activeLength: 18);
      final merged = theme.merge(override);
      expect(merged.activeLength, 18);
      expect(merged, const CoreDotIndicatorStyle(activeLength: 18));
      expect(
        merged.hashCode,
        const CoreDotIndicatorStyle(activeLength: 18).hashCode,
      );
      expect(merged.copyWith(activeLength: 20).activeLength, 20);
      expect(merged, isNot(theme));
    });
    test('chain — design system → theme.style → widget', () {
      const designSystem = CoreDotIndicatorStyle(
        spacing: 8,
        padding: CoreEdgeInsets.all(8),
        dotSize: 12,
        borderRadius: CoreBorderRadius.all(9999),
        activeColor: _kColorPrimary,
        inactiveColor: _kColorSurface,
        inactiveBorderColor: _kColorOutline,
        inactiveBorderWidth: 2,
      );
      const themeStyle = CoreDotIndicatorStyle(spacing: 12);
      const widgetStyle = CoreDotIndicatorStyle(dotSize: 16);

      final effective = designSystem.merge(themeStyle).merge(widgetStyle);

      expect(effective.spacing, 12);
      expect(effective.padding, const CoreEdgeInsets.all(8));
      expect(effective.dotSize, 16);
      expect(effective.activeColor, _kColorPrimary);
      expect(effective.inactiveColor, _kColorSurface);
      expect(effective.inactiveBorderColor, _kColorOutline);
      expect(effective.inactiveBorderWidth, 2);
    });

    test('equality + copyWith', () {
      const a = CoreDotIndicatorStyle(
        dotSize: 12,
        activeColor: _kColorPrimary,
      );
      const b = CoreDotIndicatorStyle(
        dotSize: 12,
        activeColor: _kColorPrimary,
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);

      final copy = a.copyWith(spacing: 16);
      expect(copy.spacing, 16);
      expect(copy.dotSize, 12);
      expect(copy.activeColor, _kColorPrimary);
    });
  });

  group('design-system defaults — the designer\'s decisions', () {
    test('both states are filled discs — no ring', () {
      // A ring reads as more present than a fill at 6–12px, on the very
      // thing meant to recede. With both states filled the difference is
      // tone alone.
      expect(CoreDotIndicatorStyle.defaultInactiveBorderWidth, 0);
      expect(
        CoreDotIndicatorStyle.defaultInactiveColor,
        const CoreColor.token(CoreColors.outlineVariant),
      );
    });

    test('the active dot does not spend the accent', () {
      // A dot indicator says where you are, not what to press.
      expect(
        CoreDotIndicatorStyle.defaultActiveColor,
        const CoreColor.token(CoreColors.onSurface),
      );
    });
  });

  group('CoreDotIndicatorTheme passes through style', () {
    test('CoreDotIndicatorTheme', () {
      const style = CoreDotIndicatorStyle(dotSize: 16);
      const theme = CoreDotIndicatorTheme(style: style);
      expect(theme.style, style);
    });
  });
}
