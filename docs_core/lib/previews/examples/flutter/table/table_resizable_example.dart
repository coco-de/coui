import 'package:coui_flutter/coui_flutter.dart';

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
    // Column widths sum to ~container width so the table starts filling the
    // preview area without gaps. Users can still reallocate space between
    // neighbouring columns via the drag handles.
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
}
