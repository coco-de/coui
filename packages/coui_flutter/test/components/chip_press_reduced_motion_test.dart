import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/clickable_feedback.dart';

import '../helpers/test_app.dart';

/// Chip twin of `button_press_reduced_motion_test.dart` (#4407) — the
/// same shadow-hide + travel pair, wired through `ResolvedChip
/// .castHideDuration` instead of `ResolvedButton.castHideDuration`, but
/// answering to the same policy: state (the cast hides, the chip moves)
/// survives reduced motion, only the transition speed collapses.
void main() {
  Future<void> pumpChip(
    WidgetTester tester, {
    required bool disableAnimations,
  }) async {
    // See `chip_hover_engage_test.dart` for why `pumpTestApp`'s centring
    // and neo-brutalism (the only preset that states a signature shadow
    // and an engage offset) are both required here.
    await pumpTestApp(
      tester,
      Chip(onTap: () {}, label: 'Tag'),
      theme: ThemeData.fromCore(CoreThemePresets.light),
      surfaceStyle: .neoBrutalism,
      disableAnimations: disableAnimations,
    );
  }

  Future<TestGesture> pumpChipWithMouse(
    WidgetTester tester, {
    required bool disableAnimations,
  }) async {
    final gesture = await tester.createGesture(kind: .mouse);
    await gesture.addPointer(location: .zero);
    addTearDown(gesture.removePointer);
    await pumpChip(tester, disableAnimations: disableAnimations);
    return gesture;
  }

  InjectedCast castLayer(WidgetTester tester) =>
      tester.widget<InjectedCast>(find.byType(InjectedCast));

  ClickableFeedback shiftContainer(WidgetTester tester) =>
      clickableFeedback(tester).single;

  group('reduced motion — the clock collapses, the state does not', () {
    testWidgets(
      'both halves of the press pair read Duration.zero',
      (tester) async {
        final gesture = await pumpChipWithMouse(
          tester,
          disableAnimations: true,
        );

        await gesture.moveTo(tester.getCenter(find.byType(Chip)));
        await tester.pumpAndSettle();

        expect(
          castLayer(tester).duration,
          Duration.zero,
          reason:
              'ResolvedChip.castHideDuration must reach '
              'resolveMotionDuration — this used to be a hardcoded '
              '50ms literal',
        );
        expect(
          shiftContainer(tester).duration,
          Duration.zero,
          reason:
              'the travel half (Clickable.pressDuration, via '
              'resolveClickable) must reach resolveMotionDuration too',
        );
      },
    );

    testWidgets(
      'the cast still hides and the chip still travels — hover engage',
      (tester) async {
        final gesture = await pumpChipWithMouse(
          tester,
          disableAnimations: true,
        );

        expect(castLayer(tester).visible, isTrue);
        expect(shiftContainer(tester).transform, Matrix4.identity());

        await gesture.moveTo(tester.getCenter(find.byType(Chip)));
        await tester.pumpAndSettle();

        expect(
          castLayer(tester).visible,
          isFalse,
          reason: 'AC: the cast must still hide under reduced motion',
        );
        expect(
          shiftContainer(tester).transform,
          isNot(Matrix4.identity()),
          reason: 'AC: the chip must still travel under reduced motion',
        );

        await gesture.moveTo(.zero);
        await tester.pumpAndSettle();

        expect(castLayer(tester).visible, isTrue);
        expect(shiftContainer(tester).transform, Matrix4.identity());
      },
    );

    testWidgets(
      'the cast still hides and the chip still travels — mobile press',
      (tester) async {
        await pumpChip(tester, disableAnimations: true);

        expect(castLayer(tester).visible, isTrue);

        final gesture = await tester.startGesture(
          tester.getCenter(find.byType(Chip)),
        );
        await tester.pumpAndSettle();

        expect(castLayer(tester).visible, isFalse);
        expect(shiftContainer(tester).transform, isNot(Matrix4.identity()));

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
        await pumpChip(tester, disableAnimations: false);

        expect(castLayer(tester).visible, isTrue);
        expect(shiftContainer(tester).transform, Matrix4.identity());
        expect(
          castLayer(tester).duration,
          equals(const Duration(milliseconds: CoreDuration.ms50)),
          reason: 'un-reduced clock is unchanged by the fix',
        );
      },
    );
  });
}
