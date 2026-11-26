import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/clickable_feedback.dart';

import '../helpers/test_app.dart';

/// Chip composes `Clickable` the same way `Button` does (S3, #4404) —
/// this asserts the hover-engage wiring actually reached it. It did not
/// on the first pass: S3's brief named only `clickable.dart` and
/// `button.dart` as targets (S1, #4402, wired `castMotion` into both
/// Button and Chip, but the S3 brief only listed one of the two), so
/// `engageOnHover` shipped opted-in on Button and never touched here —
/// Chip kept reacting to press only, silently, until someone hovered it
/// on a live server and noticed nothing happened.
void main() {
  Future<void> pumpChip(WidgetTester tester) async {
    // `pumpTestApp` centres its child — `CoUIApp(home:)` alone would
    // hand `Chip` the tight full-screen constraints a `Scaffold`-style
    // `home` slot gives its content, and a hover anywhere on screen
    // (including where the test pointer starts) would read as
    // "hovering the chip". See `button_hover_engage_test.dart` for the
    // same trap, found and fixed there first.
    await pumpTestApp(
      tester,
      Chip(onTap: () {}, label: 'Tag'),
      theme: ThemeData.fromCore(CoreThemePresets.light),
      surfaceStyle: .neoBrutalism,
    );
  }

  /// Connects a mouse *before* [pumpChip] and returns it.
  ///
  /// `FocusableActionDetector` (inside `Clickable`) snapshots
  /// `FocusHighlightMode` — which falls back to `mouseTracker
  /// .mouseIsConnected` when nothing else has set it — in its very first
  /// post-frame callback, and a mouse pointer event alone never
  /// re-triggers that snapshot afterwards. Connect after the chip mounts
  /// and it locks into touch mode and never shows a hover highlight for
  /// the rest of the test.
  Future<TestGesture> pumpChipWithMouse(WidgetTester tester) async {
    final gesture = await tester.createGesture(kind: .mouse);
    await gesture.addPointer(location: .zero);
    addTearDown(gesture.removePointer);
    await pumpChip(tester);
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
      'hover hides the cast and shifts the chip, reverting on exit',
      (tester) async {
        final gesture = await pumpChipWithMouse(tester);

        expect(castLayer(tester).visible, isTrue);
        expect(shiftTransform(tester), Matrix4.identity());

        await gesture.moveTo(tester.getCenter(find.byType(Chip)));
        await tester.pumpAndSettle();

        expect(
          castLayer(tester).visible,
          isFalse,
          reason: 'hover alone must hide the cast on desktop',
        );
        expect(
          shiftTransform(tester),
          isNot(Matrix4.identity()),
          reason: 'hover alone must shift the chip on desktop',
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
        final gesture = await pumpChipWithMouse(tester);

        // Hover enter — engages.
        await gesture.moveTo(tester.getCenter(find.byType(Chip)));
        await tester.pumpAndSettle();
        expect(castLayer(tester).visible, isFalse);
        expect(shiftTransform(tester), isNot(Matrix4.identity()));

        // Press while still hovering — was already engaged, must not
        // flicker the cast back on before hiding it again.
        await gesture.down(tester.getCenter(find.byType(Chip)));
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
      final gesture = await pumpChipWithMouse(tester);

      await gesture.moveTo(tester.getCenter(find.byType(Chip)));
      await tester.pumpAndSettle();

      expect(
        clickableFeedback(tester).single.scale,
        1.0,
        reason:
            'DDR-1 — the shift already carries the engage signal, so '
            'scale must not also shrink (mirrors button_hover_engage_test)',
      );
    });

    testWidgets(
      'pressedScale also stays pinned to 1.0 on a physical press — not '
      'just hover',
      (tester) async {
        // Scale is gated on `_pressed` alone (never hover, by design — see
        // `Clickable._ClickableState.build`), so the hover-only assertion
        // above is trivially 1.0 whether or not `chip_style.dart` pins
        // `pressedScale` at all. A regression that dropped the pin (chip
        // resolver never applied DDR-1, unlike the button resolver) would
        // still pass that assertion and only show up here, on a real
        // press, under neo-brutalism's non-zero `pressedTranslate`.
        await pumpChip(tester);

        final press = await tester.startGesture(
          tester.getCenter(find.byType(Chip)),
        );
        await tester.pumpAndSettle();

        expect(
          clickableFeedback(tester).single.scale,
          1.0,
          reason:
              'DDR-1 — a chip with a signature shadow to shift into '
              'must not also shrink on press, the same pin '
              'button_cast_motion_test / neo_brutalism_e2e_test already '
              'lock down for Button',
        );

        await press.up();
        await tester.pumpAndSettle();
      },
    );
  });

  group('mobile press is unchanged', () {
    testWidgets('a touch press still hides the cast and shifts the chip', (
      tester,
    ) async {
      await pumpChip(tester);

      expect(castLayer(tester).visible, isTrue);

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(Chip)),
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
