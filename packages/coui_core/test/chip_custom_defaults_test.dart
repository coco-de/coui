// The `custom` seed variant's disabled defaults, held against the table
// every other Chip variant uses.
//
// `custom` has no per-variant table row — its colours come from a seed the
// caller supplies — so its disabled fallback is written out as three named
// defaults instead. Those three drifted: they named surface tones while
// their own doc comments said they matched the per-variant tokens. Nothing
// compared the two, so the comment stayed true-sounding and false.
//
// `surfaceContainerHigh` on `surfaceContainer` is two adjacent steps of one
// ramp — 1.15:1 light, 1.29:1 dark. A disabled label is exempt from the
// contrast floor, but exempt is not the same as legible: a chip whose label
// has vanished does not read as disabled, it reads as broken.
import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

/// A representative table row. Every variant states the same disabled
/// tokens, so any one of them answers "what does Chip use".
const _tableRow = CoreChipColor.primary;

void main() {
  group('CoreChipStyle custom-seed disabled defaults', () {
    test('name the same tokens the per-variant table names', () {
      final table = CoreChipStyle.defaultsByColor[_tableRow]!;

      // Disabled is two rows since the redesign. The custom default is the
      // SELECTED row's fill (the container that keeps a selection legible);
      // the unselected row's surface is a shared default both branches read.
      expect(
        CoreChipStyle.defaultCustomDisabledBackgroundColor,
        table.disabledSelectedBg,
      );
      expect(
        CoreChipStyle.defaultCustomDisabledUnselectedBackgroundColor,
        table.disabledBg,
      );
      expect(
        CoreChipStyle.defaultCustomDisabledForegroundColor,
        table.disabledFg,
      );
      expect(
        CoreChipStyle.defaultCustomDisabledBorderColor,
        table.disabledBorderColor,
      );
    });

    test('and are not two adjacent steps of the surface ramp', () {
      // The specific shape of the defect, pinned separately: equality with
      // the table would still pass if the table itself were changed to
      // surface tones. This says what must never be true regardless.
      final surfaceRamp = {
        CoreColors.surface,
        CoreColors.surfaceDim,
        CoreColors.surfaceBright,
        CoreColors.surfaceContainerLowest,
        CoreColors.surfaceContainerLow,
        CoreColors.surfaceContainer,
        CoreColors.surfaceContainerHigh,
        CoreColors.surfaceContainerHighest,
      };

      final fg = CoreChipStyle.defaultCustomDisabledForegroundColor.token;
      final bg = CoreChipStyle.defaultCustomDisabledBackgroundColor.token;

      expect(
        surfaceRamp.contains(fg) && surfaceRamp.contains(bg),
        isFalse,
        reason:
            'a foreground and a background from the same surface ramp are '
            'a step apart, not a contrast',
      );
    });
  });
}
