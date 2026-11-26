/// Tests for [CoreCardStyle] (Epic #1415 option D — platform-neutral).
library;

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

const _kPadMd = CoreEdgeInsets.all(16);
const _kPadLg = CoreEdgeInsets.all(24);
const _kRadiusMd = CoreBorderRadius.all(8);
const _kBgPrimary = CoreColor(0xFF3B82F6);
const _kBgSecondary = CoreColor(0xFFE0E0E0);

void main() {
  group('CoreCardStyle.merge', () {
    test('null other returns this', () {
      const base = CoreCardStyle(padding: _kPadMd);
      expect(base.merge(null), same(base));
    });

    test('non-null fields in other override receiver', () {
      const base = CoreCardStyle(padding: _kPadMd);
      const override = CoreCardStyle(padding: _kPadLg);
      expect(base.merge(override).padding, _kPadLg);
    });

    test('null fields in other inherit from receiver', () {
      const base = CoreCardStyle(
        padding: _kPadMd,
        backgroundColor: _kBgPrimary,
      );
      const override = CoreCardStyle(padding: _kPadLg);
      final merged = base.merge(override);
      expect(merged.padding, _kPadLg);
      expect(merged.backgroundColor, _kBgPrimary);
    });

    test('chain — theme.style → variantStyles → widget', () {
      const themeStyle = CoreCardStyle(padding: _kPadMd);
      const variantStyle = CoreCardStyle(backgroundColor: _kBgPrimary);
      const widgetStyle = CoreCardStyle(borderRadius: _kRadiusMd);
      final merged = themeStyle.merge(variantStyle).merge(widgetStyle);
      expect(merged.padding, _kPadMd);
      expect(merged.backgroundColor, _kBgPrimary);
      expect(merged.borderRadius, _kRadiusMd);
    });
  });

  group('CoreCardStyle equality', () {
    test('same fields → equal', () {
      const a = CoreCardStyle(padding: _kPadMd, backgroundColor: _kBgPrimary);
      const b = CoreCardStyle(padding: _kPadMd, backgroundColor: _kBgPrimary);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('different padding → not equal', () {
      const a = CoreCardStyle(padding: _kPadMd);
      const b = CoreCardStyle(padding: _kPadLg);
      expect(a, isNot(equals(b)));
    });

    test('different elevation → not equal', () {
      const a = CoreCardStyle(elevation: .none);
      const b = CoreCardStyle(elevation: .soft);
      expect(a, isNot(equals(b)));
    });
  });

  group('CoreCardStyle.copyWith', () {
    test('only-supplied fields override', () {
      const base = CoreCardStyle(
        padding: _kPadMd,
        backgroundColor: _kBgPrimary,
      );
      final copy = base.copyWith(backgroundColor: _kBgSecondary);
      expect(copy.padding, _kPadMd);
      expect(copy.backgroundColor, _kBgSecondary);
    });

    test('preserves untouched fields (width/height)', () {
      const base = CoreCardStyle(width: 100, height: 50);
      final copy = base.copyWith(width: 200);
      expect(copy.width, 200);
      expect(copy.height, 50);
    });
  });

  group('CoreCardStyle spacing defaults', () {
    test('content padding is 20 vertical and 24 horizontal', () {
      const padding = CoreCardStyle.defaultPadding;
      expect(padding.left, CoreSpace.space24);
      expect(padding.right, CoreSpace.space24);
      expect(padding.top, CoreSpace.space20);
      expect(padding.bottom, CoreSpace.space20);
    });

    test('header to body gap is 8 and body to footer gap is 12', () {
      expect(CoreCardStyle.defaultHeaderBodyGapStyle.size, CoreSpace.space8);
      expect(CoreCardStyle.defaultBodyFooterGapStyle.size, CoreSpace.space12);
    });
  });

  group('CoreCardStyle defaults', () {
    test('default constants exposed on the class', () {
      expect(CoreCardStyle.defaultPadding, isA<CoreEdgeInsets>());
      expect(CoreCardStyle.defaultBorderRadius, isA<CoreBorderRadius>());
      expect(CoreCardStyle.defaultSizing, CoreCardSizing.intrinsic);
      expect(CoreCardStyle.defaultElevation, CoreCardElevation.none);
      expect(CoreCardStyle.defaultClipBehavior, CoreClipMode.none);
    });

    test('variantStyles — outlined uses surface + outlineVariant border', () {
      final chrome = CoreCardStyle.defaultsByVariant[CoreCardVariant.outlined]!;
      expect(chrome.backgroundColor.token?.name, 'surface');
      expect(chrome.borderColor?.token?.name, 'outline-variant');
      expect(chrome.borderColor?.fallbacks, [CoreColors.outline]);
      expect(chrome.borderWidth, CoreCardStyle.defaultOutlinedBorderWidth);
    });

    test('the widget default variant is the borderless fill', () {
      expect(CoreCardVariant.defaultVariant, CoreCardVariant.filled);
      final chrome =
          CoreCardStyle.defaultsByVariant[CoreCardVariant.defaultVariant]!;
      expect(chrome.borderWidth, 0);
    });

    test('the outlined edge is the outlineVariant hairline in every mode', () {
      final edge = CoreCardStyle
          .defaultsByVariant[CoreCardVariant.outlined]!
          .borderColor!;
      for (final (mode, scheme) in [
        ('light', CouiColorPresets.source.light()),
        ('dark', CouiColorPresets.source.dark()),
        ('high-contrast light', CouiColorPresets.source.highContrastLight()),
        ('high-contrast dark', CouiColorPresets.source.highContrastDark()),
      ]) {
        expect(
          scheme.resolve(edge).argb,
          scheme.resolve(const CoreColor.token(CoreColors.outlineVariant)).argb,
          reason: mode,
        );
      }
    });

    test('variantStyles — filled uses surfaceContainer + no border', () {
      final chrome = CoreCardStyle.defaultsByVariant[CoreCardVariant.filled]!;
      expect(chrome.backgroundColor.token?.name, 'surface-container');
      // Explicit `CoreColor.transparent`, not null — a null borderColor lets
      // Flutter's OutlinedContainer fall back to a surfaceContainerHigh
      // hairline even at borderWidth: 0 (widget/render-only.md "Flutter
      // OutlinedContainer 함정"), which grew a stray border on Flutter that
      // Web (no border class) never drew.
      expect(chrome.borderColor, CoreColor.transparent);
      expect(chrome.borderWidth, 0);
    });

    test('variantStyles — outlined declares fallbacks', () {
      final chrome = CoreCardStyle.defaultsByVariant[CoreCardVariant.outlined]!;
      expect(chrome.backgroundColor.fallbacks, isNotEmpty);
      expect(chrome.borderColor?.fallbacks, isNotEmpty);
    });
  });

  group('CoreCardTheme', () {
    test('style + variantStyles pass through', () {
      const style = CoreCardStyle(padding: _kPadMd);
      const variantStyle = CoreCardStyle(backgroundColor: _kBgPrimary);
      const theme = CoreCardTheme(
        style: style,
        // partial map under test
        variantStyles: {.filled: variantStyle},
      );
      expect(theme.style, style);
      expect(theme.variantStyles![CoreCardVariant.filled], variantStyle);
    });

    test('null style + null variantStyles', () {
      const theme = CoreCardTheme();
      expect(theme.style, isNull);
      expect(theme.variantStyles, isNull);
    });

    test('equality with same variantStyles map content', () {
      const a = CoreCardTheme(
        style: CoreCardStyle(padding: _kPadMd),
        // partial map under test
        variantStyles: {.filled: CoreCardStyle(backgroundColor: _kBgPrimary)},
      );
      const b = CoreCardTheme(
        style: CoreCardStyle(padding: _kPadMd),
        // partial map under test
        variantStyles: {.filled: CoreCardStyle(backgroundColor: _kBgPrimary)},
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });
  });
}
