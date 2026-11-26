/// Returns a Web code snippet string for the NavigationBar component.
String navigationBarCode(String? variant) {
  return switch (variant) {
    'chain' => _chainCode,
    'rail' => _railCode,
    'sidebar' => _sidebarCode,
    'compact' => _compactCode,
    'text-tabs' => _textTabsCode,
    _ => _defaultCode,
  };
}

const String _chainCode = '''
class NavigationBarChainExample extends StatefulComponent {
  const NavigationBarChainExample({super.key});

  @override
  State<NavigationBarChainExample> createState() => _NavigationBarChainExampleState();
}

class _NavigationBarChainExampleState extends State<NavigationBarChainExample> {
  int _selectedIndex = 0;

  @override
  Component build(BuildContext context) {
    return NavigationBar(
          mode: CoreNavigationBarMode.bar,
          selectedIndex: _selectedIndex,
          onSelected: (index) => setState(() => _selectedIndex = index),
          labelMode: CoreNavigationLabelMode.all,
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
              label: '프로필',
            ),
          ],
        )
        .withStyle(
          const CoreNavigationBarStyle(
            itemSpacing: CoreSpace.space12,
            itemPadding: CoreEdgeInsets.all(CoreSpace.space12),
            itemRadius: CoreBorderRadius.all(CoreRadius.radius16),
          ),
        )
        .surfaceContainer;
  }
}''';

const String _defaultCode = '''
class NavigationBarDefaultExample extends StatefulComponent {
  const NavigationBarDefaultExample({super.key});

  @override
  State<NavigationBarDefaultExample> createState() =>
      _NavigationBarDefaultExampleState();
}

class _NavigationBarDefaultExampleState
    extends State<NavigationBarDefaultExample> {
  int _selectedIndex = 0;

  @override
  Component build(BuildContext context) {
    return NavigationBar(
      mode: CoreNavigationBarMode.bar,
      selectedIndex: _selectedIndex,
      onSelected: (index) => setState(() => _selectedIndex = index),
      labelMode: CoreNavigationLabelMode.all,
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
          label: '프로필',
        ),
      ],
    );
  }
}''';

const String _railCode = '''
class NavigationBarRailExample extends StatefulComponent {
  const NavigationBarRailExample({super.key});

  @override
  State<NavigationBarRailExample> createState() =>
      _NavigationBarRailExampleState();
}

class _NavigationBarRailExampleState extends State<NavigationBarRailExample> {
  int _selectedIndex = 0;

  @override
  Component build(BuildContext context) {
    return NavigationBar(
      mode: CoreNavigationBarMode.rail,
      selectedIndex: _selectedIndex,
      onSelected: (index) => setState(() => _selectedIndex = index),
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
          label: '프로필',
        ),
      ],
    );
  }
}''';

const String _sidebarCode = '''
class NavigationBarSidebarExample extends StatefulComponent {
  const NavigationBarSidebarExample({super.key});

  @override
  State<NavigationBarSidebarExample> createState() =>
      _NavigationBarSidebarExampleState();
}

// This example documents `mode: sidebar`, which `Sidebar` replaces; it
// stays (and is announced with the mode) until the mode is removed.
@Deprecated('Use Sidebar (since 0.164) — this shows the announced mode.')
class _NavigationBarSidebarExampleState
    extends State<NavigationBarSidebarExample> {
  int _selectedIndex = 0;

  @override
  Component build(BuildContext context) {
    return NavigationBar(
      mode: CoreNavigationBarMode.sidebar,
      selectedIndex: _selectedIndex,
      onSelected: (index) => setState(() => _selectedIndex = index),
      items: const [
        CoreNavigationBarItem.label('메인'),
        CoreNavigationBarItem.destination(
          icon: Icon(LucideIcons.house),
          label: '대시보드',
        ),
        CoreNavigationBarItem.destination(
          icon: Icon(LucideIcons.search),
          label: '탐색',
        ),
        CoreNavigationBarItem.divider(),
        CoreNavigationBarItem.label('계정'),
        CoreNavigationBarItem.destination(
          icon: Icon(LucideIcons.bell),
          label: '알림',
          badge: Badge(
            form: CoreBadgeForm.count,
            tone: CoreBadgeTone.info,
            variant: CoreBadgeVariant.filled,
            size: CoreComponentSize.xs,
            child: Text('3'),
          ),
        ),
        CoreNavigationBarItem.destination(
          icon: Icon(LucideIcons.settings),
          label: '설정',
        ),
      ],
      footer: const Text('무료 플랜 · 좌석 5개 중 3개 사용').labelMedium.onSurfaceVariant,
    );
  }
}''';

const String _textTabsCode = '''
class NavigationBarTextTabsExample extends StatefulComponent {
  const NavigationBarTextTabsExample({super.key});

  @override
  State<NavigationBarTextTabsExample> createState() => _NavigationBarTextTabsExampleState();
}

class _NavigationBarTextTabsExampleState extends State<NavigationBarTextTabsExample> {
  int _selectedIndex = 0;

  @override
  Component build(BuildContext context) {
    // Bare-label tabs: no icons, every label shown, and a dot over the
    // selected one. Every tab keeps the dot's room, so the labels stay level.
    return NavigationBar(
      mode: CoreNavigationBarMode.bar,
      selectedIndex: _selectedIndex,
      onSelected: (index) => setState(() => _selectedIndex = index),
      labelMode: CoreNavigationLabelMode.all,
      selectionMark: CoreNavigationSelectionMark.dot,
      items: const [
        CoreNavigationBarItem.destination(label: '홈'),
        CoreNavigationBarItem.destination(label: '지도'),
        CoreNavigationBarItem.destination(label: '채팅'),
        CoreNavigationBarItem.destination(label: '내 정보'),
      ],
    );
  }
}''';

const String _compactCode = '''
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
                  classes: 'py-\${CoreSpace.scale.space16}',
                ),
            ],
            classes: 'flex flex-col p-\${CoreSpace.scale.space16}',
          ),
        ),
      ],
      classes: 'w-full overflow-y-auto',
      styles: Styles(raw: const {'height': '\${384 / 16}rem'}),
    );
  }
}''';
