// Tests for CoreClickableStyle and CoreClickableTheme.

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

const _kColorPrimary = CoreColor.token(CoreColors.primary);
const _kColorError = CoreColor.token(CoreColors.error);
const _kRadius = CoreBorderRadius.all(8);
const _kDurationFast = Duration(milliseconds: 100);
const _kDurationSlow = Duration(milliseconds: 300);

void main() {
  group('CoreClickableStyle', () {
    test('chain — design system → theme.style → widget', () {
      const designSystem = CoreClickableStyle(
        borderRadius: _kRadius,
        focusOutlineStyle: CoreFocusOutlineStyle(
          borderColor: _kColorPrimary,
          borderWidth: 2,
        ),
        pressedScale: 0.97,
        disabledOpacity: 0.5,
        duration: _kDurationFast,
        pressDuration: _kDurationFast,
      );
      const themeStyle = CoreClickableStyle(pressedScale: 0.9);
      const widgetStyle = CoreClickableStyle(
        focusOutlineStyle: CoreFocusOutlineStyle(borderColor: _kColorError),
      );

      final effective = designSystem.merge(themeStyle).merge(widgetStyle);

      expect(effective.borderRadius, _kRadius);
      expect(effective.focusOutlineStyle?.borderColor, _kColorError);
      expect(effective.focusOutlineStyle?.borderWidth, 2);
      expect(effective.pressedScale, 0.9);
      expect(effective.disabledOpacity, 0.5);
      expect(effective.duration, _kDurationFast);
    });

    test('merge with null keeps original', () {
      const a = CoreClickableStyle(pressedScale: 0.95);
      expect(a.merge(null), same(a));
    });

    test('press duration override on widget wins', () {
      const a = CoreClickableStyle(pressDuration: _kDurationFast);
      const b = CoreClickableStyle(pressDuration: _kDurationSlow);
      expect(a.merge(b).pressDuration, _kDurationSlow);
    });

    test('static const defaults', () {
      expect(
        CoreClickableStyle.defaultBorderRadius,
        const CoreBorderRadius.all(CoreRadius.radius4),
      );
      expect(
        CoreClickableStyle.defaultFocusOutlineStyle.borderColor,
        CoreFocusOutlineStyle.defaultBorderColor,
      );
      expect(
        CoreClickableStyle.defaultFocusOutlineStyle.borderWidth,
        CoreFocusRing.ringWidth,
      );
      expect(
        CoreClickableStyle.defaultFocusOutlineStyle.offsetColor,
        CoreFocusOutlineStyle.defaultOffsetColor,
      );
      // The gap band is transparent: a Clickable's background is the page
      // it sits on, so the gap shows that page rather than a second outline.
      expect(
        CoreClickableStyle.defaultFocusOutlineStyle.offsetColor,
        CoreColor.transparent,
      );
      expect(CoreClickableStyle.defaultPressedScale, 0.97);
      expect(CoreClickableStyle.defaultDisabledOpacity, 0.5);
      expect(
        CoreClickableStyle.defaultDuration,
        const Duration(milliseconds: CoreDuration.ms150),
      );
      expect(
        CoreClickableStyle.defaultPressDuration,
        const Duration(milliseconds: CoreDuration.ms100),
      );
    });

    test('equality + hashCode + copyWith', () {
      const slot = CoreFocusOutlineStyle(borderColor: _kColorPrimary);
      const a = CoreClickableStyle(
        focusOutlineStyle: slot,
        pressedScale: 0.95,
      );
      const b = CoreClickableStyle(
        focusOutlineStyle: slot,
        pressedScale: 0.95,
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);

      final copy = a.copyWith(disabledOpacity: 0.3);
      expect(copy.disabledOpacity, 0.3);
      expect(copy.focusOutlineStyle?.borderColor, _kColorPrimary);
      expect(copy.pressedScale, 0.95);
    });
  });

  group('CoreClickableTheme', () {
    test('passes through style', () {
      const style = CoreClickableStyle(pressedScale: 0.9);
      const theme = CoreClickableTheme(style: style);
      expect(theme.style, style);
    });

    test('equality + hashCode', () {
      const a = CoreClickableTheme(
        style: CoreClickableStyle(pressedScale: 0.9),
      );
      const b = CoreClickableTheme(
        style: CoreClickableStyle(pressedScale: 0.9),
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });
  });
}
