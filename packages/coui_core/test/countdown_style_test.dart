// Tests for CoreCountdownStyle.

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

const _kColorPrimary = CoreColor.token(CoreColors.primary);
const _kColorOnSurface = CoreColor.token(CoreColors.onSurface);
const _kFontLabel = 14.0;
const _kFontTitle = 18.0;
const int _kWeightSemiBold = CoreFontWeight.semiBold;
const _kDurationFast = Duration(milliseconds: 150);

void main() {
  group('CoreCountdownStyle', () {
    test('null other returns this on merge', () {
      const a = CoreCountdownStyle(fontSize: _kFontLabel);
      expect(identical(a.merge(null), a), isTrue);
    });

    test('chain — design system → theme.style → widget', () {
      const designSystem = CoreCountdownStyle(
        fontSize: _kFontLabel,
        color: _kColorOnSurface,
        animationDuration: _kDurationFast,
        labelStyle: CoreTextStyle(
          fontSize: _kFontLabel,
          color: _kColorOnSurface,
        ),
      );
      const themeStyle = CoreCountdownStyle(
        labelStyle: CoreTextStyle(fontWeight: _kWeightSemiBold),
      );
      const widgetStyle = CoreCountdownStyle(fontSize: _kFontTitle);

      final effective = designSystem.merge(themeStyle).merge(widgetStyle);

      expect(effective.fontSize, _kFontTitle);
      expect(effective.color, _kColorOnSurface);
      expect(effective.animationDuration, _kDurationFast);
      expect(effective.labelStyle?.fontSize, _kFontLabel);
      expect(effective.labelStyle?.fontWeight, _kWeightSemiBold);
      expect(effective.labelStyle?.color, _kColorOnSurface);
    });

    test('labelStyle merges recursively', () {
      const base = CoreCountdownStyle(
        labelStyle: CoreTextStyle(fontSize: _kFontLabel),
      );
      const override = CoreCountdownStyle(
        labelStyle: CoreTextStyle(fontSize: _kFontTitle),
      );
      final merged = base.merge(override);
      expect(merged.labelStyle?.fontSize, _kFontTitle);
    });

    test('equality + copyWith preserves nested', () {
      const a = CoreCountdownStyle(
        fontSize: _kFontLabel,
        labelStyle: CoreTextStyle(fontSize: _kFontLabel),
      );
      const b = CoreCountdownStyle(
        fontSize: _kFontLabel,
        labelStyle: CoreTextStyle(fontSize: _kFontLabel),
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);

      final copy = a.copyWith(color: _kColorPrimary);
      expect(copy.color, _kColorPrimary);
      expect(copy.fontSize, _kFontLabel);
      expect(copy.labelStyle?.fontSize, _kFontLabel);
    });
  });

  group('CoreCountdownStyle default digit', () {
    // The digit is the `headlineLarge` role in the primary ink and nothing
    // more: the widget draws one number, so a unit box, a unit word or a
    // width floor around it belongs to the caller, not to this style.
    test('is the headlineLarge role — 32 / Bold', () {
      const style = CoreCountdownStyle.defaultLabelStyle;
      expect(style.token, CoreTextStyles.headlineLarge);
      final resolved = CoreTypography.coui.resolve(style);
      expect(resolved.fontSize, 32);
      expect(resolved.fontWeight, CoreFontWeight.bold);
    });

    test('states a role and an ink — no size or weight overlay', () {
      const style = CoreCountdownStyle.defaultLabelStyle;
      expect(style.fontSize, isNull);
      expect(style.fontWeight, isNull);
      expect(style.color, _kColorOnSurface);
    });
  });

  group('CoreCountdownTheme passes through style', () {
    test('CoreCountdownTheme', () {
      const style = CoreCountdownStyle(fontSize: _kFontTitle);
      const theme = CoreCountdownTheme(style: style);
      expect(theme.style, style);
    });
  });
}
