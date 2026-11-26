import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

material.Widget _buildApp(material.Widget child) => material.MaterialApp(
  home: Theme(data: const ThemeData(), child: child),
);

void main() {
  testWidgets(
    'trigger shows the click cursor under an ambient SelectionArea',
    (tester) async {
      // Mirrors CoUIApp.enableWebTextSelection — without the trigger's
      // SelectionContainer.disabled, the selectable text fragment
      // registers the deepest hit-test annotation with a `text` cursor
      // and beats the trigger MouseRegion's `click`.
      await tester.pumpWidget(
        _buildApp(
          material.SelectionArea(
            child: Center(
              child: HoverCard(
                trigger: const Text('@coui'),
                content: const Text('content'),
              ),
            ),
          ),
        ),
      );

      final gesture = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      await gesture.addPointer(location: Offset.zero);
      await tester.pump();
      await gesture.moveTo(tester.getCenter(find.text('@coui')));
      await tester.pump();

      expect(
        RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
        SystemMouseCursors.click,
      );

      // Leave the trigger before teardown so the hover-open delay timer
      // resolves without opening the card mid-teardown.
      await gesture.moveTo(Offset.zero);
      await gesture.removePointer();
      await tester.pumpAndSettle(const Duration(seconds: 1));
    },
  );
}
