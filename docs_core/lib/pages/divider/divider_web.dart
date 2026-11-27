/// Divider 페이지의 미리보기 — Jaspr Web.
///
/// 속성 빌더는 `<Preview props>` · 플레이그라운드가, 장면은
/// `<Preview demo="divider/...">` 가 읽는다. 같은 이름의 Flutter
/// 파일(`divider_flutter.dart`)과 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
///
/// 구분선은 한 축을 부모에게서 받는다. 문서 무대는 내용만큼만 넓어지는
/// 자리라, 가로선의 부모에는 폭을, 세로선의 부모에는 높이를 정해 둔다.
library;

import 'package:coui_web/coui_web.dart';

import '../../previews/props/web_prop_previews.dart';
import 'divider_page.dart';

/// 속성 → Component.
WebPropPreviewBuilder? get propPreview => _divider;

/// 장면 이름(`divider/<장면>`) → 장면.
final Map<String, Component Function()> demos = {
  // 구조 — 선 두 개를 선택자로 가리키도록 바깥 요소에 문서 표지를 단다.
  'divider/anatomy': () => _column([
    Divider(
      attributes: const {'data-docs-part': 'divider'},
      child: _label(dividerSampleText(null)),
    ),
  ]),
  'divider/orientation': () => div(
    styles: Styles(
      raw: {
        'display': 'flex',
        'flex-wrap': 'wrap',
        'align-items': 'center',
        'justify-content': 'center',
        'gap': spaceCss(CoreSpace.space48),
      },
    ),
    [
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
      _column(width: null, gap: CoreSpace.space6, [
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
    div(
      styles: Styles(
        raw: {
          'display': 'flex',
          'align-items': 'center',
          'gap': spaceCss(CoreSpace.space12),
          'width': '100%',
        },
      ),
      [
        _label(dividerSceneRowTitle),
        div(classes: 'flex-1', [const Divider()]),
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
  'divider/related-gap': () => div(
    styles: Styles(raw: {'display': 'flex', 'align-items': 'center'}),
    [
      Button(variant: CoreButtonVariant.outline, onPressed: () {}, child: const Text('A')),
      const Gap.space32(),
      Button(variant: CoreButtonVariant.outline, onPressed: () {}, child: const Text('B')),
    ],
  ),
  'divider/related-resizable': () => div(
    styles: Styles(
      raw: {
        'width': pinnedLengthCss(CoreSpace.space200),
        'max-width': '100%',
        'height': pinnedLengthCss(CoreSpace.space96),
      },
    ),
    [
      Resizable(
        panes: [
          CoreResizablePaneData<Component>(content: _pane(dividerScenePanes.$1)),
          CoreResizablePaneData<Component>(content: _pane(dividerScenePanes.$2)),
        ],
      ),
    ],
  ),
};

Component _divider(Map<String, String> props, String? label) {
  final orientation = dividerPreviewOrientation(props);
  final vertical = orientation == CoreDividerOrientation.vertical;
  final (before, after) = vertical ? dividerRowTexts : dividerColumnTexts;
  final children = <Component>[
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
Component _label(String text) => Text(text).labelMedium.onSurfaceVariant;

/// 세로로 쌓는 flex 부모. [width] 가 `null` 이면 바깥 상자의 폭을 채운다.
/// [width] 와 [gap] 은 logical px.
Component _column(
  List<Component> children, {
  double? width = dividerStageWidth,
  double gap = CoreSpace.space12,
  bool start = false,
}) => div(
  styles: Styles(
    raw: {
      'display': 'flex',
      'flex-direction': 'column',
      'align-items': start ? 'flex-start' : 'center',
      'gap': spaceCss(gap),
      'width': width == null ? '100%' : pinnedLengthCss(width),
      'max-width': '100%',
    },
  ),
  children,
);

/// 높이를 정한 가로 flex 부모. [height] 는 logical px.
Component _row(List<Component> children, {required double height}) => div(
  styles: Styles(
    raw: {
      'display': 'flex',
      'flex-direction': 'row',
      'align-items': 'center',
      'gap': spaceCss(CoreSpace.space16),
      'height': pinnedLengthCss(height),
    },
  ),
  children,
);

/// Resizable 관련 카드의 한 영역.
Component _pane(String text) => div(classes: 'flex h-full items-center justify-center', [_label(text)]);
