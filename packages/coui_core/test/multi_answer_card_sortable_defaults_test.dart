import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

void main() {
  group('CoreMultiAnswerCardStyle defaults', () {
    test(
      'selecting never thickens the border, so the card height is fixed',
      () {
        expect(
          CoreMultiAnswerCardStyle.defaultSelectedBorderWidth,
          CoreMultiAnswerCardStyle.defaultBorderWidth,
        );
        expect(
          CoreMultiAnswerCardStyle.defaultBorderWidth,
          CoreStrokeWidth.stroke1,
        );
      },
    );

    test('the selected label keeps the resting line height', () {
      expect(
        CoreMultiAnswerCardStyle.defaultSelectedBodyTextStyle.lineHeight,
        CoreLineHeight.h150,
      );
    });

    test('the corner is the lg control row at 0.25', () {
      const radius = CoreMultiAnswerCardStyle.defaultBorderRadius;
      expect(
        radius.topLeft,
        CoreControlSize.heightLg * CoreControlSize.cornerRatio,
      );
    });

    test('state tokens', () {
      expect(
        CoreMultiAnswerCardStyle.defaultSelectedBackgroundColor,
        const CoreColor.token(CoreColors.primaryContainer),
      );
      expect(
        CoreMultiAnswerCardStyle.defaultBorderColor,
        const CoreColor.token(CoreColors.outlineVariant),
      );
      expect(
        CoreMultiAnswerCardStyle.defaultHoverBorderColor,
        const CoreColor.token(CoreColors.outline),
      );
      expect(
        CoreMultiAnswerCardStyle.defaultDisabledBackgroundColor,
        const CoreColor.token(CoreColors.disabledContainer),
      );
      expect(
        CoreMultiAnswerCardStyle.defaultDisabledBorderColor,
        const CoreColor.token(CoreColors.disabledOutline),
      );
    });

    test('merge / copyWith carry the new fields', () {
      const base = CoreMultiAnswerCardStyle(
        hoverBorderColor: CoreColor.token(CoreColors.primary),
      );
      final merged = base.merge(
        const CoreMultiAnswerCardStyle(
          checkboxGapStyle: CoreGapStyle(size: CoreSpace.space8),
        ),
      );
      expect(merged.hoverBorderColor, base.hoverBorderColor);
      expect(merged.checkboxGapStyle!.size, CoreSpace.space8);
      expect(merged, isNot(base));
      expect(merged.copyWith(), merged);
    });
  });

  group('CoreSortableStyle defaults', () {
    test('the row is the lg control row: 48 high, radius 12', () {
      expect(CoreSortableStyle.defaultItemMinHeight, CoreControlSize.heightLg);
      expect(
        CoreSortableStyle.defaultItemBorderRadius.topLeft,
        CoreControlSize.heightLg * CoreControlSize.cornerRatio,
      );
    });

    test('the padding is directional 12 / 0 / 8 / 0', () {
      const padding = CoreSortableStyle.defaultItemPadding;
      expect(padding.isDirectional, isTrue);
      expect(padding.start, CoreSpace.space12);
      expect(padding.end, CoreSpace.space8);
      expect(padding.top, 0);
      expect(padding.bottom, 0);
    });

    test('the handle is onSurfaceSubtle and the remove glyph is '
        'onSurfaceVariant', () {
      const subtle = CoreColor.token(CoreColors.onSurfaceSubtle);
      const variant = CoreColor.token(CoreColors.onSurfaceVariant);
      expect(CoreSortableStyle.defaultHandleColor, subtle);
      expect(CoreSortableStyle.defaultHandleStyle.foregroundColor, subtle);
      expect(
        CoreSortableStyle.defaultRemoveButtonStyle.foregroundColor,
        variant,
      );
    });

    test('the remove control is the sm control row, square', () {
      const style = CoreSortableStyle.defaultRemoveButtonStyle;
      expect(style.width, CoreControlSize.heightSm);
      expect(style.height, CoreControlSize.heightSm);
      expect(style.padding, CoreEdgeInsets.zero);
      expect(style.leadingIconStyle!.size, CoreIconSize.size16);
      expect(
        style.borderRadius!.topLeft,
        CoreControlSize.heightSm * CoreControlSize.cornerRatio,
      );
    });

    test('the disabled list uses the dedicated tokens', () {
      expect(
        CoreSortableStyle.defaultDisabledItemBackgroundColor,
        const CoreColor.token(CoreColors.disabledContainer),
      );
      expect(
        CoreSortableStyle.defaultDisabledItemBorderColor,
        const CoreColor.token(CoreColors.disabledOutline),
      );
      expect(
        CoreSortableStyle.defaultDisabledHandleColor,
        const CoreColor.token(CoreColors.disabledContent),
      );
    });

    test('merge / copyWith carry the new fields', () {
      const base = CoreSortableStyle(itemMinHeight: 56);
      final merged = base.merge(
        const CoreSortableStyle(
          itemBorderColor: CoreColor.token(CoreColors.outline),
        ),
      );
      expect(merged.itemMinHeight, 56);
      expect(merged.itemBorderColor, isNotNull);
      expect(merged, isNot(base));
      expect(merged.copyWith(), merged);
    });
  });
}
