// The outer focus ring is a keyboard signal (#5747), read back under the
// framework's own focus-highlight strategy (`automatic`) and driven by real
// pointer and key events.
//
// `input_redesign_test.dart` forces the strategy to `alwaysTouch` /
// `alwaysTraditional`, which cannot tell a mouse from a keyboard: a mouse
// never moves `FocusManager.highlightMode` off `traditional` on a desktop, so
// a click rang the field while that test stayed green.

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(List<Widget> children) => material.MaterialApp(
  home: material.Scaffold(
    body: Theme(
      data: const ThemeData(),
      child: Center(
        child: SizedBox(
          width: 240,
          child: Column(mainAxisSize: MainAxisSize.min, children: children),
        ),
      ),
    ),
  ),
);

const _firstKey = ValueKey<String>('first');
const _secondKey = ValueKey<String>('second');

bool _ringShown(WidgetTester tester, Key field) => tester
    .widget<FocusOutline>(
      find
          .descendant(
            of: find.byKey(field),
            matching: find.byType(FocusOutline),
          )
          .first,
    )
    .focused;

Finder _editableIn(Key field) => find.descendant(
  of: find.byKey(field),
  matching: find.byType(EditableText),
);

bool _hasFocus(WidgetTester tester, Key field) =>
    tester.widget<EditableText>(_editableIn(field)).focusNode.hasFocus;

Future<void> _mouseClick(WidgetTester tester, Finder target) async {
  final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
  addTearDown(gesture.removePointer);
  final at = tester.getCenter(target);
  await gesture.addPointer(location: Offset.zero);
  await gesture.moveTo(at);
  await gesture.down(at);
  await gesture.up();
  await tester.pumpAndSettle();
}

Future<void> _shiftTab(WidgetTester tester) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
  await tester.sendKeyEvent(LogicalKeyboardKey.tab);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
  await tester.pumpAndSettle();
}

void main() {
  // A desktop target: where the framework's highlight mode starts at
  // `traditional` and a mouse leaves it there.
  final desktop = TargetPlatformVariant.only(TargetPlatform.macOS);

  for (final entry in <String, Widget Function(Key key)>{
    'TextField': (key) => TextField(key: key),
    'TextArea': (key) => TextArea(key: key),
  }.entries) {
    group('${entry.key} — the outer ring under real input', () {
      testWidgets('a mouse click draws no ring', (tester) async {
        await tester.pumpWidget(_app([entry.value(_firstKey)]));
        await _mouseClick(tester, _editableIn(_firstKey));

        expect(_hasFocus(tester, _firstKey), isTrue);
        expect(_ringShown(tester, _firstKey), isFalse);
      }, variant: desktop);

      testWidgets('typing after a mouse click does not turn the ring on', (
        tester,
      ) async {
        await tester.pumpWidget(_app([entry.value(_firstKey)]));
        await _mouseClick(tester, _editableIn(_firstKey));
        await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
        await tester.pumpAndSettle();

        expect(_hasFocus(tester, _firstKey), isTrue);
        expect(_ringShown(tester, _firstKey), isFalse);
      }, variant: desktop);

      testWidgets('a touch tap draws no ring', (tester) async {
        await tester.pumpWidget(_app([entry.value(_firstKey)]));
        await tester.tap(_editableIn(_firstKey));
        await tester.pumpAndSettle();

        expect(_hasFocus(tester, _firstKey), isTrue);
        expect(_ringShown(tester, _firstKey), isFalse);
      }, variant: desktop);

      testWidgets('Tab into the field draws the ring', (tester) async {
        await tester.pumpWidget(_app([entry.value(_firstKey)]));
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();

        expect(_hasFocus(tester, _firstKey), isTrue);
        expect(_ringShown(tester, _firstKey), isTrue);
      }, variant: desktop);

      testWidgets('a field a mouse focused rings when the keyboard returns '
          'to it', (tester) async {
        await tester.pumpWidget(
          _app([entry.value(_firstKey), entry.value(_secondKey)]),
        );
        await _mouseClick(tester, _editableIn(_firstKey));
        expect(_ringShown(tester, _firstKey), isFalse);

        // Tab moves on to the second field: the first loses focus and the
        // click that focused it is spent.
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
        expect(_hasFocus(tester, _secondKey), isTrue);
        expect(_ringShown(tester, _secondKey), isTrue);
        expect(_ringShown(tester, _firstKey), isFalse);

        // Shift+Tab comes back by keyboard: this focus is new.
        await _shiftTab(tester);
        expect(_hasFocus(tester, _firstKey), isTrue);
        expect(_ringShown(tester, _firstKey), isTrue);
      }, variant: desktop);

      testWidgets('a click on the field the keyboard already focused keeps '
          'its ring', (tester) async {
        await tester.pumpWidget(_app([entry.value(_firstKey)]));
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
        expect(_ringShown(tester, _firstKey), isTrue);

        // Focus does not arrive again, so nothing re-judges it.
        await _mouseClick(tester, _editableIn(_firstKey));
        expect(_hasFocus(tester, _firstKey), isTrue);
        expect(_ringShown(tester, _firstKey), isTrue);
      }, variant: desktop);
    });
  }
}
