/// Returns a Flutter code snippet string for the Table component.
String tableCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
class TableChainExample extends StatelessWidget {
  const TableChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 토큰-정확 getter combo — 이름이 곧 값 (getter 이름 = Core 토큰 상수 1:1).
        Table(
          rows: [
            CoreTableRowData<Widget>.header(
              cells: const [
                CoreTableCellData<Widget>(child: Text('이름')),
                CoreTableCellData<Widget>(child: Text('상태')),
                CoreTableCellData<Widget>(child: Text('역할')),
              ],
            ),
            CoreTableRowData<Widget>(
              cells: [
                const CoreTableCellData<Widget>(child: Text('김코드')),
                CoreTableCellData<Widget>(
                  child: Badge(
                    tone: CoreBadgeTone.primary,
                    child: const Text('활성'),
                  ),
                ),
                const CoreTableCellData<Widget>(child: Text('관리자')),
              ],
            ),
            CoreTableRowData<Widget>(
              cells: [
                const CoreTableCellData<Widget>(child: Text('이코드')),
                CoreTableCellData<Widget>(
                  child: Badge(
                    tone: CoreBadgeTone.neutral,
                    child: const Text('비활성'),
                  ),
                ),
                const CoreTableCellData<Widget>(child: Text('사용자')),
              ],
            ),
          ],
        ).radius16.primary,
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(borderWidth)까지 한 번에.
        Table(
          rows: [
            CoreTableRowData<Widget>.header(
              cells: const [
                CoreTableCellData<Widget>(child: Text('이름')),
                CoreTableCellData<Widget>(child: Text('상태')),
                CoreTableCellData<Widget>(child: Text('역할')),
              ],
            ),
            CoreTableRowData<Widget>(
              cells: [
                const CoreTableCellData<Widget>(child: Text('김코드')),
                CoreTableCellData<Widget>(
                  child: Badge(
                    tone: CoreBadgeTone.primary,
                    child: const Text('활성'),
                  ),
                ),
                const CoreTableCellData<Widget>(child: Text('관리자')),
              ],
            ),
            CoreTableRowData<Widget>(
              cells: [
                const CoreTableCellData<Widget>(child: Text('이코드')),
                CoreTableCellData<Widget>(
                  child: Badge(
                    tone: CoreBadgeTone.neutral,
                    child: const Text('비활성'),
                  ),
                ),
                const CoreTableCellData<Widget>(child: Text('사용자')),
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
    );
  }
}''',
    'resizable' =>
      '''
class TableResizableExample extends StatefulWidget {
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
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ResizableTable(
      controller: _controller,
      rows: [/* ... */],
    );
  }
}''',
    'scrollable' =>
      '''
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
            rows: [/* ... */],
          );
        },
      ),
    );
  }
}''',
    _ =>
      '''
class TableDefaultExample extends StatelessWidget {
  const TableDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Table(
      rows: [
        CoreTableRowData<Widget>.header(
          cells: const [
            CoreTableCellData<Widget>(child: Text('이름')),
            CoreTableCellData<Widget>(child: Text('상태')),
            CoreTableCellData<Widget>(child: Text('역할')),
          ],
        ),
        CoreTableRowData<Widget>(
          cells: [
            const CoreTableCellData<Widget>(child: Text('김코드')),
            CoreTableCellData<Widget>(
              child: Badge(
                tone: CoreBadgeTone.primary,
                child: const Text('활성'),
              ),
            ),
            const CoreTableCellData<Widget>(child: Text('관리자')),
          ],
        ),
        CoreTableRowData<Widget>(
          cells: [
            const CoreTableCellData<Widget>(child: Text('이코드')),
            CoreTableCellData<Widget>(
              child: Badge(
                tone: CoreBadgeTone.neutral,
                child: const Text('비활성'),
              ),
            ),
            const CoreTableCellData<Widget>(child: Text('사용자')),
          ],
        ),
      ],
    );
  }
}''',
  };
}
