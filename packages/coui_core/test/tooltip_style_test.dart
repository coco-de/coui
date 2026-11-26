// Tests for CoreTooltipStyle (Epic #1302 — Story #1310 Tooltip).

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

const _kRadiusSm = CoreBorderRadius.all(4);
const _kRadiusLg = CoreBorderRadius.all(8);
const _kPaddingSm = CoreEdgeInsets.all(8);
const _kPaddingLg = CoreEdgeInsets.all(12);
const double _kBlurNone = 0;
const double _kBlurSoft = 6;
const double _kOpacityFull = 1;
const double _kOpacityMuted = 0.95;
const double _kMaxWidthNarrow = 200;
const double _kMaxWidthWide = 320;

const _kBgInverseSurface = CoreColor.token(CoreColors.inverseSurface);
const _kBgError = CoreColor.token(CoreColors.error);

const double _kFontBody = 12;
const int _kWeightSemiBold = CoreFontWeight.semiBold;
const int _kWeightRegular = CoreFontWeight.regular;
const _kColorOnInverse = CoreColor.token(CoreColors.inverseOnSurface);
const _kColorOnSurface = CoreColor.token(CoreColors.onSurface);

void main() {
  group('CoreTooltipStyle.merge', () {
    test('null other returns this', () {
      const a = CoreTooltipStyle(
        panelBackgroundColor: _kBgInverseSurface,
        panelBorderRadius: _kRadiusSm,
      );
      expect(identical(a.merge(null), a), isTrue);
    });

    test('chain — design system → theme.style → widget', () {
      const designSystem = CoreTooltipStyle(
        panelBackgroundColor: _kBgInverseSurface,
        panelBorderRadius: _kRadiusSm,
        panelPadding: _kPaddingSm,
        surfaceBlur: _kBlurNone,
        surfaceOpacity: _kOpacityFull,
      );
      const themeStyle = CoreTooltipStyle(
        panelBorderRadius: _kRadiusLg,
      );
      const widgetStyle = CoreTooltipStyle(
        panelPadding: _kPaddingLg,
        surfaceOpacity: _kOpacityMuted,
      );

      final effective = designSystem.merge(themeStyle).merge(widgetStyle);

      expect(effective.panelBackgroundColor, _kBgInverseSurface);
      expect(effective.panelBorderRadius, _kRadiusLg); // theme
      expect(effective.panelPadding, _kPaddingLg); // widget
      expect(effective.surfaceBlur, _kBlurNone);
      expect(effective.surfaceOpacity, _kOpacityMuted); // widget
    });

    test('right-most non-null wins on each field', () {
      const a = CoreTooltipStyle(
        panelPadding: _kPaddingSm,
        surfaceBlur: _kBlurNone,
      );
      const b = CoreTooltipStyle(panelPadding: _kPaddingLg);
      const c = CoreTooltipStyle(surfaceBlur: _kBlurSoft);

      final result = a.merge(b).merge(c);

      expect(result.panelPadding, _kPaddingLg);
      expect(result.surfaceBlur, _kBlurSoft);
    });

    test('labelStyle merges recursively (subset override)', () {
      const base = CoreTooltipStyle(
        labelStyle: CoreTextStyle(
          fontSize: _kFontBody,
          fontWeight: _kWeightRegular,
          color: _kColorOnInverse,
        ),
      );
      const override = CoreTooltipStyle(
        labelStyle: CoreTextStyle(fontWeight: _kWeightSemiBold),
      );
      final merged = base.merge(override);
      expect(merged.labelStyle?.fontSize, _kFontBody);
      expect(merged.labelStyle?.fontWeight, _kWeightSemiBold);
      expect(merged.labelStyle?.color, _kColorOnInverse);
    });

    test('null nested style on base inherits from override', () {
      const base = CoreTooltipStyle();
      const override = CoreTooltipStyle(
        labelStyle: CoreTextStyle(
          fontSize: _kFontBody,
          color: _kColorOnSurface,
        ),
      );
      final merged = base.merge(override);
      expect(merged.labelStyle?.fontSize, _kFontBody);
      expect(merged.labelStyle?.color, _kColorOnSurface);
    });
  });

  group('CoreTooltipStyle equality', () {
    test('same fields → equal', () {
      const a = CoreTooltipStyle(
        panelBackgroundColor: _kBgInverseSurface,
        panelBorderRadius: _kRadiusSm,
        panelPadding: _kPaddingSm,
      );
      const b = CoreTooltipStyle(
        panelBackgroundColor: _kBgInverseSurface,
        panelBorderRadius: _kRadiusSm,
        panelPadding: _kPaddingSm,
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('different panelBackgroundColor → not equal', () {
      const a = CoreTooltipStyle(panelBackgroundColor: _kBgInverseSurface);
      const b = CoreTooltipStyle(panelBackgroundColor: _kBgError);
      expect(a, isNot(equals(b)));
    });

    test('different labelStyle → not equal', () {
      const a = CoreTooltipStyle(
        labelStyle: CoreTextStyle(fontSize: _kFontBody),
      );
      const b = CoreTooltipStyle(
        labelStyle: CoreTextStyle(fontSize: _kFontBody * 1.25),
      );
      expect(a, isNot(equals(b)));
    });
  });

  group('CoreTooltipStyle.copyWith', () {
    test('only-supplied fields override', () {
      const base = CoreTooltipStyle(
        panelBackgroundColor: _kBgInverseSurface,
        panelPadding: _kPaddingSm,
        surfaceBlur: _kBlurNone,
      );
      final copy = base.copyWith(surfaceBlur: _kBlurSoft);
      expect(copy.panelBackgroundColor, _kBgInverseSurface);
      expect(copy.panelPadding, _kPaddingSm);
      expect(copy.surfaceBlur, _kBlurSoft);
    });

    test('preserves nested labelStyle when not specified', () {
      const base = CoreTooltipStyle(
        labelStyle: CoreTextStyle(fontSize: _kFontBody),
      );
      final copy = base.copyWith(panelPadding: _kPaddingLg);
      expect(copy.panelPadding, _kPaddingLg);
      expect(copy.labelStyle?.fontSize, _kFontBody);
    });
  });

  group('CoreTooltipStyle.panelMaxWidth', () {
    test('defaults to unconstrained', () {
      // No paired `default*` by design — a shared ceiling would re-wrap
      // every tooltip that never asked for one.
      expect(const CoreTooltipStyle().panelMaxWidth, isNull);
    });

    test('merge lets the later style override the width ceiling', () {
      const themeStyle = CoreTooltipStyle(panelMaxWidth: _kMaxWidthNarrow);
      const widgetStyle = CoreTooltipStyle(panelMaxWidth: _kMaxWidthWide);

      expect(
        themeStyle.merge(widgetStyle).panelMaxWidth,
        _kMaxWidthWide,
      );
    });

    test('merge keeps the base ceiling when the override omits it', () {
      const base = CoreTooltipStyle(panelMaxWidth: _kMaxWidthNarrow);
      const override = CoreTooltipStyle(panelPadding: _kPaddingLg);

      expect(base.merge(override).panelMaxWidth, _kMaxWidthNarrow);
    });

    test('copyWith carries it, and participates in equality', () {
      const base = CoreTooltipStyle(panelPadding: _kPaddingSm);
      final copy = base.copyWith(panelMaxWidth: _kMaxWidthNarrow);

      expect(copy.panelMaxWidth, _kMaxWidthNarrow);
      expect(copy.panelPadding, _kPaddingSm);
      // A field missing from `==` reads as "no change" to the framework,
      // so a theme swap that only moves the ceiling would not rebuild.
      expect(copy, isNot(equals(base)));
      expect(
        copy,
        equals(
          const CoreTooltipStyle(
            panelPadding: _kPaddingSm,
            panelMaxWidth: _kMaxWidthNarrow,
          ),
        ),
      );
      expect(
        copy.hashCode,
        const CoreTooltipStyle(
          panelPadding: _kPaddingSm,
          panelMaxWidth: _kMaxWidthNarrow,
        ).hashCode,
      );
    });
  });

  group('CoreTooltipTheme', () {
    test('style passes through', () {
      const style = CoreTooltipStyle(panelPadding: _kPaddingLg);
      const theme = CoreTooltipTheme(style: style);
      expect(theme.style, style);
    });

    test('null style', () {
      const theme = CoreTooltipTheme();
      expect(theme.style, isNull);
    });

    test('equality', () {
      const a = CoreTooltipTheme(
        style: CoreTooltipStyle(panelPadding: _kPaddingLg),
      );
      const b = CoreTooltipTheme(
        style: CoreTooltipStyle(panelPadding: _kPaddingLg),
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });
  });

  group('defaults', () {
    test(
      'the label is the labelSmall role as it is, on the surface colour',
      () {
        const label = CoreTooltipStyle.defaultLabelStyle;
        expect(label.token, CoreTextStyles.labelSmall);
        // The role states the weight (12 Medium); the slot adds no overlay.
        expect(label.fontWeight, isNull);
        expect(label.color, const CoreColor.token(CoreColors.surface));
      },
    );

    test('padding is 10 across, 6 down', () {
      expect(
        CoreTooltipStyle.defaultPanelPadding,
        const CoreEdgeInsets.symmetric(horizontal: 10, vertical: 6),
      );
    });

    test('a tooltip draws no tail unless its style states one', () {
      expect(CoreTooltipStyle.defaultTailWidth, 0);
      expect(CoreTooltipStyle.defaultTailHeight, 0);
    });
  });
}
