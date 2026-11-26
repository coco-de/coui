import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';
import 'package:jaspr_test/server_test.dart' show testServer;

import '../../helpers/pump_with_theme.dart';

/// The Web twin of the Flutter `navigation_bar_item_test`: the destination
/// the bar composes, placed on its own, read back from the rendered page —
/// the current-place state, the accessible name, the badge's seat, the
/// interactivity the callback grants, and the state layer a standalone row
/// has to carry itself.

Component _host(Component child) => CoUIWeb(theme: .coui, child: child);

const _badge = Badge(
  form: CoreBadgeForm.count,
  tone: CoreBadgeTone.info,
  variant: CoreBadgeVariant.filled,
  size: CoreComponentSize.xs,
  child: Text('3'),
);

void main() {
  group('a standalone item draws a sidebar row', () {
    testServer('the current place, named label then badge', (tester) async {
      tester.pumpComponent(
        _host(
          NavigationBarItem(
            id: 'inbox',
            icon: const Icon(LucideIcons.inbox),
            label: 'Inbox',
            badge: _badge,
            selected: true,
            onPressed: () {},
          ),
        ),
      );
      final document = (await tester.request('/')).document!;
      final root = document.getElementById('inbox')!;

      expect(
        CoreNavigationBarItemContract.defaultMode,
        CoreNavigationBarMode.sidebar,
      );
      expect(root.attributes['role'], 'button');
      expect(root.attributes['aria-current'], 'page');
      expect(root.attributes['aria-labelledby'], 'inbox-label inbox-badge');
      expect(root.attributes['data-coui-nav-index'], isNull);
      expect(document.getElementById('inbox-label')!.text, 'Inbox');
      // The sidebar row carries the count at its far end.
      final badge = document.getElementById('inbox-badge')!;
      expect(badge.text, '3');
      expect(badge.attributes['style'], contains('margin-inline-start: auto'));
      // A flex box, so the badge is a flex item and not an inline box on a
      // line — a line takes the label's 21px line height and makes the row
      // 37 where the Flutter twin's is 36 (measured in Chrome).
      expect(badge.classes, containsAll(['flex', 'shrink-0']));
    });

    testServer('without a callback the row is not interactive', (
      tester,
    ) async {
      tester.pumpComponent(
        _host(const NavigationBarItem(id: 'inbox', label: 'Inbox')),
      );
      final document = (await tester.request('/')).document!;
      final root = document.getElementById('inbox')!;

      expect(root.attributes['aria-disabled'], 'true');
      expect(root.attributes['tabindex'], isNot('0'));
    });

    testServer('a callback makes it a tab stop', (tester) async {
      tester.pumpComponent(
        _host(NavigationBarItem(id: 'inbox', label: 'Inbox', onPressed: () {})),
      );
      final document = (await tester.request('/')).document!;
      final root = document.getElementById('inbox')!;

      expect(root.attributes['aria-disabled'], isNull);
      expect(root.attributes['tabindex'], '0');
    });

    testServer('a disabled item is never the current place', (tester) async {
      tester.pumpComponent(
        _host(
          NavigationBarItem(
            id: 'inbox',
            label: 'Inbox',
            selected: true,
            enabled: false,
            onPressed: () {},
          ),
        ),
      );
      final document = (await tester.request('/')).document!;
      final root = document.getElementById('inbox')!;

      expect(root.attributes['aria-current'], isNull);
      expect(root.attributes['aria-disabled'], 'true');
    });

    testServer('a hidden label stays in the tree and becomes the tooltip', (
      tester,
    ) async {
      tester.pumpComponent(
        _host(
          NavigationBarItem(
            id: 'inbox',
            icon: const Icon(LucideIcons.inbox),
            label: 'Inbox',
            labelMode: CoreNavigationLabelMode.none,
            onPressed: () {},
          ),
        ),
      );
      final document = (await tester.request('/')).document!;
      final label = document.getElementById('inbox-label')!;

      expect(label.classes, containsAll(['sr-only', 'fixed']));
      expect(label.text, 'Inbox');
      expect(
        document.getElementById('inbox')!.attributes['aria-labelledby'],
        'inbox-label',
      );
    });

    for (final mode in [
      CoreNavigationBarMode.bar,
      CoreNavigationBarMode.rail,
    ]) {
      testServer('${mode.name} hangs the badge on the icon', (tester) async {
        tester.pumpComponent(
          _host(
            NavigationBarItem(
              id: 'inbox',
              mode: mode,
              icon: const Icon(LucideIcons.inbox),
              label: 'Inbox',
              badge: _badge,
              onPressed: () {},
            ),
          ),
        );
        final document = (await tester.request('/')).document!;
        final overlay = document.getElementById('inbox-badge')!.parent!;

        expect(overlay.attributes['style'], contains('right: -0.375rem'));
        expect(overlay.attributes['style'], contains('top: -0.375rem'));
      });
    }
  });

  group('the state layer', () {
    testServer('a standalone row writes its own rules', (tester) async {
      tester.pumpComponent(
        _host(NavigationBarItem(id: 'inbox', label: 'Inbox', onPressed: () {})),
      );
      final document = (await tester.request('/')).document!;
      final root = document.getElementById('inbox')!;
      final chrome = root.querySelector('[data-coui-nav-chrome]')!;
      final scope = chrome.classes.firstWhere(
        (c) => c.startsWith('co-navbar-sl-'),
      );
      final styles = root
          .querySelectorAll('style')
          .map((style) => style.text)
          .join();

      expect(styles, contains('.$scope:hover{'));
      // The focus rule keys on the focusable Clickable root, the chrome's
      // parent — the chrome itself never takes focus.
      expect(styles, contains(':focus-visible>.$scope{'));
      expect(styles, contains('.$scope:active{'));
    });

    testServer('inside a bar the bar writes them once', (tester) async {
      tester.pumpComponent(
        _host(
          NavigationBar(
            id: 'nav',
            mode: CoreNavigationBarMode.sidebar,
            selectedIndex: 0,
            onSelected: (_) {},
            items: const [
              CoreNavigationBarItem.destination(label: 'Inbox'),
              CoreNavigationBarItem.destination(label: 'Drafts'),
            ],
          ),
        ),
      );
      final document = (await tester.request('/')).document!;
      final nav = document.getElementById('nav')!;
      final rules = nav
          .querySelectorAll('style')
          .where((style) => style.text.contains('co-navbar-sl-'));

      expect(rules, hasLength(1));
      for (final destination in nav.querySelectorAll('[data-coui-nav-index]')) {
        expect(destination.querySelectorAll('style'), isEmpty);
      }
    });
  });

  testServer('a standalone row is the destination the bar composes', (
    tester,
  ) async {
    tester.pumpComponent(
      _host(
        div([
          NavigationBar(
            id: 'nav',
            mode: CoreNavigationBarMode.sidebar,
            selectedIndex: 0,
            onSelected: (_) {},
            items: const [
              CoreNavigationBarItem.destination(
                icon: Icon(LucideIcons.inbox),
                label: 'Inbox',
                badge: _badge,
              ),
            ],
          ),
          NavigationBarItem(
            id: 'inbox',
            icon: const Icon(LucideIcons.inbox),
            label: 'Inbox',
            badge: _badge,
            selected: true,
            onPressed: () {},
          ),
        ]),
      ),
    );
    final document = (await tester.request('/')).document!;
    final composed = document.querySelector('[data-coui-nav-index="0"]')!;
    final standalone = document.getElementById('inbox')!;

    expect(standalone.classes, composed.classes);
    expect(standalone.attributes['aria-current'], 'page');
    expect(standalone.attributes['role'], composed.attributes['role']);
    expect(
      standalone.querySelector('[data-coui-nav-chrome]')!.classes,
      composed.querySelector('[data-coui-nav-chrome]')!.classes,
    );
    expect(
      standalone.querySelector('[data-coui-nav-chrome]')!.attributes['style'],
      composed.querySelector('[data-coui-nav-chrome]')!.attributes['style'],
    );
  });

  group('interaction', () {
    testComponents('a click reaches onPressed', (tester) async {
      var presses = 0;
      pumpWithTheme(
        tester,
        NavigationBarItem(label: 'Inbox', onPressed: () => presses++),
      );
      await tester.click(find.byType(Clickable));
      expect(presses, 1);
    });

    testComponents('a click on a disabled row does nothing', (tester) async {
      var presses = 0;
      pumpWithTheme(
        tester,
        NavigationBarItem(
          label: 'Inbox',
          enabled: false,
          onPressed: () => presses++,
        ),
      );
      await tester.click(find.byType(Clickable));
      expect(presses, 0);
    });

    testComponents('hover selects the hover face', (tester) async {
      // A raw hover fill has no preset utility, so the item paints it inline
      // while hovered — the face the item's own hover state selects.
      pumpWithTheme(
        tester,
        NavigationBarItem(
          label: 'Inbox',
          onPressed: () {},
          navigationBarStyle: const CoreNavigationBarStyle(
            hoverBackgroundColor: CoreColor.fromARGB(255, 10, 20, 30),
          ),
        ),
      );
      String? chromeStyle() {
        for (final element in find.byType(DomComponent).evaluate()) {
          final dom = element.component as DomComponent;
          if (dom.attributes?.containsKey('data-coui-nav-chrome') ?? false) {
            return dom.styles?.properties['background-color'];
          }
        }
        return null;
      }

      expect(chromeStyle(), isNull);
      tester.dispatchEvent(find.byType(Clickable), 'mouseenter');
      await tester.pump();
      expect(chromeStyle(), isNotNull);
      tester.dispatchEvent(find.byType(Clickable), 'mouseleave');
      await tester.pump();
      expect(chromeStyle(), isNull);
    });
  });

  testServer('withStyle merges into the bar style the item draws', (
    tester,
  ) async {
    tester.pumpComponent(
      _host(
        NavigationBarItem(
          id: 'inbox',
          label: 'Inbox',
          onPressed: () {},
        ).withStyle(
          const CoreNavigationBarStyle(
            itemRadius: CoreBorderRadius.all(CoreRadius.radius2),
          ),
        ),
      ),
    );
    final document = (await tester.request('/')).document!;
    final chrome = document
        .getElementById('inbox')!
        .querySelector('[data-coui-nav-chrome]')!;

    expect(chrome.attributes['style'], contains('--coui-radius-2'));
  });
}
