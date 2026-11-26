import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

const _kTerm = '사업자등록번호';
const _kValue = '000-00-00000';
const _kSecondTerm = '대표';
const _kSecondValue = '한동우';

const _kEntries = <CoreDefinitionEntry<Widget>>[
  CoreDefinitionEntry(term: _kTerm, description: _kValue),
  CoreDefinitionEntry(term: _kSecondTerm, description: _kSecondValue),
];

const _kOverrideEntrySpacing = 31.0;
const _kOverridePairSpacing = 3.0;

Widget _app(Widget child) => material.MaterialApp(
  home: Theme(
    data: const ThemeData(),
    child: material.Scaffold(
      body: Align(child: SizedBox(width: 400, child: child)),
    ),
  ),
);

/// Every semantics node in the pumped tree, flattened.
List<SemanticsData> _allNodes(WidgetTester tester) {
  final result = <SemanticsData>[];
  void visit(SemanticsNode node) {
    result.add(node.getSemanticsData());
    node.visitChildren((child) {
      visit(child);
      return true;
    });
  }

  visit(tester.binding.pipelineOwner.semanticsOwner!.rootSemanticsNode!);
  return result;
}

/// Resolves a [ResolvedDefinitionList] inside a real element tree, so
/// `Theme.of(context)` / the typography scheme run against a live theme.
Future<ResolvedDefinitionList> _resolve(
  WidgetTester tester, {
  CoreDefinitionLayout layout = CoreDefinitionLayout.stacked,
  bool numeric = false,
  bool mono = false,
  CoreDefinitionListStyle? definitionListStyle,
  CoreDefinitionListTheme? componentTheme,
}) async {
  late ResolvedDefinitionList resolved;
  await tester.pumpWidget(
    material.MaterialApp(
      home: Theme(
        data: ThemeData(
          coreComponentTheme: CoreComponentTheme(
            definitionList: componentTheme,
          ),
        ),
        child: Builder(
          builder: (context) {
            resolved = resolveDefinitionList(
              context,
              layout: layout,
              numeric: numeric,
              mono: mono,
              definitionListStyle: definitionListStyle,
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    ),
  );
  return resolved;
}

void main() {
  // ═══════════════════════════════════════════════
  // Semantics — the reason the component exists
  // ═══════════════════════════════════════════════

  group('a value is announced with the term that names it', () {
    for (final layout in CoreDefinitionLayout.values) {
      testWidgets('${layout.name} pairs term and value on one node', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(
          _app(DefinitionList(items: _kEntries, layout: layout)),
        );

        final paired = _allNodes(
          tester,
        ).where((data) => data.label == _kTerm).toList();

        expect(
          paired,
          hasLength(1),
          reason:
              'The term must reach a reader exactly once — as the name of '
              'the node carrying its value. Twice means the <dt> was left '
              'announcing itself as well; zero means the digits are read '
              'with nothing to attach them to, which is the failure this '
              'component exists to prevent.',
        );
        expect(paired.single.value, _kValue);

        handle.dispose();
      });
    }

    testWidgets('the layout does not change what is announced', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final announced = <CoreDefinitionLayout, List<String>>{};

      for (final layout in CoreDefinitionLayout.values) {
        await tester.pumpWidget(
          _app(DefinitionList(items: _kEntries, layout: layout)),
        );
        announced[layout] = _allNodes(tester)
            .where((data) => data.label.isNotEmpty)
            .map((data) => '${data.label}=${data.value}')
            .toList();
      }

      expect(
        announced[CoreDefinitionLayout.columns],
        announced[CoreDefinitionLayout.stacked],
      );
      expect(
        announced[CoreDefinitionLayout.inline],
        announced[CoreDefinitionLayout.stacked],
      );
      expect(
        announced[CoreDefinitionLayout.stacked],
        ['$_kTerm=$_kValue', '$_kSecondTerm=$_kSecondValue'],
      );

      handle.dispose();
    });

    testWidgets('a single-node rich value is named on that same node', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _app(
          DefinitionList(
            items: [
              CoreDefinitionEntry.rich(
                term: '이메일',
                description: Clickable(
                  onPressed: () {},
                  child: const Text('cody@cocode.im'),
                ),
              ),
            ],
          ),
        ),
      );

      final named = _allNodes(
        tester,
      ).where((data) => data.label.contains('이메일')).toList();

      expect(named, hasLength(1));
      expect(
        named.single.label,
        contains('cody@cocode.im'),
        reason:
            'One stop, term first — the same shape the plain-string '
            'branch produces, so a linked value is not read as an '
            'unattached address.',
      );
      expect(
        named.single.hasFlag(SemanticsFlag.isButton),
        isTrue,
        reason:
            'Naming the value must not cost it the action it carries: '
            'a pair that reads correctly and cannot be activated is a '
            'regression, not a fix.',
      );

      handle.dispose();
    });

    testWidgets('a multi-node rich value keeps every action reachable', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _app(
          DefinitionList(
            items: [
              CoreDefinitionEntry.rich(
                term: '이메일',
                description: Row(
                  mainAxisSize: .min,
                  children: [
                    Clickable(
                      onPressed: () {},
                      child: const Text('cody@cocode.im'),
                    ),
                    Clickable(onPressed: () {}, child: const Text('복사')),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

      final nodes = _allNodes(tester);
      expect(
        nodes.where((data) => data.label == '이메일'),
        hasLength(1),
        reason: 'The term names the group when it cannot name one node.',
      );
      expect(
        nodes
            .where((data) => data.hasFlag(SemanticsFlag.isButton))
            .map((data) => data.label),
        containsAll(['cody@cocode.im', '복사']),
        reason:
            'Collapsing a rich value into one node would leave the '
            'second action with no node to be reached through.',
      );

      handle.dispose();
    });
  });

  // ═══════════════════════════════════════════════
  // resolveDefinitionList — merge chain
  // ═══════════════════════════════════════════════

  group('resolveDefinitionList', () {
    testWidgets('each layout reads its own row of the default table', (
      tester,
    ) async {
      // Distances in logical pixels, per layout: entry gap, pair gap.
      const expected = {
        CoreDefinitionLayout.stacked: (14.0, 2.0),
        CoreDefinitionLayout.columns: (24.0, 8.0),
        CoreDefinitionLayout.inline: (16.0, 8.0),
      };

      for (final layout in CoreDefinitionLayout.values) {
        final resolved = await _resolve(tester, layout: layout);
        final (entry, pair) = expected[layout]!;
        final row = CoreDefinitionListStyle.defaultsByLayout[layout]!;

        expect(resolved.entrySpacing, entry, reason: layout.name);
        expect(resolved.pairSpacing, pair, reason: layout.name);
        expect(resolved.entrySpacing, row.entrySpacing);
        expect(resolved.pairSpacing, row.pairSpacing);
        expect(
          resolved.entrySpacing,
          greaterThan(resolved.pairSpacing),
          reason:
              'Proximity is what groups a term with its own value; an entry '
              'gap at or below the pair gap reads as one flat run.',
        );
      }
    });

    testWidgets('the instance override wins over the component theme', (
      tester,
    ) async {
      final resolved = await _resolve(
        tester,
        componentTheme: const CoreDefinitionListTheme(
          style: CoreDefinitionListStyle(
            entrySpacing: _kOverridePairSpacing,
            pairSpacing: _kOverridePairSpacing,
          ),
        ),
        definitionListStyle: const CoreDefinitionListStyle(
          entrySpacing: _kOverrideEntrySpacing,
        ),
      );

      expect(resolved.entrySpacing, _kOverrideEntrySpacing);
      expect(
        resolved.pairSpacing,
        _kOverridePairSpacing,
        reason: 'An override of one distance must not drop the other.',
      );
    });

    testWidgets('stacked sets the term one step below the description', (
      tester,
    ) async {
      final resolved = await _resolve(tester);
      final term = resolved.termTextStyle;
      final description = resolved.descriptionTextStyle;

      expect(term.fontSize, 12);
      expect(description.fontSize, 13);
      expect(term.fontWeight, FontWeight.w500);
      expect(description.fontWeight, FontWeight.w500);
      expect(term.fontSize! * term.height!, closeTo(16.8, 0.01));
      expect(description.fontSize! * description.height!, closeTo(18.2, 0.01));
      expect(term.color, isNotNull);
      expect(term.color, isNot(description.color));
    });

    testWidgets('columns and inline set term and description on one role', (
      tester,
    ) async {
      for (final layout in [
        CoreDefinitionLayout.columns,
        CoreDefinitionLayout.inline,
      ]) {
        final resolved = await _resolve(tester, layout: layout);
        final term = resolved.termTextStyle;
        final description = resolved.descriptionTextStyle;

        expect(term.fontSize, 13, reason: layout.name);
        expect(description.fontSize, 13, reason: layout.name);
        expect(term.fontWeight, FontWeight.w500, reason: layout.name);
        expect(description.fontWeight, FontWeight.w500, reason: layout.name);
        expect(term.height, description.height, reason: layout.name);
        expect(term.fontSize! * term.height!, closeTo(18.2, 0.01));
        // The role is shared, so colour is what is left to tell the two
        // apart besides position.
        expect(term.color, isNot(description.color), reason: layout.name);
      }
    });

    testWidgets('mono sets the description in the code role on a 21px line', (
      tester,
    ) async {
      for (final layout in CoreDefinitionLayout.values) {
        final plain = await _resolve(tester, layout: layout);
        final mono = await _resolve(tester, layout: layout, mono: true);
        final description = mono.descriptionTextStyle;

        expect(description.fontSize, 12, reason: layout.name);
        expect(description.fontWeight, FontWeight.w400, reason: layout.name);
        expect(description.fontFamily, CoreFontFamily.mono);
        expect(
          description.fontSize! * description.height!,
          closeTo(CoreLineBox.px21, 1e-9),
          reason: layout.name,
        );
        expect(description.color, plain.descriptionTextStyle.color);
        expect(
          mono.termTextStyle,
          plain.termTextStyle,
          reason: 'mono is a value flag; the term keeps its role.',
        );
        expect(mono.entrySpacing, plain.entrySpacing);
        expect(mono.pairSpacing, plain.pairSpacing);
      }
    });

    testWidgets('mono and numeric combine, and an override reaches both', (
      tester,
    ) async {
      final resolved = await _resolve(
        tester,
        mono: true,
        numeric: true,
        definitionListStyle: const CoreDefinitionListStyle(
          descriptionTextStyle: CoreTextStyle(fontWeight: CoreFontWeight.bold),
        ),
      );

      expect(resolved.descriptionTextStyle.fontFamily, CoreFontFamily.mono);
      expect(
        resolved.descriptionTextStyle.fontFeatures,
        contains(const FontFeature.tabularFigures()),
      );
      expect(
        resolved.descriptionTextStyle.fontWeight,
        CoreFontWeight.bold.weight,
      );
    });

    testWidgets('a mono override reaches only a mono list', (tester) async {
      const style = CoreDefinitionListStyle(
        monoDescriptionTextStyle: CoreTextStyle(
          fontWeight: CoreFontWeight.bold,
        ),
      );
      final plain = await _resolve(tester);
      final plainWithOverride = await _resolve(
        tester,
        definitionListStyle: style,
      );
      final mono = await _resolve(
        tester,
        mono: true,
        definitionListStyle: style,
      );

      expect(
        plainWithOverride.descriptionTextStyle,
        plain.descriptionTextStyle,
        reason: 'A mono-only override must not touch a list that is not mono.',
      );
      expect(mono.descriptionTextStyle.fontWeight, CoreFontWeight.bold.weight);
      expect(mono.descriptionTextStyle.fontFamily, CoreFontFamily.mono);
      expect(mono.descriptionTextStyle.fontSize, 12);
    });

    testWidgets('termWidth is unset by default and carries the given width', (
      tester,
    ) async {
      final unset = await _resolve(
        tester,
        layout: CoreDefinitionLayout.columns,
      );
      final fixed = await _resolve(
        tester,
        layout: CoreDefinitionLayout.columns,
        definitionListStyle: const CoreDefinitionListStyle(termWidth: 90),
      );

      expect(unset.termWidth, isNull);
      expect(fixed.termWidth, 90);
    });

    testWidgets('a typographic override keeps the rest of the role', (
      tester,
    ) async {
      final plain = await _resolve(tester);
      final bold = await _resolve(
        tester,
        definitionListStyle: const CoreDefinitionListStyle(
          termTextStyle: CoreTextStyle(fontWeight: CoreFontWeight.bold),
        ),
      );

      expect(bold.termTextStyle.fontWeight, CoreFontWeight.bold.weight);
      expect(bold.termTextStyle.fontSize, plain.termTextStyle.fontSize);
      expect(bold.termTextStyle.color, plain.termTextStyle.color);
    });

    testWidgets('numeric turns on tabular figures, and only on the value', (
      tester,
    ) async {
      final plain = await _resolve(tester);
      final numeric = await _resolve(tester, numeric: true);

      expect(plain.descriptionTextStyle.fontFeatures, isNull);
      expect(
        numeric.descriptionTextStyle.fontFeatures,
        contains(const FontFeature.tabularFigures()),
      );
      expect(numeric.termTextStyle.fontFeatures, isNull);
    });
  });

  // ═══════════════════════════════════════════════
  // Layout
  // ═══════════════════════════════════════════════

  group('layout', () {
    testWidgets('columns starts every description on the same edge', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          const DefinitionList(
            items: _kEntries,
            layout: CoreDefinitionLayout.columns,
          ),
        ),
      );

      expect(
        tester.getTopLeft(find.text(_kValue)).dx,
        tester.getTopLeft(find.text(_kSecondValue)).dx,
        reason: 'A column that does not line up is not a column.',
      );
    });

    testWidgets('stacked puts the value below its term', (tester) async {
      await tester.pumpWidget(_app(const DefinitionList(items: _kEntries)));

      expect(
        tester.getTopLeft(find.text(_kValue)).dy,
        greaterThan(tester.getTopLeft(find.text(_kTerm)).dy),
      );
      expect(
        tester.getTopLeft(find.text(_kValue)).dx,
        tester.getTopLeft(find.text(_kTerm)).dx,
      );
    });

    testWidgets('inline keeps the value on the term line', (tester) async {
      await tester.pumpWidget(
        _app(
          const DefinitionList(
            items: _kEntries,
            layout: CoreDefinitionLayout.inline,
          ),
        ),
      );

      expect(
        tester.getTopLeft(find.text(_kValue)).dx,
        greaterThan(tester.getTopLeft(find.text(_kTerm)).dx),
      );
    });

    testWidgets('the first pair carries no leading gap', (tester) async {
      await tester.pumpWidget(
        _app(
          const DefinitionList(
            items: _kEntries,
            layout: CoreDefinitionLayout.columns,
          ),
        ),
      );

      // Row-major: term / description of pair 0, then of pair 1.
      final leadingGaps = tester
          .widgetList<Padding>(
            find.descendant(
              of: find.byType(DefinitionList),
              matching: find.byType(Padding),
            ),
          )
          .map((padding) => padding.padding.resolve(TextDirection.ltr).top)
          .toList();

      expect(leadingGaps, hasLength(4));
      expect(
        leadingGaps.take(2),
        everyElement(isZero),
        reason:
            'The entry gap rides the pair that follows another, so the '
            'list must not open with a blank strip no caller asked for.',
      );
      expect(leadingGaps.skip(2), everyElement(greaterThan(0.0)));
    });

    testWidgets('termWidth holds the term column at the given width', (
      tester,
    ) async {
      const termWidth = 140.0;
      await tester.pumpWidget(
        _app(
          const DefinitionList(
            items: _kEntries,
            layout: CoreDefinitionLayout.columns,
          ).withStyle(const CoreDefinitionListStyle(termWidth: termWidth)),
        ),
      );

      final left = tester.getTopLeft(find.byType(DefinitionList)).dx;
      const pairSpacing = 8.0;
      expect(
        tester.getTopLeft(find.text(_kValue)).dx,
        left + termWidth + pairSpacing,
      );
      expect(
        tester.getTopLeft(find.text(_kSecondValue)).dx,
        tester.getTopLeft(find.text(_kValue)).dx,
      );
    });

    testWidgets('without termWidth the column is as wide as its widest term', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          const DefinitionList(
            items: _kEntries,
            layout: CoreDefinitionLayout.columns,
          ),
        ),
      );

      final left = tester.getTopLeft(find.byType(DefinitionList)).dx;
      const pairSpacing = 8.0;
      expect(
        tester.getTopLeft(find.text(_kValue)).dx,
        left + tester.getSize(find.text(_kTerm)).width + pairSpacing,
      );
    });

    testWidgets('stacked and inline ignore termWidth', (tester) async {
      for (final layout in [
        CoreDefinitionLayout.stacked,
        CoreDefinitionLayout.inline,
      ]) {
        await tester.pumpWidget(
          _app(
            DefinitionList(
              items: _kEntries,
              layout: layout,
            ).withStyle(const CoreDefinitionListStyle(termWidth: 140)),
          ),
        );
        final plain = tester.getTopLeft(find.text(_kValue));

        await tester.pumpWidget(
          _app(DefinitionList(items: _kEntries, layout: layout)),
        );

        expect(
          tester.getTopLeft(find.text(_kValue)),
          plain,
          reason: layout.name,
        );
      }
    });

    testWidgets('mono lays the description out on the 21px line box', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          const DefinitionList(
            items: [CoreDefinitionEntry(term: _kTerm, description: _kValue)],
            mono: true,
          ),
        ),
      );

      expect(tester.getSize(find.text(_kValue)).height, closeTo(21, 0.01));
    });

    testWidgets('an empty list renders nothing rather than throwing', (
      tester,
    ) async {
      for (final layout in CoreDefinitionLayout.values) {
        await tester.pumpWidget(
          _app(DefinitionList(items: const [], layout: layout)),
        );
        expect(tester.takeException(), isNull);
      }
    });
  });

  // ═══════════════════════════════════════════════
  // Chain sugar
  // ═══════════════════════════════════════════════

  group('withStyle', () {
    test('merges into the existing style, patch wins', () {
      final list = const DefinitionList(items: _kEntries)
          .withStyle(
            const CoreDefinitionListStyle(
              entrySpacing: _kOverrideEntrySpacing,
              pairSpacing: _kOverridePairSpacing,
            ),
          )
          .withStyle(
            const CoreDefinitionListStyle(entrySpacing: _kOverridePairSpacing),
          );

      expect(list.definitionListStyle?.entrySpacing, _kOverridePairSpacing);
      expect(list.definitionListStyle?.pairSpacing, _kOverridePairSpacing);
    });

    test('copyWith keeps every field it was not given', () {
      const original = DefinitionList(
        items: _kEntries,
        layout: CoreDefinitionLayout.inline,
        numeric: true,
        mono: true,
      );
      final copy = original.copyWith(numeric: false);

      expect(copy.items, _kEntries);
      expect(copy.layout, CoreDefinitionLayout.inline);
      expect(copy.numeric, isFalse);
      expect(copy.mono, isTrue);
      expect(original.copyWith(mono: false).mono, isFalse);
    });
  });
}
