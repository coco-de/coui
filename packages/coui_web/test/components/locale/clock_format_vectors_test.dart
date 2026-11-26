// Every Web CoUI locale formats clock values to the same strings the
// Flutter locales do — both read one vector table owned by coui_core.
//
// The localization parity guard compares member *sets*; it cannot see two
// implementations of the same member answering differently. These vectors
// are what fails when a clock fix lands on one platform or one locale only.
import 'dart:convert';
import 'dart:io';

import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

const String kClockFormatVectorsPath =
    '../coui_core/test/fixtures/clock_format_vectors.json';

const Map<String, CouiLocalizations> kLocalizationsByLocale = {
  'ar': ArCouiLocalizations.instance,
  'de': DeCouiLocalizations.instance,
  'en': DefaultCouiLocalizations.instance,
  'es': EsCouiLocalizations.instance,
  'fr': FrCouiLocalizations.instance,
  'it': ItCouiLocalizations.instance,
  'ja': JaCouiLocalizations.instance,
  'ko': KoCouiLocalizations.instance,
  'pt': PtCouiLocalizations.instance,
  'ru': RuCouiLocalizations.instance,
  'zh-Hans': ZhHansCouiLocalizations.instance,
};

void main() {
  final doc =
      jsonDecode(File(kClockFormatVectorsPath).readAsStringSync())
          as Map<String, Object?>;
  final cases = (doc['cases']! as List).cast<Map<String, Object?>>();

  test('every vector locale has a Web implementation', () {
    expect(cases, isNotEmpty);
    expect(
      cases.map((c) => c['locale']).toSet(),
      kLocalizationsByLocale.keys.toSet(),
    );
  });

  for (final c in cases) {
    final expected = c['expected']! as String;
    test('${c['locale']} ${c['api']} '
        '(24h=${c['use24HourFormat']}, seconds=${c['showSeconds']}) '
        '→ $expected', () {
      final l10n = kLocalizationsByLocale[c['locale']]!;
      final hour = c['hour']! as int;
      final minute = c['minute']! as int;
      final second = c['second']! as int;
      final showSeconds = c['showSeconds']! as bool;
      final use24HourFormat = c['use24HourFormat']! as bool;

      final actual = switch (c['api']) {
        'formatTimeOfDay' => l10n.formatTimeOfDay(
          TimeOfDay(hour: hour, minute: minute, second: second),
          showSeconds: showSeconds,
          use24HourFormat: use24HourFormat,
        ),
        'formatDateTime' => l10n.formatDateTime(
          DateTime(
            (c['year'] as int?) ?? 2026,
            (c['month'] as int?) ?? 1,
            (c['day'] as int?) ?? 1,
            hour,
            minute,
            second,
          ),
          showDate: c['showDate']! as bool,
          showSeconds: showSeconds,
          use24HourFormat: use24HourFormat,
        ),
        final api => throw StateError('unknown api $api'),
      };

      expect(actual, expected);
    });
  }
}
