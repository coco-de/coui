// Pins the divider's runtime states — resting, hover, dragging, focus — to
// the values the redesign states: a 1px `outlineVariant` line, 1px `outline`
// on hover, a 2px `primary` line while dragged, and the shared focus ring
// (keyboard focus only) over the resting line. The grab area is its own 8px
// and does not follow the line.

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart' as material;
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

const _kPanes = <CoreResizablePaneData<Widget>>[
  CoreResizablePaneData(content: Text('left')),
  CoreResizablePaneData(content: Text('right')),
];

Widget _app(Widget child) => material.MaterialApp(
  home: Theme(
    data: const ThemeData(),
    child: material.Scaffold(
      body: material.SizedBox(width: 400, height: 200, child: child),
    ),
  ),
);

Color _token(WidgetTester tester, CoreColor token) => Theme.of(
  tester.element(find.byType(Resizable)),
).colorScheme.resolve(token).toValue();

AnimatedContainer _line(WidgetTester tester) =>
    tester.widget<AnimatedContainer>(find.byType(AnimatedContainer).first);

Color? _lineColor(WidgetTester tester) {
  final decoration = _line(tester).decoration;

  return decoration is BoxDecoration ? decoration.color : null;
}

double? _lineWidth(WidgetTester tester) => _line(tester).constraints?.maxWidth;

void main() {
  group('Resizable divider states', () {
    testWidgets('resting is a 1px outlineVariant line', (tester) async {
      await tester.pumpWidget(_app(const Resizable(panes: _kPanes)));

      expect(
        _lineColor(tester),
        _token(tester, CoreResizableStyle.defaultDividerColor),
      );
      expect(_lineWidth(tester), CoreStrokeWidth.stroke1);
    });

    testWidgets('hover is the 1px outline line', (tester) async {
      await tester.pumpWidget(_app(const Resizable(panes: _kPanes)));
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(
        tester.getCenter(find.byType(AnimatedContainer).first),
      );
      await tester.pumpAndSettle();

      expect(
        _lineColor(tester),
        _token(tester, CoreResizableStyle.defaultDividerHoverColor),
      );
      expect(_lineWidth(tester), CoreStrokeWidth.stroke1);
    });

    testWidgets('dragging is the 2px primary line, grab area unchanged', (
      tester,
    ) async {
      await tester.pumpWidget(_app(const Resizable(panes: _kPanes)));
      final hitBefore = tester
          .getSize(find.byType(GestureDetector).first)
          .width;
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(AnimatedContainer).first),
      );
      await gesture.moveBy(const Offset(10, 0));
      await tester.pumpAndSettle();

      expect(
        _lineColor(tester),
        _token(tester, CoreResizableStyle.defaultDividerDraggingColor),
      );
      expect(_lineWidth(tester), CoreStrokeWidth.stroke2);
      expect(
        tester.getSize(find.byType(GestureDetector).first).width,
        hitBefore,
      );
      expect(hitBefore, CoreResizableStyle.defaultDividerHitExtent);
      await gesture.up();
    });

    testWidgets('keyboard focus keeps the resting line and shows the ring', (
      tester,
    ) async {
      await tester.pumpWidget(_app(const Resizable(panes: _kPanes)));
      expect(
        tester.widget<FocusOutline>(find.byType(FocusOutline).first).focused,
        isFalse,
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      expect(
        tester.widget<FocusOutline>(find.byType(FocusOutline).first).focused,
        isTrue,
      );
      expect(
        _lineColor(tester),
        _token(tester, CoreResizableStyle.defaultDividerColor),
      );
      expect(_lineWidth(tester), CoreStrokeWidth.stroke1);
    });
  });
}
