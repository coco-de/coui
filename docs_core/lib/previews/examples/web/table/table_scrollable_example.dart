import 'package:coui_web/coui_web.dart';

/// Web counterpart of TableScrollableExample in Flutter. Uses the unified
/// [ScrollableClient] to provide a fixed-size viewport that hands the
/// current scroll offset + viewport size to [Table], which honours
/// `horizontalOffset` / `verticalOffset` + `frozenCells`.
class TableScrollableExample extends StatelessComponent {
  const TableScrollableExample({super.key});

  @override
  Component build(BuildContext context) {
    return div(
      [
        ScrollableClient(
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
                CoreTableRowData<Component>.header(
                  cells: List.generate(
                    6,
                    (index) => CoreTableCellData<Component>(
                      child: Text('${index + 1}열'),
                    ),
                  ),
                ),
                for (var r = 1; r <= 12; r++)
                  CoreTableRowData<Component>(
                    cells: List.generate(
                      6,
                      (c) => CoreTableCellData<Component>(
                        child: Text('$r행 · ${c + 1}열'),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
      styles: Styles(
        raw: const {
          'height': '320px',
          'width': '100%',
          // Prevent the flex parent from shrinking this container below the
          // grid's natural width — otherwise the ScrollableClient can't
          // detect horizontal overflow.
          'min-width': '0',
        },
      ),
    );
  }
}
