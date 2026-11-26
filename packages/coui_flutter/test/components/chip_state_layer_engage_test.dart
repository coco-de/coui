import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

/// The wiring `chip_state_layer_engage_test`'s name promises: `Chip` reads
/// `_pressed`/`_focused`/`_hovered` and selects among four pre-baked
/// `OutlinedContainer` fills, rather than always painting the rest-state
/// one it used to hand `_PressableChip` as a finished box.
///
/// Companion to `chip_hover_engage_test.dart` (the cast/shift pair) and
/// `button_state_change_perceptibility_test.dart` (the composited-colour
/// claim); this file only pins that the SELECTED fill actually changes
/// per state — the perceptibility test owns whether the composited
/// colours differ enough to read as a change at all.
void main() {
  Future<void> pumpChip(WidgetTester tester) async {
    // Centred, not full-screen `home:` — a hover anywhere on screen would
    // otherwise read as hovering the chip (same trap `chip_hover_engage_
    // test.dart` and `button_hover_engage_test.dart` document).
    await pumpTestApp(
      tester,
      Chip(onTap: () {}, label: 'Tag'),
      theme: ThemeData.fromCore(CoreThemePresets.light),
    );
  }

  Future<TestGesture> pumpChipWithMouse(WidgetTester tester) async {
    final gesture = await tester.createGesture(kind: .mouse);
    await gesture.addPointer(location: .zero);
    addTearDown(gesture.removePointer);
    await pumpChip(tester);
    return gesture;
  }

  // `OutlinedContainer` nests two `AnimatedContainer`s (outer = fill/
  // border, inner = padding/inner-radius only) — `first` picks the outer
  // one, the one whose `BoxDecoration.color` is the selected chrome.
  Color? boxFill(WidgetTester tester) {
    final decoration = tester
        .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
        .first
        .decoration;
    return (decoration as BoxDecoration?)?.color;
  }

  group('Chip selects a different box fill per engage state', () {
    testWidgets('rest -> hover changes the painted fill', (tester) async {
      final gesture = await pumpChipWithMouse(tester);
      final rest = boxFill(tester);

      await gesture.moveTo(tester.getCenter(find.byType(Chip)));
      await tester.pump();
      final hovered = boxFill(tester);

      expect(
        hovered,
        isNot(rest),
        reason:
            'hovering painted the same fill as rest — the state layer '
            'select never ran, or the four container styles collapsed '
            'to one colour',
      );

      await gesture.moveTo(.zero);
      await tester.pump();
      expect(
        boxFill(tester),
        rest,
        reason: 'moving the pointer away must revert to the rest fill',
      );
    });

    testWidgets('press paints a stronger wash than hover, not the same one', (
      tester,
    ) async {
      final gesture = await pumpChipWithMouse(tester);

      await gesture.moveTo(tester.getCenter(find.byType(Chip)));
      await tester.pump();
      final hovered = boxFill(tester);

      await gesture.down(tester.getCenter(find.byType(Chip)));
      await tester.pump();
      final pressed = boxFill(tester);

      expect(
        pressed,
        isNot(hovered),
        reason:
            'pressed painted the same fill as hover — pressed must read '
            'as a stronger state, not the same one twice',
      );

      await gesture.up();
      await tester.pump();
    });

    testWidgets('keyboard focus paints a fill distinct from rest and hover', (
      tester,
    ) async {
      await pumpChip(tester);
      final rest = boxFill(tester);

      // `Chip` exposes no `focusNode` of its own — `Clickable` owns one
      // internally and hands it straight to `FocusableActionDetector`, so
      // it is still reachable off THAT widget instance in the tree.
      //
      // `requestFocus()` alone moves the node but does not fire
      // `onShowFocusHighlight` — `FocusableActionDetector` gates that on
      // `FocusManager.highlightMode`, which starts in `.touch` mode in a
      // bare test harness (no keyboard has been seen yet), the same class
      // of trap `chip_hover_engage_test.dart` documents for hover mode. A
      // real key event is what flips the mode to `.traditional`.
      await tester.sendKeyDownEvent(LogicalKeyboardKey.tab);
      final node = tester
          .widget<FocusableActionDetector>(
            find.byType(FocusableActionDetector),
          )
          .focusNode!;
      node.requestFocus();
      await tester.pump();
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.tab);

      expect(
        tester.binding.focusManager.primaryFocus,
        isNotNull,
        reason: 'focus traversal found nothing to land on',
      );

      final focused = boxFill(tester);
      expect(
        focused,
        isNot(rest),
        reason:
            'a focused chip painted the same fill as rest — the focus '
            'rung of the ramp never reached the box',
      );
    });

    testWidgets('a disabled chip never engages — fill stays pinned to rest', (
      tester,
    ) async {
      await pumpTestApp(
        tester,
        const Chip(onTap: null, label: 'Tag'),
        theme: ThemeData.fromCore(CoreThemePresets.light),
      );
      final rest = boxFill(tester);

      final gesture = await tester.createGesture(kind: .mouse);
      await gesture.addPointer(location: .zero);
      addTearDown(gesture.removePointer);
      await gesture.moveTo(tester.getCenter(find.byType(Chip)));
      await tester.pump();

      expect(
        boxFill(tester),
        rest,
        reason:
            'a disabled chip must not wash on hover — Clickable should '
            'never report the engage, and the select gates on `enabled` '
            'as a second line of defence',
      );
    });
  });
}
