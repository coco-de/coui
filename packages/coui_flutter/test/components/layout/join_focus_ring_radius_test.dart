// Pins that a Join member's focus RING follows the same seam corners its
// chrome does.
//
// The chrome already took the join's per-item radius (`JoinItemData`), but
// the ring's radius was built from the button's own shape and never looked
// at the join — so a middle item painted a square box inside a rounded ring.
// It stayed hidden while the ring was clipped away entirely; letting the
// ring out made it visible.
//
// The obvious fix is the wrong one. `JoinItemData.borderRadius` is
// paint-ready — geometry applied, `* scaling` applied — while the ring's
// radius is handed to `FocusOutline`, which applies both again. Forwarding
// the paint-ready value would round the ring by `scaling²`. That is why the
// scaled-theme case compares the ring against the chrome instead of against
// a constant: at `scaling == 1` a double scale is invisible.

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

/// Not 1 — the only scale at which scaling twice and scaling once differ.
const double _kScaling = 1.25;

Widget _app(Widget child, {double scaling = 1}) => material.MaterialApp(
  home: Theme(
    data: ThemeData(scaling: scaling),
    child: material.Center(child: child),
  ),
);

Widget _strip() => Join(
  children: [
    for (final label in ['A', 'B', 'C'])
      Button(variant: .outline, onPressed: () {}, child: Text(label)),
  ],
);

Finder _ringOf(Finder host) =>
    find.descendant(of: host, matching: find.byType(FocusOutline)).first;

/// The raw radius the button hands its ring.
CoreBorderRadius _ringCoreRadius(WidgetTester tester, String label) => tester
    .widget<FocusOutline>(_ringOf(find.widgetWithText(Button, label)))
    .focusOutlineStyle!
    .borderRadius!;

/// The radius the ring actually paints with — resolved exactly as the
/// `FocusOutline` widget resolves it, scaling included.
BorderRadius _ringPaintRadius(WidgetTester tester, Finder host) {
  final ring = _ringOf(host);

  return resolveFocusOutline(
        tester.element(ring),
        widgetStyle: tester.widget<FocusOutline>(ring).focusOutlineStyle,
      ).borderRadius!
      as BorderRadius;
}

/// The radius the button's chrome paints with.
BorderRadius _chromeRadius(WidgetTester tester, String label) {
  final decoration = tester
      .widgetList<material.AnimatedContainer>(
        find.descendant(
          of: find.widgetWithText(Button, label),
          matching: find.byType(material.AnimatedContainer),
        ),
      )
      .map((w) => w.decoration)
      .whereType<BoxDecoration>()
      .firstWhere((d) => d.borderRadius != null);

  return decoration.borderRadius! as BorderRadius;
}

void main() {
  group('Join focus ring radius', () {
    testWidgets("a middle item's ring is square at both seams", (
      tester,
    ) async {
      await tester.pumpWidget(_app(_strip()));

      expect(
        _ringCoreRadius(tester, 'B'),
        CoreBorderRadius.zero,
        reason: 'the box is square on both sides, so its ring must be too',
      );
    });

    testWidgets('the end items round only their outer corners', (
      tester,
    ) async {
      await tester.pumpWidget(_app(_strip()));

      final first = _ringCoreRadius(tester, 'A');
      final last = _ringCoreRadius(tester, 'C');

      expect(first.topLeft, isNot(0));
      expect(first.bottomLeft, isNot(0));
      expect(first.topRight, 0);
      expect(first.bottomRight, 0);

      expect(last.topRight, isNot(0));
      expect(last.bottomRight, isNot(0));
      expect(last.topLeft, 0);
      expect(last.bottomLeft, 0);
    });

    testWidgets('a vertical strip squares the top and bottom seams', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          Join(
            vertical: true,
            children: [
              for (final label in ['A', 'B'])
                Button(variant: .outline, onPressed: () {}, child: Text(label)),
            ],
          ),
        ),
      );

      final top = _ringCoreRadius(tester, 'A');
      expect(top.topLeft, isNot(0));
      expect(top.topRight, isNot(0));
      expect(top.bottomLeft, 0);
      expect(top.bottomRight, 0);
    });

    testWidgets('under a scaled theme the ring is scaled exactly once', (
      tester,
    ) async {
      await tester.pumpWidget(_app(_strip(), scaling: _kScaling));

      // The chrome is the reference: it is scaled once, by the resolver.
      // A ring handed the chrome's already-scaled radius would come out
      // `_kScaling` times larger than it.
      for (final label in ['A', 'B', 'C']) {
        expect(
          _ringPaintRadius(tester, find.widgetWithText(Button, label)),
          _chromeRadius(tester, label),
          reason: 'ring and box must agree on every corner of $label',
        );
      }
      // Guard the guard: the outer corner is actually rounded, so the
      // comparison above is not two zeros agreeing.
      expect(_chromeRadius(tester, 'A').topLeft, isNot(Radius.zero));
    });

    testWidgets("a middle TextField's ring is square too", (tester) async {
      await tester.pumpWidget(
        _app(
          material.SizedBox(
            width: 480,
            child: Join(
              children: [
                Button(
                  variant: .outline,
                  onPressed: () {},
                  child: const Text('L'),
                ),
                material.SizedBox(width: 200, child: TextField()),
                Button(
                  variant: .outline,
                  onPressed: () {},
                  child: const Text('R'),
                ),
              ],
            ),
          ),
          scaling: _kScaling,
        ),
      );

      expect(
        tester
            .widget<FocusOutline>(_ringOf(find.byType(TextField)))
            .focusOutlineStyle!
            .borderRadius,
        CoreBorderRadius.zero,
      );
    });

    testWidgets("a lone Button's ring still hugs its own corners", (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          Button(variant: .outline, onPressed: () {}, child: const Text('솔로')),
          scaling: _kScaling,
        ),
      );

      final ring = _ringPaintRadius(tester, find.widgetWithText(Button, '솔로'));
      expect(ring, _chromeRadius(tester, '솔로'));
      expect(ring.topLeft, isNot(Radius.zero));
    });
  });
}
