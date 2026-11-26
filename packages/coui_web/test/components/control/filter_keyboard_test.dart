// `role="radiogroup"` promises the WAI-ARIA radio group keys (#3968 ·
// #4154): the group is one tab stop — the checked radio — and the arrows
// move focus and check. This pins the markup half: exactly one radio at
// `tabindex="0"`, each carrying a roving marker the arrow handler finds.
import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/server_test.dart';

Component _host(Component child) => CoUIWeb(theme: .coui, child: child);

const _items = [
  CoreFilterItem<String, Component>(value: 'all', label: 'All'),
  CoreFilterItem<String, Component>(value: 'open', label: 'Open'),
  CoreFilterItem<String, Component>(value: 'done', label: 'Done'),
];

void main() {
  testServer('the checked radio is the one tab stop', (tester) async {
    tester.pumpComponent(
      _host(
        Filter<String>(
          id: 'f',
          items: _items,
          groupValue: 'open',
          onValueChanged: (_) {},
        ),
      ),
    );
    final radios = (await tester.request(
      '/',
    )).document!.querySelectorAll('[role="radio"]');

    expect(radios.map((e) => e.attributes['tabindex']), ['-1', '0', '-1']);
    expect(radios.map((e) => e.attributes['data-roving-item']), [
      'f:0',
      'f:1',
      'f:2',
    ]);
  });

  testServer('with nothing checked the first radio is the tab stop', (
    tester,
  ) async {
    tester.pumpComponent(
      _host(
        Filter<String>(
          items: _items,
          groupValue: 'missing',
          onValueChanged: (_) {},
        ),
      ),
    );
    final radios = (await tester.request(
      '/',
    )).document!.querySelectorAll('[role="radio"]');

    expect(radios.map((e) => e.attributes['tabindex']), ['0', '-1', '-1']);
  });
}
