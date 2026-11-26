import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

const _message = '툴팁';
const _trigger = 'hover me';

/// A tooltip draws no tail by default; these tests are about the tail, so
/// each states one (12 × 6).
const _kTailed = CoreTooltipStyle(
  tailWidth: CoreSpace.space12,
  tailHeight: CoreSpace.space6,
);

material.Widget _buildApp(material.Widget child) => material.MaterialApp(
  home: Theme(
    data: const ThemeData(),
    child: material.Center(child: child),
  ),
);

/// The default 800×600 surface with the trigger pinned by [alignment] — an
/// edge placement is what makes the engine flip the bubble.
material.Widget _buildPlaced({
  required Alignment alignment,
  required CoreTooltipPosition position,
  required Size triggerSize,
}) => material.MaterialApp(
  home: Theme(
    data: const ThemeData(),
    child: Align(
      alignment: alignment,
      child: Tooltip(
        message: _message,
        tooltipStyle: _kTailed,
        position: position,
        child: SizedBox.fromSize(
          size: triggerSize,
          child: const Text(_trigger),
        ),
      ),
    ),
  ),
);

final Finder _tailFinder = find.byWidgetPredicate(
  (w) =>
      w is material.CustomPaint &&
      w.painter.runtimeType.toString() == '_TailPainter',
);

/// Hovers the trigger and waits out the hover delay and the open
/// animation, then the one frame the flip report takes to arrive.
Future<TestGesture> _hoverOpen(WidgetTester tester) async {
  final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await gesture.addPointer(location: Offset.zero);
  await tester.pump();
  await gesture.moveTo(tester.getCenter(find.byType(SizedBox).last));
  await tester.pump(const Duration(seconds: 1));
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump();

  return gesture;
}

Future<void> _hoverClose(WidgetTester tester, TestGesture gesture) async {
  await gesture.moveTo(Offset.zero);
  await gesture.removePointer();
  await tester.pumpAndSettle(const Duration(seconds: 1));
}

/// The painted bubble — the decorated box the message sits in.
Rect _bubbleRect(WidgetTester tester) => tester.getRect(
  find
      .ancestor(
        of: find.text(_message),
        matching: find.byType(DecoratedBox),
      )
      .first,
);

void main() {
  testWidgets('hovered tooltip paints the trigger-pointing tail', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildApp(
        const Tooltip(
          message: _message,
          tooltipStyle: _kTailed,
          child: Text(_trigger),
        ),
      ),
    );

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    await tester.pump();
    await gesture.moveTo(tester.getCenter(find.text(_trigger)));
    // Hover wait + open animation.
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text(_message), findsOneWidget);
    expect(_tailFinder, findsOneWidget);

    await _hoverClose(tester, gesture);
  });

  // The engine flips a bubble that would leave the viewport. The tail is
  // drawn by the tooltip, not the engine, so it has to be told about the
  // flip or it stays on the requested edge — pointing away from the
  // trigger it is supposed to indicate.
  group('the tail follows a flipped bubble', () {
    testWidgets('vertical flip — a top tooltip pushed below its trigger '
        'points up', (tester) async {
      await tester.pumpWidget(
        _buildPlaced(
          alignment: Alignment.topCenter,
          position: .top,
          triggerSize: const Size(384, 48),
        ),
      );
      final gesture = await _hoverOpen(tester);

      final trigger = tester.getRect(find.byType(SizedBox).last);
      final bubble = _bubbleRect(tester);
      final tail = tester.getRect(_tailFinder);

      expect(
        bubble.top,
        greaterThanOrEqualTo(trigger.bottom),
        reason:
            'the harness has to make the engine flip, or this test '
            'passes on the bug',
      );
      expect(
        tail.bottom,
        lessThanOrEqualTo(bubble.top),
        reason:
            'tail $tail sits on bubble $bubble below the trigger — it '
            'has to be on the edge facing the trigger',
      );
      expect(tail.top, greaterThanOrEqualTo(trigger.bottom));

      await _hoverClose(tester, gesture);
    });

    testWidgets('horizontal flip — a left tooltip pushed right of its '
        'trigger points left', (tester) async {
      await tester.pumpWidget(
        _buildPlaced(
          alignment: Alignment.centerLeft,
          position: .left,
          triggerSize: const Size(40, 96),
        ),
      );
      final gesture = await _hoverOpen(tester);

      final trigger = tester.getRect(find.byType(SizedBox).last);
      final bubble = _bubbleRect(tester);
      final tail = tester.getRect(_tailFinder);

      expect(
        bubble.left,
        greaterThanOrEqualTo(trigger.right),
        reason:
            'the harness has to make the engine flip, or this test '
            'passes on the bug',
      );
      expect(
        tail.right,
        lessThanOrEqualTo(bubble.left),
        reason:
            'tail $tail sits on bubble $bubble right of the trigger — '
            'it has to be on the edge facing the trigger',
      );
      expect(tail.left, greaterThanOrEqualTo(trigger.right));

      await _hoverClose(tester, gesture);
    });

    testWidgets('no flip — a centred top tooltip keeps its tail where it '
        'was', (tester) async {
      await tester.pumpWidget(
        _buildPlaced(
          alignment: Alignment.center,
          position: .top,
          triggerSize: const Size(384, 48),
        ),
      );
      final gesture = await _hoverOpen(tester);

      final bubble = _bubbleRect(tester);
      final tail = tester.getRect(_tailFinder);

      // Measured before the tail learned about flips; nothing flips here,
      // so nothing may move.
      expect(tail, const Rect.fromLTRB(394, 268, 406, 274));
      expect(tail.top, greaterThanOrEqualTo(bubble.bottom));

      await _hoverClose(tester, gesture);
    });
  });
}
