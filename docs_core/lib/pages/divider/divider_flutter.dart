/// Divider 페이지의 미리보기 — Flutter.
///
/// 속성 빌더는 `<Preview props>` · 플레이그라운드가, 장면은
/// `<Preview demo="divider/...">` 가 읽는다. 같은 이름의 Web
/// 파일(`divider_web.dart`)과 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
///
/// 구분선은 한 축을 부모에게서 받는다. 장면은 높이 제한이 없는 스크롤 안에도
/// 놓이므로, 가로선의 부모에는 폭을, 세로선의 부모에는 높이를 정해 둔다.
library;

import 'package:coui_flutter/coui_flutter.dart';

import '../../previews/props/flutter_prop_previews.dart';
import 'divider_page.dart';

/// 속성 → Widget.
FlutterPropPreviewBuilder? get propPreview => _divider;

/// 장면 이름(`divider/<장면>`) → 장면.
final Map<String, Widget Function()> demos = {
  'divider/anatomy': () => _column([Divider(child: _label(dividerSampleText(null)))]),
  'divider/orientation': () => Wrap(
    spacing: CoreSpace.space48,
    runSpacing: CoreSpace.space24,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      _column(width: CoreSpace.space160, [
        Text(dividerColumnTexts.$1),
        const Divider(),
        Text(dividerColumnTexts.$2),
      ]),
      _row(height: CoreSpace.space96, [
        Text(dividerRowTexts.$1),
        const Divider(orientation: CoreDividerOrientation.vertical),
        Text(dividerRowTexts.$2),
      ]),
    ],
  ),
  'divider/label-alignment': () => _column(gap: CoreSpace.space24, [
    for (final alignment in dividerSceneAlignments)
      Divider(
        dividerStyle: CoreDividerStyle(childAlignment: alignment),
        child: _label(alignment.name),
      ),
  ]),
  'divider/indent': () => _column(gap: CoreSpace.space16, [
    for (final (caption, style, labelled) in dividerSceneIndents)
      _column(gap: CoreSpace.space6, [
        Text(caption).labelSmall.onSurfaceVariant,
        Divider(dividerStyle: style, child: labelled ? _label(dividerSampleText(null)) : null),
      ]),
  ]),
  'divider/do-group': () => _column(width: CoreSpace.space160, gap: CoreSpace.space8, start: true, [
    for (final (index, group) in dividerSceneGroups.indexed) ...[
      if (index > 0) const Divider(),
      for (final item in group) Text(item).bodySmall,
    ],
  ]),
  'divider/dont-every-row': () => _column(width: CoreSpace.space160, gap: CoreSpace.space8, start: true, [
    for (final (index, item) in dividerSceneGroups.expand((group) => group).indexed) ...[
      if (index > 0) const Divider(),
      Text(item).bodySmall,
    ],
  ]),
  'divider/in-row': () => _column(gap: CoreSpace.space24, [
    Row(
      spacing: CoreSpace.space12,
      children: [
        _label(dividerSceneRowTitle),
        const Expanded(child: Divider()),
      ],
    ),
    _row(height: CoreSpace.space24, [
      for (final (index, tool) in dividerSceneTools.indexed) ...[
        if (index > 0) const Divider(orientation: CoreDividerOrientation.vertical),
        Text(tool),
      ],
    ]),
  ]),
  'divider/chain': () => _column([
    const Divider().withStyle(
      const CoreDividerStyle(
        color: CoreColor.token(CoreColors.primary),
        thickness: CoreStrokeWidth.stroke4,
        indent: CoreSpace.space24,
        endIndent: CoreSpace.space24,
      ),
    ),
  ]),
  'divider/related-gap': () => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Button(variant: CoreButtonVariant.outline, onPressed: () {}, child: const Text('A')),
      const Gap.space32(),
      Button(variant: CoreButtonVariant.outline, onPressed: () {}, child: const Text('B')),
    ],
  ),
  'divider/related-resizable': () => SizedBox(
    width: CoreSpace.space200,
    height: CoreSpace.space96,
    child: Resizable(
      panes: [
        CoreResizablePaneData<Widget>(content: _pane(dividerScenePanes.$1)),
        CoreResizablePaneData<Widget>(content: _pane(dividerScenePanes.$2)),
      ],
    ),
  ),
};

Widget _divider(Map<String, String> props, String? label) {
  final orientation = dividerPreviewOrientation(props);
  final vertical = orientation == CoreDividerOrientation.vertical;
  final (before, after) = vertical ? dividerRowTexts : dividerColumnTexts;
  final children = <Widget>[
    Text(before),
    Divider(
      orientation: orientation,
      dividerStyle: dividerPreviewStyle(props),
      child: dividerPreviewChildAlignment(props) == null ? null : _label(dividerSampleText(label)),
    ),
    Text(after),
  ];
  return vertical ? _row(children, height: dividerStageHeight) : _column(children, gap: CoreSpace.space16);
}

/// 선 사이 · 선 옆에 두는 라벨.
Widget _label(String text) => Text(text).labelMedium.onSurfaceVariant;

/// 폭을 정한 세로 부모. [width] 와 [gap] 은 logical px.
Widget _column(
  List<Widget> children, {
  double width = dividerStageWidth,
  double gap = CoreSpace.space12,
  bool start = false,
}) => SizedBox(
  width: width,
  child: Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: start ? CrossAxisAlignment.start : CrossAxisAlignment.center,
    spacing: gap,
    children: children,
  ),
);

/// 높이를 정한 가로 부모. [height] 는 logical px.
Widget _row(List<Widget> children, {required double height}) => SizedBox(
  height: height,
  child: Row(mainAxisSize: MainAxisSize.min, spacing: CoreSpace.space16, children: children),
);

/// Resizable 관련 카드의 한 영역.
Widget _pane(String text) => Center(child: _label(text));
