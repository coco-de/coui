import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

/// The single `<span>` a bare `Text` chain renders.
DomComponent _span(ComponentTester tester) =>
    find.byType(DomComponent).evaluate().single.component as DomComponent;

List<String> _classes(ComponentTester tester) =>
    (_span(tester).classes ?? '').split(' ');

Map<String, String> _inline(ComponentTester tester) =>
    _span(tester).styles?.properties ?? const {};

void main() {
  // #4080 — a chain without a role overrides only what it names and lets
  // the cascade supply the rest. Flutter pins the same contract against
  // the resolved `DefaultTextStyle` in `text_test.dart`; these tests pin
  // the Web half so the two can't drift apart again.
  group('partial chain emits only the property it names', () {
    testComponents(
      '.semiBold emits the weight only — size, line-height and colour '
      'stay with the ancestor',
      (tester) async {
        pumpWithTheme(tester, const Text('Hi').semiBold);

        final classes = _classes(tester);
        expect(classes, contains('font-${CoreFontWeight.scale.semibold}'));
        expect(classes, contains('text-inherit'));
        expect(
          classes.where(
            (c) => CoreTextStyles.values.any((r) => c == 'text-${r.name}'),
          ),
          isEmpty,
        );
        final inline = _inline(tester);
        expect(inline.containsKey('font-size'), isFalse);
        expect(inline.containsKey('line-height'), isFalse);
      },
    );

    testComponents(
      '.onSurface emits the colour only — no role class, no size',
      (tester) async {
        pumpWithTheme(tester, const Text('Hi').onSurface);

        final classes = _classes(tester);
        expect(classes, isNot(contains('text-inherit')));
        expect(
          classes.where(
            (c) => CoreTextStyles.values.any((r) => c == 'text-${r.name}'),
          ),
          isEmpty,
        );
        expect(classes.any((c) => c.startsWith('font-')), isFalse);
        expect(_inline(tester).containsKey('font-size'), isFalse);
      },
    );

    testComponents('a role chain names the role class', (tester) async {
      pumpWithTheme(tester, const Text('Hi').bodyMedium.semiBold);

      expect(
        _classes(tester),
        contains('text-${CoreTextStyles.bodyMedium.name}'),
      );
    });
  });
}
