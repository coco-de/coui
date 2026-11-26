// Calendar month/weekday headers and Pagination previous/next render in
// each of the 11 supported chrome languages — the observable symptom of a
// locale missing from the registry is these strings staying English.
//
// Expectations are written out independently (CLDR stand-alone month name
// with the locale's `yMMMM` order, CLDR short weekdays) rather than read from
// the slang source, so a wrong source value fails here even when the
// generated class faithfully renders it.
import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

typedef _Expected = ({
  String monthYear,
  List<String> weekdays,
  String previous,
  String next,
});

const Map<String, _Expected> kExpected = {
  'en': (
    monthYear: 'January 2026',
    weekdays: ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'],
    previous: 'Previous',
    next: 'Next',
  ),
  'ko': (
    monthYear: '2026년 1월',
    weekdays: ['일', '월', '화', '수', '목', '금', '토'],
    previous: '이전',
    next: '다음',
  ),
  'zh-Hans': (
    monthYear: '2026年1月',
    weekdays: ['周日', '周一', '周二', '周三', '周四', '周五', '周六'],
    previous: '上一页',
    next: '下一页',
  ),
  'ja': (
    monthYear: '2026年1月',
    weekdays: ['日', '月', '火', '水', '木', '金', '土'],
    previous: '前へ',
    next: '次へ',
  ),
  'de': (
    monthYear: 'Januar 2026',
    weekdays: ['So', 'Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa'],
    previous: 'Zurück',
    next: 'Weiter',
  ),
  'fr': (
    monthYear: 'janvier 2026',
    weekdays: ['di', 'lu', 'ma', 'me', 'je', 've', 'sa'],
    previous: 'Précédent',
    next: 'Suivant',
  ),
  'es': (
    monthYear: 'enero de 2026',
    weekdays: ['do', 'lu', 'ma', 'mi', 'ju', 'vi', 'sá'],
    previous: 'Anterior',
    next: 'Siguiente',
  ),
  'pt': (
    monthYear: 'janeiro de 2026',
    weekdays: ['dom.', 'seg.', 'ter.', 'qua.', 'qui.', 'sex.', 'sáb.'],
    previous: 'Anterior',
    next: 'Próximo',
  ),
  'it': (
    monthYear: 'gennaio 2026',
    weekdays: ['dom', 'lun', 'mar', 'mer', 'gio', 'ven', 'sab'],
    previous: 'Indietro',
    next: 'Avanti',
  ),
  'ru': (
    monthYear: 'январь 2026 г.',
    weekdays: ['вс', 'пн', 'вт', 'ср', 'чт', 'пт', 'сб'],
    previous: 'Назад',
    next: 'Далее',
  ),
  'ar': (
    monthYear: 'يناير 2026',
    weekdays: ['أحد', 'إثنين', 'ثلاثاء', 'أربعاء', 'خميس', 'جمعة', 'سبت'],
    previous: 'السابق',
    next: 'التالي',
  ),
};

Locale _locale(String tag) {
  final parts = tag.split('-');

  return parts.length == 1
      ? Locale(parts.first)
      : Locale.fromSubtags(languageCode: parts.first, scriptCode: parts[1]);
}

void main() {
  for (final MapEntry(key: tag, value: expected) in kExpected.entries) {
    testWidgets('$tag — Calendar header, weekdays and Pagination', (
      tester,
    ) async {
      // Pagination's labelled buttons overflow their fixed square face in
      // every locale, English included — a layout bug outside this test's
      // concern (strings), tracked in #5352. Only that overflow is tolerated;
      // anything else still fails the test.
      final reportError = FlutterError.onError;
      FlutterError.onError = (details) {
        final paginationOverflow =
            details.exceptionAsString().contains('RenderFlex overflowed') &&
            details.toString().contains('pagination.dart');
        if (!paginationOverflow) reportError?.call(details);
      };
      try {
        await _pumpAndCheck(tester, tag, expected);
      } finally {
        FlutterError.onError = reportError;
      }
    });
  }
}

Future<void> _pumpAndCheck(
  WidgetTester tester,
  String tag,
  _Expected expected,
) async {
  await tester.pumpWidget(
    CoUIApp(
      locale: _locale(tag),
      supportedLocales: [for (final t in kExpected.keys) _locale(t)],
      theme: ThemeData.fromCore(CoreThemePresets.light),
      home: SingleChildScrollView(
        child: Column(
          children: [
            const Calendar(initialView: CoreCalendarView(2026, 1)),
            Pagination(
              onPageChanged: (_) {},
              page: 2,
              totalPages: 5,
              showLabel: true,
            ),
          ],
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  expect(find.text(expected.monthYear), findsOneWidget);
  for (final weekday in expected.weekdays) {
    expect(find.text(weekday), findsWidgets, reason: weekday);
  }
  expect(find.text(expected.previous), findsOneWidget);
  expect(find.text(expected.next), findsOneWidget);

  final direction = Directionality.of(
    tester.element(find.byType(Calendar)),
  );
  expect(
    direction,
    tag == 'ar' ? TextDirection.rtl : TextDirection.ltr,
  );
}
