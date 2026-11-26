import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

// Tooltip now drives its overlay through the shared `PopoverOverlayHandler`
// engine directly (the same one Popover uses), instead of the deprecated
// `OverlayManager` / `PopoverController`. It therefore works with only a
// `MaterialApp` (root Overlay) ancestor — no `OverlayManager` / `CoUILayer`
// needed. This test pins that decoupling.
void main() {
  testWidgets(
    'Tooltip shows on hover with NO OverlayManager ancestor (engine-direct)',
    (tester) async {
      // Only a CoUI `Theme` (which every CoUI component needs) — explicitly
      // NO `CoUILayer` / `OverlayManager`. If the tooltip still shows, it is
      // driving its overlay through the engine, not the overlay manager.
      await tester.pumpWidget(
        material.MaterialApp(
          builder: (context, navigator) => Theme(
            data: const ThemeData(),
            child: navigator ?? const material.SizedBox.shrink(),
          ),
          home: const material.Scaffold(
            body: material.Center(
              child: Tooltip(
                message: 'tip-text',
                child: material.Text('target'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('tip-text'), findsNothing);

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await gesture.moveTo(tester.getCenter(find.text('target')));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      expect(find.text('tip-text'), findsOneWidget);

      // Hover out dismisses it (pump past the hide delay + close animation).
      await gesture.moveTo(Offset.zero);
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(find.text('tip-text'), findsNothing);
    },
  );
}
