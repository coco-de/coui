/// ToolbarGroup 페이지의 미리보기 — Jaspr Web.
///
/// 속성 빌더는 `<Preview props>` · 플레이그라운드가, 장면은
/// `<Preview demo="toolbar-group/...">` · `<Card demo="toolbar-group/...">` 가
/// 읽는다. 같은 이름의 Flutter 파일(`toolbar_group_flutter.dart`)과 컴포넌트 ·
/// 속성 · 장면 이름이 같아야 한다.
///
/// Web 의 `ToolbarGroup` 은 블록 부모에서 부모 폭을 채운다. 그래서 장면의
/// 그룹은 늘 내용 폭이 되는 자리(가운데 정렬 flex 무대, [_row] · [_captioned])
/// 에 둔다.
library;

import 'package:coui_web/coui_web.dart';

import '../../previews/props/web_prop_previews.dart';
import 'toolbar_group_page.dart' as page;

/// 속성 → Component.
WebPropPreviewBuilder? get propPreview => _toolbarGroup;

/// 장면 이름(`toolbar-group/<장면>`) → 장면.
final Map<String, Component Function()> demos = {
  'toolbar-group/anatomy': () => _group(_actions(marked: true)),
  'toolbar-group/direction': () => _pair([
    _captioned('horizontal', _group(_actions())),
    _captioned('vertical', _group(_actions(), direction: CoreAxis.vertical)),
  ]),
  'toolbar-group/surface': () => _pair([
    _captioned('불투명', _group(_actions(), popupStyle: page.toolbarDemoOpaqueStyle)),
    _captioned('Liquid Glass', _group(_actions(), popupStyle: page.toolbarDemoGlassStyle)),
    _captioned(
      'Liquid Glass 세로',
      _group(_actions(), direction: CoreAxis.vertical, popupStyle: page.toolbarDemoGlassStyle),
    ),
  ]),
  'toolbar-group/disabled': () => _group([
    _action('실행 취소', LucideIcons.undo2),
    _action('다시 실행', LucideIcons.redo2, enabled: false),
  ]),
  'toolbar-group/bar-actions': () => _pair([
    _captioned('가로 그룹', _group(_barActions())),
    _captioned('세로 그룹', _group(_barActions(), direction: CoreAxis.vertical)),
  ]),
  'toolbar-group/do-split': () => _row([
    _group(_history(), label: '편집 기록'),
    _group(_zoom(), label: '배율'),
  ]),
  'toolbar-group/dont-merged': () => _group([..._history(), ..._zoom()]),
  'toolbar-group/do-ghost': () => _group([_textButton('축소'), _textButton('확대')], label: '배율'),
  'toolbar-group/dont-filled': () => _group([
    _textButton('축소', variant: CoreButtonVariant.primary),
    _textButton('확대', variant: CoreButtonVariant.primary),
  ], label: '배율'),
};

Component _toolbarGroup(Map<String, String> props, String? label) => _group(
  _actions(),
  direction: page.toolbarPreviewDirection(props),
  popupStyle: page.toolbarPreviewStyle(props),
);

Component _group(
  List<Component> children, {
  String label = page.toolbarDemoLabel,
  CoreAxis direction = CoreAxis.horizontal,
  CorePopupStyle? popupStyle,
}) => ToolbarGroup(ariaLabel: label, direction: direction, popupStyle: popupStyle, children: children);

/// 속성 미리보기의 아이콘 버튼. [marked] 면 첫 버튼에 구조 블록이 번호를 붙일
/// 표지를 단다.
List<Component> _actions({bool marked = false}) => [
  for (final (index, (_, name, icon)) in page.toolbarDemoActions.indexed)
    _action(name, icon, marked: marked && index == 0),
];

/// 이름을 가진 아이콘 버튼.
Component _action(String name, IconName icon, {bool marked = false, bool enabled = true}) => Button(
  variant: CoreButtonVariant.ghost,
  shape: CoreButtonShape.square,
  enabled: enabled,
  onPressed: () {},
  attributes: {'aria-label': name, if (marked) 'data-docs-part': 'control'},
  child: Icon(icon),
);

Component _textButton(String text, {CoreButtonVariant variant = CoreButtonVariant.ghost}) =>
    Button(variant: variant, onPressed: () {}, child: Text(text));

/// 바의 동작 목록 — 아이콘 동작, 바에 남는 글자 동작, 따로 묶은 그룹.
List<Component> _barActions() => [
  _action('뒤로', LucideIcons.chevronLeft),
  BarAction(axisBehavior: CoreBarActionAxisBehavior.horizontalOnly, child: _textButton('편집')),
  _group([_action('공유', LucideIcons.share), _action('더 보기', LucideIcons.ellipsis)], label: '공유와 더 보기'),
];

List<Component> _history() => [_action('실행 취소', LucideIcons.undo2), _action('다시 실행', LucideIcons.redo2)];

List<Component> _zoom() => [_action('축소', LucideIcons.zoomOut), _action('확대', LucideIcons.zoomIn)];

/// 그룹 여러 개를 한 줄로.
Component _row(List<Component> children) => div(
  styles: Styles(raw: {'display': 'flex', 'align-items': 'center', 'gap': spaceCss(CoreSpace.space12)}),
  children,
);

/// 장면 조각 여러 개를 나란히 — 폭이 모자라면 아래로 넘어간다.
Component _pair(List<Component> children) => div(
  styles: Styles(
    raw: {
      'display': 'flex',
      'flex-wrap': 'wrap',
      'justify-content': 'center',
      'align-items': 'flex-start',
      'gap': spaceCss(CoreSpace.space32),
    },
  ),
  children,
);

/// 위에 이름을 단 장면 조각.
Component _captioned(String caption, Component child) => div(
  styles: Styles(raw: {'display': 'flex', 'flex-direction': 'column', 'align-items': 'center'}),
  [Text(caption).labelSmall.onSurfaceVariant, const Gap.space8(), child],
);
