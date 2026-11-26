// Tests for CoreDrawerStyle (Epic #1302 — Story #1310 Drawer).

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

const _kRadiusSm = CoreBorderRadius.all(4);
const _kRadiusLg = CoreBorderRadius.all(16);
const double _kWidthSm = 280;
const double _kWidthLg = 360;
const double _kHeightSm = 240;
const double _kHeightLg = 360;

const _kPadSm = CoreEdgeInsets.all(16);
const _kPadLg = CoreEdgeInsets.all(24);

const _kBgSurface = CoreColor.token(CoreColors.surface);
const _kBorderOutline = CoreColor.token(CoreColors.outline);
const _kBarrierScrim = CoreColor.token(CoreColors.scrim);
const _kBarrierOpaque = CoreColor.token(CoreColors.shadow);

const Duration _kAnim200 = Duration(milliseconds: 200);
const Duration _kAnim350 = Duration(milliseconds: 350);
const Duration _kAnim100 = Duration(milliseconds: 100);

const double _kFontTitle = 18;
const int _kWeightSemiBold = CoreFontWeight.semiBold;
const int _kWeightRegular = CoreFontWeight.regular;
const _kColorOnSurface = CoreColor.token(CoreColors.onSurface);

void main() {
  group('CoreDrawerStyle.merge', () {
    test('null other returns this', () {
      const a = CoreDrawerStyle(
        panelBackgroundColor: _kBgSurface,
        panelWidth: _kWidthSm,
      );
      expect(identical(a.merge(null), a), isTrue);
    });

    test('chain — design system → theme.style → widget', () {
      const designSystem = CoreDrawerStyle(
        panelBackgroundColor: _kBgSurface,
        panelBorderColor: _kBorderOutline,
        panelBorderRadius: _kRadiusSm,
        panelWidth: _kWidthSm,
        barrierColor: _kBarrierScrim,
        openAnimationDuration: _kAnim350,
        closeAnimationDuration: _kAnim200,
      );
      const themeStyle = CoreDrawerStyle(
        panelBorderRadius: _kRadiusLg,
      );
      const widgetStyle = CoreDrawerStyle(
        panelWidth: _kWidthLg,
        barrierColor: _kBarrierOpaque,
      );

      final effective = designSystem.merge(themeStyle).merge(widgetStyle);

      expect(effective.panelBackgroundColor, _kBgSurface);
      expect(effective.panelBorderColor, _kBorderOutline);
      expect(effective.panelBorderRadius, _kRadiusLg); // theme
      expect(effective.panelWidth, _kWidthLg); // widget
      expect(effective.barrierColor, _kBarrierOpaque); // widget
      expect(effective.openAnimationDuration, _kAnim350);
      expect(effective.closeAnimationDuration, _kAnim200);
    });

    test('right-most non-null wins on each field', () {
      const a = CoreDrawerStyle(
        panelBorderRadius: _kRadiusSm,
        panelWidth: _kWidthSm,
      );
      const b = CoreDrawerStyle(panelBorderRadius: _kRadiusLg);
      const c = CoreDrawerStyle(panelWidth: _kWidthLg);

      final result = a.merge(b).merge(c);

      expect(result.panelBorderRadius, _kRadiusLg);
      expect(result.panelWidth, _kWidthLg);
    });

    test('panelHeight / open + close anim merge', () {
      const base = CoreDrawerStyle(
        panelHeight: _kHeightSm,
        openAnimationDuration: _kAnim350,
        closeAnimationDuration: _kAnim200,
      );
      const override = CoreDrawerStyle(
        panelHeight: _kHeightLg,
        closeAnimationDuration: _kAnim100,
      );
      final merged = base.merge(override);
      expect(merged.panelHeight, _kHeightLg);
      expect(merged.openAnimationDuration, _kAnim350);
      expect(merged.closeAnimationDuration, _kAnim100);
    });

    test('barrierOpacity merges and defaults to the modal scrim', () {
      const base = CoreDrawerStyle(barrierOpacity: 0.4);
      const override = CoreDrawerStyle(barrierOpacity: 0.6);
      expect(base.merge(override).barrierOpacity, 0.6);
      expect(base.merge(null).barrierOpacity, 0.4);
      expect(CoreDrawerStyle.defaultBarrierOpacity, CoreOpacity.scrim);
    });

    test('panelPadding / panelBoxShadow merge', () {
      const base = CoreDrawerStyle(
        panelPadding: _kPadSm,
        panelBoxShadow: CoreShadow.md,
      );
      const override = CoreDrawerStyle(panelPadding: _kPadLg);
      final merged = base.merge(override);
      expect(merged.panelPadding, _kPadLg);
      expect(merged.panelBoxShadow, CoreShadow.md);
    });
  });

  group('CoreDrawerStyle defaults', () {
    test('static const defaults reference drawer tokens', () {
      expect(
        CoreDrawerStyle.defaultPanelBackgroundColor,
        const CoreColor.token(CoreColors.surfaceBright),
      );
      expect(
        CoreDrawerStyle.defaultPanelBorderColor,
        const CoreColor.token(CoreColors.outlineVariant),
      );
      expect(
        CoreDrawerStyle.defaultBarrierColor,
        const CoreColor.token(CoreColors.scrim),
      );
      expect(
        CoreDrawerStyle.defaultPanelBorderRadius,
        const CoreBorderRadius.all(CoreRadius.radius16),
      );
      expect(
        CoreDrawerStyle.defaultPanelPadding,
        const CoreEdgeInsets.symmetric(
          horizontal: CoreSpace.space24,
          vertical: CoreSpace.space20,
        ),
      );
      expect(CoreDrawerStyle.defaultPanelBoxShadow, isEmpty);
      expect(
        CoreDrawerStyle.defaultOpenAnimationDuration,
        const Duration(milliseconds: CoreDuration.ms350),
      );
      // The flat close-button chrome (border radius / idle + hover
      // opacity) moved into the nested `defaultCloseButtonStyle`
      // (a `CoreButtonStyle`) when the close affordance migrated to
      // `Button(variant: .plain)`.
      expect(
        CoreDrawerStyle.defaultCloseButtonStyle,
        isA<CoreButtonStyle>(),
      );
    });

    test('titleStyle merges recursively (subset override)', () {
      const base = CoreDrawerStyle(
        titleStyle: CoreTextStyle(
          fontSize: _kFontTitle,
          fontWeight: _kWeightSemiBold,
          color: _kColorOnSurface,
        ),
      );
      const override = CoreDrawerStyle(
        titleStyle: CoreTextStyle(fontWeight: _kWeightRegular),
      );
      final merged = base.merge(override);
      expect(merged.titleStyle?.fontSize, _kFontTitle);
      expect(merged.titleStyle?.fontWeight, _kWeightRegular);
      expect(merged.titleStyle?.color, _kColorOnSurface);
    });

    test('null nested style on base inherits from override', () {
      const base = CoreDrawerStyle();
      const override = CoreDrawerStyle(
        titleStyle: CoreTextStyle(fontSize: _kFontTitle),
      );
      final merged = base.merge(override);
      expect(merged.titleStyle?.fontSize, _kFontTitle);
    });
  });

  group('CoreDrawerStyle equality', () {
    test('same fields → equal', () {
      const a = CoreDrawerStyle(
        panelBackgroundColor: _kBgSurface,
        panelWidth: _kWidthSm,
        barrierColor: _kBarrierScrim,
      );
      const b = CoreDrawerStyle(
        panelBackgroundColor: _kBgSurface,
        panelWidth: _kWidthSm,
        barrierColor: _kBarrierScrim,
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('different barrierColor → not equal', () {
      const a = CoreDrawerStyle(barrierColor: _kBarrierScrim);
      const b = CoreDrawerStyle(barrierColor: _kBarrierOpaque);
      expect(a, isNot(equals(b)));
    });

    test('different titleStyle → not equal', () {
      const a = CoreDrawerStyle(
        titleStyle: CoreTextStyle(fontSize: _kFontTitle),
      );
      const b = CoreDrawerStyle(
        titleStyle: CoreTextStyle(fontSize: _kFontTitle * 1.25),
      );
      expect(a, isNot(equals(b)));
    });
  });

  group('CoreDrawerStyle.copyWith', () {
    test('only-supplied fields override', () {
      const base = CoreDrawerStyle(
        panelBackgroundColor: _kBgSurface,
        panelWidth: _kWidthSm,
        barrierColor: _kBarrierScrim,
      );
      final copy = base.copyWith(panelWidth: _kWidthLg);
      expect(copy.panelBackgroundColor, _kBgSurface);
      expect(copy.panelWidth, _kWidthLg);
      expect(copy.barrierColor, _kBarrierScrim);
    });

    test('preserves nested titleStyle when not specified', () {
      const base = CoreDrawerStyle(
        titleStyle: CoreTextStyle(fontSize: _kFontTitle),
      );
      final copy = base.copyWith(panelWidth: _kWidthLg);
      expect(copy.panelWidth, _kWidthLg);
      expect(copy.titleStyle?.fontSize, _kFontTitle);
    });
  });

  group('CoreDrawerTheme', () {
    test('style passes through', () {
      const style = CoreDrawerStyle(panelWidth: _kWidthLg);
      const theme = CoreDrawerTheme(style: style);
      expect(theme.style, style);
    });

    test('null style', () {
      const theme = CoreDrawerTheme();
      expect(theme.style, isNull);
    });

    test('equality', () {
      const a = CoreDrawerTheme(
        style: CoreDrawerStyle(panelWidth: _kWidthLg),
      );
      const b = CoreDrawerTheme(
        style: CoreDrawerStyle(panelWidth: _kWidthLg),
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });
  });

  group('CoreDrawerStyle sheet parts', () {
    const handleColor = CoreColor.token(CoreColors.outlineVariant);

    test('defaults draw the bottom-sheet header and the swiper handle', () {
      // Description: the supporting-text tier the kit's other descriptions
      // use. Handle: the pill the Swiper drew before the drawer owned it,
      // so a Swiper looks the same.
      expect(
        CoreDrawerStyle.defaultDescriptionStyle,
        const CoreTextStyle.token(
          CoreTextStyles.bodySmall,
          color: CoreColor.token(CoreColors.onSurfaceVariant),
        ),
      );
      expect(
        CoreDrawerStyle.defaultTitleDescriptionGapStyle,
        const CoreGapStyle(size: CoreSpace.space4),
      );
      expect(
        CoreDrawerStyle.defaultDragHandleColor,
        const CoreColor.token(CoreColors.surfaceContainer),
      );
      expect(CoreDrawerStyle.defaultDragHandleWidth, CoreSize.size48);
      expect(CoreDrawerStyle.defaultDragHandleThickness, CoreSize.size6);
      expect(CoreDrawerStyle.defaultDragHandleInset, CoreSpace.space8);
      expect(
        CoreDrawerStyle.defaultDragHandleBorderRadius,
        const CoreBorderRadius.all(CoreRadius.radius9999),
      );
    });

    test('merge — handle fields: right-most non-null wins', () {
      const base = CoreDrawerStyle(
        dragHandleColor: handleColor,
        dragHandleWidth: 40,
        dragHandleThickness: 4,
        dragHandleInset: 12,
        dragHandleBorderRadius: _kRadiusSm,
      );
      const override = CoreDrawerStyle(dragHandleWidth: 56);
      final merged = base.merge(override);

      expect(merged.dragHandleWidth, 56);
      expect(merged.dragHandleColor, handleColor);
      expect(merged.dragHandleThickness, 4);
      expect(merged.dragHandleInset, 12);
      expect(merged.dragHandleBorderRadius, _kRadiusSm);
    });

    test('merge — description and its gap merge recursively', () {
      const base = CoreDrawerStyle(
        descriptionStyle: CoreTextStyle(fontWeight: _kWeightRegular),
        titleDescriptionGapStyle: CoreGapStyle(size: CoreSpace.space8),
      );
      const override = CoreDrawerStyle(
        descriptionStyle: CoreTextStyle(color: _kColorOnSurface),
      );
      final merged = base.merge(override);

      expect(merged.descriptionStyle?.fontWeight, _kWeightRegular);
      expect(merged.descriptionStyle?.color, _kColorOnSurface);
      expect(
        merged.titleDescriptionGapStyle,
        const CoreGapStyle(size: CoreSpace.space8),
      );
    });

    test('every new field takes part in equality and hashCode', () {
      const reference = CoreDrawerStyle();
      const variants = <CoreDrawerStyle>[
        CoreDrawerStyle(
          descriptionStyle: CoreTextStyle(fontWeight: _kWeightSemiBold),
        ),
        CoreDrawerStyle(
          titleDescriptionGapStyle: CoreGapStyle(size: CoreSpace.space8),
        ),
        CoreDrawerStyle(dragHandleColor: handleColor),
        CoreDrawerStyle(dragHandleWidth: 40),
        CoreDrawerStyle(dragHandleThickness: 4),
        CoreDrawerStyle(dragHandleInset: 12),
        CoreDrawerStyle(dragHandleBorderRadius: _kRadiusSm),
      ];
      for (final variant in variants) {
        expect(variant, isNot(equals(reference)));
        expect(variant, equals(variant.copyWith()));
        expect(variant.hashCode, variant.copyWith().hashCode);
      }
    });

    test('copyWith carries every new field', () {
      final copy = const CoreDrawerStyle().copyWith(
        descriptionStyle: const CoreTextStyle(fontWeight: _kWeightSemiBold),
        titleDescriptionGapStyle: const CoreGapStyle(size: CoreSpace.space8),
        dragHandleColor: handleColor,
        dragHandleWidth: 40,
        dragHandleThickness: 4,
        dragHandleInset: 12,
        dragHandleBorderRadius: _kRadiusLg,
      );

      expect(copy.descriptionStyle?.fontWeight, _kWeightSemiBold);
      expect(
        copy.titleDescriptionGapStyle,
        const CoreGapStyle(size: CoreSpace.space8),
      );
      expect(copy.dragHandleColor, handleColor);
      expect(copy.dragHandleWidth, 40);
      expect(copy.dragHandleThickness, 4);
      expect(copy.dragHandleInset, 12);
      expect(copy.dragHandleBorderRadius, _kRadiusLg);
    });
  });

  group('CoreDrawerStyle side panel redesign', () {
    test('a side panel is 400 wide, square, with a 1px inner line', () {
      expect(CoreDrawerStyle.defaultPanelWidth, 400);
      expect(
        CoreDrawerStyle.defaultSidePanelBorderRadius,
        CoreBorderRadius.zero,
      );
      expect(CoreDrawerStyle.defaultPanelBorderWidth, CoreStrokeWidth.stroke1);
    });

    test('a top / bottom sheet keeps its 16 corner and has no line', () {
      expect(
        CoreDrawerStyle.defaultPanelBorderRadius,
        const CoreBorderRadius.all(CoreRadius.radius16),
      );
      expect(CoreDrawerStyle.defaultSheetPanelBorderWidth, 0);
    });

    test('header is 24 above and at the sides, 16 below, 16 to the close', () {
      expect(
        CoreDrawerStyle.defaultHeaderPadding,
        const CoreEdgeInsets.only(
          left: CoreSpace.space24,
          top: CoreSpace.space24,
          right: CoreSpace.space24,
          bottom: CoreSpace.space16,
        ),
      );
      expect(CoreDrawerStyle.defaultHeaderSpacing, CoreSpace.space16);
    });

    test('footer row is 16 above and below, 24 at the sides', () {
      expect(
        CoreDrawerStyle.defaultFooterPadding,
        const CoreEdgeInsets.symmetric(
          horizontal: CoreSpace.space24,
          vertical: CoreSpace.space16,
        ),
      );
    });

    test('close button is the sm row square, no padding, radius 8', () {
      const close = CoreDrawerStyle.defaultCloseButtonStyle;
      expect(close.width, CoreControlSize.heightSm);
      expect(close.height, CoreControlSize.heightSm);
      expect(close.padding, CoreEdgeInsets.zero);
      expect(
        close.borderRadius,
        const CoreBorderRadius.all(CoreRadius.radius8),
      );
    });

    test('headerSpacing and footerPadding merge, copy and compare', () {
      const a = CoreDrawerStyle(headerSpacing: 8);
      const b = CoreDrawerStyle(footerPadding: CoreEdgeInsets.zero);
      final merged = a.merge(b);
      expect(merged.headerSpacing, 8);
      expect(merged.footerPadding, CoreEdgeInsets.zero);
      expect(merged.copyWith(headerSpacing: 4).headerSpacing, 4);
      expect(a == const CoreDrawerStyle(headerSpacing: 8), isTrue);
      expect(a == const CoreDrawerStyle(headerSpacing: 4), isFalse);
      expect(
        a.hashCode == const CoreDrawerStyle(headerSpacing: 8).hashCode,
        isTrue,
      );
    });
  });
}
