// Filter draws no track or segment of its own — the segments are a composed
// `ToggleGroup`. What is pinned here is the Core half: the nested
// `toggleGroupStyle` slot with its empty default, the deprecated flat
// track / segment fields still reaching the group through
// `toggleGroupStyleFor`, and the hairline that parts the segments from the
// reset button.
//
// The deprecated fields are used on purpose.

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

void main() {
  group('CoreFilterStyle.toggleGroupStyleFor', () {
    test('states nothing of its own — the group keeps every default', () {
      expect(
        const CoreFilterStyle().toggleGroupStyleFor(),
        CoreFilterStyle.defaultToggleGroupStyle,
      );
      expect(
        CoreFilterStyle.defaultToggleGroupStyle,
        const CoreToggleGroupStyle(),
      );
    });

    test('the toggleGroupStyle slot is forwarded', () {
      const slot = CoreToggleGroupStyle(itemHeight: CoreSize.size40);
      expect(
        const CoreFilterStyle(toggleGroupStyle: slot).toggleGroupStyleFor(),
        slot,
      );
    });

    test('the deprecated flat fields fold in, and the slot wins', () {
      const style = CoreFilterStyle(
        itemHeight: CoreSize.size40,
        itemSpacing: CoreSpace.space4,
        toggleGroupStyle: CoreToggleGroupStyle(itemHeight: CoreSize.size48),
      );
      final folded = style.toggleGroupStyleFor();
      expect(folded.itemHeight, CoreSize.size48);
      expect(folded.itemSpacing, CoreSpace.space4);
    });

    test('the old label override reaches the chosen label too', () {
      const red = CoreTextStyle(color: CoreColor.fromRGB(255, 0, 0));
      const style = CoreFilterStyle(
        labelTextStyle: red,
      );
      final folded = style.toggleGroupStyleFor();
      expect(folded.labelTextStyle?.color, red.color);
      expect(folded.selectedLabelTextStyle?.color, red.color);
    });
  });

  group('CoreFilterStyle hairline', () {
    test('is a 1 px outline-variant line 16 long', () {
      expect(
        CoreFilterStyle.defaultDividerStyle.color,
        const CoreColor.token(CoreColors.outlineVariant),
      );
      expect(CoreFilterStyle.defaultDividerStyle.thickness, 1);
      expect(CoreFilterStyle.defaultDividerHeight, 16);
    });

    test('sits 6 from the last segment and 2 from the reset button', () {
      expect(CoreFilterStyle.defaultDividerLeadingSpacing, 6);
      expect(CoreFilterStyle.defaultTrailingSpacing, 2);
    });

    test('merge / copyWith / == carry the new fields', () {
      const a = CoreFilterStyle(
        dividerHeight: 12,
        dividerLeadingSpacing: 8,
        trailingSpacing: 4,
        dividerStyle: CoreDividerStyle(thickness: 2),
        toggleGroupStyle: CoreToggleGroupStyle(itemHeight: 40),
      );
      expect(const CoreFilterStyle().merge(a), a);
      expect(a.copyWith(dividerHeight: 8).dividerHeight, 8);
      expect(a == a.copyWith(trailingSpacing: 6), isFalse);
      expect(a == a.copyWith(dividerLeadingSpacing: 6), isFalse);
      expect(a.copyWith(dividerLeadingSpacing: 10).dividerLeadingSpacing, 10);
      expect(a.hashCode, a.copyWith().hashCode);
    });
  });

  group('CoreFilterStyle.disabledDividerColor', () {
    test('defaults to the disabledOutline token', () {
      expect(
        CoreFilterStyle.defaultDisabledDividerColor,
        const CoreColor.token(CoreColors.disabledOutline),
      );
    });

    test('merge / copyWith / == carry the field', () {
      const color = CoreColor.token(CoreColors.primary);
      const base = CoreFilterStyle();
      expect(
        base
            .merge(const CoreFilterStyle(disabledDividerColor: color))
            .disabledDividerColor,
        color,
      );
      expect(
        base.copyWith(disabledDividerColor: color).disabledDividerColor,
        color,
      );
      expect(const CoreFilterStyle(disabledDividerColor: color), isNot(base));
      expect(
        const CoreFilterStyle(disabledDividerColor: color).hashCode,
        isNot(base.hashCode),
      );
    });
  });
}
