import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

/// The root `<span>` — the outermost DOM element the component owns.
///
/// The label and the marker dot are also `<span>`s, so every read here
/// goes through the first one deliberately: the outline lives on the
/// root and nowhere else.
DomComponent _root(ComponentTester tester) =>
    find.tag('span').evaluate().first.component as DomComponent;

/// The root's Tailwind classes, split for exact membership checks —
/// `contains` on the raw string would let `border-dashed` satisfy a
/// probe for `border-dash`.
Set<String> _rootClasses(ComponentTester tester) =>
    (_root(tester).classes ?? '').split(' ').where((c) => c.isNotEmpty).toSet();

/// The root's inline-CSS properties.
Map<String, String> _rootStyles(ComponentTester tester) =>
    _root(tester).styles?.properties ?? const {};

/// Every class on every element in the rendered tree.
Set<String> _allClasses(ComponentTester tester) => {
  for (final e in find.byType(DomComponent).evaluate())
    ...?(e.component as DomComponent).classes?.split(' '),
}..remove('');

/// Every attribute on every element in the rendered tree.
Map<String, String> _allAttrs(ComponentTester tester) => {
  for (final e in find.byType(DomComponent).evaluate())
    ...?(e.component as DomComponent).attributes,
};

void main() {
  group('the three kinds are told apart by shape, not only by colour', () {
    // This is the group the component exists for. A colour-blind reader
    // and — more concretely — the 실사 담당자 who prints the evidence
    // pack to black-and-white PDF both lose every colour distinction.
    // If these three assertions collapse to the same class set, the
    // badge is stating its meaning in colour alone (WCAG 1.4.1).

    testComponents('open draws a solid outline', (tester) async {
      pumpWithTheme(
        tester,
        const DisclosureBadge(kind: CoreDisclosureKind.open, label: '공개'),
      );

      expect(_rootClasses(tester), contains('border-solid'));
      expect(_rootClasses(tester), isNot(contains('border-dashed')));
    });

    testComponents('private draws a dashed outline', (tester) async {
      pumpWithTheme(
        tester,
        const DisclosureBadge(
          kind: CoreDisclosureKind.private,
          label: '비공개 · NDA',
        ),
      );

      expect(_rootClasses(tester), contains('border-dashed'));
      expect(_rootClasses(tester), isNot(contains('border-solid')));
    });

    testComponents('open and private do not render the same outline', (
      tester,
    ) async {
      // Stated as a direct comparison as well as the two membership
      // checks above, because the way this regresses is someone dropping
      // the stroke switch and leaving both kinds on whatever the default
      // border class happens to be — at which point both assertions
      // above could still be rewritten to pass while the printed page
      // shows two identical rectangles.
      pumpWithTheme(
        tester,
        const DisclosureBadge(kind: CoreDisclosureKind.open, label: '공개'),
      );
      final openStroke = _rootClasses(
        tester,
      ).where((c) => c.startsWith('border-')).toSet();

      pumpWithTheme(
        tester,
        const DisclosureBadge(
          kind: CoreDisclosureKind.private,
          label: '비공개',
        ),
      );
      final privateStroke = _rootClasses(
        tester,
      ).where((c) => c.startsWith('border-')).toSet();

      expect(openStroke, isNot(privateStroke));
    });

    testComponents('commitment shares the solid outline but adds a dot', (
      tester,
    ) async {
      // `commitment` and `open` are both solid, so the stroke alone
      // cannot separate them — the marker dot is the second non-colour
      // signal, and it has to be a real element, not a `::before` a
      // print stylesheet may drop.
      pumpWithTheme(
        tester,
        const DisclosureBadge(
          kind: CoreDisclosureKind.commitment,
          label: '계약 시 제공',
        ),
      );

      expect(_rootClasses(tester), contains('border-solid'));
      expect(find.tag('span').evaluate().length, greaterThan(2));
      expect(_allAttrs(tester)['aria-hidden'], 'true');
    });

    testComponents('and the kinds that are not deferred have no dot', (
      tester,
    ) async {
      for (final kind in [
        CoreDisclosureKind.open,
        CoreDisclosureKind.private,
      ]) {
        pumpWithTheme(tester, DisclosureBadge(kind: kind, label: '상태'));

        expect(
          _allAttrs(tester).containsKey('aria-hidden'),
          isFalse,
          reason: '${kind.name} rendered a marker it should not have',
        );
      }
    });

    test('the shape lives on the kind, out of a theme\'s reach', () {
      // The enforcement, stated where it actually lives. A project theme
      // can retune every colour on this badge; there is no slot through
      // which it can make all three kinds solid and undotted.
      expect(CoreDisclosureKind.open.stroke, CoreDisclosureStroke.solid);
      expect(CoreDisclosureKind.commitment.stroke, CoreDisclosureStroke.solid);
      expect(CoreDisclosureKind.private.stroke, CoreDisclosureStroke.dashed);

      expect(CoreDisclosureKind.open.hasMarker, isFalse);
      expect(CoreDisclosureKind.commitment.hasMarker, isTrue);
      expect(CoreDisclosureKind.private.hasMarker, isFalse);

      // Every kind is distinguishable from every other kind by shape
      // alone — the property the three cases above each check one slice
      // of. Written as a pairwise sweep so adding a fourth kind that
      // reuses an existing (stroke, marker) pair fails here rather than
      // shipping two states that print identically.
      final shapes = {
        for (final kind in CoreDisclosureKind.values)
          (kind.stroke, kind.hasMarker),
      };
      expect(shapes.length, CoreDisclosureKind.values.length);
    });
  });

  group('the state is written down, not implied', () {
    testComponents('the label reaches the DOM as text', (tester) async {
      pumpWithTheme(
        tester,
        const DisclosureBadge(
          kind: CoreDisclosureKind.private,
          label: '비공개 · NDA',
        ),
      );

      expect(find.text('비공개 · NDA'), findsOneComponent);
    });

    testComponents('every kind renders its own words', (tester) async {
      // The failure this blocks is a resolver that renders chrome and
      // forgets the content slot for one branch — the `commitment`
      // branch is the one with an extra child, so it is the one where a
      // dropped label is easiest to miss.
      const labels = {
        CoreDisclosureKind.open: '지금 열람',
        CoreDisclosureKind.commitment: '계약 시 제공',
        CoreDisclosureKind.private: '비공개 · NDA',
      };

      for (final entry in labels.entries) {
        pumpWithTheme(
          tester,
          DisclosureBadge(kind: entry.key, label: entry.value),
        );

        expect(find.text(entry.value), findsOneComponent);
      }
    });

    test('an empty label is rejected at construction', () {
      // `required` alone still admits `label: ''`, and an outline with
      // nothing in it states its meaning through colour and border style
      // alone — exactly what this component exists to prevent.
      expect(
        () => DisclosureBadge(
          kind: CoreDisclosureKind.private,
          label: '',
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('it does not dress up as a control', () {
    testComponents('no fill', (tester) async {
      // A `Chip` reads as pressable because it is filled. This badge is
      // never pressable, so it carries no background on either surface —
      // not a `bg-*` utility and not an inline `background-color`.
      for (final kind in CoreDisclosureKind.values) {
        pumpWithTheme(tester, DisclosureBadge(kind: kind, label: '상태'));

        expect(
          _rootClasses(tester).where((c) => c.startsWith('bg-')),
          isEmpty,
          reason: '${kind.name} filled itself with a bg-* utility',
        );
        expect(_rootStyles(tester).containsKey('background-color'), isFalse);
      }
    });

    testComponents('no pointer feedback', (tester) async {
      pumpWithTheme(
        tester,
        const DisclosureBadge(kind: CoreDisclosureKind.open, label: '공개'),
      );
      final classes = _allClasses(tester);

      expect(classes.where((c) => c.startsWith('hover:')), isEmpty);
      expect(classes.where((c) => c.startsWith('active:')), isEmpty);
      expect(classes.where((c) => c.startsWith('focus:')), isEmpty);
      expect(classes.where((c) => c.startsWith('transition')), isEmpty);
      expect(classes, isNot(contains('cursor-pointer')));
    });

    testComponents('and does not announce itself as one', (tester) async {
      pumpWithTheme(
        tester,
        const DisclosureBadge(kind: CoreDisclosureKind.open, label: '공개'),
      );
      final attrs = _allAttrs(tester);

      expect(attrs.containsKey('role'), isFalse);
      expect(attrs.containsKey('tabindex'), isFalse);
      expect(_root(tester).events, anyOf(isNull, isEmpty));
    });
  });

  group('private is not painted in the colour of what opens', () {
    testComponents('it uses on-surface-variant over outline', (tester) async {
      pumpWithTheme(
        tester,
        const DisclosureBadge(
          kind: CoreDisclosureKind.private,
          label: '비공개',
        ),
      );

      expect(_rootClasses(tester), contains('text-on-surface-variant'));
      expect(_rootClasses(tester), contains('border-outline'));
    });

    testComponents('and never borrows a primary-family token', (tester) async {
      // The lie this blocks: a reader who has learned that primary means
      // "this opens" clicks the badge and gets nothing. `open` is the one
      // kind that resolves to a link, so it is the one kind that may
      // wear primary.
      pumpWithTheme(
        tester,
        const DisclosureBadge(
          kind: CoreDisclosureKind.private,
          label: '비공개',
        ),
      );

      expect(
        _allClasses(tester).where((c) => c.contains('primary')),
        isEmpty,
      );
    });

    testComponents('while open does wear it', (tester) async {
      // The positive control — without it, a resolver that emitted no
      // colour classes at all would pass the assertion above.
      pumpWithTheme(
        tester,
        const DisclosureBadge(kind: CoreDisclosureKind.open, label: '공개'),
      );

      expect(_rootClasses(tester), contains('text-primary'));
      expect(_rootClasses(tester), contains('border-primary'));
    });
  });

  group('colour rides classes, box chrome rides inline', () {
    testComponents(
      'typography and colour are classes; radius and padding are inline',
      (
        tester,
      ) async {
        // This split is a repo rule, not a preference —
        // `scripts/guards/resolver/check_web_resolver.sh` RULE F enforces it:
        // chrome (radius / padding / gap / size) must be inline
        // `.toValue()` / rem, and Tailwind chrome classes (`rounded-*`,
        // `p-*`, …) are rejected. Colour and typography go the other way:
        // token default on a class, caller override inline.
        //
        // Reading Card and Badge's inline radius as a *defect* gets this
        // exactly backwards. The guard is the source of truth.
        pumpWithTheme(
          tester,
          const DisclosureBadge(kind: CoreDisclosureKind.open, label: '공개'),
        );
        final classes = _rootClasses(tester);
        final styles = _rootStyles(tester);

        expect(classes, contains('text-label-small'));
        expect(classes.any((c) => c.startsWith('rounded-')), isFalse);
        expect(
          classes.any((c) => c.startsWith('p-') || c.startsWith('pl-')),
          isFalse,
        );

        expect(styles.containsKey('color'), isFalse);
        expect(styles.containsKey('border-color'), isFalse);
        expect(styles.containsKey('border-radius'), isTrue);
        expect(styles.containsKey('padding'), isTrue);
        // Stroke width has no Tailwind emitter in this repo, so it rides
        // inline — but through the `--coui-stroke-width-N` variable, which
        // a designer override still reaches.
        expect(styles['border-width'], 'var(--coui-stroke-width-1)');
      },
    );

    testComponents('a caller override moves inline and wins', (tester) async {
      pumpWithTheme(
        tester,
        const DisclosureBadge(
          kind: CoreDisclosureKind.open,
          label: '공개',
          disclosureBadgeStyle: CoreDisclosureBadgeStyle(
            borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
            padding: CoreEdgeInsets.all(CoreSpace.space8),
          ),
        ),
      );
      final styles = _rootStyles(tester);

      expect(
        styles['border-radius'],
        'var(--coui-radius-8) var(--coui-radius-8)'
        ' var(--coui-radius-8) var(--coui-radius-8)',
      );
      expect(
        styles['padding'],
        'var(--coui-space-8) var(--coui-space-8) '
        'var(--coui-space-8) var(--coui-space-8)',
      );
      expect(_rootClasses(tester), isNot(contains('rounded-tl-radius4')));
      expect(_rootClasses(tester), isNot(contains('pl-space6')));
    });

    testComponents('a token colour override stays on a class', (tester) async {
      // Token overrides keep riding classes so dark mode keeps reacting.
      pumpWithTheme(
        tester,
        const DisclosureBadge(
          kind: CoreDisclosureKind.private,
          label: '비공개',
          disclosureBadgeStyle: CoreDisclosureBadgeStyle(
            foregroundColor: CoreColor.token(CoreColors.error),
          ),
        ),
      );

      expect(_rootClasses(tester), contains('text-error'));
      expect(_rootStyles(tester).containsKey('color'), isFalse);
    });
  });

  group('the caller can reach the root', () {
    // Chip and Avatar shipped without `attributes` / `eventHandlers`, so
    // a caller could style them but could not hang a test id or a
    // `data-*` hook on them. Locked here rather than left to review.
    testComponents('id, classes, css, attributes all pass through', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        DisclosureBadge(
          kind: CoreDisclosureKind.open,
          label: '공개',
          id: 'proof-1',
          classes: 'ml-2',
          css: const Styles(raw: {'opacity': '0.5'}),
          attributes: const {'data-testid': 'disclosure'},
        ),
      );
      final root = _root(tester);

      expect(root.id, 'proof-1');
      expect(_rootClasses(tester), contains('ml-2'));
      // The component's own chrome survives the caller's classes.
      expect(_rootClasses(tester), contains('border-solid'));
      expect(_rootStyles(tester)['opacity'], '0.5');
      expect(root.attributes?['data-testid'], 'disclosure');
    });

    testComponents('and copyWith keeps the kind and the label', (tester) async {
      const original = DisclosureBadge(
        kind: CoreDisclosureKind.private,
        label: '비공개',
      );
      final rechromed = original.copyWith(id: 'x');

      pumpWithTheme(tester, rechromed);

      expect(rechromed.kind, CoreDisclosureKind.private);
      expect(find.text('비공개'), findsOneComponent);
      expect(_rootClasses(tester), contains('border-dashed'));
    });

    testComponents('withStyle merges rather than replaces', (tester) async {
      const badge = DisclosureBadge(
        kind: CoreDisclosureKind.open,
        label: '공개',
        disclosureBadgeStyle: CoreDisclosureBadgeStyle(
          borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
        ),
      );

      pumpWithTheme(
        tester,
        badge.withStyle(
          const CoreDisclosureBadgeStyle(
            padding: CoreEdgeInsets.all(CoreSpace.space8),
          ),
        ),
      );
      final styles = _rootStyles(tester);

      expect(
        styles['border-radius'],
        'var(--coui-radius-8) var(--coui-radius-8)'
        ' var(--coui-radius-8) var(--coui-radius-8)',
      );
      expect(
        styles['padding'],
        'var(--coui-space-8) var(--coui-space-8) '
        'var(--coui-space-8) var(--coui-space-8)',
      );
    });
  });

  group('a project theme retunes colour but cannot erase the distinction', () {
    testComponents('kindStyles reaches the rendered element', (tester) async {
      tester.pumpComponent(
        const Theme(
          data: ThemeData(
            coreComponentTheme: CoreComponentTheme(
              disclosureBadge: CoreDisclosureBadgeTheme(
                kindStyles: {
                  CoreDisclosureKind.private: CoreDisclosureBadgeStyle(
                    foregroundColor: CoreColor.token(CoreColors.error),
                  ),
                },
              ),
            ),
          ),
          child: DisclosureBadge(
            kind: CoreDisclosureKind.private,
            label: '비공개',
          ),
        ),
      );

      expect(_rootClasses(tester), contains('text-error'));
      // …and the dashed outline is still dashed. Colour is the theme's
      // to change; shape is not.
      expect(_rootClasses(tester), contains('border-dashed'));
    });
  });
}
