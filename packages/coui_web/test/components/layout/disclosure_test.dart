import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

/// Every rendered element, in tree order.
List<DomComponent> _elements(ComponentTester tester) => [
  for (final e in find.byType(DomComponent).evaluate())
    e.component as DomComponent,
];

DomComponent _byTag(ComponentTester tester, String tag) =>
    _elements(tester).firstWhere((e) => e.tag == tag);

Set<String> _classesOf(DomComponent e) =>
    (e.classes ?? '').split(' ').where((c) => c.isNotEmpty).toSet();

/// Every attribute name present anywhere in the tree.
Set<String> _allAttrNames(ComponentTester tester) => {
  for (final e in _elements(tester)) ...?e.attributes?.keys,
};

void main() {
  // The group the component exists for. Everything here is asserted on
  // the *rendered markup* — no toggling, no events — because that is the
  // state a statically rendered page is served in and the state a reader
  // with scripting off never leaves.
  group('renders usable without hydration', () {
    testComponents('the root is <details> with a <summary> header', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const Disclosure(title: 'Question', content: Text('Answer')),
      );

      expect(_byTag(tester, 'details'), isNotNull);
      expect(_byTag(tester, 'summary'), isNotNull);
    });

    testComponents('open: true renders the open attribute', (tester) async {
      pumpWithTheme(
        tester,
        const Disclosure(
          title: 'Question',
          open: true,
          content: Text('Answer'),
        ),
      );

      expect(_byTag(tester, 'details').attributes, contains('open'));
    });

    testComponents('open: false renders no open attribute', (tester) async {
      pumpWithTheme(
        tester,
        const Disclosure(title: 'Question', content: Text('Answer')),
      );

      expect(
        _byTag(tester, 'details').attributes ?? const {},
        isNot(contains('open')),
      );
    });

    // The regression this component was filed over: an islanded accordion
    // pre-rendered `hidden` on *every* panel, including the ones told to
    // start expanded, so the answer a reader was meant to see on first
    // paint was invisible until hydration moved it.
    testComponents('never hides the body from the pre-rendered markup', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const Disclosure(
          title: 'Question',
          open: true,
          content: Text('Answer'),
        ),
      );

      expect(_allAttrNames(tester), isNot(contains('hidden')));
      expect(_allAttrNames(tester), isNot(contains('inert')));
    });

    // The chevron has to answer to the browser's own open state, because
    // nothing here re-renders when the reader clicks. A rotation driven
    // from a Dart branch would sit still forever with scripting off.
    testComponents('the chevron rotates from CSS, not from a state branch', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const Disclosure(title: 'Question', content: Text('Answer')),
      );

      final classes = {for (final e in _elements(tester)) ..._classesOf(e)};
      expect(classes, contains('group-open:rotate-180'));
      // `group-open:` only resolves against an ancestor marked `group`.
      expect(_classesOf(_byTag(tester, 'details')), contains('group'));
    });

    // Closed or open, the answer text is in the document — which is why
    // the reporter measured no SEO impact from the islanded version and
    // why the fix must not regress it.
    testComponents('the body is in the markup while closed', (tester) async {
      pumpWithTheme(
        tester,
        const Disclosure(title: 'Question', content: Text('Answer')),
      );

      expect(find.text('Answer'), findsOneComponent);
    });

    // A generated id would differ between the server render and the
    // client, which is the one thing this component must not do. The
    // marker rule is class-scoped so the default path needs no id.
    testComponents('the default path emits no generated id', (tester) async {
      pumpWithTheme(
        tester,
        const Disclosure(title: 'Question', content: Text('Answer')),
      );

      expect(_byTag(tester, 'details').id, isNull);
    });
  });

  group('chrome flows through the style slot', () {
    testComponents('contentInset override reaches the summary padding', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const Disclosure(
          title: 'Question',
          content: Text('Answer'),
          disclosureStyle: CoreDisclosureStyle(
            contentInset: CoreEdgeInsets.all(CoreSpace.space24),
          ),
        ),
      );

      final padding =
          _byTag(tester, 'summary').styles?.properties['padding'] ?? '';
      expect(padding, isNotEmpty);
      expect(
        padding,
        isNot(
          equals(CoreDisclosureStyle.defaultContentInset.toValue()),
        ),
      );
    });

    testComponents('the header falls back to the title string', (tester) async {
      pumpWithTheme(
        tester,
        const Disclosure(title: 'Question', content: Text('Answer')),
      );

      expect(find.text('Question'), findsOneComponent);
    });

    testComponents('a trigger slot wins over the title', (tester) async {
      pumpWithTheme(
        tester,
        const Disclosure(
          title: 'Question',
          trigger: Text('Custom'),
          content: Text('Answer'),
        ),
      );

      expect(find.text('Custom'), findsOneComponent);
      expect(find.text('Question'), findsNothing);
    });
  });

  group('the focus ring', () {
    testComponents('is the browser\'s own until a caller states one', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const Disclosure(title: 'Question', content: Text('Answer')),
      );

      final summary = _byTag(tester, 'summary');
      // Suppressing the UA outline without drawing a replacement would
      // leave keyboard users with no focus indication at all.
      expect(
        _classesOf(summary).any((c) => c.contains('outline-none')),
        isFalse,
      );
      expect(
        _classesOf(summary).any((c) => c.startsWith('focus-visible:')),
        isFalse,
      );
    });

    // The override rides a nested slot's sub-field, so the resolver has to
    // fill the rest of it from the same constant the Flutter side's
    // `Clickable` fills it from. Stating only a colour is the case that
    // catches a resolver which gave up on partials: it renders on Flutter
    // and would vanish here.
    testComponents('a partial ring override still paints a ring', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const Disclosure(
          title: 'Question',
          content: Text('Answer'),
          disclosureStyle: CoreDisclosureStyle(
            clickableStyle: CoreClickableStyle(
              focusOutlineStyle: CoreFocusOutlineStyle(
                borderColor: CoreColor.token(CoreColors.primary),
              ),
            ),
          ),
        ),
      );

      final classes = _classesOf(_byTag(tester, 'summary'));
      // `outline-none` is the ring's resting state, so it is
      // unconditional; focusing moves the colour, width and offset.
      expect(
        classes,
        containsAll(<String>[
          'outline-none',
          'focus-visible:outline-2',
          'focus-visible:outline-offset-2',
          'focus-visible:outline-primary',
        ]),
      );
      expect(classes.any((c) => c.contains('ring-')), isFalse);
    });
  });

  group('DisclosureGroup', () {
    testComponents('stacks each item as its own <details>', (tester) async {
      pumpWithTheme(
        tester,
        const DisclosureGroup(
          items: [
            Disclosure(title: 'First', open: true, content: Text('One')),
            Disclosure(title: 'Second', content: Text('Two')),
          ],
        ),
      );

      final details = _elements(tester).where((e) => e.tag == 'details');
      expect(details, hasLength(2));
      // Independent by construction: opening one cannot close the other
      // because neither one is told about the other.
      expect(details.first.attributes, contains('open'));
      expect(details.last.attributes ?? const {}, isNot(contains('open')));
    });

    // Pins the documented boundary: the group states the stack's spacing
    // and nothing about the sections. `items` is a list of components, so
    // the group cannot know which entries are `Disclosure`s — restyling
    // them would be guessing. Styling every section at once is what
    // `CoreDisclosureTheme.style` is for.
    testComponents('does not restyle the sections it stacks', (tester) async {
      pumpWithTheme(
        tester,
        const DisclosureGroup(
          disclosureStyle: CoreDisclosureStyle(
            contentInset: CoreEdgeInsets.all(CoreSpace.space24),
          ),
          items: [Disclosure(title: 'First', content: Text('One'))],
        ),
      );

      expect(
        _byTag(tester, 'summary').styles?.properties['padding'],
        CoreDisclosureStyle.defaultContentInset.toValue(),
      );
    });

    testComponents('spaces siblings from the resolved itemSpacing', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const DisclosureGroup(
          items: [
            Disclosure(title: 'First', content: Text('One')),
            Disclosure(title: 'Second', content: Text('Two')),
          ],
        ),
      );

      final root = _elements(tester).first;
      expect(root.styles?.properties['gap'], isNotNull);
    });
  });
}
