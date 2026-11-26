import 'package:coui_core/coui_core.dart';
import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// The direction the tree below the app is actually laid out in.
Future<TextDirection> _rootDirection(
  WidgetTester tester, {
  required Locale locale,
}) async {
  late TextDirection observed;
  await tester.pumpWidget(
    CoUIApp(
      locale: locale,
      // Passed explicitly: without the locale in this list it resolves
      // to the default and the test would pass or fail for a reason
      // that has nothing to do with direction.
      supportedLocales: const [Locale('ar'), Locale('en', 'US')],
      theme: ThemeData.fromCore(CoreThemePresets.light),
      home: Builder(
        builder: (context) {
          observed = Directionality.of(context);

          return const SizedBox.shrink();
        },
      ),
    ),
  );
  await tester.pumpAndSettle();

  return observed;
}

void main() {
  group('the root lays out in the direction of its locale', () {
    testWidgets('a right-to-left locale', (tester) async {
      // Measured before this existed: an app set to Arabic laid itself
      // out left-to-right and nothing said so. The delegate stack ended
      // in `DefaultWidgetsLocalizations`, which answers every locale
      // with `TextDirection.ltr` — so the direction handle was there
      // the whole time and nothing was ever connected to it.
      expect(
        await _rootDirection(tester, locale: const Locale('ar')),
        TextDirection.rtl,
      );
    });

    testWidgets('and a left-to-right one', (tester) async {
      expect(
        await _rootDirection(tester, locale: const Locale('en', 'US')),
        TextDirection.ltr,
      );
    });
  });

  group('a test can ask for the other direction', () {
    testWidgets('the harness no longer pins left-to-right', (tester) async {
      // This is what makes any future mirroring claim checkable. The
      // helper hardcoded `.ltr` with no override, so a component could
      // assert it mirrored and no test could contradict it.
      late TextDirection observed;
      await tester.pumpWidget(
        buildCoUITestApp(
          textDirection: TextDirection.rtl,
          child: Builder(
            builder: (context) {
              observed = Directionality.of(context);

              return const SizedBox.shrink();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(observed, TextDirection.rtl);
    });
  });
}
