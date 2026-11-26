// The menu row's Web contract: what it announces, which seat each part
// takes, and how the row's chrome follows size / tone / state. The
// Flutter twin asserts the same behaviours against the rendered widget
// (`coui_flutter/test/components/menu/menu_item_test.dart`); this file
// asserts them against the SSR markup, where the announcement lives in
// attributes rather than a semantics node.
import 'package:coui_web/coui_web.dart';
import 'package:html/dom.dart' as html;
import 'package:jaspr_test/server_test.dart';

Component _host(Component child) => CoUIWeb(theme: .coui, child: child);

html.Element? _one(DocumentResponse response, String selector) =>
    response.document?.querySelector(selector);

List<html.Element> _all(DocumentResponse response, String selector) =>
    response.document?.querySelectorAll(selector) ?? const [];

void main() {
  group('MenuItem announcement', () {
    testServer('a plain row is a menuitem and takes the tab stop', (
      tester,
    ) async {
      tester.pumpComponent(
        _host(MenuItem(label: const Text('Copy'), onPressed: () {})),
      );
      final row = _one(await tester.request('/'), '[role="menuitem"]');

      expect(row, isNotNull);
      expect(row!.attributes['tabindex'], '0');
      expect(row.attributes['aria-disabled'], isNull);
    });

    testServer('a row with no handler announces as disabled and keeps its '
        'place in the rotation', (tester) async {
      tester.pumpComponent(_host(const MenuItem(label: Text('Paste'))));
      final row = _one(await tester.request('/'), '[role="menuitem"]');

      expect(row!.attributes['aria-disabled'], 'true');
      // Inert, not unreachable — the WAI-ARIA menu pattern keeps a
      // disabled row focusable so a keyboard user can hear why it does
      // nothing.
      expect(row.attributes['tabindex'], '0');
    });

    testServer('a submenu row says so and shows a chevron instead of its '
        'shortcut', (tester) async {
      tester.pumpComponent(
        _host(
          MenuItem(
            label: const Text('More'),
            shortcut: const Text('⌘M'),
            hasSubmenu: true,
            onPressed: () {},
          ),
        ),
      );
      final response = await tester.request('/');
      final row = _one(response, '[role="menuitem"]');

      expect(row!.attributes['aria-haspopup'], 'menu');
      expect(response.document?.body?.text, isNot(contains('⌘M')));
    });
  });

  group('MenuItem seats', () {
    testServer('label, description and shortcut all render', (tester) async {
      tester.pumpComponent(
        _host(
          MenuItem(
            label: const Text('Rename'),
            description: const Text('Change the display name'),
            shortcut: const Text('F2'),
            onPressed: () {},
          ),
        ),
      );
      final body = (await tester.request('/')).document?.body?.text;

      expect(body, contains('Rename'));
      expect(body, contains('Change the display name'));
      expect(body, contains('F2'));
    });

    testServer('a reserved mark column keeps its width with no mark drawn', (
      tester,
    ) async {
      tester.pumpComponent(
        _host(
          MenuItem(
            label: const Text('Grid'),
            reserveMark: true,
            onPressed: () {},
          ),
        ),
      );
      final seat = _one(
        await tester.request('/'),
        '[role="menuitem"] > div.shrink-0',
      );

      // The seat exists and states a width even though nothing fills it —
      // that is what keeps a mixed group's labels on one x.
      expect(seat, isNotNull);
      expect(seat!.attributes['style'], contains('width'));
    });
  });

  group('MenuItem chrome', () {
    testServer('the density ladder moves the row height', (tester) async {
      final heights = <CoreMenuItemSize, String?>{};
      for (final size in CoreMenuItemSize.values) {
        tester.pumpComponent(
          _host(
            MenuItem(label: const Text('Row'), size: size, onPressed: () {}),
          ),
        );
        heights[size] = _one(
          await tester.request('/'),
          '[role="menuitem"]',
        )?.attributes['style'];
      }

      // 32 / 36 / 48 — the sm and lg rows are control-ladder rungs and go
      // out through their row variable, so a density re-points them; the 36
      // md row is off the ladder and goes out as a length.
      expect(
        heights[CoreMenuItemSize.sm],
        contains('min-height: var(--coui-control-height-32)'),
      );
      expect(heights[CoreMenuItemSize.md], contains('min-height: 2.25rem'));
      expect(
        heights[CoreMenuItemSize.md],
        isNot(contains('--coui-control-height')),
      );
      expect(
        heights[CoreMenuItemSize.lg],
        contains('min-height: var(--coui-control-height-48)'),
      );
    });

    testServer('a critical row reads in the error colour, a neutral one in '
        'the surface foreground', (tester) async {
      tester.pumpComponent(
        _host(
          MenuItem(
            label: const Text('Delete'),
            tone: CoreMenuItemTone.critical,
            onPressed: () {},
          ),
        ),
      );
      final critical = _one(await tester.request('/'), '[role="menuitem"]');

      expect(critical!.attributes['class'], contains('text-error'));
      expect(critical.attributes['class'], isNot(contains('text-on-surface')));
    });

    testServer('a selected row takes the primary fill', (tester) async {
      tester.pumpComponent(
        _host(
          MenuItem(
            label: const Text('Chosen'),
            selected: true,
            onPressed: () {},
          ),
        ),
      );
      final row = _one(await tester.request('/'), '[role="menuitem"]');

      expect(row!.attributes['class'], contains('bg-primary'));
      expect(row.attributes['class'], contains('text-on-primary'));
    });

    testServer('a disabled row reads in disabledContent on every seat', (
      tester,
    ) async {
      tester.pumpComponent(
        _host(
          const MenuItem(
            label: Text('Export'),
            description: Text('Write a file'),
            shortcut: Text('Ctrl+E'),
          ),
        ),
      );
      final response = await tester.request('/');
      final row = _one(response, '[role="menuitem"]');

      expect(row!.attributes['class'], contains('text-disabled-content'));
      // The label, the description and the shortcut each carry the ink on
      // their own element, so none of them falls back to the muted colour a
      // resting row keeps for its second line.
      for (final text in const ['Export', 'Write a file', 'Ctrl+E']) {
        final seat = _all(response, 'div').firstWhere(
          (e) =>
              e.text.trim() == text &&
              (e.attributes['class'] ?? '').contains('text-'),
        );
        expect(
          seat.attributes['class'],
          contains('text-disabled-content'),
          reason: text,
        );
        expect(
          seat.attributes['class'],
          isNot(contains('text-on-surface-variant')),
          reason: text,
        );
      }
    });

    testServer('the wash weighs 8 on hover and focus and 12 when pressed', (
      tester,
    ) async {
      tester.pumpComponent(
        _host(MenuItem(label: const Text('Hover me'), onPressed: () {})),
      );
      final css = _all(
        await tester.request('/'),
        'style',
      ).map((e) => e.text).join();

      expect(
        RegExp(
          r':hover > \.co-menu-item-wash\{background-color:[^;]*8%',
        ).hasMatch(css),
        isTrue,
        reason: css,
      );
      expect(
        RegExp(
          r':focus-visible > \.co-menu-item-wash\{background-color:[^;]*8%',
        ).hasMatch(css),
        isTrue,
        reason: css,
      );
      expect(
        RegExp(
          r':active > \.co-menu-item-wash\{background-color:[^;]*12%',
        ).hasMatch(css),
        isTrue,
        reason: css,
      );
    });

    testServer('the wash is a scoped rule on an overlay, not a fill swap', (
      tester,
    ) async {
      tester.pumpComponent(
        _host(MenuItem(label: const Text('Hover me'), onPressed: () {})),
      );
      final response = await tester.request('/');
      final css = _all(response, 'style').map((e) => e.text).join();

      // Three weights, one per interaction — and every one of them paints
      // the overlay rather than the row, so the row's own fill stays
      // visible under it.
      expect(css, contains(':hover > .co-menu-item-wash{background-color:'));
      expect(
        css,
        contains(':focus-visible > .co-menu-item-wash{background-color:'),
      );
      expect(css, contains(':active > .co-menu-item-wash{background-color:'));
    });

    testServer('a critical row fills on hover, focus and press and keeps '
        'its inks', (tester) async {
      tester.pumpComponent(
        _host(
          MenuItem(
            label: const Text('Delete'),
            description: const Text('Cannot be undone'),
            shortcut: const Text('Del'),
            tone: CoreMenuItemTone.critical,
            onPressed: () {},
          ),
        ),
      );
      final response = await tester.request('/');
      final css = _all(response, 'style').map((e) => e.text).join();
      final row = _one(response, '[role="menuitem"]')!;

      // The fill rides the overlay: opaque, behind the text, in a row that
      // owns its stacking context. The row's own fill is inline, which no
      // rule could beat.
      expect(row.attributes['class'], contains('isolate'));
      final scopeClass = row.classes.singleWhere(
        (name) =>
            name.startsWith('co-menu-item-') && name != 'co-menu-item-row',
      );
      final hover = '.$scopeClass:hover > .co-menu-item-wash';
      final focus = '.$scopeClass:focus-visible > .co-menu-item-wash';
      final active = '.$scopeClass:active > .co-menu-item-wash';
      const fill =
          'background-color:rgb(var(--coui-error-container));z-index:-1;';
      expect(
        css,
        contains('$hover,$focus{$fill}'),
      );
      expect(
        css,
        contains('$active{$fill}'),
      );
      // The inks do not change with the fill (designer decision 2026-11-05,
      // #6012): no rule recolours the row or its seats, so the label stays
      // `error` and the description and the shortcut keep their muted
      // colour.
      expect(css, isNot(contains('.co-menu-item-ink')));
      expect(css, isNot(contains('on-error-container')));
      expect(row.attributes['class'], contains('text-error'));
      // Not a wash of the error ink over the resting fill.
      expect(css, isNot(contains('rgb(var(--coui-error) /')));
    });

    testServer('a neutral row keeps the wash and no stacking context', (
      tester,
    ) async {
      tester.pumpComponent(
        _host(MenuItem(label: const Text('Copy'), onPressed: () {})),
      );
      final response = await tester.request('/');
      // The rules in the body: the app root also states page-wide rules in
      // the head — the page transition stacks a leaving page over the one
      // returned to — which say nothing about the row.
      final css = _all(response, 'body style').map((e) => e.text).join();

      expect(
        _one(response, '[role="menuitem"]')!.attributes['class'],
        isNot(contains('isolate')),
      );
      expect(css, contains('.co-menu-item-wash'));
      expect(css, isNot(contains('z-index')));
      expect(css, isNot(contains('error-container')));
    });

    testServer('a selected or disabled critical row takes no active fill', (
      tester,
    ) async {
      tester.pumpComponent(
        _host(
          MenuItem(
            label: const Text('Delete'),
            tone: CoreMenuItemTone.critical,
            selected: true,
            onPressed: () {},
          ),
        ),
      );
      final selected = await tester.request('/');
      final selectedCss = _all(selected, 'style').map((e) => e.text).join();
      expect(selectedCss, isNot(contains('error-container')));
      expect(
        _one(selected, '[role="menuitem"]')!.attributes['class'],
        isNot(contains('isolate')),
      );

      tester.pumpComponent(
        _host(
          const MenuItem(
            label: Text('Delete'),
            tone: CoreMenuItemTone.critical,
          ),
        ),
      );
      final disabled = await tester.request('/');
      expect(
        _all(disabled, 'style').map((e) => e.text).join(),
        isNot(contains('error-container')),
      );
    });

    testServer('a disabled row draws no wash', (tester) async {
      tester.pumpComponent(_host(const MenuItem(label: Text('Inert'))));
      final css = _all(
        await tester.request('/'),
        'style',
      ).map((e) => e.text).join();

      expect(css, isNot(contains('co-menu-item-wash{background-color:')));
    });

    testServer('a raw colour override emits a rule instead of throwing', (
      tester,
    ) async {
      tester.pumpComponent(
        _host(
          MenuItem(
            label: const Text('Custom'),
            onPressed: () {},
          ).withStyle(
            const CoreMenuItemStyle(
              foregroundColor: CoreColor.fromRGB(12, 34, 56),
            ),
          ),
        ),
      );
      final response = await tester.request('/');

      expect(_one(response, '[role="menuitem"]'), isNotNull);
      expect(
        _all(response, 'style').map((e) => e.text).join(),
        contains('co-menu-item-wash{background-color:'),
      );
    });
  });

  group('Menu composes rows', () {
    testServer('toggle rows announce their kind and their state', (
      tester,
    ) async {
      tester.pumpComponent(
        _host(
          Menu(
            items: [
              CoreMenuItem<Component>.checkbox(
                'Show grid',
                checked: true,
                onChanged: (_) {},
              ),
              CoreMenuItem<Component>.radio(
                'Compact',
                onChanged: (_) {},
              ),
            ],
          ),
        ),
      );
      final response = await tester.request('/');
      final checkbox = _one(response, '[role="menuitemcheckbox"]');
      final radio = _one(response, '[role="menuitemradio"]');

      expect(checkbox!.attributes['aria-checked'], 'true');
      expect(radio!.attributes['aria-checked'], 'false');
    });

    testServer('one row holds the tab stop and the rest wait at -1', (
      tester,
    ) async {
      tester.pumpComponent(
        _host(
          Menu(
            items: [
              CoreMenuItem<Component>.action('First', onPressed: () {}),
              const CoreMenuItem<Component>.divider(),
              CoreMenuItem<Component>.action('Second', onPressed: () {}),
              CoreMenuItem<Component>.action('Third', onPressed: () {}),
            ],
          ),
        ),
      );
      final rows = _all(await tester.request('/'), '[data-roving-item]');

      expect(rows.map((e) => e.attributes['tabindex']), ['0', '-1', '-1']);
      // The divider is structure, not a stop — numbering it would make an
      // arrow press look like it did nothing.
      expect(
        rows.map((e) => e.attributes['data-roving-item']!.split(':').last),
        ['0', '1', '2'],
      );
    });

    testServer('the menu hands its density to every row', (tester) async {
      tester.pumpComponent(
        _host(
          Menu(
            size: CoreMenuItemSize.lg,
            items: [
              CoreMenuItem<Component>.action('One', onPressed: () {}),
              CoreMenuItem<Component>.action('Two', onPressed: () {}),
            ],
          ),
        ),
      );
      final rows = _all(await tester.request('/'), '[data-roving-item]');

      expect(rows, hasLength(2));
      for (final row in rows) {
        expect(
          row.attributes['style'],
          contains('min-height: var(--coui-control-height-48)'),
        );
      }
    });

    testServer('an itemStyle override reaches the row', (tester) async {
      tester.pumpComponent(
        _host(
          Menu(
            menuStyle: const CoreMenuStyle(
              itemStyle: CoreMenuItemStyle(
                padding: CoreEdgeInsets.symmetric(horizontal: 24),
              ),
            ),
            items: [CoreMenuItem<Component>.action('Wide', onPressed: () {})],
          ),
        ),
      );
      final row = _one(await tester.request('/'), '[data-roving-item]');

      expect(
        row!.attributes['style'],
        contains('padding-inline: var(--coui-space-24)'),
      );
    });
  });
}
