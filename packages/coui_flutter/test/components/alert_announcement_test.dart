import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

/// Whether any node in the tree announces itself as it changes.
///
/// Flutter has one announcement axis — a node either is a live region
/// or it is not. Politeness is a Web-only distinction, so this is the
/// whole of what the Flutter half can be asked.
bool _announces(WidgetTester tester) => tester
    .widgetList<Semantics>(find.byType(Semantics))
    .any((w) => w.properties.liveRegion ?? false);

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    CoUIApp(
      theme: ThemeData.fromCore(CoreThemePresets.light),
      home: Align(child: SizedBox(width: 320, child: child)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('a toned alert announces itself', () {
    testWidgets('a failure does', (tester) async {
      // Measured before this existed: Web emitted `role="alert"` and
      // Flutter emitted nothing at all, so the same component
      // interrupted on one platform and was silent on the other.
      await _pump(
        tester,
        const Alert.destructive(title: 'Could not load orders'),
      );

      expect(_announces(tester), isTrue);
    });

    testWidgets('and so does a confirmation', (tester) async {
      await _pump(
        tester,
        const Alert(
          variant: CoreAlertVariant.success,
          title: 'Saved',
        ),
      );

      expect(_announces(tester), isTrue);
    });
  });

  group('the inline strip announces the same way', () {
    testWidgets('by tone, with the whole title as its label', (tester) async {
      // The strip draws the title on one line and cuts it short when it
      // runs out of room. The cut is visual only: the accessible name is
      // still the whole title, and the tone still decides the urgency.
      const long =
          'Could not sync the last three changes because the connection '
          'dropped halfway through';
      await _pump(
        tester,
        const Alert.destructive(layout: CoreAlertLayout.inline, title: long),
      );

      expect(_announces(tester), isTrue);
      expect(
        tester
            .widgetList<Semantics>(find.byType(Semantics))
            .any((w) => w.properties.label == long),
        isTrue,
      );
    });
  });

  group('an untoned alert does not', () {
    testWidgets('the neutral variant stays silent', (tester) async {
      // The half a blanket live region would fail. A neutral alert
      // carries no tone — it is a container holding a message, not a
      // report that something just happened. Announcing every one of
      // them means a page that renders three banners reads three
      // interruptions before the user has done anything.
      await _pump(
        tester,
        const Alert(title: 'Orders are shown newest first'),
      );

      expect(_announces(tester), isFalse);
    });
  });
}
