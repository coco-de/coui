/// Popup 페이지의 미리보기 — Jaspr Web.
///
/// 속성 빌더는 `<Preview props>` · 플레이그라운드가, 장면은
/// `<Preview demo="popup/...">` · `<Card demo="popup/...">` 가 읽는다. 같은
/// 이름의 Flutter 파일(`popup_flutter.dart`)과 컴포넌트 · 속성 · 장면 이름이
/// 같아야 한다.
///
/// `Popup` 은 놓은 자리에 그려지므로 모든 장면이 실제 위젯이다. 상한이 없는
/// `Popup` 은 블록 부모의 폭을 채운다. 패널 하나인 장면은 문서 무대의 flex 가
/// 내용 폭으로 두고, 둘을 나란히 놓는 장면(`_pair` · `_captioned`)은
/// `align-items: flex-start` flex 부모를 직접 만든다.
library;

import 'package:coui_web/coui_web.dart';

import '../../previews/props/web_prop_previews.dart';
import 'popup_page.dart' as page;

/// 속성 → Component.
WebPropPreviewBuilder? get propPreview => _popup;

/// 장면 이름(`popup/<장면>`) → 장면.
final Map<String, Component Function()> demos = {
  'popup/anatomy': () => _listPanel(_rows(marked: true)),
  'popup/padding': () => _pair([
    _captioned('내용 16 (기본)', Popup(children: _notice())),
    _captioned('목록 6', _listPanel(_rows())),
  ]),
  'popup/direction': () => _pair([
    _captioned('vertical', Popup(popupStyle: page.popupDemoListStyle, children: _actions())),
    _captioned(
      'horizontal',
      Popup(direction: CoreAxis.horizontal, popupStyle: page.popupDemoListStyle, children: _actions()),
    ),
  ]),
  'popup/do-list-padding': () => _listPanel(_rows()),
  'popup/dont-list-padding': () => Popup(children: _rows()),
  'popup/do-menu': () => _menu(),
  'popup/dont-double-panel': () => Popup(children: [_menu()]),
};

Component _popup(Map<String, String> props, String? label) => Popup(
  direction: page.popupPreviewDirection(props),
  popupStyle: page.popupPreviewStyle(props),
  children: _actions(),
);

/// 속성 미리보기의 버튼 줄.
List<Component> _actions() => [
  for (final (_, text) in page.popupDemoActions)
    Button(variant: CoreButtonVariant.ghost, size: CoreComponentSize.sm, onPressed: () {}, child: Text(text)),
];

/// 목록 패널의 행 — `Menu` 가 자기 행에 주는 모서리를 쓴다. [marked] 면 첫 행에
/// 구조 블록이 번호를 붙일 표지를 단다.
List<Component> _rows({bool marked = false}) => [
  for (final (index, text) in page.popupDemoRows.indexed)
    MenuItem(
      label: Text(text),
      menuItemStyle: CoreMenuStyle.defaultItemStyle,
      attributes: marked && index == 0 ? const {'data-docs-part': 'item'} : null,
      onPressed: () {},
    ),
];

Component _listPanel(List<Component> rows) => Popup(popupStyle: page.popupDemoListStyle, children: rows);

/// 자유 형식 내용 — 제목 · 설명 · 버튼.
List<Component> _notice() => [
  Text(page.popupDemoNoticeTitle).titleSmall,
  const Gap.space4(),
  Text(page.popupDemoNoticeBody).bodySmall.onSurfaceVariant,
  const Gap.space12(),
  Button(size: CoreComponentSize.sm, onPressed: () {}, child: Text(page.popupDemoNoticeAction)),
];

/// 자기 패널을 그리는 `Menu`.
Component _menu() => Menu(
  items: [
    for (final text in page.popupDemoRows) CoreMenuItem.action(text, onPressed: () {}),
  ],
);

/// 패널 두 개를 나란히 — 폭이 모자라면 아래로 넘어간다.
Component _pair(List<Component> children) => div(
  styles: Styles(
    raw: {
      'display': 'flex',
      'flex-wrap': 'wrap',
      'justify-content': 'center',
      'align-items': 'flex-start',
      'gap': spaceCss(CoreSpace.space24),
    },
  ),
  children,
);

/// 위에 이름을 단 장면 조각.
Component _captioned(String caption, Component child) => div(
  styles: Styles(raw: {'display': 'flex', 'flex-direction': 'column', 'align-items': 'flex-start'}),
  [Text(caption).labelSmall.onSurfaceVariant, const Gap.space8(), child],
);
