/// Returns a Web code snippet string for the Table component.
String tableCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
class TableChainExample extends StatelessComponent {
  const TableChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return div(
      [
        // 토큰-정확 getter combo — 이름이 곧 값 (getter 이름 = Core 토큰 상수 1:1).
        Table(
          rows: [
            CoreTableRowData<Component>.header(
              cells: [
                CoreTableCellData<Component>(child: Text('이름')),
                CoreTableCellData<Component>(child: Text('상태')),
                CoreTableCellData<Component>(child: Text('역할')),
              ],
            ),
            CoreTableRowData<Component>(
              cells: [
                CoreTableCellData<Component>(child: Text('김코드')),
                CoreTableCellData<Component>(
                  child: Badge(
                    tone: CoreBadgeTone.primary,
                    child: Text('활성'),
                  ),
                ),
                CoreTableCellData<Component>(child: Text('관리자')),
              ],
            ),
            CoreTableRowData<Component>(
              cells: [
                CoreTableCellData<Component>(child: Text('이코드')),
                CoreTableCellData<Component>(
                  child: Badge(
                    tone: CoreBadgeTone.neutral,
                    child: Text('비활성'),
                  ),
                ),
                CoreTableCellData<Component>(child: Text('사용자')),
              ],
            ),
          ],
        ).radius16.primary,
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(borderWidth)까지 한 번에.
        Table(
          rows: [
            CoreTableRowData<Component>.header(
              cells: [
                CoreTableCellData<Component>(child: Text('이름')),
                CoreTableCellData<Component>(child: Text('상태')),
                CoreTableCellData<Component>(child: Text('역할')),
              ],
            ),
            CoreTableRowData<Component>(
              cells: [
                CoreTableCellData<Component>(child: Text('김코드')),
                CoreTableCellData<Component>(
                  child: Badge(
                    tone: CoreBadgeTone.primary,
                    child: Text('활성'),
                  ),
                ),
                CoreTableCellData<Component>(child: Text('관리자')),
              ],
            ),
            CoreTableRowData<Component>(
              cells: [
                CoreTableCellData<Component>(child: Text('이코드')),
                CoreTableCellData<Component>(
                  child: Badge(
                    tone: CoreBadgeTone.neutral,
                    child: Text('비활성'),
                  ),
                ),
                CoreTableCellData<Component>(child: Text('사용자')),
              ],
            ),
          ],
        ).withStyle(
          const CoreTableStyle(
            headerBackgroundColor: CoreColor.token(CoreColors.tertiary),
            borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
            borderWidth: CoreStrokeWidth.stroke2,
          ),
        ),
      ],
      classes: 'flex flex-col items-start',
    );
  }
}''',
    'resizable' =>
      '''
class TableResizableExample extends StatefulComponent {
  const TableResizableExample({super.key});

  @override
  State<TableResizableExample> createState() => _TableResizableExampleState();
}

class _TableResizableExampleState extends State<TableResizableExample> {
  late final ResizableTableController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ResizableTableController(
      defaultColumnWidth: 300,
      defaultRowHeight: 56,
      defaultWidthConstraint: const CoreConstrainedTableSize(min: 80),
      defaultHeightConstraint: const CoreConstrainedTableSize(min: 44),
    );
  }

  @override
  Component build(BuildContext context) {
    return ResizableTable(
      controller: _controller,
      rows: [/* ... */],
    );
  }
}''',
    'scrollable' =>
      '''
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
              rows: [/* ... */],
            );
          },
        ),
      ],
      styles: Styles(raw: const {'height': '320px'}),
    );
  }
}''',
    _ =>
      '''
class TableDefaultExample extends StatelessComponent {
  const TableDefaultExample({super.key});

  @override
  Component build(BuildContext context) {
    return Table(
      rows: [
        CoreTableRowData<Component>.header(
          cells: [
            CoreTableCellData<Component>(child: Text('이름')),
            CoreTableCellData<Component>(child: Text('상태')),
            CoreTableCellData<Component>(child: Text('역할')),
          ],
        ),
        CoreTableRowData<Component>(
          cells: [
            CoreTableCellData<Component>(child: Text('김코드')),
            CoreTableCellData<Component>(
              child: Badge(
                tone: CoreBadgeTone.primary,
                child: Text('활성'),
              ),
            ),
            CoreTableCellData<Component>(child: Text('관리자')),
          ],
        ),
        CoreTableRowData<Component>(
          cells: [
            CoreTableCellData<Component>(child: Text('이코드')),
            CoreTableCellData<Component>(
              child: Badge(
                tone: CoreBadgeTone.neutral,
                child: Text('비활성'),
              ),
            ),
            CoreTableCellData<Component>(child: Text('사용자')),
          ],
        ),
      ],
    );
  }
}''',
  };
}
