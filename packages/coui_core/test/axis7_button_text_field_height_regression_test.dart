// Regression net for Epic K (#3767) axis 7 — cross-component invariant
// (epic-k-dimension-table.md §축7).
//
// The Input Height spec (§1.2) declares the equation
// `button-height-{size} == input-height-{size} == dropdown-height-{size}`
// as specification text, not an incidental observation — axis 1 (#3881,
// Button) and axis 3 (#3883, TextField) both landed their confirmed
// per-size values, so `CoreButtonStyle.defaultsBySize`'s `height` and
// `CoreTextFieldStyle.defaultsBySize`'s `minHeight` (the field's floor —
// it still grows past it when padding + line box are taller) must be
// byte-identical for every `CoreComponentSize` member.
//
// This file guards that equation directly so a future edit to either
// map alone (rather than both, in lockstep) fails a test instead of
// landing as a silent divergence.
import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

void main() {
  group('Axis 7 — Button/TextField height invariant (#3767 §축7)', () {
    test(
      'CoreButtonStyle and CoreTextFieldStyle agree on height per size',
      () {
        for (final size in CoreComponentSize.values) {
          final buttonEntry = CoreButtonStyle.defaultsBySize[size]!;
          final textFieldEntry = CoreTextFieldStyle.defaultsBySize[size]!;

          expect(
            buttonEntry.height,
            textFieldEntry.minHeight,
            reason:
                'Button/TextField height must stay byte-identical per '
                'input-height spec §1.2 (button-height-${size.name} == '
                'input-height-${size.name}) — '
                'epic-k-dimension-table.md §축7',
          );
        }
      },
    );

    test('row-aligned control heights come from CoreControlSize', () {
      // The alignment contract's single source is the semantic layer
      // (CoUI_Size_Token_Specification §2-1) — participating
      // `defaultsBySize` maps must resolve to the CoreControlSize
      // member for their tier, so one map cannot drift without the
      // contract (and this test) moving with it.
      const controlHeights = {
        CoreComponentSize.xs: CoreControlSize.heightXs,
        CoreComponentSize.sm: CoreControlSize.heightSm,
        CoreComponentSize.md: CoreControlSize.heightMd,
        CoreComponentSize.lg: CoreControlSize.heightLg,
        CoreComponentSize.xl: CoreControlSize.heightXl,
        CoreComponentSize.xl2: CoreControlSize.heightXl2,
      };

      for (final size in CoreComponentSize.values) {
        expect(
          CoreButtonStyle.defaultsBySize[size]!.height,
          controlHeights[size],
          reason:
              'Button height for ${size.name} must be '
              'CoreControlSize.height* (semantic alignment contract)',
        );
        expect(
          CoreTextFieldStyle.defaultsBySize[size]!.minHeight,
          controlHeights[size],
          reason:
              'TextField minHeight for ${size.name} must be '
              'CoreControlSize.height* (semantic alignment contract)',
        );
      }
    });
  });
}
