import 'package:coui_flutter/coui_flutter.dart';

/// Mirrors shadcn_flutter's scrollable + frozen demo using the unified
/// [ScrollableClient]: a fixed-size viewport hands
/// `horizontalOffset` / `verticalOffset` / `viewportSize` to [Table]
/// (no `SingleChildScrollView` involved), and freezes the header row plus a
/// leftmost column using [CoreFrozenTableData].
class TableScrollableExample extends StatelessWidget {
  const TableScrollableExample({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 320,
      child: ScrollableClient(
        diagonalDragBehavior: CoreDiagonalDragBehavior.free,
        builder: (context, offset, viewportSize, child) {
          return Table(
            horizontalOffset: offset.dx,
            verticalOffset: offset.dy,
            tableStyle: CoreTableStyle(
              viewportWidth: viewportSize.width,
              viewportHeight: viewportSize.height,
            ),
            defaultColumnWidth: const CoreFixedTableSize(160),
            defaultRowHeight: const CoreFixedTableSize(44),
            frozenCells: const CoreFrozenTableData(
              frozenRows: [CoreTableRef(0)],
              frozenColumns: [CoreTableRef(0)],
            ),
            rows: [
              CoreTableRowData<Widget>.header(
                cells: List.generate(
                  6,
                  (i) => CoreTableCellData<Widget>(
                    child: Text('${i + 1}열'),
                  ),
                ),
              ),
              for (var r = 1; r <= 12; r++)
                CoreTableRowData<Widget>(
                  cells: List.generate(
                    6,
                    (c) => CoreTableCellData<Widget>(
                      child: Text('$r행 · ${c + 1}열'),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
