/// FadeScroll 페이지의 미리보기 — Jaspr Web.
///
/// 속성 빌더는 `<Preview props>` · 플레이그라운드가, 장면은
/// `<Preview demo="fade-scroll/...">` · `<Card demo>` 가 읽는다. 같은 이름의
/// Flutter 파일(`fade_scroll_flutter.dart`)과 컴포넌트 · 속성 · 장면 이름이
/// 같아야 한다.
///
/// FadeScroll 의 루트는 부모를 채운다. 그래서 모든 미리보기는 크기를 정한
/// 상자 안에 놓고, 상자에는 가장자리가 보이게 옅은 선을 두른다. 장면은 서버에서
/// 그린 채 깨어나지 않아 스크롤해도 페이드가 바뀌지 않는다. 플레이그라운드는
/// 브라우저에서 깨어난다.
library;

import 'package:coui_web/coui_web.dart';

import '../../previews/props/web_prop_previews.dart';
import 'fade_scroll_page.dart' as page;

/// 속성 → Component.
WebPropPreviewBuilder? get propPreview => _fadeScroll;

/// 장면 이름(`fade-scroll/<장면>`) → 장면.
final Map<String, Component Function()> demos = {
  'fade-scroll/directions': () => _cells([
    (CoreFadeScrollDirection.vertical.name, _sample(CoreFadeScrollDirection.vertical)),
    (CoreFadeScrollDirection.horizontal.name, _sample(CoreFadeScrollDirection.horizontal)),
  ]),
  'fade-scroll/states': () => _cells([
    ('넘칠 때', _list(page.demoRowCount, width: page.sceneStateWidth, height: page.sceneStateHeight)),
    ('다 들어갈 때', _list(page.sceneFitRowCount, width: page.sceneStateWidth, height: page.sceneStateHeight)),
  ]),
  'fade-scroll/offsets': () => _cells([
    for (final offset in page.sceneOffsets)
      (
        page.sceneOffsetCaption(offset),
        _list(
          page.demoRowCount,
          width: page.sceneOffsetWidth,
          height: page.sceneStateHeight,
          fadeScrollStyle: page.offsetStyle(offset),
        ),
      ),
  ]),
  'fade-scroll/scrollbar': () => _frame(
    FadeScroll(showScrollbar: true, child: _rows(page.demoRowCount)),
    width: page.sceneGuideWidth,
    height: page.sceneStateHeight,
  ),
  'fade-scroll/do-focusable': () => _frame(
    FadeScroll(child: _buttons()),
    width: page.sceneGuideWidth,
    height: page.sceneFocusHeight,
  ),
  'fade-scroll/dont-text-only': () => _frame(
    FadeScroll(child: _paragraph()),
    width: page.sceneGuideWidth,
    height: page.sceneFocusHeight,
  ),
  'fade-scroll/do-short-fade': () => _list(
    page.demoRowCount,
    width: page.sceneGuideWidth,
    height: page.sceneShortBoxHeight,
    fadeScrollStyle: page.offsetStyle(page.sceneShortFade),
  ),
  'fade-scroll/dont-long-fade': () => _list(
    page.demoRowCount,
    width: page.sceneGuideWidth,
    height: page.sceneShortBoxHeight,
    fadeScrollStyle: page.offsetStyle(page.sceneLongFade),
  ),
  'fade-scroll/related-scroll-area': () => _frame(
    ScrollArea(
      scrollAreaStyle: const CoreScrollAreaStyle(height: page.sceneScrollAreaHeight),
      child: _rows(page.demoRowCount),
    ),
    width: page.sceneScrollAreaWidth,
  ),
  'fade-scroll/related-chip-group': () => div(
    styles: Styles(raw: {'width': pinnedLengthCss(page.sceneChipGroupWidth), 'max-width': '100%'}),
    [
      ChipGroup<String>(
        items: [for (var i = 1; i <= page.demoTagCount; i += 1) page.demoTagLabel(i)],
        initialValue: {page.demoTagLabel(1)},
        layout: CoreChipGroupLayout.scroll,
        chipBuilder: _chip,
      ),
    ],
  ),
};

