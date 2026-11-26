import 'package:coui_web/coui_web.dart';
import 'package:coui_web/src/components/locale/coui_localizations/coui_localizations.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../helpers/pump_with_theme.dart';

/// A locale whose loading label is unmistakably not the English one.
class _MarkedLocalizations extends DefaultCouiLocalizations {
  const _MarkedLocalizations();

  @override
  String get loadingLabel => '로딩중';
}

Iterable<String> _ariaLabels(ComponentTester tester) => find
    .byType(DomComponent)
    .evaluate()
    .map((e) => e.component as DomComponent)
    .map((c) => (c.attributes ?? const {})['aria-label'])
    .whereType<String>();

void main() {
  group('the loading label comes from the active locale', () {
    testComponents('not from a constant in the component', (tester) async {
      // Measured before this changed: the Flutter twin read this from
      // localizations and the Web side had `'Loading'` as a class
      // constant. Both rendered correctly — in English, forever — so only
      // a locale switch showed it, and nothing in the suite did that.
      pumpWithTheme(
        tester,
        CouiLocalizationsScope(
          localizations: const _MarkedLocalizations(),
          child: Skeleton(width: '100px', height: '20px'),
        ),
      );

      expect(_ariaLabels(tester), contains('로딩중'));
    });

    testComponents('and the default locale still reads in English', (
      tester,
    ) async {
      pumpWithTheme(tester, Skeleton(width: '100px', height: '20px'));

      expect(_ariaLabels(tester), contains('Loading'));
    });
  });
}
