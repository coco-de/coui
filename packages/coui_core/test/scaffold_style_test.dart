// Tests for CoreScaffoldStyle.
// ignore_for_file: avoid_redundant_argument_values

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

const _kColorPrimary = CoreColor.token(CoreColors.primary);
const _kPadding = CoreEdgeInsets.all(8);

void main() {
  group('CoreScaffoldStyle', () {
    test('chain — design system → theme.style → widget', () {
      const designSystem = CoreScaffoldStyle(
        backgroundColor: _kColorPrimary,
        fabPadding: _kPadding,
        headerBorderWidth: 7,
      );
      const themeStyle = CoreScaffoldStyle(headerBorderWidth: 9);
      const widgetStyle = CoreScaffoldStyle(
        fabPadding: CoreEdgeInsets.all(2),
      );

      final effective = designSystem.merge(themeStyle).merge(widgetStyle);

      expect(effective.backgroundColor, _kColorPrimary);
      expect(effective.headerBorderWidth, 9);
      expect(effective.fabPadding, const CoreEdgeInsets.all(2));
    });

    test('merge with null returns this', () {
      const a = CoreScaffoldStyle(headerBorderWidth: 7);
      expect(a.merge(null), same(a));
    });

    test('equality + copyWith', () {
      const a = CoreScaffoldStyle(
        backgroundColor: _kColorPrimary,
        headerBorderWidth: 7,
      );
      const b = CoreScaffoldStyle(
        backgroundColor: _kColorPrimary,
        headerBorderWidth: 7,
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);

      final copy = a.copyWith(headerBorderWidth: 9);
      expect(copy.headerBorderWidth, 9);
      expect(copy.backgroundColor, _kColorPrimary);
    });

    test('design-system defaults', () {
      expect(
        CoreScaffoldStyle.defaultFabPadding,
        const CoreEdgeInsets.all(CoreSpace.space16),
      );
      expect(
        CoreScaffoldStyle.defaultHeaderBorderWidth,
        CoreStrokeWidth.stroke1,
      );
      expect(
        CoreScaffoldStyle.defaultHeaderBorderColor,
        const CoreColor.token(
          CoreColors.outlineVariant,
          fallbacks: [CoreColors.outline],
        ),
      );
    });

    test('defaultsByVariant exposes standard chrome', () {
      final chrome =
          CoreScaffoldStyle.defaultsByVariant[CoreScaffoldVariant.standard]!;
      expect(
        chrome.backgroundColor,
        const CoreColor.token(CoreColors.surface),
      );
      expect(
        chrome.headerBackgroundColor,
        const CoreColor.token(CoreColors.surface),
      );
      expect(
        chrome.footerBackgroundColor,
        const CoreColor.token(CoreColors.surface),
      );
    });
  });

  group('CoreScaffoldTheme', () {
    test('passes through style', () {
      const style = CoreScaffoldStyle(headerBorderWidth: 9);
      const theme = CoreScaffoldTheme(style: style);
      expect(theme.style, style);
    });

    test('equality', () {
      const a = CoreScaffoldTheme(
        style: CoreScaffoldStyle(headerBorderWidth: 9),
      );
      const b = CoreScaffoldTheme(
        style: CoreScaffoldStyle(headerBorderWidth: 9),
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });
  });

  group('CoreScaffoldVariant / CoreScaffoldFabLocation', () {
    test('defaults', () {
      expect(
        CoreScaffoldVariant.defaultVariant,
        CoreScaffoldVariant.standard,
      );
      expect(
        CoreScaffoldFabLocation.defaultLocation,
        CoreScaffoldFabLocation.endFloat,
      );
    });
  });
}
