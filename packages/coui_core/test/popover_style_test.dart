// Tests for CorePopoverStyle.
// ignore_for_file: avoid_redundant_argument_values

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

const _kRadiusSm = CoreBorderRadius.all(4);
const _kRadiusLg = CoreBorderRadius.all(12);
const _kPaddingSm = CoreEdgeInsets.all(8);
const _kPaddingLg = CoreEdgeInsets.all(16);
const double _kBorderThin = 1;
const double _kBorderThick = 2;
const double _kGapSm = 4;
const double _kGapLg = 8;

const _kBgSurface = CoreColor.token(CoreColors.surface);
const _kBgPrimary = CoreColor.token(CoreColors.primary);
const _kBorderOutline = CoreColor.token(CoreColors.outline);
const _kBorderError = CoreColor.token(CoreColors.error);

const List<CoreShadowLayer> _kShadowSoft = CoreShadow.xs;
const List<CoreShadowLayer> _kShadowStrong = CoreShadow.lg;

const Duration _kAnim150 = Duration(milliseconds: 150);
const Duration _kAnim300 = Duration(milliseconds: 300);

void main() {
  group('CorePopoverStyle.merge', () {
    test('null other returns this', () {
      const a = CorePopoverStyle(
        panelStyle: CorePopupStyle(
          backgroundColor: _kBgSurface,
          borderRadius: _kRadiusLg,
        ),
      );
      expect(identical(a.merge(null), a), isTrue);
    });

    test('chain — design system → theme.style → widget', () {
      const designSystem = CorePopoverStyle(
        panelStyle: CorePopupStyle(
          backgroundColor: _kBgSurface,
          borderColor: _kBorderOutline,
          borderWidth: _kBorderThin,
          borderRadius: _kRadiusSm,
          padding: _kPaddingSm,
        ),
        placementOffset: _kGapLg,
        openAnimationDuration: _kAnim150,
      );
      const themeStyle = CorePopoverStyle(
        panelStyle: CorePopupStyle(borderRadius: _kRadiusLg),
      );
      const widgetStyle = CorePopoverStyle(
        panelStyle: CorePopupStyle(padding: _kPaddingLg),
        placementOffset: _kGapSm,
      );

      final effective = designSystem.merge(themeStyle).merge(widgetStyle);

      // Nested panelStyle merges recursively — base fields survive while
      // each later layer overrides only the field it sets.
      expect(effective.panelStyle?.backgroundColor, _kBgSurface);
      expect(effective.panelStyle?.borderColor, _kBorderOutline);
      expect(effective.panelStyle?.borderWidth, _kBorderThin);
      expect(effective.panelStyle?.borderRadius, _kRadiusLg); // theme override
      expect(effective.panelStyle?.padding, _kPaddingLg); // widget override
      expect(effective.placementOffset, _kGapSm); // widget override
      expect(effective.openAnimationDuration, _kAnim150);
    });

    test('right-most non-null wins on each field', () {
      const a = CorePopoverStyle(
        panelStyle: CorePopupStyle(borderWidth: _kBorderThin),
        placementOffset: _kGapSm,
      );
      const b = CorePopoverStyle(placementOffset: _kGapLg);
      const c = CorePopoverStyle(
        panelStyle: CorePopupStyle(borderWidth: _kBorderThick),
      );

      final result = a.merge(b).merge(c);

      expect(result.placementOffset, _kGapLg);
      expect(result.panelStyle?.borderWidth, _kBorderThick);
    });

    test('viewportPadding override field', () {
      const base = CorePopoverStyle(viewportPadding: CoreEdgeInsets.all(8));
      const override = CorePopoverStyle(
        viewportPadding: CoreEdgeInsets.all(16),
      );
      final merged = base.merge(override);
      expect(merged.viewportPadding, const CoreEdgeInsets.all(16));
      final copy = base.copyWith(
        viewportPadding: const CoreEdgeInsets.all(12),
      );
      expect(copy.viewportPadding, const CoreEdgeInsets.all(12));
      // Equality + hashCode include viewportPadding.
      const a = CorePopoverStyle(viewportPadding: CoreEdgeInsets.all(8));
      const b = CorePopoverStyle(viewportPadding: CoreEdgeInsets.all(8));
      const c = CorePopoverStyle(viewportPadding: CoreEdgeInsets.all(16));
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(equals(c)));
      // Per-side override — CLAUDE.md rule 2 parity (sticky-header
      // / banner / safe-area insets use case).
      const perSide = CorePopoverStyle(
        viewportPadding: CoreEdgeInsets.only(top: 64),
      );
      expect(perSide.viewportPadding?.top, 64);
      expect(perSide.viewportPadding?.left, 0);
    });

    test('panelStyle shadow / animationDuration / triggerSizing merge', () {
      const base = CorePopoverStyle(
        panelStyle: CorePopupStyle(boxShadow: _kShadowSoft),
        triggerSizing: .intrinsic,
        openAnimationDuration: _kAnim150,
      );
      const override = CorePopoverStyle(
        panelStyle: CorePopupStyle(boxShadow: _kShadowStrong),
        triggerSizing: .expand,
      );
      final merged = base.merge(override);
      expect(merged.panelStyle?.boxShadow, _kShadowStrong);
      expect(merged.openAnimationDuration, _kAnim150);
      expect(merged.triggerSizing, CorePopoverTriggerSizing.expand);
    });

    test('panelStyle merges recursively (subset override)', () {
      const base = CorePopoverStyle(
        panelStyle: CorePopupStyle(
          backgroundColor: _kBgSurface,
          padding: _kPaddingSm,
        ),
      );
      const override = CorePopoverStyle(
        panelStyle: CorePopupStyle(padding: _kPaddingLg),
      );
      final merged = base.merge(override);
      // padding from override, backgroundColor from base.
      expect(merged.panelStyle?.padding, _kPaddingLg);
      expect(merged.panelStyle?.backgroundColor, _kBgSurface);
    });

    test('null nested panelStyle on base inherits from override', () {
      const base = CorePopoverStyle();
      const override = CorePopoverStyle(
        panelStyle: CorePopupStyle(padding: _kPaddingLg),
      );
      final merged = base.merge(override);
      expect(merged.panelStyle?.padding, _kPaddingLg);
    });

    test('triggerStyle merges recursively (subset override)', () {
      const base = CorePopoverStyle(
        triggerStyle: CoreButtonStyle(
          backgroundColor: _kBgPrimary,
          padding: CoreEdgeInsets.symmetric(horizontal: 16),
        ),
      );
      const override = CorePopoverStyle(
        triggerStyle: CoreButtonStyle(
          padding: CoreEdgeInsets.symmetric(horizontal: 24),
        ),
      );
      final merged = base.merge(override);
      // padding from override, backgroundColor from base.
      expect(
        merged.triggerStyle?.padding,
        const CoreEdgeInsets.symmetric(horizontal: 24),
      );
      expect(merged.triggerStyle?.backgroundColor, _kBgPrimary);
    });

    test('null nested triggerStyle on base inherits from override', () {
      const base = CorePopoverStyle();
      const override = CorePopoverStyle(
        triggerStyle: CoreButtonStyle(
          padding: CoreEdgeInsets.symmetric(horizontal: 16),
        ),
      );
      final merged = base.merge(override);
      expect(
        merged.triggerStyle?.padding,
        const CoreEdgeInsets.symmetric(horizontal: 16),
      );
    });
  });

  group('CorePopoverStyle equality', () {
    test('same fields → equal', () {
      const a = CorePopoverStyle(
        panelStyle: CorePopupStyle(
          backgroundColor: _kBgSurface,
          padding: _kPaddingLg,
        ),
        placementOffset: _kGapLg,
      );
      const b = CorePopoverStyle(
        panelStyle: CorePopupStyle(
          backgroundColor: _kBgSurface,
          padding: _kPaddingLg,
        ),
        placementOffset: _kGapLg,
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('different panelStyle borderColor → not equal', () {
      const a = CorePopoverStyle(
        panelStyle: CorePopupStyle(borderColor: _kBorderOutline),
      );
      const b = CorePopoverStyle(
        panelStyle: CorePopupStyle(borderColor: _kBorderError),
      );
      expect(a, isNot(equals(b)));
    });

    test('different triggerStyle → not equal', () {
      const a = CorePopoverStyle(
        triggerStyle: CoreButtonStyle(
          padding: CoreEdgeInsets.symmetric(horizontal: 16),
        ),
      );
      const b = CorePopoverStyle(
        triggerStyle: CoreButtonStyle(
          padding: CoreEdgeInsets.symmetric(horizontal: 24),
        ),
      );
      expect(a, isNot(equals(b)));
    });
  });

  group('CorePopoverStyle.copyWith', () {
    test('only-supplied fields override', () {
      const base = CorePopoverStyle(
        panelStyle: CorePopupStyle(backgroundColor: _kBgSurface),
        placementOffset: _kGapLg,
      );
      final copy = base.copyWith(placementOffset: _kGapSm);
      expect(copy.panelStyle?.backgroundColor, _kBgSurface);
      expect(copy.placementOffset, _kGapSm);
    });

    test('preserves nested triggerStyle when not specified', () {
      const base = CorePopoverStyle(
        triggerStyle: CoreButtonStyle(
          padding: CoreEdgeInsets.symmetric(horizontal: 16),
        ),
      );
      final copy = base.copyWith(placementOffset: _kGapSm);
      expect(copy.placementOffset, _kGapSm);
      expect(
        copy.triggerStyle?.padding,
        const CoreEdgeInsets.symmetric(horizontal: 16),
      );
    });
  });

  group('CorePopoverTheme', () {
    test('style passes through (animation duration now in style)', () {
      const style = CorePopoverStyle(
        panelStyle: CorePopupStyle(padding: _kPaddingLg),
        openAnimationDuration: _kAnim150,
        closeAnimationDuration: _kAnim300,
      );
      const theme = CorePopoverTheme(style: style);
      expect(theme.style, style);
      expect(theme.style?.openAnimationDuration, _kAnim150);
      expect(theme.style?.closeAnimationDuration, _kAnim300);
    });

    test('null style', () {
      const theme = CorePopoverTheme();
      expect(theme.style, isNull);
    });

    test('equality', () {
      const a = CorePopoverTheme(
        style: CorePopoverStyle(
          panelStyle: CorePopupStyle(padding: _kPaddingLg),
          openAnimationDuration: _kAnim150,
        ),
      );
      const b = CorePopoverTheme(
        style: CorePopoverStyle(
          panelStyle: CorePopupStyle(padding: _kPaddingLg),
          openAnimationDuration: _kAnim150,
        ),
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });
  });
}
