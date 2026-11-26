import 'package:flutter_test/flutter_test.dart';
import 'package:coui_i10n/coui_i10n.dart';

void main() {
  group('i10n', () {
    test('All locales should be supported by Flutter', () {
      for (final locale in AppLocale.values) {
        // This will fail if the locale is not supported by Flutter
        expect(kMaterialSupportedLanguages, contains(locale.languageCode));
      }
    });

    group('en', () {
      test(
        'should compile english translations',
        () async => expect(
          (await AppLocale.en.build()).widgetbook.common.increment_progress,
          'Increment Progress',
        ),
      );
    });

    group('ko', () {
      test(
        'should compile korean translations',
        () => expect(
          AppLocale.ko.buildSync().widgetbook.common.increment_progress,
          '진행률 증가',
        ),
      );
    });
  });
}
