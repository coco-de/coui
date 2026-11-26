import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

List<DomComponent> _elements(ComponentTester tester) => find
    .byType(DomComponent)
    .evaluate()
    .map((element) => element.component as DomComponent)
    .toList();

void main() {
  group('DotIndicator accessibility', () {
    testComponents('interactive dots retain named tabs and selection', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        DotIndicator(index: 1, length: 3, onChanged: (_) {}),
      );
      final nodes = _elements(tester);
      final group = nodes.singleWhere(
        (node) => node.attributes?['role'] == 'tablist',
      );
      final tabs = nodes
          .where((node) => node.attributes?['role'] == 'tab')
          .toList();
      expect(group.attributes?['aria-label'], 'Page navigation');
      expect(tabs, hasLength(3));
      expect(tabs.map((tab) => tab.attributes?['aria-label']), [
        'Go to item 1',
        'Go to item 2',
        'Go to item 3',
      ]);
      expect(tabs[1].attributes?['aria-current'], 'true');
    });
    testComponents('passive dots expose one read-only position', (
      tester,
    ) async {
      pumpWithTheme(tester, DotIndicator(index: 1, length: 3));
      final nodes = _elements(tester);
      final group = nodes.singleWhere(
        (node) => node.attributes?['role'] == 'group',
      );
      expect(group.attributes?['aria-label'], 'Item 2 of 3');
      expect(group.attributes?['tabindex'], isNull);
      expect(nodes.where((node) => node.attributes?['role'] == 'tab'), isEmpty);
      expect(
        nodes.where((node) => node.attributes?['aria-hidden'] == 'true'),
        hasLength(3),
      );
    });
    testComponents('passive Korean position is localized', (tester) async {
      pumpWithTheme(
        tester,
        CouiLocalizationsScope(
          localizations: KoCouiLocalizations.instance,
          child: DotIndicator(index: 1, length: 3),
        ),
      );
      final group = _elements(
        tester,
      ).singleWhere((node) => node.attributes?['role'] == 'group');
      expect(group.attributes?['aria-label'], '전체 3개 항목 중 2번째');
    });
    testComponents('empty indicator is hidden from assistive technology', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        DotIndicator(index: 0, length: 0, onChanged: (_) {}),
      );
      final group = _elements(
        tester,
      ).singleWhere((node) => node.attributes?['role'] == 'group');
      expect(group.attributes?['aria-hidden'], 'true');
      expect(group.attributes?['tabindex'], isNull);
    });
  });
}
