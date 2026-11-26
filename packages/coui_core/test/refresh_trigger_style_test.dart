// Tests for CoreRefreshTriggerStyle (Phase 6g batch 28 — RefreshTrigger).
// ignore_for_file: avoid_redundant_argument_values

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

const _kBgSurface = CoreColor.token(CoreColors.surface);
const _kBgContainer = CoreColor.token(CoreColors.surfaceContainer);
const _kColorPrimary = CoreColor.token(CoreColors.primary);
const _kColorSuccess = CoreColor.token(CoreColors.success);
const _kColorVariant = CoreColor.token(CoreColors.onSurfaceVariant);

const _kRadiusSm = CoreBorderRadius.all(4);
const _kRadiusLg = CoreBorderRadius.all(16);

const _kPadSm = CoreEdgeInsets.all(4);
const _kPadLg = CoreEdgeInsets.symmetric(horizontal: 12, vertical: 4);

const _kGapSm = CoreGapStyle(size: 4);
const _kGapLg = CoreGapStyle(size: 8);

const Duration _kAnim300 = Duration(milliseconds: 300);

const double _kFontLabel = 14;
const int _kWeightSemiBold = CoreFontWeight.semiBold;
const int _kWeightRegular = CoreFontWeight.regular;

void main() {
  group('CoreRefreshTriggerStyle.merge', () {
    test('null other returns this', () {
      const a = CoreRefreshTriggerStyle(
        indicatorBackgroundColor: _kBgSurface,
        indicatorGapStyle: _kGapSm,
      );
      expect(identical(a.merge(null), a), isTrue);
    });

    test('chain — design system → theme.style → widget', () {
      const designSystem = CoreRefreshTriggerStyle(
        indicatorBackgroundColor: _kBgSurface,
        indicatorBorderRadius: _kRadiusSm,
        indicatorGapStyle: _kGapSm,
        idleTextStyle: CoreTextStyle(color: _kColorVariant),
        animationDuration: _kAnim300,
      );
      const themeStyle = CoreRefreshTriggerStyle(
        indicatorBorderRadius: _kRadiusLg,
      );
      const widgetStyle = CoreRefreshTriggerStyle(
        indicatorGapStyle: _kGapLg,
        refreshingTextStyle: CoreTextStyle(color: _kColorPrimary),
      );

      final effective = designSystem.merge(themeStyle).merge(widgetStyle);

      expect(effective.indicatorBackgroundColor, _kBgSurface);
      expect(effective.indicatorBorderRadius, _kRadiusLg); // theme
      expect(effective.indicatorGapStyle, _kGapLg); // widget
      expect(effective.refreshingTextStyle?.color, _kColorPrimary); // widget
      expect(effective.idleTextStyle?.color, _kColorVariant);
      expect(effective.animationDuration, _kAnim300);
    });

    test('right-most non-null wins on each field', () {
      const a = CoreRefreshTriggerStyle(
        indicatorBorderRadius: _kRadiusSm,
        indicatorGapStyle: _kGapSm,
      );
      const b = CoreRefreshTriggerStyle(indicatorBorderRadius: _kRadiusLg);
      const c = CoreRefreshTriggerStyle(indicatorGapStyle: _kGapLg);

      final result = a.merge(b).merge(c);

      expect(result.indicatorBorderRadius, _kRadiusLg);
      expect(result.indicatorGapStyle, _kGapLg);
    });

    test('padding / pullingPadding / text colours merge', () {
      const base = CoreRefreshTriggerStyle(
        indicatorPadding: _kPadLg,
        pullingPadding: _kPadSm,
        completedTextStyle: CoreTextStyle(color: _kColorSuccess),
      );
      const override = CoreRefreshTriggerStyle(
        pullingPadding: _kPadLg,
      );
      final merged = base.merge(override);
      expect(merged.indicatorPadding, _kPadLg);
      expect(merged.pullingPadding, _kPadLg);
      expect(merged.completedTextStyle?.color, _kColorSuccess);
    });
  });

  group('CoreRefreshTriggerStyle defaults', () {
    test('static const defaults reference refresh-trigger tokens', () {
      expect(
        CoreRefreshTriggerStyle.defaultIndicatorBackgroundColor,
        const CoreColor.token(CoreColors.surface),
      );
      expect(
        CoreRefreshTriggerStyle.defaultIdleTextStyle.color,
        const CoreColor.token(CoreColors.onSurfaceVariant),
      );
      expect(
        CoreRefreshTriggerStyle.defaultRefreshingTextStyle.color,
        const CoreColor.token(CoreColors.primary),
      );
      expect(
        CoreRefreshTriggerStyle.defaultCompletedTextStyle.color,
        const CoreColor.token(CoreColors.success),
      );
      expect(
        CoreRefreshTriggerStyle.defaultIndicatorBorderRadius,
        const CoreBorderRadius.all(CoreRadius.radius16),
      );
      expect(
        CoreRefreshTriggerStyle.defaultIndicatorGapStyle,
        const CoreGapStyle(size: CoreSpace.space8),
      );
      expect(
        CoreRefreshTriggerStyle.defaultAnimationDuration,
        const Duration(milliseconds: CoreDuration.ms300),
      );
    });

    test('labelStyle merges recursively (subset override)', () {
      const base = CoreRefreshTriggerStyle(
        labelStyle: CoreTextStyle(
          fontSize: _kFontLabel,
          fontWeight: _kWeightSemiBold,
          color: _kColorVariant,
        ),
      );
      const override = CoreRefreshTriggerStyle(
        labelStyle: CoreTextStyle(fontWeight: _kWeightRegular),
      );
      final merged = base.merge(override);
      expect(merged.labelStyle?.fontSize, _kFontLabel);
      expect(merged.labelStyle?.fontWeight, _kWeightRegular);
      expect(merged.labelStyle?.color, _kColorVariant);
    });

    test('null nested labelStyle on base inherits from override', () {
      const base = CoreRefreshTriggerStyle();
      const override = CoreRefreshTriggerStyle(
        labelStyle: CoreTextStyle(fontSize: _kFontLabel),
      );
      final merged = base.merge(override);
      expect(merged.labelStyle?.fontSize, _kFontLabel);
    });
  });

  group('CoreRefreshTriggerStyle equality', () {
    test('same fields → equal', () {
      const a = CoreRefreshTriggerStyle(
        indicatorBackgroundColor: _kBgSurface,
        indicatorGapStyle: _kGapSm,
        refreshingTextStyle: CoreTextStyle(color: _kColorPrimary),
      );
      const b = CoreRefreshTriggerStyle(
        indicatorBackgroundColor: _kBgSurface,
        indicatorGapStyle: _kGapSm,
        refreshingTextStyle: CoreTextStyle(color: _kColorPrimary),
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('different refreshingTextStyle → not equal', () {
      const a = CoreRefreshTriggerStyle(
        refreshingTextStyle: CoreTextStyle(color: _kColorPrimary),
      );
      const b = CoreRefreshTriggerStyle(
        refreshingTextStyle: CoreTextStyle(color: _kColorSuccess),
      );
      expect(a, isNot(equals(b)));
    });

    test('different labelStyle → not equal', () {
      const a = CoreRefreshTriggerStyle(
        labelStyle: CoreTextStyle(fontSize: _kFontLabel),
      );
      const b = CoreRefreshTriggerStyle(
        labelStyle: CoreTextStyle(fontSize: _kFontLabel * 1.25),
      );
      expect(a, isNot(equals(b)));
    });
  });

  group('CoreRefreshTriggerStyle.copyWith', () {
    test('only-supplied fields override', () {
      const base = CoreRefreshTriggerStyle(
        indicatorBackgroundColor: _kBgSurface,
        indicatorGapStyle: _kGapSm,
        refreshingTextStyle: CoreTextStyle(color: _kColorPrimary),
      );
      final copy = base.copyWith(indicatorGapStyle: _kGapLg);
      expect(copy.indicatorBackgroundColor, _kBgSurface);
      expect(copy.indicatorGapStyle, _kGapLg);
      expect(copy.refreshingTextStyle?.color, _kColorPrimary);
    });

    test('preserves nested labelStyle when not specified', () {
      const base = CoreRefreshTriggerStyle(
        labelStyle: CoreTextStyle(fontSize: _kFontLabel),
      );
      final copy = base.copyWith(indicatorBackgroundColor: _kBgContainer);
      expect(copy.indicatorBackgroundColor, _kBgContainer);
      expect(copy.labelStyle?.fontSize, _kFontLabel);
    });
  });

  group('CoreRefreshTriggerTheme', () {
    test('style passes through', () {
      const style = CoreRefreshTriggerStyle(indicatorGapStyle: _kGapLg);
      const theme = CoreRefreshTriggerTheme(style: style);
      expect(theme.style, style);
    });

    test('null style', () {
      const theme = CoreRefreshTriggerTheme();
      expect(theme.style, isNull);
    });

    test('equality', () {
      const a = CoreRefreshTriggerTheme(
        style: CoreRefreshTriggerStyle(indicatorGapStyle: _kGapLg),
      );
      const b = CoreRefreshTriggerTheme(
        style: CoreRefreshTriggerStyle(indicatorGapStyle: _kGapLg),
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });
  });

  group('CoreRefreshStage / CoreRefreshDirection', () {
    test('defaultStage is idle', () {
      expect(CoreRefreshStage.defaultStage, CoreRefreshStage.idle);
    });

    test('defaultDirection is vertical', () {
      expect(
        CoreRefreshDirection.defaultDirection,
        CoreRefreshDirection.vertical,
      );
    });

    test('stage has four lifecycle values', () {
      expect(CoreRefreshStage.values, hasLength(4));
    });

    test('behaviour defaults reference duration / extent values', () {
      expect(
        CoreRefreshTriggerStyle.defaultAnimationDuration,
        const Duration(milliseconds: CoreDuration.ms300),
      );
      expect(
        CoreRefreshTriggerStyle.defaultCompleteDuration,
        const Duration(milliseconds: CoreDuration.ms500),
      );
      expect(CoreRefreshTriggerStyle.defaultMinExtent, 75);
      expect(CoreRefreshTriggerStyle.defaultMaxExtent, 150);
    });
  });
}
