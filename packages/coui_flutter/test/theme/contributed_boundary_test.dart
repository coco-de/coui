import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

/// The boundary a style contributes to a surface that draws none of its
/// own.
///
/// A stroke floor can only raise a width already being painted, so a
/// surface with no border of its own is one the floor can never reach.
/// These have no border in this kit, and before the contributed
/// boundary existed they came out of neo-brutalism unboxed — which was
/// found by walking the rendered catalogue, not by any unit test, because
/// every unit test asserts that the floor lifts what it is *given* and
/// these four were never giving it anything.
///
/// So this reads the value back where it is consumed rather than where it
/// is declared: a field that is authored, compared and serialised while
/// nothing paints it is the failure this whole axis keeps having.
Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  required CoreSurfaceStyleId style,
}) => tester.pumpWidget(
  CoUIApp(
    theme: ThemeData.fromCore(CoreThemePresets.light),
    surfaceStyle: style,
    home: Center(child: child),
  ),
);

/// Every border painted anywhere in the tree, from both of the ways a
/// box reaches paint — `Container` builds a `DecoratedBox`, but reading
/// only that would miss a decoration handed straight to one.
Iterable<BoxBorder> _borders(WidgetTester tester) => tester
    .widgetList<DecoratedBox>(find.byType(DecoratedBox))
    .map((d) => d.decoration)
    .whereType<BoxDecoration>()
    .map((d) => d.border)
    .nonNulls;

/// Every drawn border width in the tree.
///
/// A set of widths rather than the heaviest one, because these surfaces
/// are not bare: a `Toggle` carries a focus ring that paints a 2.5px
/// border under every style, so "the heaviest border is zero" is false
/// by default and says nothing either way about the contribution. What
/// is decidable is whether the *floor* is among the widths painted —
/// exact in both directions and immune to chrome that has nothing to do
/// with this axis.
Set<double> _borderWidths(WidgetTester tester) {
  final widths = <double>{};
  for (final border in _borders(tester)) {
    if (border is! Border) continue;
    for (final side in [
      border.top,
      border.right,
      border.bottom,
      border.left,
    ]) {
      if (side.style == BorderStyle.none || side.width == 0) continue;
      widths.add(side.width);
    }
  }

  return widths;
}

/// The width this style contributes, read from the recipe rather than
/// typed here — a number repeated in a test is a second statement of it.
final double _floor = CoreSurfaceRecipe
    .presets[CoreSurfaceStyleId.neoBrutalism]!
    .geometry
    .controlBorder!;

/// The surfaces that author no border and paint in place. Built as a
/// list rather than copied test bodies so the next one is a single line,
/// and so the two directions below (contributed under the style, absent
/// without it) can never drift apart per component.
///
/// `Toggle` and `Progress` are absent on purpose, and the reason is a
/// measurement rather than a preference. Rendered, the switch track is
/// 20px tall with an 18px thumb and the progress track is 8px tall, so a
/// boundary at this style's floor leaves the thumb spilling out of its
/// own track and the progress bar with no height left to fill. The
/// reference implementations box both — at a lighter weight, on parts
/// drawn half again as large. Matching them is a change to what those
/// two components are, not to what this axis contributes.
final _surfaces = <({String name, Widget widget})>[
  (name: 'Skeleton', widget: const Skeleton(width: 120, height: 24)),
];

void main() {
  group('a style that contributes a boundary reaches surfaces with none', () {
    for (final surface in _surfaces) {
      testWidgets('${surface.name} is boxed at the floor', (tester) async {
        await _pump(
          tester,
          surface.widget,
          style: CoreSurfaceStyleId.neoBrutalism,
        );

        // The floor itself, not merely "some border": a contributed
        // boundary lighter than an authored one would sort the kit into
        // two weights with nothing behind the split.
        expect(
          _borderWidths(tester),
          contains(_floor),
          reason:
              '${surface.name} draws no border of its own, so the style has '
              'to contribute one — otherwise it renders under this preset '
              'exactly as it does with the preset off.',
        );
      });
    }
  });

  group('a style that contributes none changes nothing', () {
    for (final surface in _surfaces) {
      testWidgets('${surface.name} stays unboxed by default', (tester) async {
        await _pump(
          tester,
          surface.widget,
          style: CoreSurfaceStyleId.defaultStyle,
        );

        // The other half of the contract, and the half a one-directional
        // test would let rot: a contributed boundary that leaked into the
        // default surface would put borders on every skeleton and switch
        // in every app that never asked for a boxed style.
        expect(
          _borderWidths(tester),
          isNot(contains(_floor)),
          reason:
              'the default surface contributes no boundary, so the '
              'contributed width must appear nowhere in the tree',
        );
      });
    }
  });

  group('a surface the style does not box', () {
    // The tooltip bubble is a reversed-fill surface (an `onSurface` fill with
    // `surface` text), and a visible line round it is not the design — so it
    // takes no contributed boundary under any style. Opened for real and read
    // at the bubble, because the resolver no longer carries a boundary field
    // for a test to read.
    for (final style in [
      CoreSurfaceStyleId.neoBrutalism,
      CoreSurfaceStyleId.defaultStyle,
    ]) {
      testWidgets('Tooltip draws no border under $style', (tester) async {
        await _pump(
          tester,
          const Tooltip(
            tooltipChild: Text('tip content'),
            child: Text('tip trigger'),
          ),
          style: style,
        );

        final gesture = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
        );
        await gesture.addPointer(location: Offset.zero);
        await gesture.moveTo(tester.getCenter(find.text('tip trigger')));
        await tester.pump();
        await tester.pump(const Duration(seconds: 2));
        await tester.pumpAndSettle();

        final bubble = tester.widget<Container>(
          find
              .ancestor(
                of: find.text('tip content'),
                matching: find.byType(Container),
              )
              .first,
        );
        expect(
          (bubble.decoration! as BoxDecoration).border,
          isNull,
          reason:
              'the bubble authors no border and the style contributes none to '
              'a reversed-fill surface',
        );

        await gesture.removePointer();
        await tester.pump(const Duration(seconds: 2));
        await tester.pumpAndSettle();
      });
    }
  });

  group('the contribution is for the empty case only', () {
    testWidgets('a surface that authors a border keeps its own', (
      tester,
    ) async {
      const authored = 12.0;

      late ThemeData theme;
      await _pump(
        tester,
        Builder(
          builder: (context) {
            theme = Theme.of(context);

            return const SizedBox.shrink();
          },
        ),
        style: CoreSurfaceStyleId.neoBrutalism,
      );

      // A surface that already paints something bends it through the
      // stroke floor instead of receiving this on top — two boundaries on
      // one edge is a doubled line, and it is the shape this helper's
      // `authoredWidth` guard exists to refuse.
      expect(resolveInjectedBorder(theme, authoredWidth: authored), isNull);
      expect(resolveInjectedBorder(theme), isNotNull);
    });
  });
}
