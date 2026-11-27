/// ScrollArea 페이지의 미리보기 — Flutter.
///
/// 속성 빌더는 `<Preview props>` · 플레이그라운드가, 장면은
/// `<Preview demo="scroll-area/...">` 가 읽는다. 같은 이름의 Web
/// 파일(`scroll_area_web.dart`)과 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
///
/// 모든 상자는 폭을 정하고, 세로 상자는 `maxHeight` 로 높이를 막는다. 폭을
/// 정하지 않으면 세로 ScrollArea 는 내용의 폭만큼만 차지한다.
library;

import 'package:coui_flutter/coui_flutter.dart';

import '../../previews/props/flutter_prop_previews.dart';
import 'scroll_area_page.dart' as page;

/// 속성 → Widget.
FlutterPropPreviewBuilder? get propPreview => _scrollArea;

/// 장면 이름(`scroll-area/<장면>`) → 장면.
final Map<String, Widget Function()> demos = {
  'scroll-area/directions': () => _cells([
    (
      page.sceneVerticalCaption,
      const CoreScrollAreaStyle(maxHeight: page.sceneMaxHeight),
      CoreScrollAreaDirection.vertical,
      _inset(_column(page.demoRowCount)),
    ),
    (
      page.sceneHorizontalCaption,
      null,
      CoreScrollAreaDirection.horizontal,
      _inset(_row()),
    ),
  ]),
  'scroll-area/sizes': () => _cells([
    (
      page.sceneLongCaption,
      const CoreScrollAreaStyle(maxHeight: page.sceneMaxHeight),
      CoreScrollAreaDirection.vertical,
      _inset(_column(page.demoRowCount)),
    ),
    (
      page.sceneShortCaption,
      const CoreScrollAreaStyle(maxHeight: page.sceneMaxHeight),
      CoreScrollAreaDirection.vertical,
      _inset(_column(page.sceneShortRowCount)),
    ),
  ]),
  'scroll-area/inside': () => SizedBox(
    width: page.sceneNestedWidth,
    child: _Frame(
      child: ScrollArea(
        scrollAreaStyle: const CoreScrollAreaStyle(maxHeight: page.sceneNestedMaxHeight),
        child: _inset(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: CoreSpace.space8,
            children: [
              Text(page.demoRowLabel(1)).bodyMedium,
              ScrollArea(direction: CoreScrollAreaDirection.horizontal, child: _barClearance(_row())),
              for (var i = 2; i <= page.sceneNestedRowCount; i += 1) Text(page.demoRowLabel(i)).bodyMedium,
            ],
          ),
        ),
      ),
    ),
  ),
};

/// 폭을 정한 부모 안의 `ScrollArea`.
///
/// 방향이나 바 표시가 바뀌면 새로 만들어 스크롤 위치를 처음으로 둔다.
Widget _scrollArea(Map<String, String> props, String? label) {
  final direction = page.demoDirectionOf(props);
  final horizontal = direction == CoreScrollAreaDirection.horizontal;
  final showScrollbar = page.demoShowsScrollbar(props);
  return SizedBox(
    key: ValueKey('${direction.name}-$showScrollbar'),
    width: page.demoViewportWidth,
    child: ScrollArea(
      direction: direction,
      showScrollbar: showScrollbar,
      scrollAreaStyle: horizontal ? null : CoreScrollAreaStyle(maxHeight: page.demoMaxHeightOf(props)),
      child: horizontal ? _barClearance(_row()) : _column(page.demoRowCount),
    ),
  );
}

/// 가로 바가 글자를 덮지 않게 아래를 비운다.
Widget _barClearance(Widget child) => Padding(
  padding: const EdgeInsets.only(bottom: CoreSpace.space12),
  child: child,
);

Widget _column(int count) => Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  spacing: CoreSpace.space8,
  children: [for (var i = 1; i <= count; i += 1) Text(page.demoRowLabel(i)).bodyMedium],
);

Widget _row() => Row(
  mainAxisSize: MainAxisSize.min,
  spacing: CoreSpace.space16,
  children: [for (var i = 1; i <= page.demoColumnCount; i += 1) Text(page.demoColumnLabel(i)).bodyMedium],
);

/// 테두리 친 상자 안에서 내용이 가장자리에 붙지 않게 하는 여백.
Widget _inset(Widget child) => Padding(padding: const EdgeInsets.all(CoreSpace.space12), child: child);

/// 장면 칸을 나란히 놓고 아래에 이름을 단다.
Widget _cells(List<(String, CoreScrollAreaStyle?, CoreScrollAreaDirection, Widget)> cells) => Wrap(
  alignment: WrapAlignment.center,
  spacing: CoreSpace.space24,
  runSpacing: CoreSpace.space24,
  children: [
    for (final (caption, style, direction, child) in cells)
      SizedBox(
        width: page.sceneCellWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Frame(
              child: ScrollArea(direction: direction, scrollAreaStyle: style, child: child),
            ),
            const Gap.space8(),
            Text(caption).labelSmall.onSurfaceVariant,
          ],
        ),
      ),
  ],
);

/// 스크롤 영역의 경계를 보이는 테두리.
class _Frame extends StatelessWidget {
  const _Frame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.resolve(const CoreColor.token(CoreColors.surface)).toValue(),
        border: Border.all(color: scheme.resolve(const CoreColor.token(CoreColors.outlineVariant)).toValue()),
        borderRadius: const BorderRadius.all(Radius.circular(CoreRadiusRole.control)),
      ),
      child: child,
    );
  }
}
