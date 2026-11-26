// The state-layer ramp, and the one invariant that makes it a ramp.
//
// Three weights carried as three separate fields could state a focus
// weaker than its hover and nothing would notice. The failure does not
// look like a wrong number — it looks like hovering a focused control
// doing nothing, which reads as the control ignoring the pointer.
//
// The tiers are measured, not chosen here: `subtle` is what the library
// canvas paints on `TextField`, `Chip`, `Toggle` and the OTP cell
// (`NavigationBar` takes its hover and focus weights from it and states its
// own pressed weight — pinned in
// `navigation_bar_state_change_perceptibility_test`). `strong` is the
// heavier ramp the filled controls take, and the canvas does not paint it —
// its filled controls keep their layer node hidden in every state — so that
// half is pinned against the decision record rather than against the
// canvas.
import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

void main() {
  group('a ramp only ever gets stronger', () {
    for (final (name, ramp) in [
      ('subtle', CoreStateLayer.subtle),
      ('strong', CoreStateLayer.strong),
    ]) {
      test('$name ascends', () {
        expect(
          ramp.isAscending,
          isTrue,
          reason:
              'hover ${ramp.hover} → focus ${ramp.focus} → pressed '
              '${ramp.pressed} goes backwards somewhere',
        );
      });
    }

    test('and a descending one is caught', () {
      // The predicate is only worth having if it can say no.
      const backwards = CoreStateLayer(hover: 0.12, focus: 0.03, pressed: 0.16);

      expect(backwards.isAscending, isFalse);
    });
  });

  group('the tiers are the measured values', () {
    test('subtle is 3 / 8 / 12', () {
      expect(
        [
          CoreStateLayer.subtle.hover,
          CoreStateLayer.subtle.focus,
          CoreStateLayer.subtle.pressed,
        ],
        [0.03, 0.08, 0.12],
      );
    });

    test('strong is 8 / 12 / 16', () {
      expect(
        [
          CoreStateLayer.strong.hover,
          CoreStateLayer.strong.focus,
          CoreStateLayer.strong.pressed,
        ],
        [0.08, 0.12, 0.16],
      );
    });

    test('strong is heavier than subtle at every step', () {
      // The reason there are two: the same alpha moves a light surface
      // further than a dark one. If the tiers ever met, the split would
      // have stopped meaning anything while still costing a decision at
      // every variant.
      expect(
        CoreStateLayer.strong.hover,
        greaterThan(CoreStateLayer.subtle.hover),
      );
      expect(
        CoreStateLayer.strong.focus,
        greaterThan(CoreStateLayer.subtle.focus),
      );
      expect(
        CoreStateLayer.strong.pressed,
        greaterThan(CoreStateLayer.subtle.pressed),
      );
    });
  });

  group('Button reads the shared ramps, not numbers of its own', () {
    CoreButtonVariantStyle row(CoreButtonVariant v) =>
        CoreButtonStyle.defaultsByVariant[v]!;

    test('filled variants swap their container instead of washing it', () {
      // The saturated fills (`primary`, `destructive`) are off the ramp:
      // hover and pressed are opaque scheme steps (`primaryHover` /
      // `primaryPressed`, `errorStrong` / `errorPressed`), so the row
      // states NO layer — a wash over an already-swapped fill would darken
      // twice, and on Web the `color-mix()` rule would hide the swapped
      // class by specificity. The two halves are one contract: no layer,
      // AND a different opaque colour per step, else the button stops
      // responding.
      for (final v in [
        CoreButtonVariant.primary,
        CoreButtonVariant.destructive,
      ]) {
        final r = row(v);
        expect(r.stateLayer, isNull, reason: '${v.name} carries a wash');
        expect(
          r.hoverBackgroundColor,
          isNot(r.backgroundColor),
          reason: '${v.name} hover is the resting fill and has no wash',
        );
        expect(
          r.pressedBackgroundColor,
          allOf(isNotNull, isNot(r.hoverBackgroundColor)),
          reason: '${v.name} pressed is not a step beyond hover',
        );
      }
    });

    test('tonal and unfilled variants take the subtle one', () {
      // `secondary` is a pale container: a wash of its own ink reads over
      // it, and the fill itself stays put (hover = rest). The saturated
      // fills above cannot do this — no overlay at any opacity turns a red
      // panel into a darker red.
      for (final v in [
        CoreButtonVariant.secondary,
        CoreButtonVariant.tonal,
        CoreButtonVariant.outline,
        CoreButtonVariant.ghost,
      ]) {
        expect(row(v).stateLayer, CoreStateLayer.subtle, reason: v.name);
      }
      for (final v in [CoreButtonVariant.secondary, CoreButtonVariant.tonal]) {
        final r = row(v);
        expect(r.hoverBackgroundColor, r.backgroundColor, reason: v.name);
        expect(r.pressedBackgroundColor, isNull, reason: v.name);
      }
    });

    test('every ramp Button states ascends', () {
      // Reached through the variant table rather than through the two
      // constants, so a variant that ever writes its own ramp inline is
      // covered by the same invariant.
      for (final v in CoreButtonVariant.values) {
        final layer = row(v).stateLayer;
        if (layer == null) continue;
        expect(layer.isAscending, isTrue, reason: '${v.name} goes backwards');
      }
    });
  });
}
