/// Scrollbar 페이지의 미리보기 — Jaspr Web.
///
/// 속성 빌더는 `<Preview props>` · 플레이그라운드가, 장면은
/// `<Preview demo="scrollbar/...">` 가 읽는다. 같은 이름의 Flutter
/// 파일(`scrollbar_flutter.dart`)과 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
///
/// 정지 장면의 thumb 은 그림이다. Web 의 thumb 은 브라우저에서 스크롤 상자를
/// 잰 뒤에야 그려지는데, 장면은 서버에서 그린 채 깨어나지 않는다. 실제
/// `Scrollbar` 를 놓으면 브라우저 스크롤바까지 숨겨져 아무 바도 보이지 않는다.
/// 그림은 장면 칸의 `CoreScrollbarStyle` 과 `CoreScrollbarStyle` 기본값을 읽고,
/// 길이와 위치는 `CoreScrollbarThumbLayout` 으로 계산한다. `CoreScrollbarTheme`
/// 은 그림에 닿지 않는다. 속성 빌더(플레이그라운드)는 실제 `Scrollbar` 다.
library;

import 'package:coui_web/coui_web.dart';

import '../../previews/props/web_prop_previews.dart';
import 'scrollbar_page.dart' as page;

/// 속성 → Component.
WebPropPreviewBuilder? get propPreview => _scrollbar;

/// 장면 이름(`scrollbar/<장면>`) → 장면.
final Map<String, Component Function()> demos = {
  'scrollbar/anatomy': () => _picture(page.sceneAnatomyCell, width: page.sceneAnatomyWidth),
  'scrollbar/states': () => _cells(page.sceneStateCells, width: page.sceneStateWidth),
  'scrollbar/visibility': () => _cells(page.sceneVisibilityCells, width: page.sceneVisibilityWidth),
};

/// 높이(가로는 폭)를 정한 부모 안의 실제 `Scrollbar`.
///
/// 축이나 표시 정책이 바뀌면 새로 마운트해 스크롤 상자를 처음부터 다시 잰다.
Component _scrollbar(Map<String, String> props, String? label) {
  final axis = page.demoAxisOf(props);
  final visibility = page.demoVisibilityOf(props);
  final horizontal = axis == CoreScrollbarAxis.horizontal;
  return div(
    key: ValueKey('${axis.name}-${visibility.name}'),
    styles: Styles(
      raw: {
        'width': pinnedLengthCss(page.demoViewportWidth),
        'max-width': '100%',
        if (!horizontal) 'height': pinnedLengthCss(page.demoViewportHeight),
      },
    ),
    [
      Scrollbar(
        axis: axis,
        visibility: visibility,
        interactive: page.demoIsInteractive(props),
        child: horizontal ? _row() : _column(),
      ),
    ],
  );
}

Component _column() => div(
  classes: 'flex flex-col gap-${CoreSpace.scale.space8}',
  [for (var i = 1; i <= page.demoRowCount; i += 1) Text(page.demoRowLabel(i)).bodyMedium],
);

/// 가로 줄 — 아래 여백은 가로 바가 글자를 덮지 않게 비워 둔다.
Component _row() => div(
  classes: 'flex flex-row whitespace-nowrap gap-${CoreSpace.scale.space16} pb-${CoreSpace.scale.space12}',
  [for (var i = 1; i <= page.demoColumnCount; i += 1) Text(page.demoColumnLabel(i)).bodyMedium],
);

/// 장면 칸을 나란히 놓고 아래에 이름을 단다.
Component _cells(List<page.ScrollbarSceneCell> cells, {required double width}) => div(
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
    for (final cell in cells)
      div(
        styles: Styles(
          raw: {
            'display': 'flex',
            'flex-direction': 'column',
            'gap': spaceCss(CoreSpace.space8),
            'width': pinnedLengthCss(width),
            'max-width': '100%',
          },
        ),
        [_picture(cell, width: width), Text(cell.caption).labelSmall.onSurfaceVariant],
      ),
  ],
);

/// 스크롤해 둔 목록과 그 위의 바를 그린 그림. 부분마다 `data-docs-part` 를 달아
/// 구조 블록이 번호를 붙인다.
Component _picture(page.ScrollbarSceneCell cell, {required double width}) {
  final style = cell.style;
  final thickness = style.thickness ?? CoreScrollbarStyle.defaultThickness;
  final inset = style.thumbInset ?? CoreScrollbarStyle.defaultThumbInset;
  final layout = cell.hidden ? null : page.sceneThumbLayout(style);
  final line = const CoreColor.token(CoreColors.outlineVariant).toValue();

  return div(
    styles: Styles(
      raw: {
        'position': 'relative',
        'overflow': 'hidden',
        'width': pinnedLengthCss(width),
        'max-width': '100%',
        'height': pinnedLengthCss(page.sceneViewportHeight),
        'border-radius': radiusCss(CoreRadiusRole.control),
        'background-color': const CoreColor.token(CoreColors.surface).toValue(),
        'box-shadow': '0 0 0 ${strokeWidthCss(CoreStrokeWidth.stroke1)} $line',
      },
    ),
    [
      div(
        styles: Styles(
          raw: {'position': 'relative', 'top': pinnedLengthCss(-page.sceneScrollOffset)},
        ),
        [for (var i = 1; i <= page.sceneRowCount; i += 1) _sceneRow(i)],
      ),
      if (layout != null) ...[
        div(
          [],
          attributes: const {'data-docs-part': 'track'},
          styles: Styles(
            raw: {
              'position': 'absolute',
              'top': '0',
              'inset-inline-end': '0',
              'width': pinnedLengthCss(thickness + 2 * inset),
              'height': pinnedLengthCss(page.sceneViewportHeight),
              'background-color': (style.trackColor ?? CoreScrollbarStyle.defaultTrackColor).toValue(),
            },
          ),
        ),
        div(
          [],
          attributes: const {'data-docs-part': 'thumb'},
          styles: Styles(
            raw: {
              'position': 'absolute',
              'top': pinnedLengthCss(layout.offset),
              'inset-inline-end': pinnedLengthCss(inset),
              'width': pinnedLengthCss(thickness),
              'height': pinnedLengthCss(layout.extent),
              'border-radius': (style.thumbRadius ?? CoreScrollbarStyle.defaultThumbRadius).toValue(),
              'background-color': (style.thumbColor ?? CoreScrollbarStyle.defaultThumbColor).toValue(),
            },
          ),
        ),
      ],
    ],
  );
}

Component _sceneRow(int index) => div(
  styles: Styles(
    raw: {
      'display': 'flex',
      'align-items': 'center',
      'height': pinnedLengthCss(page.sceneRowHeight),
      'padding-inline': spaceCss(CoreSpace.space12),
    },
  ),
  [Text(page.demoRowLabel(index)).bodyMedium],
);
