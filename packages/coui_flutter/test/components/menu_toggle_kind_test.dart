import 'package:coui_core/coui_core.dart';
import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    CoUIApp(
      theme: ThemeData.fromCore(CoreThemePresets.light),
      home: Align(child: SizedBox(width: 240, child: child)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('a toggle entry reports the kind it was built as', () {
    testWidgets('a checked checkbox toggles off', (tester) async {
      // The bug this pins: the branch deciding between "toggle" and
      // "always select" compared the drawn glyph against a specific
      // icon constant. Changing the checkmark — a purely visual
      // decision, and one the icon-catalog work makes — stopped the
      // comparison matching, and every checkbox silently became a radio
      // that could be turned on but never off.
      bool? reported;
      await _pump(
        tester,
        Menu(
          items: [
            CoreMenuItem.checkbox(
              'Wrap lines',
              checked: true,
              onChanged: (v) => reported = v,
            ),
          ],
        ),
      );

      await tester.tap(find.text('Wrap lines'));
      await tester.pumpAndSettle();

      expect(
        reported,
        isFalse,
        reason: 'a checked checkbox reported $reported instead of false',
      );
    });

    testWidgets('an unchecked checkbox toggles on', (tester) async {
      bool? reported;
      await _pump(
        tester,
        Menu(
          items: [
            CoreMenuItem.checkbox('Wrap lines', onChanged: (v) => reported = v),
          ],
        ),
      );

      await tester.tap(find.text('Wrap lines'));
      await tester.pumpAndSettle();

      expect(reported, isTrue);
    });

    testWidgets('a selected radio stays selected', (tester) async {
      // The other half. A radio is not a toggle — activating the
      // already-selected option selects it again rather than clearing
      // it, which is what makes a group always have an answer.
      bool? reported;
      await _pump(
        tester,
        Menu(
          items: [
            CoreMenuItem.radio(
              'Compact',
              selected: true,
              onChanged: (v) => reported = v,
            ),
          ],
        ),
      );

      await tester.tap(find.text('Compact'));
      await tester.pumpAndSettle();

      expect(reported, isTrue);
    });
  });
}
