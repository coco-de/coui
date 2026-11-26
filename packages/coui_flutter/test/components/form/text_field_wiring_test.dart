// Pins three `TextField` parameters that were declared, stored and copied
// but read by nothing: `onTapUpOutside`, `statesController`, and the
// magnifier default. Each case reads what reached the framework — the
// callback firing, the controller's value, the `EditableText` argument —
// so it fails on a build where the parameter is only carried around.

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget child) => material.MaterialApp(
  home: Theme(
    data: const ThemeData(),
    child: material.Scaffold(
      body: Column(
        children: [
          child,
          const SizedBox(
            key: ValueKey('outside'),
            width: 200,
            height: 200,
            child: ColoredBox(color: Color(0xFF000000)),
          ),
        ],
      ),
    ),
  ),
);

EditableText _editable(WidgetTester tester) =>
    tester.widget<EditableText>(find.byType(EditableText));

void main() {
  group('TextField onTapUpOutside', () {
    testWidgets('fires for a pointer-up outside the focused field', (
      tester,
    ) async {
      PointerUpEvent? upOutside;
      await tester.pumpWidget(
        _app(
          TextField(
            autofocus: true,
            onTapUpOutside: (event) => upOutside = event,
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey('outside')));
      await tester.pump();

      expect(upOutside, isNotNull);
    });
  });

  group('TextField statesController', () {
    testWidgets('receives focused and disabled as they change', (
      tester,
    ) async {
      final controller = WidgetStatesController();
      addTearDown(controller.dispose);
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);

      await tester.pumpWidget(
        _app(TextField(focusNode: focusNode, statesController: controller)),
      );
      await tester.pump();
      expect(controller.value, isNot(contains(WidgetState.focused)));

      focusNode.requestFocus();
      await tester.pump();
      await tester.pump();
      expect(controller.value, contains(WidgetState.focused));

      await tester.pumpWidget(
        _app(
          TextField(
            focusNode: focusNode,
            statesController: controller,
            enabled: false,
          ),
        ),
      );
      await tester.pump();
      expect(controller.value, contains(WidgetState.disabled));
    });

    testWidgets('receives error and leaves foreign states alone', (
      tester,
    ) async {
      final controller = WidgetStatesController({WidgetState.selected});
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _app(TextField(statesController: controller, errorText: 'Required')),
      );
      await tester.pump();

      expect(controller.value, contains(WidgetState.error));
      expect(
        controller.value,
        contains(WidgetState.selected),
        reason: 'the field writes only the states it owns',
      );
    });
  });

  group('TextField magnifierConfiguration', () {
    testWidgets('defaults to the platform magnifier, not a disabled one', (
      tester,
    ) async {
      await tester.pumpWidget(_app(TextField()));

      final config = _editable(tester).magnifierConfiguration;
      expect(
        config,
        same(material.TextMagnifier.adaptiveMagnifierConfiguration),
      );
    });

    testWidgets('an explicit configuration still wins', (tester) async {
      await tester.pumpWidget(
        _app(
          TextField(
            magnifierConfiguration: TextMagnifierConfiguration.disabled,
          ),
        ),
      );

      expect(
        _editable(tester).magnifierConfiguration,
        same(TextMagnifierConfiguration.disabled),
      );
    });
  });
}
