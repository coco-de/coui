/// Menu 페이지의 미리보기 — Flutter.
///
/// 속성 빌더는 `<Preview props>` · `<SizeSpec>` · 플레이그라운드가, 장면은
/// `<Preview demo="menu/...">` 가 읽는다. 같은 이름의 Web 파일(`menu_web.dart`)과
/// 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
library;

import 'package:coui_flutter/coui_flutter.dart';

import '../../previews/props/flutter_prop_previews.dart';
import 'menu_page.dart';

/// 속성 → Widget.
///
/// `Menu` 는 checkbox · radio 의 값을 기억하지 않으므로 빌더가 기억한다 — Web
/// 빌더와 같다.
FlutterPropPreviewBuilder? get propPreview =>
    (props, _) => _MenuPreview(props: props);

/// 장면 이름(`menu/<장면>`) → 장면.
final Map<String, Widget Function()> demos = {
  'menu/anatomy': () => _menu(MenuPreviewList.anatomy),
  'menu/selection': () => _row([_menu(MenuPreviewList.radioDot), _menu(MenuPreviewList.radioCheck)]),
  'menu/description': () => _menu(MenuPreviewList.description),
  'menu/standard-actions': () => _menu(MenuPreviewList.standardActions),
  'menu/critical': () => _menu(MenuPreviewList.critical),
  'menu/submenu': () => _menu(MenuPreviewList.submenu),
  'menu/divider-gap': () => _menu(MenuPreviewList.dividerGap),
  'menu/states': () => _menu(MenuPreviewList.states),
  'menu/horizontal': () => _menu(MenuPreviewList.horizontal, vertical: false),
  'menu/do-critical-last': () => _menu(MenuPreviewList.criticalLast),
  'menu/dont-critical-middle': () => _menu(MenuPreviewList.criticalMiddle),
  'menu/do-leading-aligned': () => _menu(MenuPreviewList.leadingAligned),
  'menu/dont-leading-mixed': () => _menu(MenuPreviewList.leadingMixed),
  'menu/related-menu-item': () => SizedBox(
    width: 208,
    child: MenuItem(
      leading: const Icon(LucideIcons.pencil),
      label: const Text('이름 바꾸기'),
      shortcut: const Text('F2'),
      onPressed: () {},
    ),
  ),
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
      child: Padding(
        padding: const EdgeInsets.all(CoreSpace.space16),
        child: const Text('우클릭 영역').bodyMedium,
      ),
    ),
  ),
  'menu/related-menubar': () => const Menubar(
    menus: [
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
Widget _menu(MenuPreviewList list, {bool vertical = true}) =>
    Menu(ariaLabel: list.ariaLabel, vertical: vertical, items: menuItemsFor<Widget>(list));

/// 메뉴 여러 개를 나란히 — Web 과 같이 폭이 모자라면 아래로 넘어간다.
Widget _row(List<Widget> menus) => Wrap(
  alignment: WrapAlignment.center,
  spacing: CoreSpace.space24,
  runSpacing: CoreSpace.space24,
  children: menus,
);

class _MenuPreview extends StatefulWidget {
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
  Widget build(BuildContext context) {
    final props = widget.props;
    return Menu(
      ariaLabel: menuPreviewAriaLabel,
      size: menuPreviewSize(props),
      items: menuPreviewItems<Widget>(
        props,
        autoSave: _autoSave,
        density: _density,
        onAutoSave: _handleAutoSave,
        onDensity: _handleDensity,
      ),
    );
  }
}
