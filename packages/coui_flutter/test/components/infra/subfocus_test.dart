import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

material.Widget _buildApp(material.Widget child) => material.MaterialApp(
  home: Theme(data: const ThemeData(), child: child),
);

void main() {
  group('SubfocusScope arrow traversal', () {
    testWidgets('tap focuses the scope and arrows move the subfocus', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          material.Center(
            child: SubfocusScope(
              child: material.Column(
                mainAxisSize: .min,
                children: const [
                  Subfocus(focusId: 'a', child: material.Text('A')),
                  Subfocus(focusId: 'b', child: material.Text('B')),
                  Subfocus(focusId: 'c', child: material.Text('C')),
                ],
              ),
            ),
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      bool focusedOf(String label) {
        final outline = tester.widget<FocusOutline>(
          find.ancestor(
            of: find.text(label),
            matching: find.byType(FocusOutline),
          ),
        );
        return outline.focused;
      }

      // Tap moves the subfocus but keeps the ring hidden — the ring is
      // keyboard-interaction feedback (Web `:focus-visible` mirror).
      await tester.tap(find.text('A'));
      final __ = await tester.pumpAndSettle();
      expect(focusedOf('A'), isFalse);

      // Arrow traversal starts from the tapped item and shows the ring.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      final ___ = await tester.pumpAndSettle();
      expect(focusedOf('A'), isFalse);
      expect(focusedOf('B'), isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      final ____ = await tester.pumpAndSettle();
      expect(focusedOf('C'), isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      final _____ = await tester.pumpAndSettle();
      expect(focusedOf('B'), isTrue);
    });
  });
}
