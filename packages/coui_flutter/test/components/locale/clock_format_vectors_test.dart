// Every Flutter CoUI locale formats clock values to the same strings the
// Web locales do — both read one vector table owned by coui_core.
//
// The localization parity guard compares member *sets*; it cannot see two
// implementations of the same member answering differently. These vectors
// are what fails when a clock fix lands on one platform or one locale only.
import 'dart:convert';
import 'dart:io';

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

const String kClockFormatVectorsPath =
    '../coui_core/test/fixtures/clock_format_vectors.json';

const Map<String, CoUILocalizations> kLocalizationsByLocale = {
  'ar': ArCoUILocalizations.instance,
  'de': DeCoUILocalizations.instance,
  'en': DefaultCoUILocalizations.instance,
  'es': EsCoUILocalizations.instance,
  'fr': FrCoUILocalizations.instance,
  'it': ItCoUILocalizations.instance,
  'ja': JaCoUILocalizations.instance,
  'ko': KoCoUILocalizations.instance,
  'pt': PtCoUILocalizations.instance,
  'ru': RuCoUILocalizations.instance,
  'zh-Hans': ZhHansCoUILocalizations.instance,
};

void main() {
  final doc =
      jsonDecode(File(kClockFormatVectorsPath).readAsStringSync())
          as Map<String, Object?>;
  final cases = (doc['cases']! as List).cast<Map<String, Object?>>();

  test('every vector locale has a Flutter implementation', () {
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
