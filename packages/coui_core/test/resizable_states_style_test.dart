import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

void main() {
  group('CoreResizableStyle divider states', () {
    test('the resting line is a 1px outlineVariant line', () {
      expect(
        CoreResizableStyle.defaultDividerThickness,
        CoreStrokeWidth.stroke1,
      );
      expect(
        CoreResizableStyle.defaultDividerColor,
        const CoreColor.token(CoreColors.outlineVariant),
      );
    });

    test('hover is the outline line', () {
      expect(
        CoreResizableStyle.defaultDividerHoverColor,
        const CoreColor.token(CoreColors.outline),
      );
    });

    test('dragging is a heavier primary line; the grab area stays 8', () {
      expect(
        CoreResizableStyle.defaultDividerDraggingThickness,
        CoreStrokeWidth.stroke2,
      );
      expect(
        CoreResizableStyle.defaultDividerDraggingColor,
        const CoreColor.token(CoreColors.primary),
      );
      expect(CoreResizableStyle.defaultDividerHitExtent, CoreSpace.space8);
    });

    test('the new fields merge, copy and compare', () {
      const base = CoreResizableStyle(dividerDraggingThickness: 3);
      const other = CoreResizableStyle(
        dividerDraggingColor: CoreColor.token(CoreColors.error),
        focusOutlineStyle: CoreFocusOutlineStyle(borderWidth: 3),
      );
      final merged = base.merge(other);
      expect(merged.dividerDraggingThickness, 3);
      expect(merged.dividerDraggingColor, other.dividerDraggingColor);
      expect(merged.focusOutlineStyle, other.focusOutlineStyle);
      expect(merged.copyWith(dividerDraggingThickness: 4), isNot(merged));
      expect(merged, base.merge(other));
      expect(merged.hashCode, base.merge(other).hashCode);
    });
  });
}
