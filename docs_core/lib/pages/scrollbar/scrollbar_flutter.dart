/// Scrollbar 페이지의 미리보기 — Flutter.
///
/// 속성 빌더는 `<Preview props>` · 플레이그라운드가, 장면은
/// `<Preview demo="scrollbar/...">` 가 읽는다. 같은 이름의 Web
/// 파일(`scrollbar_web.dart`)과 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
///
/// 장면도 실제 `Scrollbar` 다. 가만히 있어도 thumb 이 보이도록
/// `visibility: always` 로 그리고, 올리거나 끄는 모양과 `thin` 의 모양은
/// 장면 칸의 `CoreScrollbarStyle` 로 같은 두께 · 색을 준다. `always` 는
/// 컨트롤러가 없으면 첫 프레임에 debug 오류를 내므로 칸마다 컨트롤러를 둔다.
library;

import 'package:coui_flutter/coui_flutter.dart';

import '../../previews/props/flutter_prop_previews.dart';
import 'scrollbar_page.dart' as page;

/// 속성 → Widget.
FlutterPropPreviewBuilder? get propPreview => _scrollbar;

/// 장면 이름(`scrollbar/<장면>`) → 장면.
final Map<String, Widget Function()> demos = {
  'scrollbar/anatomy': () => const _SceneBox(cell: page.sceneAnatomyCell, width: page.sceneAnatomyWidth),
  'scrollbar/states': () => _cells(page.sceneStateCells, width: page.sceneStateWidth),
  'scrollbar/visibility': () => _cells(page.sceneVisibilityCells, width: page.sceneVisibilityWidth),
};

/// 축이나 표시 정책이 바뀌면 컨트롤러까지 새로 만든다 — `hidden` 을 오가면
/// 감싼 스크롤 뷰가 다시 만들어지기 때문이다.
Widget _scrollbar(Map<String, String> props, String? label) {
  final axis = page.demoAxisOf(props);
  final visibility = page.demoVisibilityOf(props);
  return _ScrollbarDemo(
    key: ValueKey('${axis.name}-${visibility.name}'),
    axis: axis,
    visibility: visibility,
    interactive: page.demoIsInteractive(props),
  );
}

/// 컨트롤러를 스크롤 뷰와 함께 쓰는 실제 `Scrollbar`.
class _ScrollbarDemo extends StatefulWidget {
  const _ScrollbarDemo({required this.axis, required this.visibility, required this.interactive, super.key});

  final CoreScrollbarAxis axis;
  final CoreScrollbarVisibility visibility;
  final bool interactive;

  @override
  State<_ScrollbarDemo> createState() => _ScrollbarDemoState();
}

class _ScrollbarDemoState extends State<_ScrollbarDemo> {
  final ScrollController _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final horizontal = widget.axis == CoreScrollbarAxis.horizontal;
    return SizedBox(
      width: page.demoViewportWidth,
      height: horizontal ? null : page.demoViewportHeight,
      child: Scrollbar(
        controller: _controller,
        axis: widget.axis,
        visibility: widget.visibility,
        interactive: widget.interactive,
        child: SingleChildScrollView(
          scrollDirection: horizontal ? Axis.horizontal : Axis.vertical,
          controller: _controller,
          padding: horizontal ? const EdgeInsets.only(bottom: CoreSpace.space12) : null,
          child: horizontal ? _row() : _column(),
        ),
      ),
    );
  }
}

Widget _column() => Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  spacing: CoreSpace.space8,
  children: [for (var i = 1; i <= page.demoRowCount; i += 1) Text(page.demoRowLabel(i)).bodyMedium],
);

Widget _row() => Row(
  mainAxisSize: MainAxisSize.min,
  spacing: CoreSpace.space16,
  children: [for (var i = 1; i <= page.demoColumnCount; i += 1) Text(page.demoColumnLabel(i)).bodyMedium],
);

/// 장면 칸을 나란히 놓고 아래에 이름을 단다.
Widget _cells(List<page.ScrollbarSceneCell> cells, {required double width}) => Wrap(
  alignment: WrapAlignment.center,
  spacing: CoreSpace.space24,
  runSpacing: CoreSpace.space24,
  children: [
    for (final cell in cells)
      SizedBox(
        width: width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SceneBox(cell: cell, width: width),
            const Gap.space8(),
            Text(cell.caption).labelSmall.onSurfaceVariant,
          ],
        ),
      ),
  ],
);

/// 같은 자리까지 스크롤해 둔 목록을 담은 상자.
class _SceneBox extends StatefulWidget {
  const _SceneBox({required this.cell, required this.width});

  final page.ScrollbarSceneCell cell;
  final double width;

  @override
  State<_SceneBox> createState() => _SceneBoxState();
}

class _SceneBoxState extends State<_SceneBox> {
  final ScrollController _controller = ScrollController(initialScrollOffset: page.sceneScrollOffset);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: widget.width,
      height: page.sceneViewportHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.resolve(const CoreColor.token(CoreColors.surface)).toValue(),
          border: Border.all(color: scheme.resolve(const CoreColor.token(CoreColors.outlineVariant)).toValue()),
          borderRadius: const BorderRadius.all(Radius.circular(CoreRadiusRole.control)),
        ),
        child: Scrollbar(
          controller: _controller,
          visibility: widget.cell.hidden ? CoreScrollbarVisibility.hidden : CoreScrollbarVisibility.always,
          scrollbarStyle: widget.cell.style,
          child: SingleChildScrollView(
            controller: _controller,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [for (var i = 1; i <= page.sceneRowCount; i += 1) _sceneRow(i)],
            ),
          ),
        ),
      ),
    );
  }
}

Widget _sceneRow(int index) => SizedBox(
  height: page.sceneRowHeight,
  child: Padding(
    padding: const EdgeInsets.symmetric(horizontal: CoreSpace.space12),
    child: Align(
      alignment: AlignmentDirectional.centerStart,
      child: Text(page.demoRowLabel(index)).bodyMedium,
    ),
  ),
);
