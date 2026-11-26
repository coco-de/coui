import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

void main() {
  group('Clickable keyboard activation press pulse', () {
    testWidgets(
      'Enter sets pressed then clears it after pressDuration',
      (tester) async {
        final focusNode = FocusNode();
        addTearDown(focusNode.dispose);
        final pressedStates = <bool>[];

        await pumpTestApp(
          tester,
          Clickable(
            onPressed: () {},
            focusNode: focusNode,
            onPressedChange: pressedStates.add,
            child: const Text('Activate'),
          ),
        );

        focusNode.requestFocus();
        await tester.pump();

        expect(await tester.sendKeyEvent(.enter), isTrue);
        await tester.pump();

        expect(
          pressedStates,
          [true],
          reason: 'activation must pulse pressed=true immediately',
        );

        // Advance exactly to the token the pulse rides — not a literal —
        // so this stays correct if the design token value ever changes.
        await tester.pump(CoreClickableStyle.defaultPressDuration);

        expect(
          pressedStates,
          [true, false],
          reason: 'the pulse must clear pressed after one press cycle',
        );
      },
    );

    testWidgets(
      'Space sets pressed then clears it after pressDuration',
      (tester) async {
        final focusNode = FocusNode();
        addTearDown(focusNode.dispose);
        final pressedStates = <bool>[];

        await pumpTestApp(
          tester,
          Clickable(
            onPressed: () {},
            focusNode: focusNode,
            onPressedChange: pressedStates.add,
            child: const Text('Activate'),
          ),
        );

        focusNode.requestFocus();
        await tester.pump();

        expect(await tester.sendKeyEvent(.space), isTrue);
        await tester.pump();

        expect(pressedStates, [true]);

        await tester.pump(CoreClickableStyle.defaultPressDuration);

        expect(pressedStates, [true, false]);
      },
    );

    testWidgets(
      'onPressed still fires once per activation',
      (tester) async {
        final focusNode = FocusNode();
        addTearDown(focusNode.dispose);
        var pressCount = 0;

        await pumpTestApp(
          tester,
          Clickable(
            onPressed: () => pressCount++,
            focusNode: focusNode,
            child: const Text('Activate'),
          ),
        );

        focusNode.requestFocus();
        await tester.pump();

        expect(await tester.sendKeyEvent(.enter), isTrue);
        await tester.pump();
        await tester.pump(CoreClickableStyle.defaultPressDuration);

        expect(pressCount, 1);
      },
    );

    testWidgets(
      'a disabled Clickable does not pulse on activation',
      (tester) async {
        final focusNode = FocusNode();
        addTearDown(focusNode.dispose);
        final pressedStates = <bool>[];

        await pumpTestApp(
          tester,
          Clickable(
            onPressed: () {},
            enabled: false,
            focusNode: focusNode,
            onPressedChange: pressedStates.add,
            child: const Text('Activate'),
          ),
        );

        focusNode.requestFocus();
        await tester.pump();

        // Disabled means the shortcut has nothing to invoke — the key
        // event goes unhandled, same as a disabled Button ignoring a tap.
        expect(await tester.sendKeyEvent(.enter), isFalse);
        await tester.pump();
        await tester.pump(CoreClickableStyle.defaultPressDuration);

        expect(pressedStates, isEmpty);
      },
    );

    testWidgets(
      'pointer press still works unchanged (down then up, no pulse timer)',
      (tester) async {
        final pressedStates = <bool>[];

        await pumpTestApp(
          tester,
          Clickable(
            onPressed: () {},
            onPressedChange: pressedStates.add,
            child: const Text('Tap'),
          ),
        );

        final gesture = await tester.startGesture(
          tester.getCenter(find.text('Tap')),
        );
        await tester.pump();
        expect(pressedStates, [true]);

        await gesture.up();
        await tester.pump();
        expect(pressedStates, [true, false]);
      },
    );
  });
}
