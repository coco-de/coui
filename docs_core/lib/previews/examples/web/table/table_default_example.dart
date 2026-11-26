import 'package:coui_web/coui_web.dart';

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
}
