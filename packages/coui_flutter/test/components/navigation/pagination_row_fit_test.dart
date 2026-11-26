import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

// The demo locales (#5352) — fr · es · pt are the widest labels.
const _kLocales = [
  Locale('ko'),
  Locale('en'),
  Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
  Locale('ja'),
  Locale('de'),
  Locale('fr'),
  Locale('es'),
  Locale('pt'),
  Locale('it'),
  Locale('ru'),
  Locale('ar'),
];

const _kTextScales = [1.0, 1.3, 2.0];

const _kWidths = [360.0, 600.0, 800.0];

// A phone-density theme: every box is 1.25× its logical size.
const _kScaling = AdaptiveScaling(1.25);

void main() {
  group('Pagination row fits its width (#5364)', () {
    for (final locale in _kLocales) {
      for (final scale in _kTextScales) {
        for (final width in _kWidths) {
          testWidgets(
            '${locale.toLanguageTag()} × textScaler $scale × scaling 1.25 '
            '× width $width',
            (tester) async {
              final semantics = tester.ensureSemantics();
              await _pump(tester, locale: locale, scale: scale, width: width);

              expect(tester.takeException(), isNull);
              final row = tester.getRect(find.byType(Pagination));
              expect(
                row.width,
                lessThanOrEqualTo(width),
                reason: 'row is ${row.width} wide in a $width view',
              );

              // Whatever step the row settled on, previous / next keep
              // their meaning — as the label text, or as the accessible
              // name of the icon-only button.
              final localizations = CoUILocalizations.of(
                tester.element(find.byType(Pagination)),
              );
              expect(
                find.bySemanticsLabel(localizations.buttonPrevious),
                findsOneWidget,
              );
              expect(
                find.bySemanticsLabel(localizations.buttonNext),
                findsOneWidget,
              );
              semantics.dispose();
            },
          );
        }
      }
    }

    testWidgets('a wide view keeps the full row', (tester) async {
      await _pump(tester, locale: const Locale('en'), scale: 1, width: 1600);

      expect(find.text('Previous'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
      // skip-to-first / skip-to-last edge pages and the 3-page window.
      for (final page in ['1', '4', '5', '6', '10']) {
        expect(find.text(page), findsOneWidget, reason: 'page $page');
      }
    });

    testWidgets('a narrow view drops the labels before any page', (
      tester,
    ) async {
      // Wide enough for the full page window as icons, not for the labels.
      await _pump(tester, locale: const Locale('fr'), scale: 2, width: 800);

      final localizations = CoUILocalizations.of(
        tester.element(find.byType(Pagination)),
      );
      expect(find.text(localizations.buttonPrevious), findsNothing);
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('the narrowest step still shows the current page', (
      tester,
    ) async {
      await _pump(tester, locale: const Locale('fr'), scale: 2, width: 200);

      expect(tester.takeException(), isNull);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('4'), findsNothing);
    });

    testWidgets('only the shown row takes focus', (tester) async {
      await _pump(tester, locale: const Locale('fr'), scale: 2, width: 360);

      final focusable = tester
          .widgetList<ExcludeFocus>(
            find.byType(ExcludeFocus, skipOffstage: false),
          )
          .where((widget) => !widget.excluding);
      expect(focusable, hasLength(1));
    });

    testWidgets('tapping the shown row still pages', (tester) async {
      int? changedTo;
      await _pump(
        tester,
        locale: const Locale('fr'),
        scale: 2,
        width: 360,
        onPageChanged: (page) => changedTo = page,
      );

      final localizations = CoUILocalizations.of(
        tester.element(find.byType(Pagination)),
      );
      await tester.tap(find.bySemanticsLabel(localizations.buttonNext));
      expect(changedTo, 6);
    });
  });
}

Future<void> _pump(
  WidgetTester tester, {
  required Locale locale,
  required double scale,
  required double width,
  ValueChanged<int>? onPageChanged,
}) async {
  tester.view
    ..physicalSize = Size(width, 600)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    CoUIApp(
      theme: const ThemeData(),
      scaling: _kScaling,
      locale: locale,
      supportedLocales: _kLocales,
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: Center(
            child: Pagination(
              page: 5,
              totalPages: 10,
              showLabel: true,
              onPageChanged: onPageChanged ?? (_) {},
            ),
          ),
        ),
      ),
    ),
  );
  // The step the row settled on reaches focus after the frame.
  await tester.pump();
}
