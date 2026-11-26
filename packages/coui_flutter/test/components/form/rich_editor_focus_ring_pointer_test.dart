// The editor's outer focus ring is a keyboard signal, as a `TextArea`'s is
// (its box is the `TextArea`'s): a pointer press that focuses it already
// shows on the active boundary, so the ring joins only when focus arrives by
// keyboard — read back under the framework's own focus-highlight strategy
// and driven by real pointer and key events.
//
// A mouse never moves `FocusManager.highlightMode` off `traditional` on a
// desktop, so a ring read from it alone rang on every click.

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app() => material.MaterialApp(
  home: Theme(
    data: const ThemeData(),
    child: material.Scaffold(
      body: Center(
        child: SizedBox(
          width: 480,
          child: RichEditor(showToolbar: false, onChanged: (_) {}),
        ),
      ),
    ),
  ),
);

bool _ringShown(WidgetTester tester) => tester
    .widget<FocusOutline>(
      find
          .descendant(
            of: find.byType(RichEditor),
            matching: find.byType(FocusOutline),
          )
          .first,
    )
    .focused;

Future<void> _mouseClick(WidgetTester tester, Offset at) async {
  final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
  addTearDown(gesture.removePointer);
  await gesture.addPointer(location: Offset.zero);
  await gesture.moveTo(at);
  await gesture.down(at);
  await gesture.up();
  await tester.pumpAndSettle();
}

void main() {
  final desktop = TargetPlatformVariant.only(TargetPlatform.macOS);

  group('RichEditor — the outer ring under real input', () {
    testWidgets('a mouse click draws no ring', (tester) async {
      await tester.pumpWidget(_app());
      await _mouseClick(tester, tester.getCenter(find.byType(RichEditor)));

      expect(_ringShown(tester), isFalse);
    }, variant: desktop);

    testWidgets('a touch tap draws no ring', (tester) async {
      await tester.pumpWidget(_app());
      await tester.tapAt(tester.getCenter(find.byType(RichEditor)));
      await tester.pumpAndSettle();

      expect(_ringShown(tester), isFalse);
    }, variant: desktop);

    testWidgets('Tab into the editor draws the ring', (tester) async {
      await tester.pumpWidget(_app());
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      expect(_ringShown(tester), isTrue);
    }, variant: desktop);

    testWidgets('a click on the editor the keyboard already focused keeps '
        'its ring', (tester) async {
      await tester.pumpWidget(_app());
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(_ringShown(tester), isTrue);

      // Focus does not arrive again, so nothing re-judges it.
      await _mouseClick(tester, tester.getCenter(find.byType(RichEditor)));
      expect(_ringShown(tester), isTrue);
    }, variant: desktop);

    testWidgets('a focus the mouse gave is forgotten when focus leaves: Tab '
        'back in rings', (tester) async {
      await tester.pumpWidget(_app());
      await _mouseClick(tester, tester.getCenter(find.byType(RichEditor)));
      expect(_ringShown(tester), isFalse);

      // Leave, then come back by keyboard: this focus is new.
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      expect(_ringShown(tester), isTrue);
    }, variant: desktop);
  });
}
