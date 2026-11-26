// Tests for the CoreBasicStyle design-system defaults that lay out a row.

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

/// The four modes a colour slot is read in.
final List<(String, CoreColorScheme)> _kModes = [
  ('light', CouiColorPresets.source.light()),
  ('dark', CouiColorPresets.source.dark()),
  ('high-contrast light', CouiColorPresets.source.highContrastLight()),
  ('high-contrast dark', CouiColorPresets.source.highContrastDark()),
];

/// `color` as each mode paints it, so a slot assertion reads the pixel the
/// default produces and not only the token it names.
void _expectSameInEveryMode(CoreColor? actual, CoreColorToken expected) {
  for (final (mode, scheme) in _kModes) {
    expect(
      scheme.resolve(actual!).argb,
      scheme.resolve(CoreColor.token(expected)).argb,
      reason: mode,
    );
  }
}

void main() {
  group('CoreBasicStyle subtitle colour', () {
    test('the subtitle is onSurfaceSubtle in every mode', () {
      _expectSameInEveryMode(
        CoreBasicStyle.defaultSubtitleColor,
        CoreColors.onSurfaceSubtle,
      );
      _expectSameInEveryMode(
        CoreBasicStyle.defaultSubtitleTextStyle.color,
        CoreColors.onSurfaceSubtle,
      );
    });

    test('title and content stay onSurface', () {
      _expectSameInEveryMode(
        CoreBasicStyle.defaultTitleColor,
        CoreColors.onSurface,
      );
      _expectSameInEveryMode(
        CoreBasicStyle.defaultContentColor,
        CoreColors.onSurface,
      );
    });
  });

  group('CoreBasicStyle row layout defaults', () {
    test('gap between leading, body and trailing is 12', () {
      expect(
        CoreBasicStyle.defaultTitleContentGapStyle.size,
        CoreSpace.space12,
      );
    });

    test('title to subtitle gap stays 2', () {
      expect(
        CoreBasicStyle.defaultTitleSubtitleGapStyle.size,
        CoreSpace.space2,
      );
    });

    test('leading and trailing sit at the row center', () {
      expect(CoreBasicStyle.defaultLeadingAlignment, CoreBasicAlignment.center);
      expect(
        CoreBasicStyle.defaultTrailingAlignment,
        CoreBasicAlignment.center,
      );
    });

    test('title, subtitle and content stay start-aligned at the top', () {
      expect(CoreBasicStyle.defaultTitleAlignment, CoreBasicAlignment.topStart);
      expect(
        CoreBasicStyle.defaultSubtitleAlignment,
        CoreBasicAlignment.topStart,
      );
      expect(
        CoreBasicStyle.defaultContentAlignment,
        CoreBasicAlignment.topStart,
      );
    });
  });

  group('trailing', () {
    test('trailing value is Medium 15 on onSurface, 4 from the icon', () {
      expect(
        CoreBasicStyle.defaultTrailingTextStyle.token,
        CoreTextStyles.labelXl,
      );
      expect(
        CoreBasicStyle.defaultTrailingTextStyle.color,
        const CoreColor.token(CoreColors.onSurface),
      );
      expect(CoreBasicStyle.defaultTrailingGapStyle.size, CoreSpace.space4);
    });

    test('built-in chevron is drawn in onSurfaceSubtle', () {
      expect(
        CoreBasicStyle.defaultTrailingIconStyle.color,
        const CoreColor.token(CoreColors.onSurfaceSubtle),
      );
    });

    test('subtitle and trailing icon show by default', () {
      expect(CoreBasicContract.defaultShowSubtitle, isTrue);
      expect(CoreBasicContract.defaultShowTrailingIcon, isTrue);
    });

    test('trailing slots take part in merge, copyWith and equality', () {
      const a = CoreBasicStyle(
        trailingGapStyle: CoreGapStyle(size: CoreSpace.space8),
        trailingIconStyle: CoreIconStyle(size: CoreSpace.space16),
        trailingTextStyle: CoreTextStyle(fontWeight: CoreFontWeight.bold),
      );
      expect(a.merge(null), same(a));
      expect(a.copyWith(), a);
      expect(a.hashCode, a.copyWith().hashCode);
      expect(
        a,
        isNot(a.copyWith(trailingGapStyle: const CoreGapStyle(size: 2))),
      );
      expect(
        const CoreBasicStyle().merge(a).trailingIconStyle,
        a.trailingIconStyle,
      );
    });
  });
}
