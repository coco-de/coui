import 'package:coui_web/coui_web.dart';

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
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    return ResizableTable(
      controller: _controller,
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
}
