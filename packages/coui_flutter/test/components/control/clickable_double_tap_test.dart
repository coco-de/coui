// A double tap is measured on the clock the user made it on — the pointer
// events' own timestamps — not on when the app got round to handling them.
// A first press that does heavy work (a tree row that opens a document)
// delays the handling of the second, and a gap measured at handling time
// turned a quick double click into two single ones.
//
// Events synthesised in Dart (automation such as Marionette, a test that
// sets no timestamp) carry no engine time — those are timed when handled.
import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

void main() {
  group('Clickable double tap', () {
    late int pressed;
    late int doubled;

    setUp(() {
      pressed = 0;
      doubled = 0;
    });

    Widget target({FocusNode? focusNode}) => Clickable(
      onPressed: () => pressed++,
      onDoubleTap: () => doubled++,
      focusNode: focusNode,
      child: const Text('Target'),
    );

    Future<void> pressAt(WidgetTester tester, Duration timeStamp) async {
      final gesture = await tester.createGesture();
      await gesture.down(
        tester.getCenter(find.text('Target')),
        timeStamp: timeStamp,
      );
      await gesture.up(timeStamp: timeStamp + const Duration(milliseconds: 20));
      await tester.pump();
    }

    testWidgets(
      'presses close in event time are a double tap even when handled late',
      (tester) async {
        await pumpTestApp(tester, target());

        await pressAt(tester, const Duration(seconds: 1));
        // The app was busy for longer than the double-tap window …
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 350)),
        );
        // … but the user pressed again 80ms after the first press.
        await pressAt(tester, const Duration(milliseconds: 1080));

        expect(pressed, 1, reason: 'the first press is never delayed');
        expect(doubled, 1);
      },
    );

    testWidgets('presses far apart in event time are two single presses', (
      tester,
    ) async {
      await pumpTestApp(tester, target());

      await pressAt(tester, const Duration(seconds: 1));
      await pressAt(tester, const Duration(milliseconds: 1400));

      expect(pressed, 2);
      expect(doubled, 0);
    });

    testWidgets(
      'presses without an engine timestamp pair only when handled close '
      'together',
      (tester) async {
        // `tester.tap`, like Marionette, sends no timestamp. On the event
        // clock every such press is at zero and any two would pair.
        await pumpTestApp(tester, target());

        await tester.tap(find.text('Target'));
        await tester.pump();
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 350)),
        );
        await tester.tap(find.text('Target'));
        await tester.pump();

        expect(pressed, 2, reason: 'clicks seconds apart are two presses');
        expect(doubled, 0);

        await tester.tap(find.text('Target'));
        await tester.pump();

        expect(doubled, 1, reason: 'a quick second click still pairs');
      },
    );

    testWidgets('a press with a timestamp never pairs with one without', (
      tester,
    ) async {
      await pumpTestApp(tester, target());

      await pressAt(tester, const Duration(seconds: 1));
      await tester.tap(find.text('Target'));
      await tester.pump();

      expect(pressed, 2);
      expect(doubled, 0);
    });

    testWidgets('keyboard activation never forms a double tap', (
      tester,
    ) async {
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);
      await pumpTestApp(tester, target(focusNode: focusNode));
      focusNode.requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(.enter);
      await tester.pump(CoreClickableStyle.defaultPressDuration);
      await tester.sendKeyEvent(.enter);
      await tester.pump(CoreClickableStyle.defaultPressDuration);

      expect(pressed, 2);
      expect(doubled, 0);
    });
  });
}
