import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as m;
import 'package:flutter_test/flutter_test.dart';

import '../helpers/clickable_feedback.dart';

/// A tap too short to outlast the gesture arena still shows a press.
///
/// `TapGestureRecognizer` withholds `onTapDown` while it contests the
/// arena, and a tap shorter than `kPressTimeout` (100ms) resolves only at
/// the pointer-up sweep — where `acceptGesture` runs `_checkDown` and
/// `_checkUp` back to back, synchronously. The press state was computed
/// and never painted: true and false inside one batch, no frame between.
///
/// Two conditions have to hold together for this to reproduce, and the
/// suite had neither, which is why 2000-odd green tests said nothing:
///
///  1. **A contested arena.** Widget tests run with `kIsWeb == false`, so
///     the `SelectionArea` that `CoUIApp` installs on Web is absent and
///     the arena has one member — the single path that always worked. The
///     competitor is added explicitly here.
///  2. **A release before 100ms.** Every existing press test holds and
///     pumps; none lets go early, so all of them clear the deadline that
///     hides the bug.
///
/// Both are stated in the harness below rather than left to a comment,
/// because a future edit that drops either one turns this file back into
/// a test of the path that was never broken.

/// Whether any *rendered* frame showed the press.
///
/// Sampled after every frame rather than at the end: the defect is not a
/// wrong final state — the final state was always correct — it is that
/// the pressed state never survives to a frame at all.
///
/// Checks two signals, not one: under neo-brutalism a chip's press
/// affordance is the shift-into-the-cast (`Transform`), not the
/// scale-shrink — DDR-1 pins `pressedScale` to `1.0` once that shift
/// carries the signal (#4404), so a probe that only watched
/// `AnimatedScale` would read a healthy control as broken the moment
/// this file's own subject (a neo-brutalism `Chip`) started honouring
/// that pin.
Future<bool> _pressRendersDuring(
  WidgetTester tester, {
  required Duration hold,
  required bool contested,
}) async {
  Widget content = Center(
    child: Chip(label: 'c', onTap: () {}),
  );
  if (contested) {
    // What `CoUIApp` installs on Web. It contributes tap / drag / long-press
    // recognizers, so the arena no longer resolves by default at pointer
    // down. A Scrollable does the same; this is the one that ships.
    content = m.SelectionArea(child: content);
  }

  await tester.pumpWidget(
    CoUIApp(
      theme: ThemeData.fromCore(CoreThemePresets.light),
      surfaceStyle: CoreSurfaceStyleId.neoBrutalism,
      home: content,
    ),
  );
  await tester.pumpAndSettle();

  var sawPress = false;
  void sample() {
    final scales = clickableFeedback(tester).map((s) => s.scale);
    final shifted = tester
        .widgetList<Transform>(find.byType(Transform))
        .map((t) => t.transform.getTranslation())
        .any((v) => v.x != 0 || v.y != 0);
    if (scales.any((s) => s < 1) || shifted) sawPress = true;
  }

  final gesture = await tester.startGesture(
    tester.getCenter(find.byType(Chip)),
  );

  // Frame by frame across the hold, so a press that appears for a single
  // frame is still seen.
  var elapsed = Duration.zero;
  const step = Duration(milliseconds: 16);
  while (elapsed < hold) {
    await tester.pump(step);
    elapsed += step;
    sample();
  }

  await gesture.up();
  await tester.pump(step);
  sample();
  await tester.pumpAndSettle();

  return sawPress;
}

void main() {
  group('a press too quick for the arena still shows', () {
    testWidgets('a 32ms tap under a contested arena renders a press', (
      tester,
    ) async {
      expect(
        await _pressRendersDuring(
          tester,
          hold: const Duration(milliseconds: 32),
          contested: true,
        ),
        isTrue,
        reason:
            'the Web twin engages :active at mousedown with no '
            'arbitration; a control that shows nothing for a quick tap '
            'has no press affordance at all where it matters most',
      );
    });

    testWidgets('a 32ms tap with an uncontested arena still renders one', (
      tester,
    ) async {
      // The path that already worked. Kept so a fix that traded one arena
      // shape for the other cannot pass.
      expect(
        await _pressRendersDuring(
          tester,
          hold: const Duration(milliseconds: 32),
          contested: false,
        ),
        isTrue,
      );
    });

    testWidgets('a long press under a contested arena still renders one', (
      tester,
    ) async {
      // The case that always worked because it outlasts `kPressTimeout`.
      // Its job here is to prove the harness can distinguish states at all
      // — without it, a probe that never sees a press would pass the
      // negative control below for the wrong reason.
      expect(
        await _pressRendersDuring(
          tester,
          hold: const Duration(milliseconds: 300),
          contested: true,
        ),
        isTrue,
      );
    });

    testWidgets('the press retreats once the gesture is over', (tester) async {
      await tester.pumpWidget(
        CoUIApp(
          theme: ThemeData.fromCore(CoreThemePresets.light),
          surfaceStyle: CoreSurfaceStyleId.neoBrutalism,
          home: m.SelectionArea(
            child: Center(
              child: Chip(label: 'c', onTap: () {}),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(Chip)),
      );
      await tester.pump(const Duration(milliseconds: 16));
      await gesture.up();
      await tester.pumpAndSettle();

      // Starting the press on the raw pointer must not leave it stuck when
      // the recognizer never reports a tap — the failure mode this trades
      // against, and the reason the release edge is on the pointer too.
      // Checks both signals for the same reason `_pressRendersDuring`
      // does above — under DDR-1's scale pin this chip's affordance is
      // the shift, so a stuck shift is the failure mode this component
      // could actually exhibit; a scale-only check would stay green.
      expect(
        clickableFeedback(tester).every((s) => s.scale == 1),
        isTrue,
      );
      expect(
        tester.widgetList<Transform>(find.byType(Transform)).every((t) {
          final v = t.transform.getTranslation();
          return v.x == 0 && v.y == 0;
        }),
        isTrue,
      );
    });
  });
}
