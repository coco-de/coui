import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

// HoverCard now drives its overlay through the shared `PopoverOverlayHandler`
// engine directly (like Popover / Tooltip), instead of the deprecated
// `OverlayManager` / `PopoverController`. It therefore works with only a CoUI
// `Theme` + `MaterialApp` (root Overlay) — no `OverlayManager` / `CoUILayer`.
void main() {
  testWidgets(
    'HoverCard shows on hover with NO OverlayManager ancestor (engine-direct)',
    (tester) async {
      await tester.pumpWidget(
        material.MaterialApp(
          builder: (context, navigator) => Theme(
            data: const ThemeData(),
            child: navigator ?? const material.SizedBox.shrink(),
          ),
          home: const material.Scaffold(
            body: material.Center(
              child: HoverCard(
                trigger: material.Text('trigger-x'),
                content: material.Text('card-content'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('card-content'), findsNothing);

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await gesture.moveTo(tester.getCenter(find.text('trigger-x')));
      await tester.pump();
      // Pass the open delay before the card overlay mounts.
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      expect(find.text('card-content'), findsOneWidget);
    },
  );
}
