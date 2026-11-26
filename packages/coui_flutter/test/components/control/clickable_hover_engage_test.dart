import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

const _kShift = CoreOffset(4, 4);

void main() {
  group('Clickable.engageOnHover', () {
    // Inspect the painted translation, not the implicit widget's target.
    Matrix4 shiftTransform(WidgetTester tester) => tester
        .widgetList<Container>(find.byType(Container))
        .firstWhere((widget) => widget.transform != null)
        .transform!;

    testWidgets(
      'hover shifts the control when engageOnHover is true, and reverts '
      'on exit',
      (tester) async {
        // The mouse must connect *before* `Clickable` mounts —
        // `FocusableActionDetector` snapshots `FocusHighlightMode` (which
        // reads `mouseTracker.mouseIsConnected` when nothing else has set
        // it yet) in its very first post-frame callback, and a mouse
        // event alone never re-triggers that snapshot afterwards. Connect
        // late and the widget locks into touch mode and never shows a
        // hover highlight for the rest of the test.
        final gesture = await tester.createGesture(kind: .mouse);
        await gesture.addPointer(location: .zero);
        addTearDown(gesture.removePointer);

        await pumpTestApp(
          tester,
          Clickable(
            onPressed: () {},
            engageOnHover: true,
            clickableStyle: const CoreClickableStyle(pressedTranslate: _kShift),
            child: const SizedBox(width: 100, height: 40),
          ),
        );

        expect(shiftTransform(tester), Matrix4.identity());

        await gesture.moveTo(tester.getCenter(find.byType(Clickable)));
        await tester.pumpAndSettle();

        expect(
          shiftTransform(tester),
          isNot(Matrix4.identity()),
          reason: 'hover must engage the shift when engageOnHover is true',
        );

        await gesture.moveTo(.zero);
        await tester.pumpAndSettle();

        expect(shiftTransform(tester), Matrix4.identity());
      },
    );

    testWidgets(
      'hover does nothing to the shift when engageOnHover is false '
      '(the default)',
      (tester) async {
        final gesture = await tester.createGesture(kind: .mouse);
        await gesture.addPointer(location: .zero);
        addTearDown(gesture.removePointer);

        await pumpTestApp(
          tester,
          Clickable(
            onPressed: () {},
            clickableStyle: const CoreClickableStyle(pressedTranslate: _kShift),
            child: const SizedBox(width: 100, height: 40),
          ),
        );

        await gesture.moveTo(tester.getCenter(find.byType(Clickable)));
        await tester.pumpAndSettle();

        expect(
          shiftTransform(tester),
          Matrix4.identity(),
          reason:
              'every existing Clickable consumer keeps its press-only '
              'behaviour unless it opts in',
        );
      },
    );

    testWidgets(
      'a physical press still shifts the control regardless of '
      'engageOnHover',
      (tester) async {
        await pumpTestApp(
          tester,
          Clickable(
            onPressed: () {},
            engageOnHover: true,
            clickableStyle: const CoreClickableStyle(pressedTranslate: _kShift),
            child: const SizedBox(width: 100, height: 40),
          ),
        );

        final gesture = await tester.startGesture(
          tester.getCenter(find.byType(Clickable)),
        );
        await tester.pumpAndSettle();

        expect(shiftTransform(tester), isNot(Matrix4.identity()));

        await gesture.up();
        await tester.pumpAndSettle();

        expect(shiftTransform(tester), Matrix4.identity());
      },
    );

    testWidgets(
      'hover never triggers the press-shrink — only a physical press does',
      (tester) async {
        final gesture = await tester.createGesture(kind: .mouse);
        await gesture.addPointer(location: .zero);
        addTearDown(gesture.removePointer);

        await pumpTestApp(
          tester,
          Clickable(
            onPressed: () {},
            engageOnHover: true,
            clickableStyle: const CoreClickableStyle(pressedTranslate: _kShift),
            child: const SizedBox(width: 100, height: 40),
          ),
        );

        await gesture.moveTo(tester.getCenter(find.byType(Clickable)));
        await tester.pumpAndSettle();

        expect(
          tester
              .widgetList<Transform>(find.byType(Transform))
              .every((widget) => widget.transform.storage[0] == 1),
          isTrue,
          reason:
              'a hover-shrinking control would be a new affordance no '
              'consumer asked for — DDR-1 keeps scale press-only',
        );
      },
    );
  });
}
