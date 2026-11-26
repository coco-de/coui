// The field supplies `WidgetState.pressed` itself.
//
// The style already washes the fill under a pressed state layer (Select
// states a pressed-only one), and its own tests prove it by resolving the
// decoration with `{pressed}` handed in — which says nothing about whether a
// real press ever puts that state there. The field never did, so the wash the
// Core style states was never painted on Flutter. Here a real pointer is held
// on the field and the painted fill is read back.

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

/// The wash Select states: pressed only, nothing for hover or focus.
const _pressedOnly = CoreTextFieldStyle(
  stateLayer: CoreStateLayer(hover: 0, focus: 0, pressed: CoreOpacity.pressed),
);

Widget _app({bool enabled = true, CoreTextFieldStyle? style}) =>
    material.MaterialApp(
      home: material.Scaffold(
        body: Theme(
          data: const ThemeData(),
          child: Center(
            child: SizedBox(
              width: 240,
              child: TextField(enabled: enabled, textFieldStyle: style),
            ),
          ),
        ),
      ),
    );

/// The fill the field's box paints right now.
Color? _fill(WidgetTester tester) {
  final box = tester
      .widgetList<Container>(
        find.descendant(
          of: find.byType(TextField),
          matching: find.byType(Container),
        ),
      )
      // The box that paints the field's fill and its resting edge.
      .firstWhere((c) {
        final decoration = c.decoration;
        return decoration is BoxDecoration &&
            decoration.color != null &&
            decoration.border != null;
      });
  return (box.decoration! as BoxDecoration).color;
}

void main() {
  group('Select — the trigger a user presses', () {
    testWidgets('a held press washes the whole trigger; release returns it', (
      tester,
    ) async {
      await tester.pumpWidget(
        material.MaterialApp(
          home: material.Scaffold(
            body: Theme(
              data: const ThemeData(),
              child: const Center(
                child: SizedBox(
                  width: 240,
                  child: Select<String>(
                    items: [
                      CoreSelectItem(value: 'apple', label: 'Apple'),
                      CoreSelectItem(value: 'banana', label: 'Banana'),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      final rest = _fill(tester);

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      // The chevron end of the trigger — beside the field's own text.
      final at =
          tester.getTopRight(find.byType(Select<String>)) +
          const Offset(-14, 20);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(at);
      await mouse.down(at);
      await tester.pump();
      expect(
        _fill(tester),
        isNot(rest),
        reason: 'Select states a pressed wash',
      );

      await mouse.cancel();
      await tester.pump();
      expect(_fill(tester), rest);
    });
  });

  group('TextField — the pressed state', () {
    testWidgets('a held mouse press washes the field and release returns it', (
      tester,
    ) async {
      await tester.pumpWidget(_app(style: _pressedOnly));
      final rest = _fill(tester);

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      final at = tester.getCenter(find.byType(TextField));
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(at);
      await tester.pump();
      expect(_fill(tester), rest, reason: 'hovering alone washes nothing');

      await mouse.down(at);
      await tester.pump();
      expect(_fill(tester), isNot(rest), reason: 'held: the wash is on');

      await mouse.up();
      await tester.pumpAndSettle();
      expect(_fill(tester), rest, reason: 'released: the wash is gone');
    });

    testWidgets('a held touch press washes and a cancelled one returns', (
      tester,
    ) async {
      await tester.pumpWidget(_app(style: _pressedOnly));
      final rest = _fill(tester);

      final touch = await tester.startGesture(
        tester.getCenter(find.byType(TextField)),
      );
      await tester.pump();
      expect(_fill(tester), isNot(rest));

      await touch.cancel();
      await tester.pump();
      expect(_fill(tester), rest, reason: 'a cancelled press leaves no wash');
    });

    testWidgets('a field that states no pressed wash paints none', (
      tester,
    ) async {
      await tester.pumpWidget(_app());
      final rest = _fill(tester);

      final touch = await tester.startGesture(
        tester.getCenter(find.byType(TextField)),
      );
      await tester.pump();
      expect(_fill(tester), rest);
      await touch.cancel();
    });

    testWidgets('a disabled field takes no press', (tester) async {
      await tester.pumpWidget(_app(enabled: false, style: _pressedOnly));
      final rest = _fill(tester);

      final touch = await tester.startGesture(
        tester.getCenter(find.byType(TextField)),
      );
      await tester.pump();
      expect(_fill(tester), rest);
      await touch.cancel();
    });

    testWidgets('a field disabled mid-press does not come back washed', (
      tester,
    ) async {
      await tester.pumpWidget(_app(style: _pressedOnly));
      final rest = _fill(tester);

      final touch = await tester.startGesture(
        tester.getCenter(find.byType(TextField)),
      );
      await tester.pump();
      expect(_fill(tester), isNot(rest));

      await tester.pumpWidget(_app(enabled: false, style: _pressedOnly));
      await tester.pumpWidget(_app(style: _pressedOnly));
      expect(
        _fill(tester),
        rest,
        reason: 'the up never reaches a listener that was removed',
      );
      await touch.cancel();
    });
  });
}
