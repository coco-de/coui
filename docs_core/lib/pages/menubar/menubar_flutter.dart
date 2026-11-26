/// Menubar 페이지의 미리보기 — Flutter.
///
/// 속성 빌더는 `<Preview props>` · `<Card>` · 플레이그라운드가, 장면은
/// `<Preview demo="menubar/...">` 가 읽는다. 같은 이름의 Web 파일
/// (`menubar_web.dart`)과 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
///
/// 열린 메뉴는 그림이다. `Menubar` 의 패널은 누르면 앱의 `Overlay` 에 떠서,
/// 무대에 연 채로 둘 수 없다. 그림의 막대는 `resolveMenubar` 가 낸 값(테마 포함)
/// 으로 그리고(유리 재질의 흐림은 그리지 않는다), 트리거는 킷의 `Button`, 패널은
/// `Menubar` 가 패널을 그릴 때 쓰는 `Menu` 에 같은 패널 스타일을 준 것이다. 실제
/// `Menubar` 는 플레이그라운드의 그림 아래에 둔다.
library;

import 'package:coui_flutter/coui_flutter.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/flutter_prop_previews.dart';
import 'menubar_page.dart' as page;

/// 속성 → Widget.
FlutterPropPreviewBuilder? get propPreview => _menubar;

/// 장면 이름(`menubar/<장면>`) → 장면.
final Map<String, Widget Function()> demos = {
  'menubar/anatomy': () => _OpenPicture(menus: page.demoMenus(const {'shortcut': 'true'})),
  'menubar/entries': () => const _PanelPicture(menu: page.demoEntriesMenu),
  'menubar/bordered': () => Menubar(menus: page.demoMenus(const {'shortcut': 'true'})),
  'menubar/borderless': () => Menubar(menus: page.demoMenus(const {'shortcut': 'true'}), border: false),
  'menubar/states': () => _BarPicture(menus: page.demoMenus(const {}), openIndex: 1),
  'menubar/do-group': () => const _PanelPicture(menu: page.demoGroupedMenu),
  'menubar/dont-flat': () => const _PanelPicture(menu: page.demoUngroupedMenu),
  'menubar/do-shortcut': () => const _PanelPicture(menu: page.demoShortcutMenu),
  'menubar/dont-mobile-nav': () => const Menubar(menus: page.demoMobileNavMenus),
};

/// 속성으로 고른 그림. `opener` 를 켜면 그림 아래에 같은 속성의 실제 `Menubar` 를
/// 둔다 — 트리거를 누르면 패널이 열린다.
Widget _menubar(Map<String, String> props, String? label) {
  final menus = page.demoMenus(props);
  final border = page.demoBorder(props);
  final picture = _OpenPicture(menus: menus, border: border);
  if (!previewFlag(props, 'opener')) return picture;
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      picture,
      const Gap(gapStyle: CoreGapStyle(size: page.demoOpenerGap)),
      Menubar(menus: menus, border: border),
    ],
  );
}

/// 첫 메뉴가 열린 그림 — 막대와, 그 아래 첫 트리거의 왼쪽 끝에 맞춘 패널.
class _OpenPicture extends StatelessWidget {
  const _OpenPicture({required this.menus, this.border = true});

  final List<CoreMenubarMenu> menus;
  final bool border;

  @override
  Widget build(BuildContext context) {
    final resolved = resolveMenubar(context, variant: CoreMenubarVariant.standard);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BarPicture(menus: menus, openIndex: 0, border: border),
        const Gap(gapStyle: CoreGapStyle(size: CoreMenubarStyle.defaultMenuOffset)),
        Padding(
          padding: EdgeInsets.only(left: resolved.barPadding.left),
          child: _PanelPicture(menu: menus.first),
        ),
      ],
    );
  }
}

/// 막대의 그림 — [openIndex] 번째 트리거는 메뉴가 열린 모양이다.
class _BarPicture extends StatelessWidget {
  const _BarPicture({required this.menus, required this.openIndex, this.border = true});

  final List<CoreMenubarMenu> menus;
  final int openIndex;
  final bool border;

  @override
  Widget build(BuildContext context) {
    final resolved = resolveMenubar(context, variant: CoreMenubarVariant.standard);
    final bar = Padding(
      padding: resolved.barPadding,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (index, menu) in menus.indexed) _triggerPicture(resolved, menu.label, open: index == openIndex),
        ],
      ),
    );
    if (!border) return bar;
    return DecoratedBox(
      decoration: BoxDecoration(
        boxShadow: resolved.boxShadow,
        color: resolved.barBackgroundColor,
        border: Border.all(color: resolved.barBorderColor, width: resolved.barBorderWidth),
        borderRadius: resolved.barBorderRadius,
      ),
      child: bar,
    );
  }
}

Widget _triggerPicture(ResolvedMenubar resolved, String label, {required bool open}) => Data.inherit(
  data: WidgetStatesData({if (open) WidgetState.selected}),
  child: Button(
    variant: CoreButtonVariant.menubar,
    buttonStyle: open ? resolved.openTriggerButtonStyle : resolved.triggerButtonStyle,
    disableFocusOutline: true,
    onPressed: () {},
    child: Text(label, style: open ? resolved.openLabelTextStyle : resolved.labelTextStyle),
  ),
);

/// 패널의 그림 — `Menubar` 처럼 [menu] 의 항목을 같은 패널 스타일의 `Menu` 에
/// 넣는다.
class _PanelPicture extends StatelessWidget {
  const _PanelPicture({required this.menu});

  final CoreMenubarMenu menu;

  @override
  Widget build(BuildContext context) {
    final resolved = resolveMenubar(context, variant: CoreMenubarVariant.standard);
    return Menu(
      items: page.demoPanelItems<Widget>(menu),
      menuStyle: CoreMenuStyle(popupStyle: resolved.menuPanelStyle),
    );
  }
}
