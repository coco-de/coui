import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/clickable_feedback.dart';

import '../helpers/test_app.dart';

/// The reference neo-brutalism library hangs the cast affordance on
/// `:hover`, not `:active`. This asserts the Flutter twin actually reads
/// hover the same way — a `dart analyze` pass over the resolver (covered
/// by `button_cast_motion_test.dart`) cannot see whether the *widget*
/// wires that value to a running pointer, only these paint-level
/// assertions can.
void main() {
  Future<void> pumpButton(WidgetTester tester) async {
    // `pumpTestApp` centres its child in the available space —
    // `CoUIApp(home:)` alone hands `Button` the tight full-screen
    // constraints a `Scaffold`-style `home` slot gives its content, and
    // `Button`'s root `ConstrainedBox` cannot loosen an already-tight
    // incoming constraint. Without the centring, `Button`'s own hit-test
    // region stretches to cover the whole viewport, and a hover anywhere
    // on screen — including where the pointer starts — reads as
    // "hovering the button".
    await pumpTestApp(
      tester,
      Button(onPressed: () {}, child: const Text('Submit')),
      theme: ThemeData.fromCore(CoreThemePresets.light),
      surfaceStyle: .neoBrutalism,
    );
  }

  /// Connects a mouse *before* [pumpButton] and returns it.
  ///
  /// `FocusableActionDetector` (inside `Clickable`) snapshots
  /// `FocusHighlightMode` — which falls back to `mouseTracker
  /// .mouseIsConnected` when nothing else has set it — in its very first
  /// post-frame callback, and a mouse pointer event alone never
  /// re-triggers that snapshot afterwards (only a touch or keyboard event
  /// does). Connect the mouse after the button mounts and it locks into
  /// touch mode and never shows a hover highlight for the rest of the
  /// test — so every hover test in this file must connect first, then
  /// pump.
  Future<TestGesture> pumpButtonWithMouse(WidgetTester tester) async {
    final gesture = await tester.createGesture(kind: .mouse);
    await gesture.addPointer(location: .zero);
    addTearDown(gesture.removePointer);
    await pumpButton(tester);
    return gesture;
  }

  InjectedCast castLayer(WidgetTester tester) =>
      tester.widget<InjectedCast>(find.byType(InjectedCast));

  /// Painted feedback plus the resolver's motion policy, independent of
  /// the particular animation widget that implements the transition.
  Matrix4 shiftTransform(WidgetTester tester) =>
      clickableFeedback(tester).single.transform;

  group('desktop hover engages the cast motion pair', () {
    testWidgets(
      'hover hides the cast and shifts the button, reverting on exit',
      (tester) async {
        final gesture = await pumpButtonWithMouse(tester);

        expect(castLayer(tester).visible, isTrue);
        expect(shiftTransform(tester), Matrix4.identity());

        await gesture.moveTo(tester.getCenter(find.byType(Button)));
        await tester.pumpAndSettle();

        expect(
          castLayer(tester).visible,
          isFalse,
          reason: 'hover alone must hide the cast on desktop',
        );
        expect(
          shiftTransform(tester),
          isNot(Matrix4.identity()),
          reason: 'hover alone must shift the button on desktop',
        );

        await gesture.moveTo(.zero);
        await tester.pumpAndSettle();

        expect(castLayer(tester).visible, isTrue);
        expect(shiftTransform(tester), Matrix4.identity());
      },
    );

    testWidgets(
      'hover-enter -> press -> release -> hover-exit stays engaged '
      'throughout, no mid-sequence revert',
      (tester) async {
        final gesture = await pumpButtonWithMouse(tester);

        // Hover enter — engages.
        await gesture.moveTo(tester.getCenter(find.byType(Button)));
        await tester.pumpAndSettle();
        expect(castLayer(tester).visible, isFalse);
        expect(shiftTransform(tester), isNot(Matrix4.identity()));

        // Press while still hovering — was already engaged, must not
        // flicker the cast back on before hiding it again.
        await gesture.down(tester.getCenter(find.byType(Button)));
        await tester.pumpAndSettle();
        expect(castLayer(tester).visible, isFalse);
        expect(shiftTransform(tester), isNot(Matrix4.identity()));

        // Release, still hovering — hover alone keeps it engaged.
        await gesture.up();
        await tester.pumpAndSettle();
        expect(castLayer(tester).visible, isFalse);
        expect(shiftTransform(tester), isNot(Matrix4.identity()));

        // Hover exit — only now does it revert.
        await gesture.moveTo(.zero);
        await tester.pumpAndSettle();
        expect(castLayer(tester).visible, isTrue);
        expect(shiftTransform(tester), Matrix4.identity());
      },
    );

    testWidgets('pressedScale stays pinned to 1.0 while hover-engaged', (
      tester,
    ) async {
      final gesture = await pumpButtonWithMouse(tester);

      await gesture.moveTo(tester.getCenter(find.byType(Button)));
      await tester.pumpAndSettle();

      expect(
        clickableFeedback(tester).single.scale,
        1.0,
        reason:
            'DDR-1 — the shift already carries the engage signal, so '
            'scale must not also shrink',
      );
    });
  });

  group('mobile press is unchanged', () {
    testWidgets('a touch press still hides the cast and shifts the button', (
      tester,
    ) async {
      await pumpButton(tester);

      expect(castLayer(tester).visible, isTrue);

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(Button)),
      );
      await tester.pumpAndSettle();

      expect(castLayer(tester).visible, isFalse);
      expect(shiftTransform(tester), isNot(Matrix4.identity()));

      await gesture.up();
      await tester.pumpAndSettle();

      expect(castLayer(tester).visible, isTrue);
      expect(shiftTransform(tester), Matrix4.identity());
    });
  });
}
