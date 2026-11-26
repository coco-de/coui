/// ToolbarGroup 페이지의 미리보기 — Flutter.
///
/// 속성 빌더는 `<Preview props>` · 플레이그라운드가, 장면은
/// `<Preview demo="toolbar-group/...">` · `<Card demo="toolbar-group/...">` 가
/// 읽는다. 같은 이름의 Web 파일(`toolbar_group_web.dart`)과 컴포넌트 · 속성 ·
/// 장면 이름이 같아야 한다.
library;

import 'package:coui_flutter/coui_flutter.dart';

import '../../previews/props/flutter_prop_previews.dart';
import 'toolbar_group_page.dart' as page;

/// 속성 → Widget.
FlutterPropPreviewBuilder? get propPreview => _toolbarGroup;

/// 장면 이름(`toolbar-group/<장면>`) → 장면.
final Map<String, Widget Function()> demos = {
  'toolbar-group/anatomy': () => _group(_actions()),
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

Widget _toolbarGroup(Map<String, String> props, String? label) => _group(
  _actions(),
  direction: page.toolbarPreviewDirection(props),
  popupStyle: page.toolbarPreviewStyle(props),
);

Widget _group(
  List<Widget> children, {
  String label = page.toolbarDemoLabel,
  CoreAxis direction = CoreAxis.horizontal,
  CorePopupStyle? popupStyle,
}) => ToolbarGroup(ariaLabel: label, direction: direction, popupStyle: popupStyle, children: children);

/// 속성 미리보기의 아이콘 버튼.
List<Widget> _actions() => [
  for (final (_, name, icon) in page.toolbarDemoActions) _action(name, icon),
];

/// 이름을 가진 아이콘 버튼.
Widget _action(String name, IconName icon, {bool enabled = true}) => Semantics(
  label: name,
  child: Button(
    variant: CoreButtonVariant.ghost,
    shape: CoreButtonShape.square,
    enabled: enabled,
    onPressed: () {},
    child: Icon(icon),
  ),
);

Widget _textButton(String text, {CoreButtonVariant variant = CoreButtonVariant.ghost}) =>
    Button(variant: variant, onPressed: () {}, child: Text(text));

/// 바의 동작 목록 — 아이콘 동작, 바에 남는 글자 동작, 따로 묶은 그룹.
List<Widget> _barActions() => [
  _action('뒤로', LucideIcons.chevronLeft),
  BarAction(axisBehavior: CoreBarActionAxisBehavior.horizontalOnly, child: _textButton('편집')),
  _group([_action('공유', LucideIcons.share), _action('더 보기', LucideIcons.ellipsis)], label: '공유와 더 보기'),
];

List<Widget> _history() => [_action('실행 취소', LucideIcons.undo2), _action('다시 실행', LucideIcons.redo2)];

List<Widget> _zoom() => [_action('축소', LucideIcons.zoomOut), _action('확대', LucideIcons.zoomIn)];

/// 그룹 여러 개를 한 줄로.
Widget _row(List<Widget> children) =>
    Row(mainAxisSize: MainAxisSize.min, spacing: CoreSpace.space12, children: children);

/// 장면 조각 여러 개를 나란히 — 폭이 모자라면 아래로 넘어간다.
Widget _pair(List<Widget> children) =>
    Wrap(spacing: CoreSpace.space32, runSpacing: CoreSpace.space32, children: children);

/// 위에 이름을 단 장면 조각.
Widget _captioned(String caption, Widget child) => Column(
  mainAxisSize: MainAxisSize.min,
  children: [Text(caption).labelSmall.onSurfaceVariant, const Gap.space8(), child],
);
