/// Popup 페이지의 미리보기 — Flutter.
///
/// 속성 빌더는 `<Preview props>` · 플레이그라운드가, 장면은
/// `<Preview demo="popup/...">` · `<Card demo="popup/...">` 가 읽는다. 같은
/// 이름의 Web 파일(`popup_web.dart`)과 컴포넌트 · 속성 · 장면 이름이 같아야
/// 한다.
///
/// `Popup` 은 놓은 자리에 그려지므로 모든 장면이 실제 위젯이다.
library;

import 'package:coui_flutter/coui_flutter.dart';

import '../../previews/props/flutter_prop_previews.dart';
import 'popup_page.dart' as page;

/// 속성 → Widget.
FlutterPropPreviewBuilder? get propPreview => _popup;

/// 장면 이름(`popup/<장면>`) → 장면.
final Map<String, Widget Function()> demos = {
  'popup/anatomy': () => _listPanel(_rows()),
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

Widget _popup(Map<String, String> props, String? label) => Popup(
  direction: page.popupPreviewDirection(props),
  popupStyle: page.popupPreviewStyle(props),
  children: _actions(),
);

/// 속성 미리보기의 버튼 줄.
List<Widget> _actions() => [
  for (final (_, text) in page.popupDemoActions)
    Button(variant: CoreButtonVariant.ghost, size: CoreComponentSize.sm, onPressed: () {}, child: Text(text)),
];

/// 목록 패널의 행 — `Menu` 가 자기 행에 주는 모서리를 쓴다.
List<Widget> _rows() => [
  for (final text in page.popupDemoRows)
    MenuItem(label: Text(text), menuItemStyle: CoreMenuStyle.defaultItemStyle, onPressed: () {}),
];

Widget _listPanel(List<Widget> rows) => Popup(popupStyle: page.popupDemoListStyle, children: rows);

/// 자유 형식 내용 — 제목 · 설명 · 버튼.
List<Widget> _notice() => [
  Text(page.popupDemoNoticeTitle).titleSmall,
  const Gap.space4(),
  Text(page.popupDemoNoticeBody).bodySmall.onSurfaceVariant,
  const Gap.space12(),
  Button(size: CoreComponentSize.sm, onPressed: () {}, child: Text(page.popupDemoNoticeAction)),
];

/// 자기 패널을 그리는 `Menu`.
Widget _menu() => Menu(
  items: [
    for (final text in page.popupDemoRows) CoreMenuItem.action(text, onPressed: () {}),
  ],
);

/// 패널 두 개를 나란히 — 폭이 모자라면 아래로 넘어간다.
Widget _pair(List<Widget> children) =>
    Wrap(spacing: CoreSpace.space24, runSpacing: CoreSpace.space24, children: children);

/// 위에 이름을 단 장면 조각.
Widget _captioned(String caption, Widget child) => Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [Text(caption).labelSmall.onSurfaceVariant, const Gap.space8(), child],
);
