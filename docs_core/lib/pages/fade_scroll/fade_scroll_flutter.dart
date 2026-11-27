/// FadeScroll 페이지의 미리보기 — Flutter.
///
/// 속성 빌더는 `<Preview props>` · 플레이그라운드가, 장면은
/// `<Preview demo="fade-scroll/...">` · `<Card demo>` 가 읽는다. 같은 이름의 Web
/// 파일(`fade_scroll_web.dart`)과 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
///
/// 세로 FadeScroll 은 높이가 정해져야 스크롤한다. 장면은 높이가 정해지지 않은
/// 곳에서도 그려지므로 모든 세로 상자에 높이를 준다. 상자에는 가장자리가 보이게
/// 옅은 선을 두른다.
library;

import 'package:coui_flutter/coui_flutter.dart';

import '../../previews/props/flutter_prop_previews.dart';
import 'fade_scroll_page.dart' as page;

/// 속성 → Widget.
FlutterPropPreviewBuilder? get propPreview => _fadeScroll;

/// 장면 이름(`fade-scroll/<장면>`) → 장면.
final Map<String, Widget Function()> demos = {
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
    width: page.sceneGuideWidth,
    height: page.sceneStateHeight,
    child: FadeScroll(showScrollbar: true, child: _rows(page.demoRowCount)),
  ),
  'fade-scroll/do-focusable': () => _frame(
    width: page.sceneGuideWidth,
    height: page.sceneFocusHeight,
    child: FadeScroll(child: _buttons()),
  ),
  'fade-scroll/dont-text-only': () => _frame(
    width: page.sceneGuideWidth,
    height: page.sceneFocusHeight,
    child: FadeScroll(child: _paragraph()),
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
    width: page.sceneScrollAreaWidth,
    child: ScrollArea(
      scrollAreaStyle: const CoreScrollAreaStyle(height: page.sceneScrollAreaHeight),
      child: _rows(page.demoRowCount),
    ),
  ),
  'fade-scroll/related-chip-group': () => SizedBox(
    width: page.sceneChipGroupWidth,
    child: ChipGroup<String>(
      items: [for (var i = 1; i <= page.demoTagCount; i += 1) page.demoTagLabel(i)],
      initialValue: {page.demoTagLabel(1)},
      layout: CoreChipGroupLayout.scroll,
      chipBuilder: _chip,
    ),
  ),
};

/// 방향이 바뀌면 새로 마운트해 페이드를 첫 화면부터 다시 계산한다.
Widget _fadeScroll(Map<String, String> props, String? label) {
  final direction = page.demoDirectionOf(props);
  return _sample(direction, key: ValueKey(direction.name), fadeScrollStyle: page.demoStyleOf(props));
}

/// 방향에 맞는 크기의 상자에 담은 FadeScroll.
Widget _sample(CoreFadeScrollDirection direction, {Key? key, CoreFadeScrollStyle? fadeScrollStyle}) {
  final horizontal = direction == CoreFadeScrollDirection.horizontal;
  return _frame(
    key: key,
    width: page.demoBoxWidth,
    height: horizontal ? null : page.demoBoxHeight,
    child: FadeScroll(
      direction: direction,
      fadeScrollStyle: fadeScrollStyle,
      child: horizontal ? _tags() : _rows(page.demoRowCount),
    ),
  );
}

/// 크기를 정한 상자에 담은 세로 FadeScroll.
Widget _list(
  int rows, {
  required double width,
  required double height,
  CoreFadeScrollStyle? fadeScrollStyle,
}) => _frame(
  width: width,
  height: height,
  child: FadeScroll(fadeScrollStyle: fadeScrollStyle, child: _rows(rows)),
);

/// 크기를 정하고 옅은 선을 두른 상자.
Widget _frame({required Widget child, required double width, double? height, Key? key}) => Builder(
  key: key,
  builder: (context) => DecoratedBox(
    decoration: BoxDecoration(
      border: Border.all(
        color: Theme.of(context).colorScheme.resolve(const CoreColor.token(CoreColors.outlineVariant)).toValue(),
      ),
      borderRadius: const BorderRadius.all(Radius.circular(CoreRadiusRole.control)),
    ),
    child: SizedBox(width: width, height: height, child: child),
  ),
);

/// 세로 목록.
Widget _rows(int count) => Padding(
  padding: const EdgeInsets.symmetric(horizontal: CoreSpace.space12),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: CoreSpace.space12,
    children: [for (var i = 1; i <= count; i += 1) Text(page.demoRowLabel(i)).bodyMedium.onSurface],
  ),
);

/// 가로 줄.
Widget _tags() => Padding(
  padding: const EdgeInsets.all(CoreSpace.space8),
  child: Row(
    mainAxisSize: MainAxisSize.min,
    spacing: CoreSpace.space8,
    children: [for (var i = 1; i <= page.demoTagCount; i += 1) Chip(label: page.demoTagLabel(i))],
  ),
);

/// 초점을 받는 항목이 있는 목록.
Widget _buttons() => Padding(
  padding: const EdgeInsets.all(CoreSpace.space12),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: CoreSpace.space8,
    children: [
      for (var i = 1; i <= page.sceneButtonCount; i += 1)
        Button(variant: CoreButtonVariant.outline, onPressed: () {}, child: Text(page.sceneButtonLabel(i))),
    ],
  ),
);

/// 글만 있는 내용.
Widget _paragraph() => Padding(
  padding: const EdgeInsets.all(CoreSpace.space12),
  child: Text(page.sceneParagraph).bodyMedium.onSurface,
);

/// 장면 칸을 나란히 놓고 아래에 이름을 단다.
Widget _cells(List<(String, Widget)> cells) => Wrap(
  alignment: WrapAlignment.center,
  spacing: CoreSpace.space24,
  runSpacing: CoreSpace.space24,
  children: [
    for (final (caption, child) in cells)
      Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: CoreSpace.space8,
        children: [child, Text(caption).labelSmall.onSurfaceVariant],
      ),
  ],
);

Widget _chip(
  String item, {
  required bool selected,
  required bool enabled,
  required VoidCallback onTap,
}) => Chip(label: item, selected: selected, enabled: enabled, onTap: onTap);
