import 'package:coui_web/coui_web.dart';
import 'package:jaspr/jaspr.dart' as jaspr show Text;
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

/// The legal block the component was built for — five values that mean
/// nothing without their labels.
const _legalEntries = <CoreDefinitionEntry<Component>>[
  CoreDefinitionEntry(term: '사업자등록번호', description: '000-00-00000'),
  CoreDefinitionEntry(term: '법인등록번호', description: '000000-0000000'),
  CoreDefinitionEntry(term: '대표', description: '한동우'),
];

/// The `<dl>`'s direct children, in document order.
List<Component> _dlChildren(ComponentTester tester) {
  final dl = find.tag('dl').evaluate().single.component as DomComponent;
  return dl.children ?? const <Component>[];
}

/// The rendered element with [tag], as a [DomComponent].
DomComponent _elementAt(ComponentTester tester, String tag, {int index = 0}) =>
    find.tag(tag).evaluate().elementAt(index).component as DomComponent;

/// The inline-CSS properties on the element with [tag].
Map<String, String> _styleOf(ComponentTester tester, String tag) =>
    _elementAt(tester, tag).styles?.properties ?? const {};

/// The className of the element with [tag] as a set of classes.
Set<String> _classesOf(ComponentTester tester, String tag, {int index = 0}) =>
    (_elementAt(tester, tag, index: index).classes ?? '')
        .split(' ')
        .where((c) => c.isNotEmpty)
        .toSet();

/// The plain-text content of [component] when it is an element holding a
/// single text node, else `null`.
String? _textOf(Component component) {
  if (component is! DomComponent) return null;
  final children = component.children;
  if (children == null || children.length != 1) return null;
  final only = children.single;
  return only is jaspr.Text ? only.text : null;
}

