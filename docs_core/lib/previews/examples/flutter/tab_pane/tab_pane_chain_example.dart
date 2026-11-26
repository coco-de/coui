import 'package:coui_flutter/coui_flutter.dart';

/// T1 저작 규약 형태의 chain 예제 — 두 인스턴스로 구성한다:
/// (1) 토큰-정확 getter **combo 체인** 1개 (`.radius16.primary` — radius
/// 축·색 축 getter 가 base 전체에서 정확히 1회씩, 랜덤 순열 토글의 치환
/// 앵커), (2) **withStyle full-control** 1개 — getter 밖 필드까지 조합해
/// `CoreTabPaneStyle` 슬롯 전체를 여는 경로.
class TabPaneChainExample extends StatefulWidget {
  const TabPaneChainExample({super.key});

  @override
  State<TabPaneChainExample> createState() => _TabPaneChainExampleState();
}

class _TabPaneChainExampleState extends State<TabPaneChainExample> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 토큰-정확 getter combo — 이름이 곧 값 (getter 이름 = Core 토큰 상수 1:1).
        TabPane(
          tabs: [
            CoreTabItem(
              label: '계정',
              content: Padding(
                padding: const CoreEdgeInsets.all(CoreSpace.space20).toValue(geometry: Theme.of(context).geometry),
                child: Text(
                  '계정 설정을 관리해요.',
                ).bodyMedium.onSurfaceVariant,
              ),
            ),
            CoreTabItem(
              label: '비밀번호',
              content: Padding(
                padding: const CoreEdgeInsets.all(CoreSpace.space20).toValue(geometry: Theme.of(context).geometry),
                child: Text('여기에서 비밀번호를 바꿔요.').bodyMedium.onSurfaceVariant,
              ),
            ),
          ],
          selectedIndex: _index,
          onChanged: (i) => setState(() => _index = i),
        ).radius16.primary,
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(borderWidth)까지 한 번에.
        TabPane(
          tabs: [
            CoreTabItem(
              label: '계정',
              content: Padding(
                padding: const CoreEdgeInsets.all(CoreSpace.space20).toValue(geometry: Theme.of(context).geometry),
                child: Text(
                  '계정 설정을 관리해요.',
                ).bodyMedium.onSurfaceVariant,
              ),
            ),
            CoreTabItem(
              label: '비밀번호',
              content: Padding(
                padding: const CoreEdgeInsets.all(CoreSpace.space20).toValue(geometry: Theme.of(context).geometry),
                child: Text('여기에서 비밀번호를 바꿔요.').bodyMedium.onSurfaceVariant,
              ),
            ),
          ],
          selectedIndex: _index,
          onChanged: (i) => setState(() => _index = i),
        ).withStyle(
          const CoreTabPaneStyle(
            backgroundColor: CoreColor.token(CoreColors.tertiary),
            borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
            borderWidth: CoreStrokeWidth.stroke2,
          ),
        ),
      ],
    );
  }
}
