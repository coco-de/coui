/// ScrollArea 페이지의 미리보기 — Jaspr Web.
///
/// 속성 빌더는 `<Preview props>` · 플레이그라운드가, 장면은
/// `<Preview demo="scroll-area/...">` 가 읽는다. 같은 이름의 Flutter
/// 파일(`scroll_area_flutter.dart`)과 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
///
/// 장면도 실제 `ScrollArea` 다. Web 의 thumb 은 브라우저에서 스크롤 상자를 잰
/// 뒤에 그려지므로, 서버에서 그린 채로 남는 장면에는 thumb 이 없고 상자
/// 스크롤만 된다. 속성 빌더(플레이그라운드)에는 thumb 이 보인다.
library;

import 'package:coui_web/coui_web.dart';

import '../../previews/props/web_prop_previews.dart';
import 'scroll_area_page.dart' as page;

/// 속성 → Component.
WebPropPreviewBuilder? get propPreview => _scrollArea;

/// 장면 이름(`scroll-area/<장면>`) → 장면.
final Map<String, Component Function()> demos = {
  'scroll-area/directions': () => _cells([
    (
      page.sceneVerticalCaption,
      const CoreScrollAreaStyle(maxHeight: page.sceneMaxHeight),
      CoreScrollAreaDirection.vertical,
      _insetColumn(page.demoRowCount),
    ),
    (
      page.sceneHorizontalCaption,
      null,
      CoreScrollAreaDirection.horizontal,
      _insetRow(),
    ),
  ]),
  'scroll-area/sizes': () => _cells([
    (
      page.sceneLongCaption,
      const CoreScrollAreaStyle(maxHeight: page.sceneMaxHeight),
      CoreScrollAreaDirection.vertical,
      _insetColumn(page.demoRowCount),
    ),
    (
      page.sceneShortCaption,
      const CoreScrollAreaStyle(maxHeight: page.sceneMaxHeight),
      CoreScrollAreaDirection.vertical,
      _insetColumn(page.sceneShortRowCount),
    ),
  ]),
  'scroll-area/inside': () => _box(
    width: page.sceneNestedWidth,
    _frame(
      ScrollArea(
        scrollAreaStyle: const CoreScrollAreaStyle(maxHeight: page.sceneNestedMaxHeight),
        child: div(
          classes: 'flex flex-col gap-${CoreSpace.scale.space8}',
          styles: Styles(raw: {'padding': spaceCss(CoreSpace.space12)}),
          [
            Text(page.demoRowLabel(1)).bodyMedium,
            ScrollArea(direction: CoreScrollAreaDirection.horizontal, child: _row()),
            for (var i = 2; i <= page.sceneNestedRowCount; i += 1) Text(page.demoRowLabel(i)).bodyMedium,
          ],
        ),
      ),
    ),
  ),
};

/// 폭을 정한 부모 안의 `ScrollArea`.
///
/// 방향이나 바 표시가 바뀌면 새로 마운트해 스크롤 상자를 처음부터 다시 잰다.
Component _scrollArea(Map<String, String> props, String? label) {
  final direction = page.demoDirectionOf(props);
  final horizontal = direction == CoreScrollAreaDirection.horizontal;
  final showScrollbar = page.demoShowsScrollbar(props);
  return div(
    key: ValueKey('${direction.name}-$showScrollbar'),
    styles: Styles(raw: {'width': pinnedLengthCss(page.demoViewportWidth), 'max-width': '100%'}),
    [
      ScrollArea(
        direction: direction,
        showScrollbar: showScrollbar,
        scrollAreaStyle: horizontal ? null : CoreScrollAreaStyle(maxHeight: page.demoMaxHeightOf(props)),
        child: horizontal ? _row() : _column(page.demoRowCount),
      ),
    ],
  );
}

Component _column(int count) => div(
  classes: 'flex flex-col gap-${CoreSpace.scale.space8}',
  [for (var i = 1; i <= count; i += 1) Text(page.demoRowLabel(i)).bodyMedium],
);

/// 가로 줄 — 아래 여백은 가로 바가 글자를 덮지 않게 비워 둔다.
Component _row() => div(
  classes: 'flex flex-row whitespace-nowrap gap-${CoreSpace.scale.space16} pb-${CoreSpace.scale.space12}',
  [for (var i = 1; i <= page.demoColumnCount; i += 1) Text(page.demoColumnLabel(i)).bodyMedium],
);

/// 테두리 친 상자 안의 세로 목록.
Component _insetColumn(int count) => div(
  styles: Styles(raw: {'padding': spaceCss(CoreSpace.space12)}),
  [_column(count)],
);

/// 테두리 친 상자 안의 가로 줄. 폭을 내용에 맞춰야 오른쪽 끝에도 여백이 남는다.
Component _insetRow() => div(
  classes: 'flex flex-row whitespace-nowrap gap-${CoreSpace.scale.space16}',
  styles: Styles(raw: {'width': 'max-content', 'padding': spaceCss(CoreSpace.space12)}),
  [for (var i = 1; i <= page.demoColumnCount; i += 1) Text(page.demoColumnLabel(i)).bodyMedium],
);

/// 폭을 정한 칸. [width] 는 logical px.
Component _box(Component child, {required double width}) => div(
  styles: Styles(raw: {'width': pinnedLengthCss(width), 'max-width': '100%'}),
  [child],
);

/// 장면 칸을 나란히 놓고 아래에 이름을 단다.
Component _cells(List<(String, CoreScrollAreaStyle?, CoreScrollAreaDirection, Component)> cells) => div(
  styles: Styles(
    raw: {
      'display': 'flex',
      'flex-wrap': 'wrap',
      'justify-content': 'center',
      'align-items': 'flex-start',
      'gap': spaceCss(CoreSpace.space24),
    },
  ),
  [
    for (final (caption, style, direction, child) in cells)
      div(
        styles: Styles(
          raw: {
            'display': 'flex',
            'flex-direction': 'column',
            'gap': spaceCss(CoreSpace.space8),
            'width': pinnedLengthCss(page.sceneCellWidth),
            'max-width': '100%',
          },
        ),
        [
          _frame(ScrollArea(direction: direction, scrollAreaStyle: style, child: child)),
          Text(caption).labelSmall.onSurfaceVariant,
        ],
      ),
  ],
);

/// 스크롤 영역의 경계를 보이는 테두리.
Component _frame(Component child) {
  final line = const CoreColor.token(CoreColors.outlineVariant).toValue();
  return div(
    styles: Styles(
      raw: {
        'border-radius': radiusCss(CoreRadiusRole.control),
        'background-color': const CoreColor.token(CoreColors.surface).toValue(),
        'box-shadow': '0 0 0 ${strokeWidthCss(CoreStrokeWidth.stroke1)} $line',
      },
    ),
    [child],
  );
}