void main() {
  group('the pairing lives in the document, not in the layout', () {
    // What this locks: the consumer site emitted this exact block as five
    // bare `<p>` lines. A screen reader then reads "000-00-00000" with
    // nothing attached to it — the listener hears the digits but cannot
    // tell which registry to look them up in, and the number is one a
    // reviewer is expected to check against the tax office. `<dl>` is the
    // element that states "this value answers that term", and these tests
    // read it back off the DOM because a component that merely *accepts*
    // term/description pairs and renders two styled divs looks identical
    // at the call site and fixes nothing.
    testComponents('the root is a <dl>', (tester) async {
      pumpWithTheme(tester, const DefinitionList(items: _legalEntries));

      expect(find.tag('dl'), findsOneComponent);
    });

    testComponents('every entry renders a <dt> and a <dd>', (tester) async {
      pumpWithTheme(tester, const DefinitionList(items: _legalEntries));

      expect(find.tag('dt').evaluate().length, _legalEntries.length);
      expect(find.tag('dd').evaluate().length, _legalEntries.length);
    });

    testComponents('the <dl> has no children but <dt> and <dd>', (
      tester,
    ) async {
      // A `<div>` between the list and its pairs is legal HTML, and it is
      // also the first thing anyone reaches for when a layout needs a
      // per-row box. Several screen readers stop reporting the list
      // structure once the pairs are not direct children — and those
      // readers are the entire reason this component exists, so the
      // wrapper is refused rather than made optional.
      pumpWithTheme(
        tester,
        const DefinitionList(
          items: _legalEntries,
          layout: CoreDefinitionLayout.columns,
        ),
      );

      final tags = _dlChildren(
        tester,
      ).whereType<DomComponent>().map((e) => e.tag).toSet();
      expect(tags, {'dt', 'dd'});
      expect(_dlChildren(tester).length, _legalEntries.length * 2);
    });

    testComponents('each <dd> follows the <dt> it answers', (tester) async {
      // Order is the pairing. `<dl>` carries no explicit link between a
      // term and its value — the value is the `<dd>` that comes next — so
      // a build that emitted all the terms and then all the values would
      // still render three `<dt>`s and three `<dd>`s and be wrong for
      // every reader.
      pumpWithTheme(tester, const DefinitionList(items: _legalEntries));

      final children = _dlChildren(tester);
      final pairs = <(String?, String?)>[];
      for (var index = 0; index < children.length; index += 2) {
        pairs.add((_textOf(children[index]), _textOf(children[index + 1])));
      }

      expect(pairs, [
        ('사업자등록번호', '000-00-00000'),
        ('법인등록번호', '000000-0000000'),
        ('대표', '한동우'),
      ]);
      for (var index = 0; index < children.length; index += 2) {
        expect((children[index] as DomComponent).tag, 'dt');
        expect((children[index + 1] as DomComponent).tag, 'dd');
      }
    });

    testComponents('a component description renders inside its <dd>', (
      tester,
    ) async {
      // The value is not always one run of text — an email is a link, and
      // a link that had to live outside the `<dd>` would break the pairing
      // the component is for.
      pumpWithTheme(
        tester,
        DefinitionList(
          items: [
            const CoreDefinitionEntry(term: '대표', description: '한동우'),
            CoreDefinitionEntry.rich(
              term: '이메일',
              description: Link(
                href: 'mailto:cody@cocode.im',
                child: Component.text('cody@cocode.im'),
              ),
            ),
          ],
        ),
      );

      expect(
        find.descendant(of: find.tag('dd'), matching: find.tag('a')),
        findsOneComponent,
      );
    });

    testComponents('an empty list still renders a valid <dl>', (tester) async {
      pumpWithTheme(
        tester,
        const DefinitionList(items: <CoreDefinitionEntry<Component>>[]),
      );

      expect(find.tag('dl'), findsOneComponent);
      expect(find.tag('dt'), findsNothing);
      expect(_dlChildren(tester), isEmpty);
    });
  });

  group('the browser indent is neutralised, on every layout', () {
    // What this locks: every browser ships `dd { margin-inline-start:
    // 40px }`, and it survives grid and flex. In `columns` that pushes
    // each value 40px off the column edge the layout exists to line up —
    // and the site's Tailwind build runs with `preflight: false`, so no
    // reset is coming from underneath. A component library cannot render
    // differently depending on whether the host page happens to ship a
    // reset.
    for (final layout in CoreDefinitionLayout.values) {
      testComponents('${layout.name} zeroes the <dd> UA indent', (
        tester,
      ) async {
        pumpWithTheme(
          tester,
          DefinitionList(items: _legalEntries, layout: layout),
        );

        final classes = _classesOf(tester, 'dd');
        final inline = _styleOf(tester, 'dd');
        final statesInlineStart =
            classes.any((c) => c.startsWith('ms-')) ||
            inline.containsKey('margin-inline-start');

        expect(
          statesInlineStart,
          isTrue,
          reason: '${layout.name} leaves the 40px UA indent in place',
        );
        // Exactly one statement — two `ms-*` classes on one element race
        // on stylesheet order rather than one overriding the other.
        expect(classes.where((c) => c.startsWith('ms-')).length, lessThan(2));
      });
    }

    testComponents('and the <dl> drops its UA block margin', (tester) async {
      pumpWithTheme(tester, const DefinitionList(items: _legalEntries));

      expect(_classesOf(tester, 'dl'), contains('m-0'));
    });
  });

  group('each layout maps the two gaps onto its own axes', () {
    testComponents('columns is a two-track grid', (tester) async {
      pumpWithTheme(
        tester,
        const DefinitionList(
          items: _legalEntries,
          layout: CoreDefinitionLayout.columns,
        ),
      );
      final classes = _classesOf(tester, 'dl');

      expect(classes, contains('grid'));
      // `max-content` for the terms so every value starts at one edge;
      // stated inline because no Tailwind class expresses this pair.
      expect(
        _styleOf(tester, 'dl')['grid-template-columns'],
        'max-content 1fr',
      );
      // The container carries both distances, so neither `<dt>` nor
      // `<dd>` needs a margin.
      expect(classes, contains('gap-y-space24'));
      expect(classes, contains('gap-x-space8'));
    });

    testComponents('stacked is a flex column, not block flow', (tester) async {
      // Block children collapse adjacent vertical margins, which would
      // silently turn the distance between two pairs into
      // `max(entrySpacing, pairSpacing)` instead of `entrySpacing`. Flex items do not
      // collapse.
      pumpWithTheme(
        tester,
        const DefinitionList(
          items: _legalEntries,
          layout: CoreDefinitionLayout.stacked,
        ),
      );

      expect(_classesOf(tester, 'dl'), containsAll(['flex', 'flex-col']));
      expect(_classesOf(tester, 'dd'), contains('mt-space2'));
    });

    testComponents('inline wraps and aligns on the baseline', (tester) async {
      pumpWithTheme(
        tester,
        const DefinitionList(
          items: _legalEntries,
          layout: CoreDefinitionLayout.inline,
        ),
      );

      expect(
        _classesOf(tester, 'dl'),
        containsAll(['flex', 'flex-wrap', 'items-baseline']),
      );
      // The term-to-value gap rides the logical inline axis, so it flips
      // with reading direction instead of stranding the value on one side.
      expect(_classesOf(tester, 'dd'), contains('ms-space8'));
      // Pairs run 16 apart on that axis, and wrapped lines 16 apart.
      expect(_classesOf(tester, 'dt', index: 1), contains('ms-space16'));
      expect(_classesOf(tester, 'dl'), contains('gap-y-space16'));
    });

    testComponents('columns fixes the term track only when termWidth says so', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const DefinitionList(
          items: _legalEntries,
          layout: CoreDefinitionLayout.columns,
          definitionListStyle: CoreDefinitionListStyle(termWidth: 90),
        ),
      );

      // 90px as rem against the 16px root — a measure, not a gap, so it
      // is a literal rather than a spacing variable.
      expect(
        _styleOf(tester, 'dl')['grid-template-columns'],
        '${90 / 16}rem 1fr',
      );
    });

    for (final layout in [
      CoreDefinitionLayout.stacked,
      CoreDefinitionLayout.inline,
    ]) {
      testComponents('${layout.name} ignores termWidth', (tester) async {
        pumpWithTheme(
          tester,
          DefinitionList(
            items: _legalEntries,
            layout: layout,
            definitionListStyle: const CoreDefinitionListStyle(termWidth: 90),
          ),
        );

        expect(
          _styleOf(tester, 'dl'),
          isNot(contains('grid-template-columns')),
        );
        expect(_classesOf(tester, 'dl'), isNot(contains('grid')));
      });
    }

    testComponents('the first term carries no leading entry gap', (
      tester,
    ) async {
      // The gap that separates one pair from the next rides the `<dt>`
      // that opens the pair. Put it on every `<dt>` and the list opens
      // with a blank strip nobody asked for.
      pumpWithTheme(
        tester,
        const DefinitionList(
          items: _legalEntries,
          layout: CoreDefinitionLayout.stacked,
        ),
      );

      expect(_classesOf(tester, 'dt'), isNot(contains('mt-space14')));
      expect(_classesOf(tester, 'dt', index: 1), contains('mt-space14'));
      expect(_classesOf(tester, 'dt', index: 2), contains('mt-space14'));
    });
  });

  group('a numeric list gets fixed-width figures', () {
    testComponents('numeric puts tabular-nums on the values', (tester) async {
      pumpWithTheme(
        tester,
        const DefinitionList(
          items: _legalEntries,
          layout: CoreDefinitionLayout.columns,
          numeric: true,
        ),
      );

      expect(_classesOf(tester, 'dd'), contains('tabular-nums'));
      // The label is prose, not a figure — proportional digits read
      // better there and the terms are not what has to line up.
      expect(_classesOf(tester, 'dt'), isNot(contains('tabular-nums')));
    });

    testComponents('and a default list does not', (tester) async {
      pumpWithTheme(tester, const DefinitionList(items: _legalEntries));

      expect(_classesOf(tester, 'dd'), isNot(contains('tabular-nums')));
    });
  });

  group('term and value are told apart by more than colour', () {
    testComponents('stacked sets the term one role below the value', (
      tester,
    ) async {
      // A stacked term is a caption over its value: `label-small` (12)
      // against `label-medium` (13), so the hierarchy survives a
      // monochrome render, a forced-colours mode and a reader who cannot
      // distinguish the muted foreground (WCAG 1.4.1).
      pumpWithTheme(tester, const DefinitionList(items: _legalEntries));

      expect(_classesOf(tester, 'dt'), contains('text-label-small'));
      expect(_classesOf(tester, 'dd'), contains('text-label-medium'));
    });

    for (final layout in [
      CoreDefinitionLayout.columns,
      CoreDefinitionLayout.inline,
    ]) {
      testComponents('${layout.name} sets both on label-medium', (
        tester,
      ) async {
        // Beside each other the two share one 13px / 500 role; the column
        // or the order carries the pairing and the muted term colour
        // reinforces it.
        pumpWithTheme(
          tester,
          DefinitionList(items: _legalEntries, layout: layout),
        );

        expect(_classesOf(tester, 'dt'), contains('text-label-medium'));
        expect(_classesOf(tester, 'dd'), contains('text-label-medium'));
        expect(_classesOf(tester, 'dt'), isNot(contains('text-label-small')));
        expect(
          _classesOf(tester, 'dt'),
          contains('text-on-surface-subtle'),
        );
        expect(_classesOf(tester, 'dd'), contains('text-on-surface'));
      });
    }

    testComponents('and the colours ride classes, so dark mode reacts', (
      tester,
    ) async {
      pumpWithTheme(tester, const DefinitionList(items: _legalEntries));

      expect(_classesOf(tester, 'dt'), contains('text-on-surface-subtle'));
      expect(_classesOf(tester, 'dd'), contains('text-on-surface'));
      // Token defaults that went inline would be unbeatable from a
      // stylesheet — the defect Card and Badge were caught with.
      expect(_styleOf(tester, 'dt'), isEmpty);
    });
  });

  group('mono sets the value in the code role', () {
    for (final layout in CoreDefinitionLayout.values) {
      testComponents('${layout.name} swaps label-medium for code-sm', (
        tester,
      ) async {
        pumpWithTheme(
          tester,
          DefinitionList(items: _legalEntries, layout: layout, mono: true),
        );

        final value = _classesOf(tester, 'dd');
        expect(value, contains('text-code-sm'));
        expect(value, contains('text-on-surface'));
        expect(value, isNot(contains('text-label-medium')));
        // The term keeps the layout's own role.
        expect(
          _classesOf(tester, 'dt'),
          contains(
            layout == CoreDefinitionLayout.stacked
                ? 'text-label-small'
                : 'text-label-medium',
          ),
        );
      });
    }

    testComponents('a mono override reaches only a mono list', (tester) async {
      const style = CoreDefinitionListStyle(
        monoDescriptionTextStyle: CoreTextStyle(
          fontWeight: CoreFontWeight.bold,
        ),
      );
      pumpWithTheme(
        tester,
        const DefinitionList(items: _legalEntries, definitionListStyle: style),
      );
      expect(_styleOf(tester, 'dd'), isNot(contains('font-weight')));

      pumpWithTheme(
        tester,
        const DefinitionList(
          items: _legalEntries,
          mono: true,
          definitionListStyle: style,
        ),
      );
      expect(_classesOf(tester, 'dd'), contains('text-code-sm'));
      expect(_styleOf(tester, 'dd')['font-weight'], '${CoreFontWeight.bold}');
    });

    testComponents('a default list is not mono', (tester) async {
      pumpWithTheme(tester, const DefinitionList(items: _legalEntries));

      expect(_classesOf(tester, 'dd'), isNot(contains('text-code-sm')));
    });

    testComponents('mono and numeric combine', (tester) async {
      pumpWithTheme(
        tester,
        const DefinitionList(items: _legalEntries, mono: true, numeric: true),
      );

      expect(
        _classesOf(tester, 'dd'),
        containsAll(['text-code-sm', 'tabular-nums']),
      );
    });

    testComponents('a typographic override layers over the code role', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const DefinitionList(
          items: _legalEntries,
          mono: true,
          definitionListStyle: CoreDefinitionListStyle(
            descriptionTextStyle: CoreTextStyle(
              fontWeight: CoreFontWeight.bold,
            ),
          ),
        ),
      );

      expect(_classesOf(tester, 'dd'), contains('text-code-sm'));
      expect(_styleOf(tester, 'dd')['font-weight'], '${CoreFontWeight.bold}');
    });
  });

  group('a definitionListStyle override reaches the rendered element', () {
    // Declaring the slot is not implementing it. These read the value
    // back off the DOM, because a slot that is accepted, merged and then
    // never emitted looks complete from the call site and changes
    // nothing on screen.
    testComponents('a wider entry gap', (tester) async {
      pumpWithTheme(
        tester,
        const DefinitionList(
          items: _legalEntries,
          layout: CoreDefinitionLayout.stacked,
          definitionListStyle: CoreDefinitionListStyle(
            entrySpacing: CoreSpace.space24,
          ),
        ),
      );

      // An override is off the class path by construction (the emit
      // family decides by "did the caller override", never by
      // reverse-deriving a scale key from a px value), so it lands
      // inline — and inline beats the class it replaces.
      expect(_styleOf(tester, 'dt')['margin-top'], isNull);
      expect(
        _elementAt(tester, 'dt', index: 1).styles?.properties['margin-top'],
        'var(--coui-space-24)',
      );
      expect(_classesOf(tester, 'dt', index: 1), isNot(contains('mt-space14')));
    });

    testComponents('a tighter pair gap in columns', (tester) async {
      pumpWithTheme(
        tester,
        const DefinitionList(
          items: _legalEntries,
          layout: CoreDefinitionLayout.columns,
          definitionListStyle: CoreDefinitionListStyle(
            pairSpacing: CoreSpace.space4,
          ),
        ),
      );

      expect(_styleOf(tester, 'dl')['column-gap'], 'var(--coui-space-4)');
      expect(_classesOf(tester, 'dl'), isNot(contains('gap-x-space8')));
    });

    testComponents('a bolder term keeps the default role and colour', (
      tester,
    ) async {
      // A caller who states one typographic field is layering, not
      // replacing — losing the role here would drop the term back to the
      // inherited size and quietly undo the size-based hierarchy above.
      pumpWithTheme(
        tester,
        const DefinitionList(
          items: _legalEntries,
          definitionListStyle: CoreDefinitionListStyle(
            termTextStyle: CoreTextStyle(fontWeight: CoreFontWeight.bold),
          ),
        ),
      );

      expect(_styleOf(tester, 'dt')['font-weight'], '${CoreFontWeight.bold}');
      expect(_classesOf(tester, 'dt'), contains('text-label-small'));
      expect(_classesOf(tester, 'dt'), contains('text-on-surface-subtle'));
    });

    testComponents('and withStyle merges rather than replaces', (tester) async {
      pumpWithTheme(
        tester,
        const DefinitionList(
              items: _legalEntries,
              layout: CoreDefinitionLayout.columns,
            )
            .withStyle(
              const CoreDefinitionListStyle(entrySpacing: CoreSpace.space24),
            )
            .withStyle(
              const CoreDefinitionListStyle(pairSpacing: CoreSpace.space4),
            ),
      );
      final style = _styleOf(tester, 'dl');

      expect(style['row-gap'], 'var(--coui-space-24)');
      expect(style['column-gap'], 'var(--coui-space-4)');
    });
  });

  group('the caller can still chrome the root', () {
    // What this locks: Chip and Avatar shipped without `attributes` /
    // `eventHandlers` on the constructor, so a caller could style them
    // but could not hang a test id, a `data-*` hook or an `aria-*` on
    // them. The passthrough is part of the base — leaving it off the
    // constructor is what silently drops it.
    testComponents('id, classes, css, attributes and handlers all land', (
      tester,
    ) async {
      var clicks = 0;
      pumpWithTheme(
        tester,
        DefinitionList(
          items: _legalEntries,
          id: 'legal',
          classes: 'prose',
          css: const Styles(raw: {'max-width': '40rem'}),
          attributes: const {'data-testid': 'legal-block'},
          eventHandlers: {
            'click': [(_) => clicks++],
          },
        ),
      );
      final dl = _elementAt(tester, 'dl');

      expect(dl.id, 'legal');
      expect(_classesOf(tester, 'dl'), contains('prose'));
      expect(dl.styles?.properties['max-width'], '40rem');
      expect(dl.attributes?['data-testid'], 'legal-block');
      expect(dl.events?.containsKey('click'), isTrue);
    });

    testComponents('copyWith keeps the items and the layout', (tester) async {
      const original = DefinitionList(
        items: _legalEntries,
        layout: CoreDefinitionLayout.columns,
        numeric: true,
        mono: true,
      );
      final copy = original.copyWith(id: 'legal');

      expect(copy.items, same(original.items));
      expect(copy.layout, CoreDefinitionLayout.columns);
      expect(copy.numeric, isTrue);
      expect(copy.mono, isTrue);
      expect(original.copyWith(mono: false).mono, isFalse);
      expect(copy.id, 'legal');
    });
  });

  group('an entry states exactly one description', () {
    test('the string constructor fills only the text slot', () {
      const entry = CoreDefinitionEntry<Component>(
        term: '대표',
        description: '한동우',
      );

      expect(entry.descriptionText, '한동우');
      expect(entry.description, isNull);
    });

    test('and the rich constructor fills only the component slot', () {
      final entry = CoreDefinitionEntry<Component>.rich(
        term: '이메일',
        description: Component.text('cody@cocode.im'),
      );

      expect(entry.description, isNotNull);
      expect(entry.descriptionText, isNull);
    });
  });
}
