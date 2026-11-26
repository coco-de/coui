// `NavigationMenu` is a site navigation, not an application menu (#3968 ·
// #4154): its panels hold arbitrary content — links, cards, text — which
// cannot be the `menuitem`s `role="menu"` promises, so claiming menubar
// semantics asked a reader for arrow-key menu behaviour nothing could give.
// It follows the WAI-ARIA disclosure navigation pattern instead, which is
// also what the Flutter twin announces: a labelled navigation of links and
// disclosure buttons, each its own Tab stop.
import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/server_test.dart';

Component _host(Component child) => CoUIWeb(theme: .coui, child: child);

void main() {
  testServer('the bar is a labelled navigation of links and disclosure '
      'buttons, with no menu roles', (tester) async {
    tester.pumpComponent(
      _host(
        const NavigationMenu(
          items: [
            CoreNavigationMenuItem(label: 'Docs', href: '/docs'),
            CoreNavigationMenuItem(label: 'Products', content: Text('panel')),
          ],
        ),
      ),
    );
    final document = (await tester.request('/')).document!;

    // One landmark, and it is the native element — `<nav>` already is a
    // navigation landmark, so a stated `role` would only repeat it.
    final landmarks = document.querySelectorAll('nav, [role="navigation"]');
    expect(landmarks, hasLength(1));
    final nav = landmarks.single;
    expect(nav.localName, 'nav');
    expect(nav.attributes['role'], isNull);

    expect(nav.attributes['aria-label'], isNotEmpty);
    expect(
      document.querySelectorAll(
        '[role="menubar"], [role="menu"], [role="menuitem"]',
      ),
      isEmpty,
    );

    final link = nav.querySelector('a')!;
    expect(link.attributes['href'], '/docs');
    expect(link.attributes['aria-expanded'], isNull);

    final disclosure = nav.querySelector('button')!;
    expect(disclosure.attributes['aria-expanded'], 'false');
    expect(disclosure.attributes['aria-haspopup'], isNull);
  });

  group('landmark label', () {
    const items = [
      CoreNavigationMenuItem<Component>(label: 'Docs', href: '/docs'),
    ];

    testServer('defaults to the localized navigation label', (tester) async {
      tester.pumpComponent(_host(const NavigationMenu(items: items)));
      final document = (await tester.request('/')).document!;

      expect(
        document.querySelector('nav')!.attributes['aria-label'],
        DefaultCouiLocalizations.instance.navigationLabel,
      );
    });

    testServer("a caller's aria-label wins over the default", (tester) async {
      // Identity and semantics pass through freely: a page with two
      // navigation landmarks has to name them apart, and a component that
      // overwrote the caller's name would make that impossible.
      tester.pumpComponent(
        _host(
          const NavigationMenu(
            attributes: {'aria-label': 'Primary'},
            items: items,
          ),
        ),
      );
      final document = (await tester.request('/')).document!;

      final navs = document.querySelectorAll('nav');
      expect(navs, hasLength(1));
      expect(navs.single.attributes['aria-label'], 'Primary');
    });
  });
}
