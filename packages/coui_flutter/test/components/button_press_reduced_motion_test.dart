import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/clickable_feedback.dart';

import '../helpers/test_app.dart';

/// The press pair (`Clickable`'s press translation and `Button`'s
/// own cast-hiding `InjectedCast`) used to run on a bare `CoreDuration.ms50`
/// literal — never through `resolveMotionDuration` — so
/// `MediaQuery.disableAnimations` had no effect on it (#4407, the Flutter
/// twin of the Web `_controlShadowPressRule` fix).
///
/// The correct outcome is narrower than "reduced motion turns the
/// affordance off": state — the cast still hides, the control still
/// travels — has to survive with the preference on. Only the *time it
/// takes to get there* collapses to zero. So every group below pairs a
/// duration assertion with a state assertion, on the same pumped frame.
void main() {
  Future<void> pumpButton(
    WidgetTester tester, {
    required bool disableAnimations,
  }) async {
    // Mirrors `button_hover_engage_test.dart`'s `pumpButton` — centred so
    // the button's own hit-test region does not swallow the whole
    // viewport, and neo-brutalism so the button actually casts a shadow
    // and states an engage offset (the common preset's press pair is a
    // no-op: `pressedTranslateOffset` is `CoreOffset.zero` and `boxShadow`
    // is `null` there, so there is nothing here to observe).
    await pumpTestApp(
      tester,
      Button(onPressed: () {}, child: const Text('Submit')),
      theme: ThemeData.fromCore(CoreThemePresets.light),
      surfaceStyle: .neoBrutalism,
      disableAnimations: disableAnimations,
    );
  }

  Future<TestGesture> pumpButtonWithMouse(
    WidgetTester tester, {
    required bool disableAnimations,
  }) async {
    // Same connect-before-pump ordering `button_hover_engage_test.dart`
    // documents — `FocusableActionDetector` snapshots hover-capability on
    // its first post-frame callback.
    final gesture = await tester.createGesture(kind: .mouse);
    await gesture.addPointer(location: .zero);
    addTearDown(gesture.removePointer);
    await pumpButton(tester, disableAnimations: disableAnimations);
    return gesture;
  }

  InjectedCast castLayer(WidgetTester tester) =>
      tester.widget<InjectedCast>(find.byType(InjectedCast));

  /// Painted feedback plus the resolver's motion policy, independent of
  /// the particular animation widget that implements the transition.
  ClickableFeedback shiftContainer(WidgetTester tester) =>
      clickableFeedback(tester).single;

  group('normal motion — baseline (both halves animate)', () {
    testWidgets('the press pair runs on a non-zero clock while engaged', (
      tester,
    ) async {
      final gesture = await pumpButtonWithMouse(
        tester,
        disableAnimations: false,
      );

      await gesture.moveTo(tester.getCenter(find.byType(Button)));
      await tester.pumpAndSettle();

      expect(
        castLayer(tester).duration,
        isNot(Duration.zero),
        reason: 'sanity baseline — the cast-hide half normally animates',
      );
      expect(
        shiftContainer(tester).duration,
        isNot(Duration.zero),
        reason: 'sanity baseline — the travel half normally animates',
      );
    });
  });

  group('reduced motion — the clock collapses, the state does not', () {
    testWidgets(
      'both halves of the press pair read Duration.zero',
      (tester) async {
        final gesture = await pumpButtonWithMouse(
          tester,
          disableAnimations: true,
        );

        await gesture.moveTo(tester.getCenter(find.byType(Button)));
        await tester.pumpAndSettle();

        expect(
          castLayer(tester).duration,
          Duration.zero,
          reason:
              'the cast-hide half must reach resolveMotionDuration — this '
              'is the regression: it used to stay at a hardcoded 50ms',
        );
        expect(
          shiftContainer(tester).duration,
          Duration.zero,
          reason:
              'the travel half (Clickable.pressDuration) must reach '
              'resolveMotionDuration too, or the pair desyncs — one half '
              'instant, the other still easing over 50ms',
        );
      },
    );

    testWidgets(
      'the cast still hides and the control still travels — hover engage',
      (tester) async {
        final gesture = await pumpButtonWithMouse(
          tester,
          disableAnimations: true,
        );

        expect(
          castLayer(tester).visible,
          isTrue,
          reason: 'baseline before engaging: shadow shown, no travel',
        );
        expect(shiftContainer(tester).transform, Matrix4.identity());

        await gesture.moveTo(tester.getCenter(find.byType(Button)));
        await tester.pumpAndSettle();

        expect(
          castLayer(tester).visible,
          isFalse,
          reason:
              'AC: the cast must still hide under reduced motion — only '
              'the transition speed may change, not whether it happens',
        );
        expect(
          shiftContainer(tester).transform,
          isNot(Matrix4.identity()),
          reason: 'AC: the control must still travel under reduced motion',
        );

        await gesture.moveTo(.zero);
        await tester.pumpAndSettle();

        expect(
          castLayer(tester).visible,
          isTrue,
          reason: 'disengaging must still restore the resting shadow',
        );
        expect(shiftContainer(tester).transform, Matrix4.identity());
      },
    );

    testWidgets(
      'the cast still hides and the control still travels — mobile press',
      (tester) async {
        await pumpButton(tester, disableAnimations: true);

        expect(castLayer(tester).visible, isTrue);

        final gesture = await tester.startGesture(
          tester.getCenter(find.byType(Button)),
        );
        await tester.pumpAndSettle();

        expect(
          castLayer(tester).visible,
          isFalse,
          reason: 'AC: touch press must still hide the cast',
        );
        expect(
          shiftContainer(tester).transform,
          isNot(Matrix4.identity()),
          reason: 'AC: touch press must still move the control',
        );

        await gesture.up();
        await tester.pumpAndSettle();

        expect(castLayer(tester).visible, isTrue);
        expect(shiftContainer(tester).transform, Matrix4.identity());
      },
    );
  });

  group('normal render is unaffected by the fix', () {
    testWidgets(
      'resting (un-engaged) chrome is identical with the preference off',
      (tester) async {
        await pumpButton(tester, disableAnimations: false);

        expect(castLayer(tester).visible, isTrue);
        expect(shiftContainer(tester).transform, Matrix4.identity());
        expect(
          castLayer(tester).duration,
          equals(const Duration(milliseconds: CoreDuration.ms50)),
          reason:
              'un-reduced clock is still the same 50ms both halves always '
              'shared — the fix only adds an indirection, not a new value',
        );
      },
    );
  });
}
