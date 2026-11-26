import 'package:coui_web/coui_web.dart';

/// T1 저작 규약 형태의 chain 예제 — 두 인스턴스로 구성한다:
/// (1) 토큰-정확 getter **combo 체인** 1개 (`.radius16.primary` — radius
/// 축·색 축 getter 가 base 전체에서 정확히 1회씩, 랜덤 순열 토글의 치환
/// 앵커), (2) **withStyle full-control** 1개 — getter 밖 필드까지 조합해
/// `CoreTableStyle` 슬롯 전체를 여는 경로.
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
}
