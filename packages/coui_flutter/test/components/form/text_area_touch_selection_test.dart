// Pins touch selection on `TextArea`.
//
// The area wired a plain tap detector (focus only), hard-coded
// `showSelectionHandles: false` and exposed no magnifier — on a phone its
// text could not be selected with a finger. It now builds the same
// selection gesture stack `TextField` does. These cases read what the
// `EditableText` was handed after a touch long-press, so they fail on a
// build that merely declares the pieces.

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget child) => material.MaterialApp(
  home: Theme(
    data: const ThemeData(),
    child: material.Scaffold(body: Center(child: child)),
  ),
);

EditableText _editable(WidgetTester tester) =>
    tester.widget<EditableText>(find.byType(EditableText));

void main() {
  group('TextArea touch selection', () {
    testWidgets(
      'a long-press selects a word and shows the handles',
      (tester) async {
        final controller = TextEditingController(text: 'hello world');
        addTearDown(controller.dispose);
        await tester.pumpWidget(_app(TextArea(controller: controller)));

        expect(_editable(tester).showSelectionHandles, isFalse);

        // On the first word — the area is taller than its one line, so its
        // centre is empty space below the text.
        await tester.longPressAt(
          tester.getTopLeft(find.byType(EditableText)) + const Offset(12, 8),
        );
        await tester.pumpAndSettle();

        expect(controller.selection.isCollapsed, isFalse);
        expect(_editable(tester).showSelectionHandles, isTrue);
      },
      variant: const TargetPlatformVariant({TargetPlatform.android}),
    );

    testWidgets('a tap still focuses the area and reports onTap', (
      tester,
    ) async {
      var taps = 0;
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);
      await tester.pumpWidget(
        _app(TextArea(focusNode: focusNode, onTap: () => taps++)),
      );

      await tester.tap(find.byType(EditableText));
      await tester.pump();

      expect(focusNode.hasFocus, isTrue);
      expect(taps, 1);
    });

    testWidgets('a disabled area takes no focus from a tap', (tester) async {
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);
      await tester.pumpWidget(
        _app(TextArea(focusNode: focusNode, enabled: false)),
      );

      await tester.tap(find.byType(EditableText), warnIfMissed: false);
      await tester.pump();

      expect(focusNode.hasFocus, isFalse);
    });
  });

  group('TextArea magnifierConfiguration', () {
    testWidgets('defaults to the platform magnifier', (tester) async {
      await tester.pumpWidget(_app(TextArea()));

      expect(
        _editable(tester).magnifierConfiguration,
        same(material.TextMagnifier.adaptiveMagnifierConfiguration),
      );
    });

    testWidgets('an explicit configuration wins', (tester) async {
      await tester.pumpWidget(
        _app(
          TextArea(magnifierConfiguration: TextMagnifierConfiguration.disabled),
        ),
      );

      expect(
        _editable(tester).magnifierConfiguration,
        same(TextMagnifierConfiguration.disabled),
      );
    });
  });
}
