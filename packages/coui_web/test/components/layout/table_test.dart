import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

List<CoreTableRowData<Component>> _rows({bool cellEnabled = true}) => [
  const CoreTableRowData.header(
    cells: [CoreTableCellData(child: Text('Header'))],
  ),
  CoreTableRowData(
    cells: [
      CoreTableCellData(enabled: cellEnabled, child: const Text('Cell')),
    ],
  ),
];

void main() {
  group('Table', () {
    testComponents('renders header and body cells', (tester) async {
      pumpWithTheme(tester, Table(rows: _rows()));

      expect(find.text('Header'), findsOneComponent);
      expect(find.text('Cell'), findsOneComponent);
    });

    testComponents(
      'disabledForegroundColor override reaches a disabled cell',
      (tester) async {
        pumpWithTheme(
          tester,
          Table(
            rows: _rows(cellEnabled: false),
            tableStyle: const CoreTableStyle(
              disabledForegroundColor: CoreColor(0xFF223344),
            ),
          ),
        );

        final cellDiv =
            find
                    .ancestor(
                      of: find.text('Cell'),
                      matching: find.tag('div'),
                    )
                    .evaluate()
                    .first
                    .component
                as DomComponent;
        expect(cellDiv.styles?.properties['color'], contains('34, 51, 68'));
      },
    );

    testComponents(
      'disabled cell no longer applies the blanket opacity-50 class',
      (tester) async {
        pumpWithTheme(tester, Table(rows: _rows(cellEnabled: false)));

        final cellDiv =
            find
                    .ancestor(
                      of: find.text('Cell'),
                      matching: find.tag('div'),
                    )
                    .evaluate()
                    .first
                    .component
                as DomComponent;
        expect(cellDiv.classes ?? '', isNot(contains('opacity-50')));
      },
    );

    testComponents('root carries role="table"', (tester) async {
      pumpWithTheme(tester, Table(rows: _rows()));

      final root = find.byType(Table).evaluate().first.component as Table;
      expect(root.componentAttributes['role'], 'table');
    });

    testComponents('header cell carries role="columnheader"', (
      tester,
    ) async {
      pumpWithTheme(tester, Table(rows: _rows()));

      final headerDiv =
          find
                  .ancestor(of: find.text('Header'), matching: find.tag('div'))
                  .evaluate()
                  .first
                  .component
              as DomComponent;
      expect(headerDiv.attributes?['role'], 'columnheader');
    });

    testComponents('body cell carries role="cell"', (tester) async {
      pumpWithTheme(tester, Table(rows: _rows()));

      final cellDiv =
          find
                  .ancestor(of: find.text('Cell'), matching: find.tag('div'))
                  .evaluate()
                  .first
                  .component
              as DomComponent;
      expect(cellDiv.attributes?['role'], 'cell');
    });

    testComponents(
      'each cell is wrapped by a role="row" group with display:contents',
      (tester) async {
        pumpWithTheme(tester, Table(rows: _rows()));

        final rowDiv =
            find
                    .ancestor(of: find.text('Cell'), matching: find.tag('div'))
                    .evaluate()
                    .toList()[1]
                    .component
                as DomComponent;
        expect(rowDiv.attributes?['role'], 'row');
        expect(rowDiv.styles?.properties['display'], contains('contents'));
      },
    );

    testComponents('multi-column cell reflects aria-colspan', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const Table(
          rows: [
            CoreTableRowData(
              cells: [
                CoreTableCellData(columnSpan: 2, child: Text('Wide')),
              ],
            ),
          ],
        ),
      );

      final cellDiv =
          find
                  .ancestor(of: find.text('Wide'), matching: find.tag('div'))
                  .evaluate()
                  .first
                  .component
              as DomComponent;
      expect(cellDiv.attributes?['aria-colspan'], '2');
    });
  });

  group('Table outer box and cell chrome', () {
    List<DomComponent> divsAbove(String text) => find
        .ancestor(of: find.text(text), matching: find.tag('div'))
        .evaluate()
        .map((e) => e.component as DomComponent)
        .toList();

    DomComponent rootOf(String text) =>
        divsAbove(text).firstWhere((d) => (d.classes ?? '').contains('grid'));

    DomComponent cellOf(String text) => divsAbove(text).first;

    List<String> classesOf(DomComponent d) =>
        (d.classes ?? '').split(' ').where((c) => c.isNotEmpty).toList();

    testComponents('a default Table root draws no outer box', (tester) async {
      pumpWithTheme(tester, Table(rows: _rows()));

      final root = rootOf('Cell');
      final styles = root.styles?.properties ?? const <String, String>{};
      expect(classesOf(root), isNot(contains('border')));
      expect(classesOf(root).where((c) => c.startsWith('border')), isEmpty);
      expect(styles.containsKey('border-width'), isFalse);
      expect(styles.containsKey('border-style'), isFalse);
      expect(styles.containsKey('border-color'), isFalse);
      // The radius still clips the row fills.
      expect(styles['border-radius'], isNotNull);
    });

    testComponents('outerBorderWidth draws the box in the separator colour', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        Table(
          rows: _rows(),
          tableStyle: const CoreTableStyle(outerBorderWidth: 1),
        ),
      );

      final root = rootOf('Cell');
      final styles = root.styles!.properties;
      expect(styles['border-style'], 'solid');
      expect(styles['border-width'], 'var(--coui-stroke-width-1)');
      expect(classesOf(root), contains('border-outline-variant'));
      expect(classesOf(root), isNot(contains('border')));
    });

    testComponents('a border colour override rides inline with the box', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        Table(
          rows: _rows(),
          tableStyle: const CoreTableStyle(
            outerBorderWidth: 2,
            borderColor: CoreColor(0xFF223344),
          ),
        ),
      );

      final styles = rootOf('Cell').styles!.properties;
      expect(styles['border-width'], 'var(--coui-stroke-width-2)');
      expect(styles['border-color'], contains('34, 51, 68'));
    });

    testComponents('row separators stay on a table with no outer box', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        Table(
          rows: [
            ..._rows(),
            const CoreTableRowData(
              cells: [CoreTableCellData(child: Text('Last'))],
            ),
          ],
        ),
      );

      for (final text in ['Cell', 'Header']) {
        final cell = cellOf(text);
        final styles = cell.styles!.properties;
        // The hairline is the outlineVariant colour class; its width and
        // style are inline, read from `borderWidth` the way Flutter reads it.
        expect(
          classesOf(cell),
          contains('border-outline-variant'),
          reason: text,
        );
        expect(classesOf(cell), isNot(contains('border-b')), reason: text);
        expect(styles['border-bottom-width'], 'var(--coui-stroke-width-1)');
        expect(styles['border-bottom-style'], 'solid');
      }
    });

    testComponents('a borderWidth override reaches the separators', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        Table(
          rows: [
            ..._rows(),
            const CoreTableRowData(
              cells: [CoreTableCellData(child: Text('Last'))],
            ),
          ],
          tableStyle: const CoreTableStyle(borderWidth: 3),
        ),
      );

      // With the colour still the design default, only the colour is a
      // class; the width follows the override.
      final styles = cellOf('Cell').styles!.properties;
      expect(styles['border-bottom-width'], 'var(--coui-stroke-width-3)');
      expect(classesOf(cellOf('Cell')), contains('border-outline-variant'));
      // The last row draws no separator.
      expect(
        cellOf('Last').styles!.properties.containsKey('border-bottom-width'),
        isFalse,
      );
      // A default Table root still draws no outer box.
      expect(
        rootOf('Cell').styles!.properties.containsKey('border-width'),
        isFalse,
      );
    });

    testComponents('a colour override states the whole separator edge', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        Table(
          rows: [
            ..._rows(),
            const CoreTableRowData(
              cells: [CoreTableCellData(child: Text('Last'))],
            ),
          ],
          tableStyle: const CoreTableStyle(
            borderWidth: 2,
            borderColor: CoreColor(0xFF223344),
          ),
        ),
      );

      final cell = cellOf('Cell');
      expect(cell.styles!.properties['border-bottom'], contains('34, 51, 68'));
      expect(
        cell.styles!.properties['border-bottom'],
        startsWith('var(--coui-stroke-width-2) solid'),
      );
      expect(classesOf(cell), isNot(contains('border-outline-variant')));
    });

    testComponents('cells read the header and body padding defaults', (
      tester,
    ) async {
      pumpWithTheme(tester, Table(rows: _rows()));

      expect(
        cellOf('Header').styles!.properties['padding'],
        CoreTableStyle.defaultHeaderPadding.toValue(),
      );
      expect(
        cellOf('Cell').styles!.properties['padding'],
        CoreTableStyle.defaultCellPadding.toValue(),
      );
    });

    testComponents('the header reads label-medium and the body label-large', (
      tester,
    ) async {
      pumpWithTheme(tester, Table(rows: _rows()));

      final header = classesOf(cellOf('Header'));
      final body = classesOf(cellOf('Cell'));
      expect(header, contains('text-label-medium'));
      expect(header, isNot(contains('text-body-medium')));
      expect(header.where((c) => c.startsWith('font-')), isEmpty);
      expect(body, contains('text-label-large'));
      expect(body, isNot(contains('text-body-medium')));
      expect(body.where((c) => c.startsWith('font-')), isEmpty);
    });

    testComponents('a header text slot overlay rides inline on its role', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        Table(
          rows: _rows(),
          tableStyle: const CoreTableStyle(
            headerTextStyle: CoreTextStyle(fontSize: 20),
          ),
        ),
      );

      final header = cellOf('Header');
      expect(classesOf(header), contains('text-label-medium'));
      expect(header.styles!.properties['font-size'], isNotNull);
      // The body is untouched.
      expect(
        cellOf('Cell').styles!.properties.containsKey('font-size'),
        isFalse,
      );
    });

    testComponents('an enabled header takes its default ink as a class', (
      tester,
    ) async {
      pumpWithTheme(tester, Table(rows: _rows()));

      final header = cellOf('Header');
      expect(
        classesOf(header),
        contains(
          'text-${CoreTableStyle.defaultHeaderTextStyle.color!.tailwindColor}',
        ),
      );
      expect(classesOf(header), contains('text-on-surface-subtle'));
      expect(header.styles!.properties.containsKey('color'), isFalse);
      // The body states no colour and inherits.
      expect(
        classesOf(cellOf('Cell')).where((c) => c.startsWith('text-on-')),
        isEmpty,
      );
    });

    testComponents('a disabled header paints the disabled colour, not both', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const Table(
          rows: [
            CoreTableRowData.header(
              cells: [
                CoreTableCellData(enabled: false, child: Text('Off')),
              ],
            ),
          ],
        ),
      );

      final header = cellOf('Off');
      expect(classesOf(header), contains('text-disabled-content'));
      expect(classesOf(header), isNot(contains('text-on-surface-subtle')));
      expect(header.styles!.properties.containsKey('color'), isFalse);
    });

    testComponents('a flat foregroundColor override replaces that class', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        Table(
          rows: _rows(),
          tableStyle: const CoreTableStyle(
            foregroundColor: CoreColor(0xFF223344),
          ),
        ),
      );

      final header = cellOf('Header');
      expect(classesOf(header), isNot(contains('text-on-surface-subtle')));
      expect(header.styles!.properties['color'], contains('34, 51, 68'));
    });

    testComponents('a header text slot colour wins over the flat colour', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        Table(
          rows: _rows(),
          tableStyle: const CoreTableStyle(
            foregroundColor: CoreColor(0xFF223344),
            headerTextStyle: CoreTextStyle(color: CoreColor(0xFF445566)),
          ),
        ),
      );

      final header = cellOf('Header');
      expect(header.styles!.properties['color'], contains('68, 85, 102'));
      expect(classesOf(header), isNot(contains('text-on-surface-subtle')));
    });
  });

  group('Table fills', () {
    List<String> classesAt(String text) =>
        (find
                    .ancestor(of: find.text(text), matching: find.tag('div'))
                    .evaluate()
                    .first
                    .component
                as DomComponent)
            .classes
            ?.split(' ')
            .where((c) => c.isNotEmpty)
            .toList() ??
        const [];

    testComponents('the header paints no fill; the footer keeps its own', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        Table(
          rows: [
            ..._rows(),
            const CoreTableRowData.footer(
              cells: [CoreTableCellData(child: Text('Foot'))],
            ),
          ],
        ),
      );

      expect(
        classesAt('Header').where((c) => c.startsWith('bg-')),
        isEmpty,
      );
      expect(classesAt('Foot'), contains('bg-surface-container'));
    });

    testComponents('a frozen header cell takes the frozen base, not clear', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        Table(
          rows: _rows(),
          frozenCells: const CoreFrozenTableData(
            frozenRows: [CoreTableRef(0)],
          ),
        ),
      );

      expect(classesAt('Header'), contains('bg-surface'));
      // The body row is not frozen.
      expect(classesAt('Cell').where((c) => c.startsWith('bg-')), isEmpty);
    });

    testComponents('a header with its own fill keeps it when frozen', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        Table(
          rows: _rows(),
          frozenCells: const CoreFrozenTableData(
            frozenRows: [CoreTableRef(0)],
          ),
          tableStyle: const CoreTableStyle(
            headerBackgroundColor: CoreColor.token(CoreColors.surfaceBright),
          ),
        ),
      );

      // An overridden fill is inline, like every override; the frozen base
      // does not stack under it.
      expect(classesAt('Header'), isNot(contains('bg-surface')));
      final header =
          find
                  .ancestor(of: find.text('Header'), matching: find.tag('div'))
                  .evaluate()
                  .first
                  .component
              as DomComponent;
      expect(header.styles!.properties['background-color'], isNotNull);
    });

    testComponents('the hover wash and the selection fill are their tokens', (
      tester,
    ) async {
      // The class a hovered / selected cell would take, read off the same
      // defaults the resolver emits from.
      expect(
        CoreTableStyle.defaultRowHoverColor.tailwindColor,
        'on-surface/3',
      );
      expect(
        CoreTableStyle.defaultRowSelectedColor.tailwindColor,
        'surface-container-high',
      );
      pumpWithTheme(
        tester,
        const Table(
          rows: [
            CoreTableRowData.header(
              cells: [CoreTableCellData(child: Text('Head'))],
            ),
            CoreTableRowData(
              selected: true,
              cells: [CoreTableCellData(child: Text('Chosen'))],
            ),
          ],
        ),
      );

      expect(classesAt('Chosen'), contains('bg-surface-container-high'));
      expect(
        classesAt('Chosen').where((c) => c.startsWith('bg-primary')),
        isEmpty,
      );
    });
  });
}
