import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

/// Two arbitrary, distinctly-offset hard layers — only their *count*
/// (two) and that they are non-empty matter for this structural check.
const _kTwoLayers = [
  (
    offsetX: 4.0,
    offsetY: 12.0,
    blurRadius: 0.0,
    spreadRadius: 0.0,
    opacity: 1.0,
    inset: false,
  ),
  (
    offsetX: 4.0,
    offsetY: 8.0,
    blurRadius: 0.0,
    spreadRadius: 0.0,
    opacity: 1.0,
    inset: false,
  ),
];

void main() {
  // CSS `filter: drop-shadow(A) drop-shadow(B)` is a pipeline — per the
  // Filter Effects spec, `B` runs on `A`'s *output*, not on the pristine
  // source (`B(A(source))`). Verified directly in a real browser: two
  // chained hard-edged `drop-shadow()`s reach measurably farther than
  // treating them as independent copies of the source would predict (a
  // point only the chained model paints was black; the same point
  // stayed white under the independent model).
  //
  // Flutter's `_DropShadow` had no native primitive to defer to and
  // used to build every layer as an independent `ColorFiltered` copy of
  // the *same* pristine `child` — structurally, every shadow layer's
  // `ColorFiltered` was a sibling with an identical `child`, none
  // nested inside another. The pixel-level consequence (measured
  // before this fix, matching the browser experiment above) was a
  // multi-layer hard stack — the shape neo-brutalism's bent
  // `CoreShadow.lg` casts — falling visibly short of its Web twin.
  //
  // This test pins the *structural* signature of the fix rather than
  // rendering to pixels (heavier, and this repo's `flutter test`
  // environment has shown flaky timing on `RepaintBoundary.toImage()`
  // captures): each layer's `ColorFiltered` copy must wrap the
  // *previous* layer's whole composite, not the pristine child — so at
  // least one `ColorFiltered` has to have another shadow layer's
  // `AnimatedOpacity` nested somewhere inside it. The old, wrong
  // (independent-copy) shape can never produce that nesting: every
  // `ColorFiltered` there wraps `child` directly, so no
  // `AnimatedOpacity` is ever found inside another one's subtree.
  //
  // That accumulation mounts the previous composite twice per layer
  // (once recoloured for the next layer, once bare) — both the total
  // `AnimatedOpacity` count and the "nested inside a `ColorFiltered`"
  // check below are shaped by that, not just by the layer count.
  testWidgets(
    'each shadow layer wraps the previous layers (CSS pipeline), not an '
    'independent copy of the child',
    (tester) async {
      final _ = await tester.pumpWidget(
        CoUIApp(
          home: Hover(
            effect: .shadow,
            hoverStyle: const CoreHoverStyle(shadowBoxShadow: _kTwoLayers),
            child: const SizedBox(width: 80, height: 40),
          ),
          theme: ThemeData.fromCore(CoreThemePresets.light),
        ),
      );
      final _ = await tester.pump();

      final gesture = await tester.createGesture(kind: .mouse);
      final _ = await gesture.addPointer(location: .zero);
      addTearDown(gesture.removePointer);
      final _ = await gesture.moveTo(tester.getCenter(find.byType(Hover)));
      await tester.pump();

      // Scoped to inside `Hover` — `CoUIApp`'s own theme cross-fade
      // contributes an unrelated `AnimatedOpacity` above it, which an
      // unscoped `find.byType` count would otherwise pick up.
      //
      // The count itself is part of what this test pins: chaining mounts
      // the accumulated composite twice per layer (once recoloured for
      // the next layer, once bare) rather than once, so `n` layers
      // build `2ⁿ − 1` `AnimatedOpacity`s, not `n`. For two layers
      // that is 3 — see `_DropShadow`'s doc comment in `hover.dart` for
      // why that cost is accepted.
      final shadowLayerOpacities = find.descendant(
        of: find.byType(Hover),
        matching: find.byType(AnimatedOpacity),
      );
      expect(
        shadowLayerOpacities,
        findsNWidgets((1 << _kTwoLayers.length) - 1),
        reason: 'chaining mounts the accumulated composite twice per layer',
      );

      final nestedInsideAColorFilter = find.descendant(
        of: find.descendant(
          of: find.byType(Hover),
          matching: find.byType(ColorFiltered),
        ),
        matching: find.byType(AnimatedOpacity),
      );
      expect(
        nestedInsideAColorFilter,
        findsOneWidget,
        reason:
            'the pipeline shape: the outer layer\'s ColorFiltered copy '
            'wraps the whole inner-layer composite (which contains its '
            'own AnimatedOpacity), not the pristine child directly — the '
            'old independent-copy shape could never find an '
            'AnimatedOpacity nested inside a ColorFiltered',
      );
    },
  );
}
