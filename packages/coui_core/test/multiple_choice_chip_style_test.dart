// MultipleChoice draws no option box of its own — each option is a composed
// `Chip`. What is pinned here is the Core half of that: the nested
// `chipStyle` slot with its partial default, and the deprecated flat option
// fields still reaching the chip through `chipStyleFor` (so an existing
// override keeps taking effect for the version they are kept).
//
// The deprecated fields are used on purpose.

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

const CoreColor _red = CoreColor(0xFFFF0000);
const CoreColor _green = CoreColor(0xFF00FF00);
const CoreColor _blue = CoreColor(0xFF0000FF);

void main() {
  group('CoreMultipleChoiceStyle — composed Chip slot', () {
    test('the default states only the 32 row; the chip fills the rest', () {
      const base = CoreMultipleChoiceStyle.defaultChipStyle;
      expect(base.minHeight, CoreSize.size32);
      // Nothing else is restated — that would copy the Chip's own defaults.
      expect(base.copyWith(minHeight: 0), isNot(base));
      expect(base.backgroundColor, isNull);
      expect(base.borderColor, isNull);
      expect(base.labelStyle, isNull);
      expect(base.padding, isNull);
      expect(base.borderRadius, isNull);
    });

    test('options sit 8 apart', () {
      expect(CoreMultipleChoiceStyle.defaultOptionSpacing, CoreSpace.space8);
    });

    test('an unstated style hands the chip the partial default untouched', () {
      const style = CoreMultipleChoiceStyle();
      for (final selected in [true, false]) {
        for (final enabled in [true, false]) {
          expect(
            style.chipStyleFor(selected: selected, enabled: enabled),
            CoreMultipleChoiceStyle.defaultChipStyle,
          );
        }
      }
    });

    test('chipStyle overrides ride on top of the default', () {
      const style = CoreMultipleChoiceStyle(
        chipStyle: CoreChipStyle(backgroundColor: _red),
      );
      final chip = style.chipStyleFor(selected: false, enabled: true);
      expect(chip.backgroundColor, _red);
      expect(chip.minHeight, CoreSize.size32);
    });

    test('merge folds chipStyle recursively', () {
      const a = CoreMultipleChoiceStyle(
        chipStyle: CoreChipStyle(backgroundColor: _red),
      );
      const b = CoreMultipleChoiceStyle(
        chipStyle: CoreChipStyle(borderColor: _green),
      );
      final merged = a.merge(b);
      expect(merged.chipStyle?.backgroundColor, _red);
      expect(merged.chipStyle?.borderColor, _green);
    });

    test('chipStyle takes part in ==, hashCode and copyWith', () {
      const a = CoreMultipleChoiceStyle(
        chipStyle: CoreChipStyle(backgroundColor: _red),
      );
      const b = CoreMultipleChoiceStyle(
        chipStyle: CoreChipStyle(backgroundColor: _red),
      );
      const c = CoreMultipleChoiceStyle(
        chipStyle: CoreChipStyle(backgroundColor: _green),
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
      expect(
        const CoreMultipleChoiceStyle().copyWith(chipStyle: a.chipStyle),
        a,
      );
    });
  });

  group('deprecated flat option fields — pass-through to the chip', () {
    const style = CoreMultipleChoiceStyle(
      optionPadding: CoreEdgeInsets.all(CoreSpace.space4),
      optionBorderRadius: CoreBorderRadius.all(CoreRadius.radius4),
      optionBorderWidth: CoreStrokeWidth.stroke2,
      selectedBackgroundColor: _red,
      selectedBorderColor: _green,
      unselectedBackgroundColor: _blue,
      unselectedBorderColor: _red,
      selectedTextStyle: CoreTextStyle(color: _green),
      unselectedTextStyle: CoreTextStyle(color: _blue),
      disabledTextStyle: CoreTextStyle(color: _red),
    );

    test('box fields reach the chip in every state', () {
      for (final selected in [true, false]) {
        final chip = style.chipStyleFor(selected: selected, enabled: true);
        expect(chip.padding, const CoreEdgeInsets.all(CoreSpace.space4));
        expect(
          chip.borderRadius,
          const CoreBorderRadius.all(CoreRadius.radius4),
        );
        expect(chip.borderWidth, CoreStrokeWidth.stroke2);
        expect(chip.minHeight, CoreSize.size32);
      }
    });

    test('the selected pair feeds a selected chip only', () {
      final chip = style.chipStyleFor(selected: true, enabled: true);
      expect(chip.backgroundColor, _red);
      expect(chip.borderColor, _green);
      expect(chip.labelStyle?.color, _green);
    });

    test('the unselected pair feeds an unselected chip only', () {
      final chip = style.chipStyleFor(selected: false, enabled: true);
      expect(chip.backgroundColor, _blue);
      expect(chip.borderColor, _red);
      expect(chip.labelStyle?.color, _blue);
    });

    test('disabled label wins over selected / unselected, fills keep', () {
      final selected = style.chipStyleFor(selected: true, enabled: false);
      final unselected = style.chipStyleFor(selected: false, enabled: false);
      expect(selected.labelStyle?.color, _red);
      expect(unselected.labelStyle?.color, _red);
      expect(selected.backgroundColor, _red);
      expect(unselected.backgroundColor, _blue);
    });

    test('the new chipStyle slot wins over a deprecated flat field', () {
      final both = style.copyWith(
        chipStyle: const CoreChipStyle(backgroundColor: _green),
      );
      expect(
        both.chipStyleFor(selected: true, enabled: true).backgroundColor,
        _green,
      );
    });
  });
}
