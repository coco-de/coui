import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

/// Every attribute on every element in the rendered tree.
Map<String, String> _allAttrs(ComponentTester tester) => {
  for (final e in find.byType(DomComponent).evaluate())
    ...?(e.component as DomComponent).attributes,
};

void main() {
  group('a link that navigates is an anchor', () {
    // What this locks: `Link` used to render `<div role="link"
    // data-href="…">` in every case, because the chrome was easier to
    // token-drive on a div and it matched the Flutter twin's shape.
    //
    // On a statically rendered page that div is not a link at all —
    // it does not navigate without JS, a crawler has no `href` to
    // follow (Lighthouse `crawlable-anchors`), middle-click and
    // open-in-new-tab do nothing, and `mailto:` / `tel:` never reach
    // the OS. The consumer site had to stop using `Link` and hand-roll
    // its own `<a>` helpers to get a working link.
    testComponents('renders <a> with a real href when it has no callback', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const Link(href: '/pricing', child: Text('Pricing')),
      );

      expect(find.tag('a'), findsOneComponent);
      expect(_allAttrs(tester)['href'], '/pricing');
    });

    testComponents('does not fall back to role="link" on a div', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const Link(href: '/pricing', child: Text('Pricing')),
      );

      final attrs = _allAttrs(tester);
      expect(attrs['role'], isNull);
      // `data-href` was the old carrier. A real `href` replaces it —
      // keeping both would be two statements of the same thing.
      expect(attrs['data-href'], isNull);
    });

    testComponents('an external link opens safely in a new tab', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const Link(
          href: 'https://example.com',
          external: true,
          child: Text('Example'),
        ),
      );

      final attrs = _allAttrs(tester);
      expect(attrs['target'], '_blank');
      // `noopener` keeps the opened tab from reaching back into this
      // window; `noreferrer` keeps our URL out of their logs.
      expect(attrs['rel'], 'noopener noreferrer');
    });

    testComponents('a same-tab link is not given target/rel', (tester) async {
      // The case that regressed on the consumer site: an in-page anchor
      // rendered with `target="_blank"` and opened an empty tab.
      pumpWithTheme(
        tester,
        const Link(href: '#proof', child: Text('Proof')),
      );

      final attrs = _allAttrs(tester);
      expect(attrs['target'], isNull);
      expect(attrs['rel'], isNull);
    });
  });

  group("a navigating link's chrome", () {
    DomComponent anchor() =>
        find.tag('a').evaluate().single.component as DomComponent;
    Set<String> classes() => (anchor().classes ?? '').split(' ').toSet();
    Map<String, String> raw() =>
        anchor().styles?.properties ?? const <String, String>{};

    testComponents('is recognised by colour, with no permanent underline', (
      tester,
    ) async {
      pumpWithTheme(tester, const Link(href: '/x', child: Text('X')));

      expect(classes(), containsAll(['text-link', 'no-underline']));
      expect(classes(), isNot(contains('underline')));
    });

    testComponents('reveals the underline on hover, focus and press', (
      tester,
    ) async {
      pumpWithTheme(tester, const Link(href: '/x', child: Text('X')));

      expect(
        classes(),
        containsAll([
          'hover:underline',
          'focus-visible:underline',
          'active:underline',
        ]),
      );
    });

    testComponents('underline: true is underlined and waits for nothing', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const Link(href: '/x', underline: true, child: Text('X')),
      );

      expect(classes(), contains('underline'));
      expect(classes(), isNot(contains('no-underline')));
      expect(
        classes().where((cls) => cls.startsWith('hover:underline')),
        isEmpty,
      );
    });

    testComponents('the interaction decoration is a style field', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const Link(
          href: '/x',
          linkStyle: CoreLinkStyle(
            interactionTextDecoration: CoreTextDecoration.lineThrough,
          ),
          child: Text('X'),
        ),
      );

      expect(classes(), contains('hover:line-through'));
      expect(classes(), isNot(contains('hover:underline')));
    });

    testComponents('muted reads the muted colour', (tester) async {
      pumpWithTheme(
        tester,
        const Link(
          href: '/x',
          variant: CoreLinkVariant.muted,
          child: Text('X'),
        ),
      );

      expect(classes(), contains('text-on-surface-variant'));
      expect(classes(), isNot(contains('text-link')));
    });

    testComponents('draws the CoUI focus ring itself', (tester) async {
      // The browser's own outline is replaced; keyboard focus gets the ring
      // a Clickable would have drawn.
      pumpWithTheme(tester, const Link(href: '/x', child: Text('X')));

      expect(
        classes(),
        containsAll([
          'outline-none',
          'focus-visible:outline-2',
          'focus-visible:outline-offset-2',
          'focus-visible:outline-focus-ring',
        ]),
      );
    });

    testComponents('the ring corner radius is a class a stylesheet can beat', (
      tester,
    ) async {
      // A caller gives a link its own shape through `classes:` — a pill, a
      // card. An inline radius would beat that stylesheet and flatten the
      // shape, so the default radius rides a utility class instead.
      pumpWithTheme(tester, const Link(href: '/x', child: Text('X')));

      expect(classes().where((cls) => cls.startsWith('rounded-')), isNotEmpty);
      expect(raw().containsKey('border-radius'), isFalse);
    });

    testComponents('a radius the style states goes inline', (tester) async {
      pumpWithTheme(
        tester,
        const Link(
          href: '/x',
          linkStyle: CoreLinkStyle(
            clickableStyle: CoreClickableStyle(
              borderRadius: CoreBorderRadius.all(CoreRadius.radius9999),
            ),
          ),
          child: Text('X'),
        ),
      );

      expect(raw()['border-radius'], isNotNull);
      expect(classes().where((cls) => cls.startsWith('rounded-')), isEmpty);
    });

    testComponents('fades the colour and the ring in one transition', (
      tester,
    ) async {
      pumpWithTheme(tester, const Link(href: '/x', child: Text('X')));

      final transition = raw()['transition'];
      expect(transition, contains('color '));
      expect(transition, contains('outline-color '));
      // One declaration owns the property list — no class contests it.
      expect(classes().where((cls) => cls.startsWith('transition')), isEmpty);
    });

    testComponents("the underline is the font's own", (tester) async {
      pumpWithTheme(tester, const Link(href: '/x', child: Text('X')));

      expect(classes(), contains('decoration-from-font'));
      expect(raw()['text-underline-position'], 'from-font');
      expect(
        classes().where((cls) => cls.contains('underline-offset')),
        isEmpty,
      );
      expect(raw().containsKey('text-underline-offset'), isFalse);
    });

    testComponents('a raw text colour override rides inline, not a class', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const Link(
          href: '/x',
          linkStyle: CoreLinkStyle(color: CoreColor(0xFFAA0000)),
          child: Text('X'),
        ),
      );

      expect(classes(), isNot(contains('text-link')));
      expect(raw()['color'], isNotNull);
    });

    testComponents('an untouched ring needs no id and no style block', (
      tester,
    ) async {
      pumpWithTheme(tester, const Link(href: '/x', child: Text('X')));

      expect(anchor().id, isNull);
      expect(find.tag('style'), findsNothing);
    });

    testComponents('a ring override moves to a scoped rule under an id', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const Link(
          href: '/x',
          linkStyle: CoreLinkStyle(
            clickableStyle: CoreClickableStyle(
              focusOutlineStyle: CoreFocusOutlineStyle(borderWidth: 4),
            ),
          ),
          child: Text('X'),
        ),
      );

      // Class XOR rule: the ring is no longer on a preset class.
      expect(anchor().id, isNotNull);
      expect(
        classes().where((cls) => cls.startsWith('focus-visible:outline')),
        isEmpty,
      );
      expect(find.tag('style'), findsOneComponent);
    });

    testComponents('an id the caller gave is kept', (tester) async {
      pumpWithTheme(
        tester,
        const Link(href: '/x', id: 'mine', child: Text('X')),
      );

      expect(anchor().id, 'mine');
    });
  });

  group('a link that acts keeps the Clickable behaviour', () {
    // The other half of the contract: with a callback the component is
    // still an activatable control, and the Flutter twin's keyboard /
    // press behaviour lives in `Clickable`. That path must not change.
    testComponents('renders role="link" when it has a callback', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        Link(href: '/x', onPressed: () {}, child: const Text('Act')),
      );

      expect(_allAttrs(tester)['role'], 'link');
      expect(find.tag('a'), findsNothing);
    });

    testComponents('the Clickable root is the group the underline reads', (
      tester,
    ) async {
      // The Clickable — not the text inside it — is what is hovered and
      // focused, so the content reads the state off its group.
      pumpWithTheme(
        tester,
        Link(href: '/x', onPressed: () {}, child: const Text('Act')),
      );

      final root = find.tag('div').evaluate().first.component as DomComponent;
      expect((root.classes ?? '').split(' '), contains('group'));

      final content =
          find.tag('span').evaluate().first.component as DomComponent;
      expect(
        (content.classes ?? '').split(' '),
        containsAll([
          'no-underline',
          'group-hover:underline',
          'group-focus-visible:underline',
          'group-active:underline',
        ]),
      );
    });

    testComponents('a caller class survives next to the group marker', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        Link(
          href: '/x',
          classes: 'mine',
          onPressed: () {},
          child: const Text('Act'),
        ),
      );

      final root = find.tag('div').evaluate().first.component as DomComponent;
      expect((root.classes ?? '').split(' '), containsAll(['group', 'mine']));
    });
  });
}
