/// Menubar 페이지의 미리보기 — Jaspr Web.
///
/// 속성 빌더는 `<Preview props>` · `<Card>` · 플레이그라운드가, 장면은
/// `<Preview demo="menubar/...">` 가 읽는다. 같은 이름의 Flutter 파일
/// (`menubar_flutter.dart`)과 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
///
/// 열린 메뉴는 그림이다. `Menubar` 의 패널은 누르면 오버레이 호스트의 메뉴 층에
/// 떠서, 무대에 연 채로 둘 수 없다. 그림의 막대는 `resolveMenubar` 가 낸 값(테마
/// 포함)으로 그리고, 트리거는 킷의 `Button`, 패널은 `Menubar` 가 패널을 그릴 때
/// 쓰는 `Menu` 에 같은 패널 스타일을 준 것이다. 실제 `Menubar` 는 플레이그라운드의
/// 그림 아래에 둔다.
library;

import 'package:coui_web/coui_web.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/web_prop_previews.dart';
import 'menubar_page.dart' as page;

/// 속성 → Component.
WebPropPreviewBuilder? get propPreview => _menubar;

/// 장면 이름(`menubar/<장면>`) → 장면.
final Map<String, Component Function()> demos = {
  'menubar/anatomy': () => _openPicture(page.demoMenus(const {'shortcut': 'true'})),
  'menubar/entries': () => _panelScene(page.demoEntriesMenu),
  'menubar/bordered': () => _hug(Menubar(menus: page.demoMenus(const {'shortcut': 'true'}))),
  'menubar/borderless': () => _hug(Menubar(menus: page.demoMenus(const {'shortcut': 'true'}), border: false)),
  'menubar/states': () => _hug(
    Builder(
      builder: (context) => _barPicture(
        resolveMenubar(context, variant: CoreMenubarVariant.standard, border: true),
        page.demoMenus(const {}),
        openIndex: 1,
      ),
    ),
  ),
  'menubar/do-group': () => _panelScene(page.demoGroupedMenu),
  'menubar/dont-flat': () => _panelScene(page.demoUngroupedMenu),
  'menubar/do-shortcut': () => _panelScene(page.demoShortcutMenu),
  'menubar/dont-mobile-nav': () => _hug(Menubar(menus: page.demoMobileNavMenus)),
};

/// 속성으로 고른 그림. `opener` 를 켜면 그림 아래에 같은 속성의 실제 `Menubar` 를
/// 둔다 — 트리거를 누르면 패널이 열린다.
Component _menubar(Map<String, String> props, String? label) {
  final menus = page.demoMenus(props);
  final border = page.demoBorder(props);
  final picture = _openPicture(menus, border: border);
  if (!previewFlag(props, 'opener')) return picture;
  return div(
    styles: Styles(
      raw: {
        'display': 'flex',
        'flex-direction': 'column',
        'align-items': 'center',
        'gap': spaceCss(page.demoOpenerGap),
        'width': '100%',
      },
    ),
    [picture, Menubar(menus: menus, border: border)],
  );
}

/// 첫 메뉴가 열린 그림 — 막대와, 그 아래 첫 트리거의 왼쪽 끝에 맞춘 패널.
Component _openPicture(List<CoreMenubarMenu> menus, {bool border = true}) => Builder(
  builder: (context) {
    final resolved = resolveMenubar(context, variant: CoreMenubarVariant.standard, border: border);
    return div(
      styles: Styles(
        raw: {
          'display': 'inline-flex',
          'flex-direction': 'column',
          'align-items': 'flex-start',
          'gap': pinnedLengthCss(CoreMenubarStyle.defaultMenuOffset),
        },
      ),
      [
        _barPicture(resolved, menus, openIndex: 0),
        div(
          styles: Styles(raw: {'padding-left': spaceCss(CoreMenubarStyle.defaultBarPadding.left)}),
          [_panelPicture(resolved, menus.first)],
        ),
      ],
    );
  },
);

/// 막대의 그림 — [openIndex] 번째 트리거는 메뉴가 열린 모양이다. 트리거는 메뉴
/// 막대의 역할을 붙이지 않은 킷의 `Button` 이다.
Component _barPicture(ResolvedMenubar resolved, List<CoreMenubarMenu> menus, {required int openIndex}) => div(
  attributes: const {'data-docs-part': 'bar'},
  classes: resolved.root.className,
  styles: resolved.root.inlineStyles,
  [
    for (final (index, menu) in menus.indexed) _triggerPicture(resolved, menu.label, open: index == openIndex),
  ],
);

Component _triggerPicture(ResolvedMenubar resolved, String label, {required bool open}) => Button(
  variant: CoreButtonVariant.menubar,
  buttonStyle: open ? resolved.openTriggerButtonStyle : resolved.triggerButtonStyle,
  attributes: {'data-docs-part': open ? 'open-trigger' : 'trigger', if (open) 'aria-selected': 'true'},
  onPressed: () {},
  child: Text(label),
);

/// 패널의 그림 — `Menubar` 처럼 [menu] 의 항목을 같은 패널 스타일의 `Menu` 에
/// 넣는다.
Component _panelPicture(ResolvedMenubar resolved, CoreMenubarMenu menu) => div(
  attributes: const {'data-docs-part': 'panel'},
  [
    Menu(
      items: page.demoPanelItems<Component>(menu),
      menuStyle: CoreMenuStyle(popupStyle: resolved.menuPanelStyle),
    ),
  ],
);

/// 패널 하나만 보이는 장면.
Component _panelScene(CoreMenubarMenu menu) => _hug(
  Builder(
    builder: (context) =>
        _panelPicture(resolveMenubar(context, variant: CoreMenubarVariant.standard, border: true), menu),
  ),
);

/// 내용의 폭만큼만 차지한다. Web 의 막대는 블록 부모의 폭을 채우므로, 장면은
/// Flutter 처럼 트리거의 폭만큼 보이게 감싼다.
Component _hug(Component child) => div(styles: Styles(raw: {'width': 'fit-content', 'max-width': '100%'}), [child]);
