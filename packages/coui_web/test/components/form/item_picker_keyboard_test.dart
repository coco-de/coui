// `role="listbox"` promises the WAI-ARIA listbox keys (#3968 · #4154) and an
// ownership structure: every `option` a child of its `listbox`. This pins
// what the markup needs — the listbox on the element that owns the options
// (not the root, whose title and search field are not options), one option
// holding the tab stop, and the caller's accessible name following the role.
//
// The key → index arithmetic (including the grid walk) is pinned in
// `base/roving_focus_test.dart`; the live keydown dispatch is not —
// `universal_web`'s `KeyboardEvent.key` throws on the VM.
import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/server_test.dart';

Component _host(Component child) => CoUIWeb(theme: .coui, child: child);

void main() {
  group('ItemPicker listbox structure', () {
    testServer('every option is a direct child of the listbox', (tester) async {
      tester.pumpComponent(
        _host(
          ItemPicker(
            title: 'Fruit',
            items: const ['Apple', 'Banana', 'Cherry'],
            onChanged: (_) {},
          ),
        ),
      );
      final response = await tester.request('/');
      final listbox = response.document!.querySelector('[role="listbox"]')!;

      expect(
        response.document!.querySelectorAll('[role="listbox"]'),
        hasLength(1),
      );
      // The title is a presentational label ahead of the options; every
      // other child is an option.
      final options = listbox.children
          .where((e) => e.attributes['role'] != 'presentation')
          .toList();
      expect(
        options.map((e) => e.attributes['role']),
        everyElement('option'),
      );
      expect(options, hasLength(3));
      expect(listbox.children.first.attributes['role'], 'presentation');
      // The search field is not inside the listbox.
      expect(listbox.querySelector('input'), isNull);
      // The title names the list.
      expect(listbox.attributes['aria-label'], 'Fruit');
    });

    testServer('a caller aria-label names the listbox, not the wrapper', (
      tester,
    ) async {
      tester.pumpComponent(
        _host(
          const ItemPicker(
            id: 'p',
            items: ['Apple'],
            attributes: {'aria-label': 'Pick a fruit'},
          ),
        ),
      );
      final response = await tester.request('/');

      expect(
        response.document!
            .querySelector('[role="listbox"]')!
            .attributes['aria-label'],
        'Pick a fruit',
      );
      expect(
        response.document!.getElementById('p')!.attributes['aria-label'],
        isNull,
      );
    });
  });

  group('ItemPicker roving focus', () {
    testServer('the selected option holds the one tab stop', (tester) async {
      tester.pumpComponent(
        _host(
          ItemPicker(
            id: 'p',
            items: const ['Apple', 'Banana', 'Cherry'],
            selectedValue: 'Banana',
            onChanged: (_) {},
          ),
        ),
      );
      final options = (await tester.request(
        '/',
      )).document!.querySelector('[role="listbox"]')!.children;

      expect(options.map((e) => e.attributes['tabindex']), ['-1', '0', '-1']);
      expect(options.map((e) => e.attributes['data-roving-item']), [
        'p-listbox:0',
        'p-listbox:1',
        'p-listbox:2',
      ]);
    });

    testServer('with nothing selected the first option holds it', (
      tester,
    ) async {
      tester.pumpComponent(
        _host(ItemPicker(items: const ['Apple', 'Banana'], onChanged: (_) {})),
      );
      final options = (await tester.request(
        '/',
      )).document!.querySelector('[role="listbox"]')!.children;

      expect(options.map((e) => e.attributes['tabindex']), ['0', '-1']);
    });

    testServer('a list states its orientation, a grid does not', (
      tester,
    ) async {
      tester.pumpComponent(
        _host(
          const ItemPicker(
            items: ['Apple'],
            layout: CoreItemPickerLayout.grid,
          ),
        ),
      );

      expect(
        (await tester.request('/')).document!
            .querySelector('[role="listbox"]')!
            .attributes['aria-orientation'],
        isNull,
      );
    });
  });
}
