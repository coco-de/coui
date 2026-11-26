// Pins `min` / `max` to something Flutter actually does.
//
// Both fields were declared on the contract and on both widgets, and the
// Flutter widget read neither: `widget.min` / `widget.max` appeared only
// in the constructor, the field list and `copyWith`. Web emitted
// `<input min max>` and got browser constraint validation for free, so
// the same two lines of caller code produced a constraint on one platform
// and nothing at all on the other.
//
// What these cases pin, and what they deliberately do not:
//
//   The fix reports the violation through the error chrome the field
//   already has. It does *not* clamp. A browser leaves `99` sitting in a
//   `max="10"` field and only marks it `:invalid`; clamping would make
//   Flutter quietly rewrite what someone typed while Web preserved it,
//   which is a new divergence wearing the old one's clothes. The
//   `does not rewrite` case is the guard on that, and it is the one that
//   matters most — a clamping implementation passes every other case here.

import 'package:coui_core/coui_core.dart';
import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget child) => material.MaterialApp(
  home: Theme(
    data: const ThemeData(),
    child: material.Scaffold(body: child),
  ),
);

/// The border colour of the field's chrome container.
///
/// Read off the decoration the resolver produced rather than off a
/// golden, so the assertion is "the error tone was selected", not "these
/// exact pixels".
Color? _borderColour(WidgetTester tester) {
  final container = tester
      .widgetList<Container>(find.byType(Container))
      .where((c) => c.decoration is BoxDecoration)
      .map((c) => c.decoration! as BoxDecoration)
      .firstWhere((d) => d.border != null);

  return (container.border! as Border).top.color;
}

void main() {
  group('TextField min/max', () {
    testWidgets('in-range text draws no error tone', (tester) async {
      await tester.pumpWidget(
        _app(
          TextField(
            controller: TextEditingController(text: '5'),
            type: CoreInputType.number,
            min: 0,
            max: 10,
          ),
        ),
      );

      final neutral = _borderColour(tester);

      await tester.pumpWidget(
        _app(
          TextField(controller: TextEditingController(text: '5')),
        ),
      );

      expect(_borderColour(tester), equals(neutral));
    });

    testWidgets('out-of-range text draws the error tone', (tester) async {
      await tester.pumpWidget(
        _app(
          TextField(
            controller: TextEditingController(text: '5'),
            type: CoreInputType.number,
            min: 0,
            max: 10,
          ),
        ),
      );
      final neutral = _borderColour(tester);

      await tester.pumpWidget(
        _app(
          TextField(
            controller: TextEditingController(text: '99'),
            type: CoreInputType.number,
            min: 0,
            max: 10,
          ),
        ),
      );

      expect(_borderColour(tester), isNot(equals(neutral)));
    });

    testWidgets('the violation tone is the errorText tone', (tester) async {
      await tester.pumpWidget(
        _app(
          TextField(
            controller: TextEditingController(text: '5'),
            errorText: 'nope',
          ),
        ),
      );
      final errorTone = _borderColour(tester);

      await tester.pumpWidget(
        _app(
          TextField(
            controller: TextEditingController(text: '99'),
            type: CoreInputType.number,
            min: 0,
            max: 10,
          ),
        ),
      );

      expect(
        _borderColour(tester),
        equals(errorTone),
        reason: 'a range violation is an error, not a third state',
      );
    });

    testWidgets('does not rewrite the typed value', (tester) async {
      final controller = TextEditingController();
      await tester.pumpWidget(
        _app(
          TextField(
            controller: controller,
            type: CoreInputType.number,
            min: 0,
            max: 10,
          ),
        ),
      );

      await tester.enterText(find.byType(EditableText), '99');
      await tester.pump();

      expect(
        controller.text,
        equals('99'),
        reason:
            'the browser preserves out-of-range text — clamping here '
            'would make Flutter disagree with Web',
      );
    });

    testWidgets('the verdict follows the text across the boundary', (
      tester,
    ) async {
      final controller = TextEditingController(text: '5');
      await tester.pumpWidget(
        _app(
          TextField(
            controller: controller,
            type: CoreInputType.number,
            min: 0,
            max: 10,
          ),
        ),
      );
      final neutral = _borderColour(tester);

      controller.text = '99';
      await tester.pump();
      expect(_borderColour(tester), isNot(equals(neutral)));

      controller.text = '5';
      await tester.pump();
      expect(_borderColour(tester), equals(neutral));
    });

    testWidgets('moving the bounds re-judges unchanged text', (tester) async {
      final controller = TextEditingController(text: '50');
      await tester.pumpWidget(
        _app(
          TextField(
            controller: controller,
            type: CoreInputType.number,
            min: 0,
            max: 100,
          ),
        ),
      );
      final neutral = _borderColour(tester);

      await tester.pumpWidget(
        _app(
          TextField(
            controller: controller,
            type: CoreInputType.number,
            min: 0,
            max: 10,
          ),
        ),
      );

      expect(_borderColour(tester), isNot(equals(neutral)));
    });
  });
}
