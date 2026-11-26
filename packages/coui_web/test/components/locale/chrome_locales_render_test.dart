// Calendar month/weekday headers and Pagination previous/next render in
// each of the 11 supported chrome languages — the observable symptom of a
// locale missing from the registry is these strings staying English.
//
// Expectations are written out independently (CLDR stand-alone month name
// with the locale's `yMMMM` order, CLDR short weekdays) rather than read from
// the slang source, so a wrong source value fails here even when the
// generated class faithfully renders it.
import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

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

void main() {
  for (final MapEntry(key: tag, value: expected) in kExpected.entries) {
    testComponents('$tag — Calendar header, weekdays and Pagination', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        CouiLocalizationsScope(
          localizations: resolveCouiLocalizationsFor(tag.split('-').first),
          child: div([
            const Calendar(initialView: CoreCalendarView(2026, 1)),
            Pagination(
              onPageChanged: (_) {},
              page: 2,
              totalPages: 5,
              showLabel: true,
            ),
          ]),
        ),
      );

      expect(find.text(expected.monthYear), findsOneComponent);
      for (final weekday in expected.weekdays) {
        expect(find.text(weekday), findsComponents, reason: weekday);
      }
      expect(find.text(expected.previous), findsOneComponent);
      expect(find.text(expected.next), findsOneComponent);
    });
  }

  test('the root direction table lays Arabic right-to-left', () {
    for (final tag in kExpected.keys) {
      expect(
        CoreTextDirectionForLocale.of(tag),
        tag == 'ar' ? CoreTextDirection.rtl : CoreTextDirection.ltr,
        reason: tag,
      );
    }
  });
}