/// 방향이 바뀌면 새로 마운트해 스크롤 위치를 처음으로 돌린다.
Component _fadeScroll(Map<String, String> props, String? label) {
  final direction = page.demoDirectionOf(props);
  return _sample(direction, key: ValueKey(direction.name), fadeScrollStyle: page.demoStyleOf(props));
}

/// 방향에 맞는 크기의 상자에 담은 FadeScroll.
Component _sample(CoreFadeScrollDirection direction, {Key? key, CoreFadeScrollStyle? fadeScrollStyle}) {
  final horizontal = direction == CoreFadeScrollDirection.horizontal;
  return _frame(
    FadeScroll(
      direction: direction,
      fadeScrollStyle: fadeScrollStyle,
      child: horizontal ? _tags() : _rows(page.demoRowCount),
    ),
    key: key,
    width: page.demoBoxWidth,
    height: horizontal ? null : page.demoBoxHeight,
  );
}

/// 크기를 정한 상자에 담은 세로 FadeScroll.
Component _list(
  int rows, {
  required double width,
  required double height,
  CoreFadeScrollStyle? fadeScrollStyle,
}) => _frame(
  FadeScroll(fadeScrollStyle: fadeScrollStyle, child: _rows(rows)),
  width: width,
  height: height,
);

/// 크기를 정하고 옅은 선을 두른 상자.
Component _frame(Component child, {required double width, double? height, Key? key}) {
  final line = const CoreColor.token(CoreColors.outlineVariant).toValue();
  return div(
    key: key,
    styles: Styles(
      raw: {
        'width': pinnedLengthCss(width),
        'max-width': '100%',
        if (height != null) 'height': pinnedLengthCss(height),
        'border-radius': radiusCss(CoreRadiusRole.control),
        'box-shadow': '0 0 0 ${strokeWidthCss(CoreStrokeWidth.stroke1)} $line',
      },
    ),
    [child],
  );
}

/// 세로 목록.
Component _rows(int count) => div(
  styles: Styles(
    raw: {
      'display': 'flex',
      'flex-direction': 'column',
      'gap': spaceCss(CoreSpace.space12),
      'padding-inline': spaceCss(CoreSpace.space12),
    },
  ),
  [for (var i = 1; i <= count; i += 1) Text(page.demoRowLabel(i)).bodyMedium.onSurface],
);

/// 가로 줄 — 폭을 내용만큼 잡아야 항목이 줄지 않고 넘친다.
Component _tags() => div(
  styles: Styles(
    raw: {
      'display': 'flex',
      'width': 'max-content',
      'gap': spaceCss(CoreSpace.space8),
      'padding': spaceCss(CoreSpace.space8),
    },
  ),
  [for (var i = 1; i <= page.demoTagCount; i += 1) Chip(label: page.demoTagLabel(i))],
);

/// 초점을 받는 항목이 있는 목록.
Component _buttons() => div(
  styles: Styles(
    raw: {
      'display': 'flex',
      'flex-direction': 'column',
      'gap': spaceCss(CoreSpace.space8),
      'padding': spaceCss(CoreSpace.space12),
    },
  ),
  [
    for (var i = 1; i <= page.sceneButtonCount; i += 1)
      Button(variant: CoreButtonVariant.outline, onPressed: () {}, child: Text(page.sceneButtonLabel(i))),
  ],
);

/// 글만 있는 내용.
Component _paragraph() => div(
  styles: Styles(raw: {'padding': spaceCss(CoreSpace.space12)}),
  [Text(page.sceneParagraph).bodyMedium.onSurface],
);

/// 장면 칸을 나란히 놓고 아래에 이름을 단다.
Component _cells(List<(String, Component)> cells) => div(
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
    for (final (caption, child) in cells)
      div(
        styles: Styles(
          raw: {
            'display': 'flex',
            'flex-direction': 'column',
            'gap': spaceCss(CoreSpace.space8),
            'max-width': '100%',
          },
        ),
        [child, Text(caption).labelSmall.onSurfaceVariant],
      ),
  ],
);

Component _chip(
  String item, {
  required bool selected,
  required bool enabled,
  required void Function() onTap,
}) => Chip(label: item, selected: selected, enabled: enabled, onTap: onTap);
