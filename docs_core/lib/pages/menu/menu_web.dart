/// Menu 페이지의 미리보기 — Jaspr Web.
///
/// 속성 빌더는 `<Preview props>` · `<SizeSpec>` · 플레이그라운드가, 장면은
/// `<Preview demo="menu/...">` 가 읽는다. 같은 이름의 Flutter 파일(`menu_flutter.dart`)과
/// 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
library;

import 'package:coui_web/coui_web.dart';

import '../../previews/props/web_prop_previews.dart';
import 'menu_page.dart';

/// 속성 → Component.
///
/// `Menu` 는 checkbox · radio 의 값을 기억하지 않으므로 빌더가 기억한다.
/// 서버에서 그리는 블록에서는 처음 값만 보이고, 브라우저에서 깨어나는
/// 플레이그라운드에서는 줄을 눌러 값을 바꿀 수 있다.
WebPropPreviewBuilder? get propPreview =>
    (props, _) => _MenuPreview(props: props);

/// 장면 이름(`menu/<장면>`) → 장면.
final Map<String, Component Function()> demos = {
  'menu/anatomy': () => _menu(MenuPreviewList.anatomy),
  'menu/selection': () => _row([_menu(MenuPreviewList.radioDot), _menu(MenuPreviewList.radioCheck)]),
  'menu/description': () => _menu(MenuPreviewList.description),
  'menu/standard-actions': () => _menu(MenuPreviewList.standardActions),
  'menu/critical': () => _menu(MenuPreviewList.critical),
  'menu/submenu': () => _menu(MenuPreviewList.submenu),
  'menu/divider-gap': () => _menu(MenuPreviewList.dividerGap),
  'menu/states': () => _menu(MenuPreviewList.states),
  // 내용 폭으로 줄어드는 무대에서는 Web 가로 메뉴의 라벨이 글자 단위로 꺾인다(페이지의 알려진 제약).
  // 폭을 정한 블록 상자에 놓아 줄이 폭을 나눠 갖게 한다.
  'menu/horizontal': () => div(
    styles: Styles(raw: {'width': '18rem', 'max-width': '100%'}),
    [_menu(MenuPreviewList.horizontal, vertical: false)],
  ),
  'menu/do-critical-last': () => _menu(MenuPreviewList.criticalLast),
  'menu/dont-critical-middle': () => _menu(MenuPreviewList.criticalMiddle),
  'menu/do-leading-aligned': () => _menu(MenuPreviewList.leadingAligned),
  'menu/dont-leading-mixed': () => _menu(MenuPreviewList.leadingMixed),
  'menu/related-menu-item': () => div(styles: Styles(raw: {'width': '13rem', 'max-width': '100%'}), [
    MenuItem(
      leading: Icon(LucideIcons.pencil),
      label: const Text('이름 바꾸기'),
      shortcut: const Text('F2'),
      onPressed: () {},
    ),
  ]),
  'menu/related-dropdown-menu': () => DropdownMenu(
    trigger: Button(variant: CoreButtonVariant.outline, onPressed: () {}, child: const Text('작업')),
    items: [
      CoreMenuItem.action('복제', onPressed: () {}),
      CoreMenuItem.action('삭제', onPressed: () {}),
    ],
  ),
  'menu/related-context-menu': () => ContextMenu(
    items: [
      CoreMenuItem.action('복사', onPressed: () {}),
      CoreMenuItem.action('붙여넣기', onPressed: () {}),
    ],
    child: OutlinedContainer(
      child: div(styles: Styles(raw: {'padding': '1rem'}), [const Text('우클릭 영역').bodyMedium]),
    ),
  ),
  'menu/related-menubar': () => Menubar(
    menus: const [
      CoreMenubarMenu(label: '파일'),
      CoreMenubarMenu(label: '편집'),
      CoreMenubarMenu(label: '보기'),
    ],
  ),
  'menu/related-popover': () => Popover(
    trigger: Button(variant: CoreButtonVariant.outline, onPressed: () {}, child: const Text('필터')),
    content: const Text('원하는 내용을 담습니다.'),
  ),
};

/// 장면의 메뉴 하나.
Component _menu(MenuPreviewList list, {bool vertical = true}) =>
    Menu(ariaLabel: list.ariaLabel, vertical: vertical, items: menuItemsFor<Component>(list));

/// 메뉴 여러 개를 나란히 — 폭이 모자라면 아래로 넘어간다.
Component _row(List<Component> menus) => div(
  styles: Styles(
    raw: {
      'display': 'flex',
      'flex-wrap': 'wrap',
      'justify-content': 'center',
      'align-items': 'flex-start',
      'gap': '1.5rem',
      'width': '100%',
    },
  ),
  menus,
);

class _MenuPreview extends StatefulComponent {
  const _MenuPreview({required this.props});

  final Map<String, String> props;

  @override
  State<_MenuPreview> createState() => _MenuPreviewState();
}

class _MenuPreviewState extends State<_MenuPreview> {
  bool _autoSave = true;
  String _density = menuPreviewDefaultDensity;

  void _handleAutoSave(bool value) => setState(() => _autoSave = value);

  void _handleDensity(String value) => setState(() => _density = value);

  @override
  Component build(BuildContext context) {
    final props = component.props;
    return Menu(
      ariaLabel: menuPreviewAriaLabel,
      size: menuPreviewSize(props),
      items: menuPreviewItems<Component>(
        props,
        autoSave: _autoSave,
        density: _density,
        onAutoSave: _handleAutoSave,
        onDensity: _handleDensity,
      ),
    );
  }
}
