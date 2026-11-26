import 'package:coui_web/coui_web.dart';
import 'package:coui_web/src/components/text/link/link_style.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

/// The single `<a>` the inline form renders.
DomComponent _anchor() =>
    find.tag('a').evaluate().single.component as DomComponent;

/// Class tokens of the inline anchor.
Set<String> _classes() => (_anchor().classes ?? '').split(' ').toSet();

/// Pumps `Link.inlineSpan` built from a live context, inside a paragraph.
void _pumpInline(
  ComponentTester tester,
  Component Function(BuildContext context) build,
) {
  pumpWithTheme(
    tester,
    Component.element(
      tag: 'p',
      children: [
        const Text('Read the '),
        Builder(builder: build),
        const Text(' first.'),
      ],
    ),
  );
}

void main() {
  group('Link.inlineSpan renders an inline anchor', () {
    // What this locks: the inline form must take its type ramp from the
    // paragraph around it. `Link` pins its label to the body-medium role
    // class, which is right for a standalone link and wrong inside a
    // heading or a table cell — the link text jumps size.
    testComponents('is an <a href> with no typography role class', (
      tester,
    ) async {
      _pumpInline(
        tester,
        (context) => Link.inlineSpan(
          context,
          href: '/docs/theming',
          text: 'theming guide',
        ),
      );

      expect(_anchor().attributes?['href'], '/docs/theming');
      final roleClass = 'text-${CoreLinkStyle.defaultLabelStyle.token!.name}';
      expect(_classes(), isNot(contains(roleClass)));
      expect(find.text('theming guide'), findsOneComponent);
    });

    testComponents('carries the link colour and an underline', (tester) async {
      late ResolvedLink resolved;
      _pumpInline(tester, (context) {
        resolved = resolveLink(context, variant: CoreLinkVariant.standard);
        return Link.inlineSpan(context, href: '/x', text: 'x');
      });

      expect(_anchor().classes, resolved.span.className);
      expect(_classes(), containsAll(['underline', 'text-link']));
      // The standalone anchor shares the colour source — the two cannot
      // paint different links.
      expect(resolved.anchor.className.split(' '), contains('text-link'));
    });

    testComponents('is always underlined and reveals nothing on hover', (
      tester,
    ) async {
      // Inside a sentence the colour alone cannot carry the recognition, so
      // the inline form has no flag to switch the underline off: it never
      // sits behind a `no-underline`, and it has no hover underline to wait
      // for.
      _pumpInline(
        tester,
        (context) => Link.inlineSpan(context, href: '/x', text: 'x'),
      );

      expect(_classes(), contains('underline'));
      expect(_classes(), isNot(contains('no-underline')));
      expect(
        _classes().where((cls) => cls.contains('hover:underline')),
        isEmpty,
      );
    });

    testComponents('the muted variant reads the muted colour', (tester) async {
      _pumpInline(
        tester,
        (context) => Link.inlineSpan(
          context,
          href: '/x',
          text: 'x',
          variant: CoreLinkVariant.muted,
        ),
      );

      expect(_classes(), contains('text-on-surface-variant'));
      expect(_classes(), isNot(contains('text-link')));
    });

    testComponents('draws the CoUI focus ring', (tester) async {
      _pumpInline(
        tester,
        (context) => Link.inlineSpan(context, href: '/x', text: 'x'),
      );

      expect(
        _classes(),
        containsAll([
          'outline-none',
          'focus-visible:outline-2',
          'focus-visible:outline-offset-2',
          'focus-visible:outline-focus-ring',
        ]),
      );
    });

    testComponents("the underline is the font's own", (tester) async {
      _pumpInline(
        tester,
        (context) => Link.inlineSpan(context, href: '/x', text: 'x'),
      );

      final raw = _anchor().styles?.properties ?? const <String, String>{};
      expect(_classes(), contains('decoration-from-font'));
      expect(raw['text-underline-position'], 'from-font');
      // No offset is stated — a stated offset is what stops the position
      // from following the font.
      expect(
        _classes().where((cls) => cls.contains('underline-offset')),
        isEmpty,
      );
      expect(raw.containsKey('text-underline-offset'), isFalse);
    });

    testComponents('a ring override moves to a scoped rule under an id', (
      tester,
    ) async {
      _pumpInline(
        tester,
        (context) => Link.inlineSpan(
          context,
          href: '/x',
          text: 'x',
          linkStyle: const CoreLinkStyle(
            clickableStyle: CoreClickableStyle(
              focusOutlineStyle: CoreFocusOutlineStyle(borderWidth: 4),
            ),
          ),
        ),
      );

      final id = _anchor().id;
      expect(id, isNotNull);
      expect(
        _classes().where((cls) => cls.startsWith('focus-visible:outline')),
        isEmpty,
      );
      expect(find.tag('style'), findsOneComponent);
    });

    testComponents('an explicit labelStyle field is emitted inline', (
      tester,
    ) async {
      _pumpInline(
        tester,
        (context) => Link.inlineSpan(
          context,
          href: '/x',
          text: 'x',
          linkStyle: const CoreLinkStyle(
            labelStyle: CoreTextStyle(fontWeight: CoreFontWeight.semiBold),
          ),
        ),
      );

      final raw = _anchor().styles?.properties ?? const <String, String>{};
      expect(raw['font-weight'], '${CoreFontWeight.semiBold}');
      expect(raw.containsKey('font-size'), isFalse);
    });

    testComponents('shows the href when no label is given', (tester) async {
      _pumpInline(tester, (context) => Link.inlineSpan(context, href: '/x'));

      expect(find.text('/x'), findsOneComponent);
    });

    testComponents('an external link opens safely in a new tab', (
      tester,
    ) async {
      _pumpInline(
        tester,
        (context) => Link.inlineSpan(
          context,
          href: 'https://example.com',
          text: 'Example',
          external: true,
        ),
      );

      expect(_anchor().attributes?['target'], '_blank');
      expect(_anchor().attributes?['rel'], 'noopener noreferrer');
    });
  });

  group('Link.inlineSpan with onPressed', () {
    testComponents('a click runs the callback instead of navigating', (
      tester,
    ) async {
      var pressed = 0;
      _pumpInline(
        tester,
        (context) => Link.inlineSpan(
          context,
          href: '/x',
          text: 'x',
          onPressed: () => pressed++,
        ),
      );

      await tester.click(find.tag('a'));

      expect(pressed, 1);
      // The href stays for crawlers and middle-click.
      expect(_anchor().attributes?['href'], '/x');
    });

    testComponents('without onPressed no click listener is attached', (
      tester,
    ) async {
      _pumpInline(
        tester,
        (context) => Link.inlineSpan(context, href: '/x', text: 'x'),
      );

      expect(_anchor().events, isNull);
    });
  });
}
