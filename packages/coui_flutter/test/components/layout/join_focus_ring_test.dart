// Pins that a focused Join member's ring is actually visible.
//
// Two separate things hid it, and fixing either alone leaves the ring half
// drawn:
//
//   1. Every item was clipped by a `ClipRRect` whose rect is exactly the
//      item's box, while the ring band lies ENTIRELY outside that box
//      (align = ringOffset + ringWidth = 4, painted 4px→0px outside). So
//      100% of the ring was cropped, not merely most of it.
//   2. A `Row` paints in child order, so even unclipped, the middle item's
//      right-hand band is painted over by its next sibling.
//
// The clip is DISABLED, not removed. Swapping the `ClipRRect` out changes
// the child slot's widget type, which fails `Widget.canUpdate`, remounts the
// subtree, disposes the focus node the child just acquired and drops focus
// to null — the ring then settles at opacity 0, i.e. the original bug plus a
// focus regression. `clipBehavior` only marks needs-paint, so identity and
// focus survive; `focus survives focusing` is the guard on that.

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget child) => material.MaterialApp(
  home: Theme(
    data: const ThemeData(),
    child: material.Scaffold(
      body: material.Center(child: child),
    ),
  ),
);

/// Explicit nodes so a case can focus a specific member — `Button` creates
/// its own internally and does not expose it.
final _nodes = <String, FocusNode>{
  'A': FocusNode(debugLabel: 'A'),
  'B': FocusNode(debugLabel: 'B'),
  'C': FocusNode(debugLabel: 'C'),
};

Widget _strip() => Join(
  children: [
    for (final label in ['A', 'B', 'C'])
      Button(
        onPressed: () {},
        focusNode: _nodes[label],
        child: Text(label),
      ),
  ],
);

/// The `ClipRRect` wrapping the item that contains [label].
ClipRRect _clipFor(WidgetTester tester, String label) {
  final clip = find.ancestor(
    of: find.text(label),
    matching: find.byType(ClipRRect),
  );
  expect(clip, findsWidgets);

  return tester.widget<ClipRRect>(clip.first);
}

void main() {
  group('Join focus ring', () {
    testWidgets('an unfocused item clips', (tester) async {
      await tester.pumpWidget(_app(_strip()));
      await tester.pumpAndSettle();

      expect(_clipFor(tester, 'B').clipBehavior, equals(Clip.antiAlias));
    });

    testWidgets('the focused item stops clipping', (tester) async {
      await tester.pumpWidget(_app(_strip()));
      await tester.pumpAndSettle();

      // Focus the middle item — the one with a neighbour on both sides.
      _nodes['B']!.requestFocus();
      await tester.pumpAndSettle();

      expect(
        _clipFor(tester, 'B').clipBehavior,
        equals(Clip.none),
        reason:
            'the ring band lies wholly outside the item box, so any '
            'clip on that box removes all of it',
      );
      // Neighbours keep clipping.
      expect(_clipFor(tester, 'A').clipBehavior, equals(Clip.antiAlias));
    });

    testWidgets('focus survives focusing', (tester) async {
      // The failure mode of the rejected approach: unclipping by swapping
      // the widget out remounts the child, disposes its focus node and
      // leaves primaryFocus null, so the ring never appears.
      await tester.pumpWidget(_app(_strip()));
      await tester.pumpAndSettle();

      _nodes['B']!.requestFocus();
      await tester.pumpAndSettle();

      expect(
        tester.binding.focusManager.primaryFocus,
        isNotNull,
        reason: 'a remount would drop focus to null',
      );
      expect(find.text('B'), findsOneWidget);
    });

    testWidgets('the strip uses the reordering flex', (tester) async {
      // The paint-order half. This asserts the MECHANISM is installed, not
      // the pixels: reading real paint order needs a recording context that
      // widget tests do not give cheaply, and the ordering itself was
      // measured on rendered pixels during design (unclipped-only leaves the
      // right-hand band covered; unclip + elevate shows it).
      //
      // It is still a regression guard: reverting the strip to a plain
      // Row/Column — which is exactly how the band gets covered again —
      // fails here.
      await tester.pumpWidget(_app(_strip()));
      await tester.pumpAndSettle();

      RenderFlex? strip;
      void visit(RenderObject node) {
        if (strip == null && node is RenderFlex) strip = node;
        node.visitChildren(visit);
      }

      tester.renderObject<RenderBox>(find.byType(Join)).visitChildren(visit);

      expect(strip, isNotNull, reason: 'the strip lays out with a flex');
      expect(
        strip.runtimeType.toString(),
        contains('JoinRenderFlex'),
        reason:
            'a plain RenderFlex paints in child order, so the focused '
            'item\'s seam-side band is covered by its next sibling',
      );
    });

    testWidgets('a strip with no focus paints in order', (tester) async {
      await tester.pumpWidget(_app(_strip()));
      await tester.pumpAndSettle();

      // Nothing focused: every item clips, which is the untouched default.
      for (final label in ['A', 'B', 'C']) {
        expect(_clipFor(tester, label).clipBehavior, equals(Clip.antiAlias));
      }
    });
  });
}
