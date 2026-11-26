import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

void main() {
  for (final released in [false, true]) {
    testWidgets(
      'live reduced motion finishes press chrome and preserves state: '
      'released=$released',
      (tester) async {
        var reduced = false;
        var presses = 0;
        late StateSetter update;
        final focus = FocusNode();
        addTearDown(focus.dispose);
        const childKey = ValueKey('stateful-child');
        final child = StatefulBuilder(
          key: childKey,
          builder: (context, setState) =>
              const SizedBox(width: 100, height: 40),
        );
        await pumpTestApp(
          tester,
          StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  disableAnimations: reduced,
                ),
                child: Clickable(
                  focusNode: focus,
                  focusOutline: false,
                  onPressed: () => presses++,
                  clickableStyle: const CoreClickableStyle(
                    pressedScale: .8,
                    pressedTranslate: CoreOffset(4, 6),
                    pressedBoxShadow: [
                      (
                        offsetX: 0.0,
                        offsetY: 2.0,
                        blurRadius: 0.0,
                        spreadRadius: 0.0,
                        opacity: 1.0,
                        inset: false,
                      ),
                    ],
                  ),
                  child: child,
                ),
              );
            },
          ),
        );
        final originalState = tester.state(find.byKey(childKey));
        focus.requestFocus();
        await tester.pumpAndSettle();
        final resting = _paintedBounds(tester, childKey);
        final gesture = await tester.startGesture(resting.center);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 24));
        if (released) {
          await gesture.up();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 16));
        }
        expect(tester.hasRunningAnimations, isTrue);
        update(() => reduced = true);
        await tester.pump();
        expect(tester.hasRunningAnimations, isFalse);
        expect(tester.state(find.byKey(childKey)), same(originalState));
        expect(focus.hasFocus, isTrue);
        final snapped = _paintedBounds(tester, childKey);
        expect(
          snapped.width,
          closeTo(resting.width * (released ? 1 : .8), .01),
        );
        expect(
          snapped.height,
          closeTo(resting.height * (released ? 1 : .8), .01),
        );
        if (released) {
          expect(snapped.center, resting.center);
        } else {
          expect(snapped.center.dx, greaterThan(resting.center.dx));
          expect(snapped.center.dy, greaterThan(resting.center.dy));
          await gesture.up();
          await tester.pump();
        }
        expect(presses, 1);
        expect(_paintedBounds(tester, childKey), resting);
        expect(tester.hasRunningAnimations, isFalse);
        expect(tester.takeException(), isNull);
      },
    );
  }
}

Rect _paintedBounds(WidgetTester tester, Key key) {
  final box = tester.renderObject<RenderBox>(find.byKey(key));
  return Rect.fromPoints(
    box.localToGlobal(Offset.zero),
    box.localToGlobal(box.size.bottomRight(Offset.zero)),
  );
}
