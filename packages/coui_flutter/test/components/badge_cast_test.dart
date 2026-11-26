import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// The shadows the badge's own subtree paints.
///
/// Scoped to that subtree: a search across the whole tree could be
/// satisfied by some other widget and would pass whether or not this
/// component takes anything.
///
/// Reads both paint sites. A cast can be painted behind the box by
/// `BoxDecoration.boxShadow` or outside it by [InjectedCast], and which
/// one a component uses depends on whether its fill can be non-opaque —
/// a detail this question does not turn on. Asking only the decoration
/// would report "no cast" for a component that paints one perfectly
/// well.
List<BoxShadow> _badgeShadows(WidgetTester tester) => [
  ...tester
      .widgetList<AnimatedContainer>(
        find.descendant(
          of: find.byType(Badge),
          matching: find.byType(AnimatedContainer),
        ),
      )
      .map((c) => c.decoration)
      .whereType<BoxDecoration>()
      .expand((d) => d.boxShadow ?? const <BoxShadow>[]),
  ...tester
      .widgetList<InjectedCast>(
        find.descendant(
          of: find.byType(Badge),
          matching: find.byType(InjectedCast),
        ),
      )
      .expand((c) => c.shadows),
];

Future<void> _pumpBadge(WidgetTester tester, CoreSurfaceStyleId style) async {
  await tester.pumpWidget(
    CoUIApp(
      theme: ThemeData.fromCore(CoreThemePresets.light),
      surfaceStyle: style,
      home: const Center(child: Badge(child: Text('badge'))),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('the badge takes the style it is under', () {
    testWidgets('a style with a cast reaches it', (tester) async {
      // The badge draws its own box rather than composing
      // `OutlinedContainer` — it swaps its fill on hover, which that
      // component has no slot for — so without an explicit opt-in it sat
      // outside everything the style injects.
      await _pumpBadge(tester, .neoBrutalism);

      final shadows = _badgeShadows(tester);
      expect(shadows, isNotEmpty);

      final cast = shadows.first;
      expect(cast.blurRadius, 0, reason: 'the cast is hard-edged');
      // The recipe throws the cast by its own stroke floor, so matching
      // that number is what separates the injected cast from any shadow
      // that merely happens to be present.
      expect(cast.offset.dx, CoreStrokeWidth.stroke4);
      expect(cast.offset.dy, CoreStrokeWidth.stroke4);
    });

    testWidgets('a style without one does not gain a shadow', (tester) async {
      // The negative control: without it, a test that passes because
      // *something* paints a shadow reads the same as one that passes
      // because the cast arrived.
      await _pumpBadge(tester, .defaultStyle);

      expect(_badgeShadows(tester), isEmpty);
    });
  });
}
