// Tests for CoreSelectableTextStyle.
// ignore_for_file: avoid_redundant_argument_values

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

const _kColorPrimary = CoreColor.token(CoreColors.primary);
const _kColorPrimaryContainer = CoreColor.token(CoreColors.primaryContainer);
const _kColorOnSurface = CoreColor.token(CoreColors.onSurface);
const _kFontBody = 14.0;
const _kFontTitle = 18.0;
const int _kWeightSemiBold = CoreFontWeight.semiBold;

void main() {
  group('CoreSelectableTextStyle', () {
    test('chain — design system → theme.style → widget', () {
      const designSystem = CoreSelectableTextStyle(
        textStyle: CoreTextStyle(
          fontSize: _kFontBody,
          color: _kColorOnSurface,
        ),
        cursorWidth: 2,
      );
      const themeStyle = CoreSelectableTextStyle(
        textStyle: CoreTextStyle(fontWeight: _kWeightSemiBold),
      );
      const widgetStyle = CoreSelectableTextStyle(cursorWidth: 4);

      final effective = designSystem.merge(themeStyle).merge(widgetStyle);

      expect(effective.textStyle?.fontSize, _kFontBody);
      expect(effective.textStyle?.fontWeight, _kWeightSemiBold);
      expect(effective.textStyle?.color, _kColorOnSurface);
      expect(effective.cursorWidth, 4);
    });

    test('text style merges recursively', () {
      const base = CoreSelectableTextStyle(
        textStyle: CoreTextStyle(fontSize: _kFontBody),
      );
      const override = CoreSelectableTextStyle(
        textStyle: CoreTextStyle(fontSize: _kFontTitle),
      );

      final merged = base.merge(override);

      expect(merged.textStyle?.fontSize, _kFontTitle);
    });

    test('merge with null returns this', () {
      const style = CoreSelectableTextStyle(cursorWidth: 2);

      expect(style.merge(null), style);
    });

    test('copyWith overrides only the supplied fields', () {
      const style = CoreSelectableTextStyle(
        cursorColor: _kColorOnSurface,
        cursorWidth: 2,
      );

      final copy = style.copyWith(cursorColor: _kColorPrimary);

      expect(copy.cursorWidth, 2);
      expect(copy.cursorColor, _kColorPrimary);
    });

    test('equality and hashCode', () {
      const a = CoreSelectableTextStyle(
        textStyle: CoreTextStyle(fontSize: _kFontBody),
        cursorWidth: 2,
      );
      const b = CoreSelectableTextStyle(
        textStyle: CoreTextStyle(fontSize: _kFontBody),
        cursorWidth: 2,
      );
      const c = CoreSelectableTextStyle(cursorWidth: 4);

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });
  });

  group('CoreSelectableTextTheme', () {
    test('equality and hashCode', () {
      const a = CoreSelectableTextTheme(
        style: CoreSelectableTextStyle(cursorWidth: 2),
      );
      const b = CoreSelectableTextTheme(
        style: CoreSelectableTextStyle(cursorWidth: 2),
      );
      const c = CoreSelectableTextTheme();

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });
  });

  group('CoreSelectableTextStyle defaults', () {
    test('defaultCursorWidth matches focus-ring width', () {
      expect(
        CoreSelectableTextStyle.defaultCursorWidth,
        CoreFocusRing.ringWidth,
      );
    });

    test('defaultSelectionColor is the primaryContainer token', () {
      expect(
        CoreSelectableTextStyle.defaultSelectionColor,
        _kColorPrimaryContainer,
      );
      expect(
        CoreSelectableTextStyle.defaultSelectionColor,
        isNot(_kColorPrimary),
      );
    });
  });
}
