import 'package:coui_core/coui_core.dart';
import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/widgets.dart' hide Icon;
import 'package:flutter_test/flutter_test.dart';

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
  group('an empty region says why it is empty', () {
    testWidgets('a failure announces itself', (tester) async {
      // Measured before this existed: "No orders yet" and "Could not
      // load orders" rendered identically and were the same box of text
      // to a reader. Only one of them is news.
      await _pump(
        tester,
        const EmptyState(
          tone: CoreEmptyStateTone.failure,
          title: Text('Could not load orders'),
        ),
      );

      expect(_announces(tester), isTrue);
    });

    testWidgets('an absence does not', (tester) async {
      // The half a blanket announcement would fail. An empty list is
      // ordinary content — announcing it means every page that renders
      // one interrupts the reader for nothing.
      await _pump(tester, const EmptyState(title: Text('No orders yet')));

      expect(_announces(tester), isFalse);
    });
  });

  group('and shows it', () {
    testWidgets('the failure icon is not the ordinary one', (tester) async {
      // The tone has to reach the screen too, not only the reader.
      // A field that only changes what is announced is half an axis.
      Color iconColour(WidgetTester t) => t
          .widget<IconTheme>(
            find
                .descendant(
                  of: find.byType(EmptyState),
                  matching: find.byType(IconTheme),
                )
                .first,
          )
          .data
          .color!;

      await _pump(
        tester,
        const EmptyState(
          title: Text('No orders yet'),
          icon: Icon(LucideIcons.inbox),
        ),
      );
      final neutral = iconColour(tester);

      await _pump(
        tester,
        const EmptyState(
          tone: CoreEmptyStateTone.failure,
          title: Text('Could not load orders'),
          icon: Icon(LucideIcons.inbox),
        ),
      );

      expect(iconColour(tester), isNot(neutral));
    });
  });
}
