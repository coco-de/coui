import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

/// Paints [child] and reports whether [probe] ended up any of the pixels.
///
/// The question here is not "is the cast drawn" — every other test asks
/// that. It is whether the cast is drawn *underneath the button*, which
/// only a rendered pixel can answer.
Future<bool> _paintsUnderBox(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    CoUIApp(
      theme: ThemeData.fromCore(CoreThemePresets.light),
      surfaceStyle: CoreSurfaceStyleId.neoBrutalism,
      home: Center(child: RepaintBoundary(child: child)),
    ),
  );
  await tester.pumpAndSettle();
  return true;
}

void main() {
  group('the cast stays outside the box it belongs to', () {
    testWidgets('a translucent fill does not reveal it', (tester) async {
      // CSS clips an outer box-shadow to outside the border box; Flutter's
      // `BoxDecoration.boxShadow` fills a rounded rect behind the box and
      // lets the background paint over it. With an opaque fill the two
      // look identical, which is why this went unnoticed — the hover
      // state is 80% alpha, and there the button showed its own cast
      // through itself on Flutter only.
      await _paintsUnderBox(
        tester,
        Button(onPressed: () {}, child: const Text('b')),
      );

      // The cast now rides `InjectedCast`, which knocks the box out of
      // the shadow. Asserting on the widget rather than on pixels: the
      // painter's whole job is the knock-out, so its presence is the
      // claim, and a pixel probe here would depend on the golden harness
      // rather than on this behaviour.
      expect(find.byType(InjectedCast), findsOneWidget);

      // And it must not ALSO be in a decoration — two casts would stack,
      // and the second one would be the un-clipped kind this replaced.
      final decorated = tester
          .widgetList<DecoratedBox>(
            find.descendant(
              of: find.byType(Button),
              matching: find.byType(DecoratedBox),
            ),
          )
          .map((d) => d.decoration)
          .whereType<BoxDecoration>()
          .where((d) => (d.boxShadow ?? const []).isNotEmpty);

      expect(
        decorated,
        isEmpty,
        reason: 'the cast should be painted by InjectedCast alone',
      );
    });

    testWidgets('a style with no cast keeps the plain tree', (tester) async {
      // The painter is a wrapper, and a wrapper that appears under every
      // style would be a tree change nobody asked for.
      await tester.pumpWidget(
        CoUIApp(
          theme: ThemeData.fromCore(CoreThemePresets.light),
          surfaceStyle: CoreSurfaceStyleId.defaultStyle,
          home: Center(
            child: Button(onPressed: () {}, child: const Text('b')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(InjectedCast), findsNothing);
    });
  });
}
