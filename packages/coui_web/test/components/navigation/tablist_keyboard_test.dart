// `role="tablist"` promises the WAI-ARIA tabs keys (#3968 · #4154): the
// tablist is one tab stop — the selected tab — and the arrows move between
// tabs. This pins what the markup needs for that on both tablists (`Tabs`
// and `TabPane`): exactly one tab at `tabindex="0"`, the rest at `-1`, each
// carrying a host-scoped roving marker the arrow handler finds them by.
//
// The key → index arithmetic is pinned in `base/roving_focus_test.dart`;
// the live keydown dispatch is not — `universal_web`'s `KeyboardEvent.key`
// throws on the VM this suite runs on.
import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/server_test.dart';

Component _host(Component child) => CoUIWeb(theme: .coui, child: child);

const _items = [
  CoreTabItem<Component>(label: 'One'),
  CoreTabItem<Component>(label: 'Two', enabled: false),
  CoreTabItem<Component>(label: 'Three'),
];

void main() {
  group('Tabs roving focus', () {
    testServer('the selected tab is the one tab stop', (tester) async {
      tester.pumpComponent(
        _host(Tabs(id: 't', tabs: _items, selectedIndex: 2, onChanged: (_) {})),
      );
      final tabs = (await tester.request(
        '/',
      )).document!.querySelectorAll('[role="tab"]');

      expect(tabs.map((e) => e.attributes['tabindex']), ['-1', '-1', '0']);
      expect(tabs.map((e) => e.attributes['data-roving-item']), [
        't:0',
        't:1',
        't:2',
      ]);
    });

    testServer('a disabled tab stays in the rotation, reachable and inert', (
      tester,
    ) async {
      tester.pumpComponent(
        _host(Tabs(id: 't', tabs: _items, selectedIndex: 0, onChanged: (_) {})),
      );
      final disabled = (await tester.request(
        '/',
      )).document!.querySelectorAll('[role="tab"]')[1];

      expect(disabled.attributes['tabindex'], '-1');
      expect(disabled.attributes['aria-disabled'], 'true');
    });

    testServer('an out-of-range selection still leaves the first tab '
        'reachable', (tester) async {
      tester.pumpComponent(
        _host(Tabs(tabs: _items, selectedIndex: 7, onChanged: (_) {})),
      );
      final tabs = (await tester.request(
        '/',
      )).document!.querySelectorAll('[role="tab"]');

      expect(tabs.map((e) => e.attributes['tabindex']), ['0', '-1', '-1']);
    });
  });

  group('TabPane roving focus', () {
    testServer('the selected tab is the one tab stop', (tester) async {
      tester.pumpComponent(
        _host(
          TabPane(
            id: 'p',
            tabs: _items,
            selectedIndex: 0,
            onChanged: (_) {},
          ),
        ),
      );
      final tabs = (await tester.request(
        '/',
      )).document!.querySelectorAll('[role="tab"]');

      expect(tabs.map((e) => e.attributes['tabindex']), ['0', '-1', '-1']);
      expect(tabs.map((e) => e.attributes['data-roving-item']), [
        'p-tabs:0',
        'p-tabs:1',
        'p-tabs:2',
      ]);
    });
  });
}
