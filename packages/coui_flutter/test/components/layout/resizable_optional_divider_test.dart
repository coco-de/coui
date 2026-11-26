// Pins `optionalDivider` — the divider hides until it is interacted with.
//
// Two properties matter and they pull in opposite directions:
//
//   1. Hidden means *not painted*, not *not there*. The hit area has to
//      survive, or the seam becomes ungrabbable and the feature is a
//      regression rather than an option. `hidden keeps its hit area` is the
//      guard on that.
//   2. `optionalDivider: false` — the default — has to render byte-identically
//      to before. A knob that quietly changes the default is not opt-in.
//
// `optionalDivider` reaches the resolver, not the widget build: it is a
// build-time semantic prop, so the idle colour is decided where every other
// colour is decided. Choosing it in `build` would put a colour literal in a
// render-only widget, which is what the issue's draft did.

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart' as material;
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

/// The idle divider colour the resolver produced for [optionalDivider].
Color? _idleColour(WidgetTester tester) {
  final containers = tester
      .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
      .toList();
  expect(containers, isNotEmpty, reason: 'the divider line is drawn');

  final decoration = containers.first.decoration;

  return decoration is BoxDecoration ? decoration.color : null;
}

/// Far enough that the divider is pinned at its bound while the pointer
/// keeps going — past the widget's own width, so hover cannot survive.
const _kOutrunDistance = 500.0;

/// A move that stays on the divider, for the touch case where the point is
/// that there is no hover to begin with.
const _kNudgeDistance = 10.0;

void main() {
  group('Resizable optionalDivider', () {
    testWidgets('the default paints an opaque divider', (tester) async {
      await tester.pumpWidget(_app(const Resizable(panes: _kPanes)));
      await tester.pumpAndSettle();

      final colour = _idleColour(tester);
      expect(colour, isNotNull);
      expect(
        colour!.a,
        greaterThan(0),
        reason: 'unchanged behaviour when the knob is off',
      );
    });

    testWidgets('optionalDivider hides the idle divider', (tester) async {
      await tester.pumpWidget(
        _app(const Resizable(panes: _kPanes, optionalDivider: true)),
      );
      await tester.pumpAndSettle();

      expect(_idleColour(tester)?.a, equals(0));
    });

    testWidgets('hidden keeps its hit area', (tester) async {
      // Invisible and ungrabbable are different things. The overlay that
      // owns the drag must still be laid out at full extent.
      await tester.pumpWidget(
        _app(const Resizable(panes: _kPanes, optionalDivider: true)),
      );
      await tester.pumpAndSettle();

      final line = find.byType(AnimatedContainer).first;
      final rect = tester.getRect(line);
      expect(rect.height, greaterThan(0));
      expect(rect.width, greaterThan(0));
    });

    testWidgets(
      'a hidden divider stays revealed for the whole drag, including '
      'after the pointer outruns it',
      (tester) async {
        // The divider pins at its bound while the pointer keeps travelling.
        // That is the moment hover stops being true, and a reveal that
        // rides hover alone goes dark mid-gesture — the user is still
        // holding the thing that just vanished.
        await tester.pumpWidget(
          _app(const Resizable(panes: _kPanes, optionalDivider: true)),
        );
        await tester.pumpAndSettle();

        final gesture = await tester.startGesture(
          tester.getCenter(find.byType(Resizable)),
          kind: PointerDeviceKind.mouse,
        );
        await gesture.moveBy(const Offset(_kOutrunDistance, 0));
        await tester.pump();

        expect(
          _idleColour(tester)?.a,
          greaterThan(0),
          reason: 'the divider being dragged must stay visible',
        );

        await gesture.up();
        await tester.pumpAndSettle();

        // And it hides again once the gesture is over, rather than
        // staying stuck on.
        expect(_idleColour(tester)?.a, equals(0));
      },
    );

    testWidgets('a touch drag reveals it even though touch never hovers', (
      tester,
    ) async {
      // Sharper than the mouse case: a touch pointer produces no hover at
      // all, so hover-only reveal leaves the divider invisible for the
      // entire gesture on every touch device.
      await tester.pumpWidget(
        _app(const Resizable(panes: _kPanes, optionalDivider: true)),
      );
      await tester.pumpAndSettle();

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(Resizable)),
      );
      await gesture.moveBy(const Offset(_kNudgeDistance, 0));
      await tester.pump();

      expect(_idleColour(tester)?.a, greaterThan(0));

      await gesture.up();
      await tester.pumpAndSettle();
      expect(_idleColour(tester)?.a, equals(0));
    });

    testWidgets('the knob survives copyWith', (tester) async {
      const original = Resizable(panes: _kPanes, optionalDivider: true);
      final copy = original.copyWith(showDragHandle: true);

      expect(copy.optionalDivider, isTrue);
      expect(copy.showDragHandle, isTrue);
    });

    testWidgets('the default is off', (tester) async {
      const widget = Resizable(panes: _kPanes);

      expect(
        widget.optionalDivider,
        equals(CoreResizableContract.defaultOptionalDivider),
      );
      expect(CoreResizableContract.defaultOptionalDivider, isFalse);
    });
  });
}
