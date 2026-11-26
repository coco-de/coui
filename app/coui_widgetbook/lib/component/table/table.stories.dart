import 'package:coui_flutter/coui_flutter.dart';
import 'package:coui_i10n/coui_i10n.dart';
import 'package:widgetbook/widgetbook.dart';

part 'table.stories.g.dart';

const _kCellSelectionRows = 3;
const _kCellSelectionCols = 3;

/// Which interaction flavour the [TableDemo] renders.
enum TableDemoMode {
  /// Plain read-only table.
  basic,

  /// Individual cells toggled by pressing them.
  cellSelection,

  /// Rows toggled via a leading checkbox column.
  selectableRows,
}

/// Interactive demo host for [Table] stories.
///
/// Owns row / cell selection state so the selectable modes work
/// without external controllers.
class TableDemo extends StatefulWidget {
  /// Creates a [TableDemo].
  const TableDemo({super.key, this.mode = TableDemoMode.basic});

  /// Interaction flavour to render.
  final TableDemoMode mode;

  @override
  State<TableDemo> createState() => _TableDemoState();
}

class _TableDemoState extends State<TableDemo> {
  Set<int> _selectedRows = <int>{};
  Set<(int, int)> _selectedCells = <(int, int)>{};

  void handleToggleRow(int index) {
    setState(() {
      _selectedRows = _selectedRows.contains(index)
          ? ({..._selectedRows}..remove(index))
          : {..._selectedRows, index};
    });
  }

  void handleToggleCell({required int row, required int col}) {
    final key = (row, col);
    setState(() {
      _selectedCells = _selectedCells.contains(key)
          ? ({..._selectedCells}..remove(key))
          : {..._selectedCells, key};
    });
  }

  static Widget get _basicTable {
    final tableStrings = t.widgetbook.table;

    return Table(
      rows: [
        CoreTableRowData(
          cells: [
            CoreTableCellData(child: Text(tableStrings.name)),
            CoreTableCellData(child: Text(tableStrings.email)),
            CoreTableCellData(child: Text(tableStrings.role)),
          ],
        ),
        CoreTableRowData(
          cells: [
            CoreTableCellData(child: Text(tableStrings.john_doe)),
            CoreTableCellData(child: Text(tableStrings.john_email)),
            CoreTableCellData(child: Text(tableStrings.developer)),
          ],
        ),
        CoreTableRowData(
          cells: [
            CoreTableCellData(child: Text(tableStrings.jane_smith)),
            CoreTableCellData(child: Text(tableStrings.jane_email)),
            CoreTableCellData(child: Text(tableStrings.designer)),
          ],
        ),
        CoreTableRowData(
          cells: [
            CoreTableCellData(child: Text(tableStrings.bob_johnson)),
            CoreTableCellData(child: Text(tableStrings.bob_email)),
            CoreTableCellData(child: Text(tableStrings.manager)),
          ],
        ),
      ],
    );
  }

  Widget get _selectableRowsTable {
    final tableStrings = t.widgetbook.table;
    final products = [
      (tableStrings.laptop, r'$999', '15'),
      (tableStrings.mouse, r'$29', '50'),
      (tableStrings.keyboard, r'$79', '30'),
    ];

    return Column(
      crossAxisAlignment: .start,
      spacing: CoreSpace.space16,
      children: [
        Table(
          rows: [
            CoreTableRowData(
              cells: [
                CoreTableCellData(child: Text(tableStrings.select)),
                CoreTableCellData(child: Text(tableStrings.product)),
                CoreTableCellData(child: Text(tableStrings.price)),
                CoreTableCellData(child: Text(tableStrings.stock)),
              ],
            ),
            ...products.asMap().entries.map((entry) {
              final index = entry.key;
              final (itemName, price, stock) = entry.value;
              final isSelected = _selectedRows.contains(index);

              return CoreTableRowData(
                cells: [
                  CoreTableCellData(
                    child: Checkbox(
                      onChanged: (_) => handleToggleRow(index),
                      checked: isSelected,
                    ),
                  ),
                  CoreTableCellData(child: Text(itemName)),
                  CoreTableCellData(child: Text(price)),
                  CoreTableCellData(child: Text(stock)),
                ],
                selected: isSelected,
              );
            }),
          ],
        ),
        Text(
          t.widgetbook.common.selected_rows(
            count: _selectedRows.length.toString(),
          ),
        ).bodySmall().onSurface(),
      ],
    );
  }

  Widget get _cellSelectionTable {
    final tableStrings = t.widgetbook.table;
    final headers = [tableStrings.name, tableStrings.email, tableStrings.role];
    final data = [
      [tableStrings.john_doe, tableStrings.john_email, tableStrings.developer],
      [tableStrings.jane_smith, tableStrings.jane_email, tableStrings.designer],
      [tableStrings.bob_johnson, tableStrings.bob_email, tableStrings.manager],
    ];

    return Column(
      crossAxisAlignment: .start,
      spacing: CoreSpace.space16,
      children: [
        Table(
          rows: [
            CoreTableRowData(
              cells: headers
                  .map((h) => CoreTableCellData(child: Text(h)))
                  .toList(),
            ),
            for (int r = 0; r < _kCellSelectionRows; r += 1)
              CoreTableRowData(
                cells: [
                  for (int c = 0; c < _kCellSelectionCols; c += 1)
                    CoreTableCellData(
                      onPressed: () => handleToggleCell(row: r, col: c),
                      selected: _selectedCells.contains((r, c)),
                      child: Text(data[r][c]),
                    ),
                ],
              ),
          ],
        ),
        Text(
          t.widgetbook.common.selected_cells(
            count: _selectedCells.length.toString(),
          ),
        ).bodySmall().onSurface(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return switch (widget.mode) {
      .basic => _basicTable,
      .selectableRows => _selectableRowsTable,
      .cellSelection => _cellSelectionTable,
    };
  }
}

/// Navigation metadata for the Table component.
const kComponentMeta = ComponentMeta(name: 'Table', path: 'layout');

/// Story metadata for [TableDemo].
const kMeta = Meta(TableDemo.new);

/// Plain read-only table.
final $Default = _Story();

/// Table whose rows are toggled via a checkbox column.
final $SelectableRows = _Story(
  name: 'Selectable Rows',
  args: _Args(
    mode: EnumArg(TableDemoMode.selectableRows, values: TableDemoMode.values),
  ),
);

/// Table whose individual cells toggle when pressed.
final $CellSelection = _Story(
  name: 'Cell Selection',
  args: _Args(
    mode: EnumArg(TableDemoMode.cellSelection, values: TableDemoMode.values),
  ),
);
