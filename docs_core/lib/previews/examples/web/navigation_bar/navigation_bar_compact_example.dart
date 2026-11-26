import 'package:coui_web/coui_web.dart';

class NavigationBarCompactExample extends StatefulComponent {
  const NavigationBarCompactExample({super.key});

  @override
  State<NavigationBarCompactExample> createState() => _NavigationBarCompactExampleState();
}

class _NavigationBarCompactExampleState extends State<NavigationBarCompactExample> {
  static const _posts = [
    '아침 산책에서 찍은 사진',
    '주말에 다녀온 전시',
    '새로 들인 화분',
    '동네 빵집의 신메뉴',
    '비 오는 날의 창가',
    '퇴근길 노을',
    '오랜만에 만난 친구',
    '직접 만든 저녁',
    '책장 정리를 마쳤어요',
    '첫 자전거 출근',
    '한강에서 본 야경',
    '고양이의 낮잠 자리',
    '여행 계획을 세우는 중',
    '새 운동화 개시',
    '옥상에서 본 일출',
    '올해의 첫 눈',
  ];

  int _selectedIndex = 0;

  @override
  Component build(BuildContext context) {
    // The bar floats over a body that scrolls. Scrolling the list toward its
    // end draws the bar compact; scrolling back, or reaching the top, returns
    // it. The Web scaffold grows with its content and scrolls in whatever
    // holds it, so the fixed-height frame is the scrollport the bar follows
    // (the Flutter twin's scaffold scrolls its own body). Under liquid glass
    // the bar is the floating capsule — the form that has a compact size.
    return div(
      [
        Scaffold(
          floatingFooter: true,
          footers: [
            NavigationBar(
              selectedIndex: _selectedIndex,
              onSelected: (index) => setState(() => _selectedIndex = index),
              compact: CoreNavigationCompact.onScroll,
              navigationBarStyle: const CoreNavigationBarStyle(
                surfaceStyle: CoreSurfaceStyleId.liquidGlass,
              ),
              items: const [
                CoreNavigationBarItem.destination(
                  icon: Icon(LucideIcons.house),
                  label: '홈',
                ),
                CoreNavigationBarItem.destination(
                  icon: Icon(LucideIcons.search),
                  label: '검색',
                ),
                CoreNavigationBarItem.destination(
                  icon: Icon(LucideIcons.bell),
                  label: '알림',
                ),
                CoreNavigationBarItem.destination(
                  icon: Icon(LucideIcons.user),
                  label: '내 정보',
                ),
              ],
            ),
          ],
          child: div(
            [
              for (final post in _posts)
                div(
                  [Text(post).bodyMedium],
                  classes: 'py-${CoreSpace.scale.space16}',
                ),
            ],
            classes: 'flex flex-col p-${CoreSpace.scale.space16}',
          ),
        ),
      ],
      classes: 'w-full overflow-y-auto',
      styles: Styles(raw: const {'height': '${384 / 16}rem'}),
    );
  }
}
