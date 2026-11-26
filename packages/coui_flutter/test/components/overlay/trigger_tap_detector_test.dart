// Pins which presses count as a trigger tap.
//
// `PointerEvent.buttons` is a bitmask. The detector compared it for
// equality with the primary button, so a primary press that arrived with
// a second button already held — a chord, or a stylus barrel button,
// `buttons == 3` — was dropped. A lone secondary press must still pass
// through: right-click belongs to the context menu.

import 'package:coui_flutter/src/components/overlay/trigger_tap_detector.dart';
import 'package:flutter/gestures.dart'
    show kMiddleMouseButton, kPrimaryButton, kSecondaryButton;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Future<int> _tapWith(WidgetTester tester, int buttons) async {
  var taps = 0;
  await tester.pumpWidget(
    Directionality(
      textDirection: .ltr,
      child: Center(
        child: TriggerTapDetector(
          onTap: () => taps++,
          // Painted, so the `Listener` (defer-to-child) is hit at all.
          child: const ColoredBox(
            color: Color(0xFF000000),
            child: SizedBox.square(dimension: 40),
          ),
        ),
      ),
    ),
  );

  final gesture = await tester.startGesture(
    tester.getCenter(find.byType(TriggerTapDetector)),
    buttons: buttons,
  );
  await gesture.up();
  await tester.pump();
  return taps;
}

void main() {
  group('TriggerTapDetector', () {
    testWidgets('a primary press is a tap', (tester) async {
      expect(await _tapWith(tester, kPrimaryButton), 1);
    });

    testWidgets('a primary press chorded with another button is a tap', (
      tester,
    ) async {
      expect(await _tapWith(tester, kPrimaryButton | kSecondaryButton), 1);
    });

    testWidgets('a lone secondary press is not', (tester) async {
      expect(await _tapWith(tester, kSecondaryButton), 0);
    });

    testWidgets('a lone middle press is not', (tester) async {
      expect(await _tapWith(tester, kMiddleMouseButton), 0);
    });
  });
}
