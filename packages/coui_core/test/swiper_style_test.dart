// Tests for CoreSwiperStyle.

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

const _kHandleColor = CoreColor.token(CoreColors.primary);
const _kDrawerOverride = CoreDrawerStyle(panelBorderWidth: 2);

void main() {
  group('CoreSwiperStyle', () {
    test('default constructor leaves every field null', () {
      const style = CoreSwiperStyle();
      expect(style.drawerStyle, isNull);
      expect(style.dragHandleColor, isNull);
      expect(style.dragHandleWidth, isNull);
      expect(style.dragHandleThickness, isNull);
      expect(style.dragHandleInset, isNull);
      expect(style.dragHandleBorderRadius, isNull);
    });

    test('static const defaults expose design-system values', () {
      expect(CoreSwiperStyle.defaultDragHandleWidth, CoreSpace.space48);
      expect(CoreSwiperStyle.defaultDragHandleThickness, CoreSpace.space6);
      expect(CoreSwiperStyle.defaultDragHandleInset, CoreSpace.space8);
      expect(
        CoreSwiperStyle.defaultDragHandleBorderRadius,
        const CoreBorderRadius.all(CoreRadius.radius9999),
      );
    });

    test(
      'defaultsByVariant — drawer zooms the backdrop out, sheet strips chrome',
      () {
        final drawer =
            CoreSwiperStyle.defaultsByVariant[CoreSwiperVariant.drawer];
        final sheet =
            CoreSwiperStyle.defaultsByVariant[CoreSwiperVariant.sheet];
        expect(
          drawer,
          const CoreDrawerStyle(
            backdropScale: CoreDrawerStyle.zoomBackdropScale,
            backdropCornerRadius: CoreDrawerStyle.zoomBackdropCornerRadius,
          ),
        );
        // The drawer itself has no zoom-out unless a style asks for it.
        expect(CoreDrawerStyle.defaultBackdropScale, 1.0);
        expect(
          CoreDrawerStyle.defaultBackdropCornerRadius,
          CoreBorderRadius.zero,
        );
        expect(sheet!.panelBoxShadow, isEmpty);
        expect(sheet.panelBorderWidth, 0);
        expect(sheet.panelBorderRadius, CoreBorderRadius.zero);
      },
    );

    test('merge prefers non-null fields and merges the nested slot', () {
      const base = CoreSwiperStyle(
        drawerStyle: CoreDrawerStyle(panelWidth: 320),
        dragHandleWidth: 40,
      );
      const override = CoreSwiperStyle(
        drawerStyle: _kDrawerOverride,
        dragHandleColor: _kHandleColor,
      );
      final merged = base.merge(override);
      // Nested slot merges recursively — both sub-fields survive.
      expect(merged.drawerStyle!.panelWidth, 320);
      expect(merged.drawerStyle!.panelBorderWidth, 2);
      expect(merged.dragHandleWidth, 40);
      expect(merged.dragHandleColor, _kHandleColor);
    });

    test('merge with null returns same style', () {
      const a = CoreSwiperStyle(dragHandleWidth: 40);
      expect(a.merge(null), same(a));
    });

    test('copyWith overrides only supplied fields', () {
      const a = CoreSwiperStyle(dragHandleWidth: 40, dragHandleInset: 4);
      final copy = a.copyWith(dragHandleWidth: 56);
      expect(copy.dragHandleWidth, 56);
      expect(copy.dragHandleInset, 4);
    });

    test('equality and hashCode include every field', () {
      const a = CoreSwiperStyle(
        drawerStyle: _kDrawerOverride,
        dragHandleColor: _kHandleColor,
        dragHandleWidth: 40,
      );
      const b = CoreSwiperStyle(
        drawerStyle: _kDrawerOverride,
        dragHandleColor: _kHandleColor,
        dragHandleWidth: 40,
      );
      const c = CoreSwiperStyle(dragHandleWidth: 40);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(equals(c)));
    });

    test('the deprecated handle fields fold into the drawer style', () {
      const swiper = CoreSwiperStyle(
        dragHandleColor: _kHandleColor,
        dragHandleWidth: 40,
        dragHandleThickness: 4,
        dragHandleInset: 12,
        dragHandleBorderRadius: CoreBorderRadius.all(CoreRadius.radius4),
      );

      expect(
        swiper.legacyDragHandleStyle,
        const CoreDrawerStyle(
          dragHandleColor: _kHandleColor,
          dragHandleWidth: 40,
          dragHandleThickness: 4,
          dragHandleInset: 12,
          dragHandleBorderRadius: CoreBorderRadius.all(CoreRadius.radius4),
        ),
      );
      expect(
        const CoreSwiperStyle().legacyDragHandleStyle,
        const CoreDrawerStyle(),
        reason: 'nothing stated the old way → nothing folds in',
      );
    });

    test('the deprecated defaults are the drawer handle defaults', () {
      // The handle moved to the drawer; a Swiper looks the same because
      // the values did not change on the way.
      expect(
        CoreSwiperStyle.defaultDragHandleColor,
        CoreDrawerStyle.defaultDragHandleColor,
      );
      expect(
        CoreSwiperStyle.defaultDragHandleWidth,
        CoreDrawerStyle.defaultDragHandleWidth,
      );
      expect(
        CoreSwiperStyle.defaultDragHandleThickness,
        CoreDrawerStyle.defaultDragHandleThickness,
      );
      expect(
        CoreSwiperStyle.defaultDragHandleInset,
        CoreDrawerStyle.defaultDragHandleInset,
      );
      expect(
        CoreSwiperStyle.defaultDragHandleBorderRadius,
        CoreDrawerStyle.defaultDragHandleBorderRadius,
      );
    });
  });
}
