import 'package:coui_flutter/coui_flutter.dart';

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
}
