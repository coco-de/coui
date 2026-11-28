/// Diff 페이지의 미리보기 — Flutter.
///
/// 속성 빌더는 `<Preview props>` · 플레이그라운드가, 장면은
/// `<Preview demo="diff/...">` 가 읽는다. 같은 이름의 Web
/// 파일(`diff_web.dart`)과 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
///
/// Diff 는 받은 폭과 `aspectRatio` 로 높이를 정한다. 장면마다 폭을 정해, 높이가
/// 정해지지 않은 스크롤 안에서도 같은 크기로 그려진다.
library;

import 'package:coui_flutter/coui_flutter.dart';

import '../../previews/props/flutter_prop_previews.dart';
import '../page_kit_flutter.dart';
import 'diff_page.dart';

/// 속성 → Widget.
FlutterPropPreviewBuilder? get propPreview => _diff;

/// 장면 이름(`diff/<장면>`) → 장면.
final Map<String, Widget Function()> demos = {
  'diff/anatomy': () => _frame(
    const Diff(
      ariaLabel: diffSceneName,
      beforeLabel: Text(diffBeforeText),
      afterLabel: Text(diffAfterText),
      before: _Landscape(vivid: false),
      after: _Landscape(vivid: true),
    ),
  ),
  'diff/content-text': () => _frame(
    Diff(
      ariaLabel: diffTextSceneName,
      before: _TextFace(CoreColors.primary, const Text(diffTextSample).displaySmall.onPrimary),
      after: _TextFace(CoreColors.surfaceContainer, const Text(diffTextSample).displaySmall.onSurface),
    ),
  ),
  'diff/positions': () => docsFlutterDemoRow([_positioned(0.25), _positioned(0.75)]),
  'diff/state-interactive': () => _frame(_scene(), width: _cardWidth),
  'diff/state-static': () => _frame(_scene(interactive: false), width: _cardWidth),
  'diff/do-labels': () => _frame(
    _scene(beforeLabel: const Text(diffBeforeText), afterLabel: const Text(diffAfterText)),
    width: _cardWidth,
  ),
  'diff/dont-long-labels': () => _frame(
    _scene(beforeLabel: const Text(diffLongBeforeText), afterLabel: const Text(diffLongAfterText)),
    width: _cardWidth,
  ),
  'diff/theme-style': () => _frame(_scene(style: diffThemeDemoStyle)),
  'diff/related-code-diff': () => _frame(const CodeDiff(lines: diffRelatedCodeLines), width: _relatedWidth),
  'diff/related-carousel': () => _frame(
    Carousel(
      transition: const CarouselTransition.sliding(),
      items: [
        for (var index = 0; index < 3; index++)
          SizedBox(width: double.infinity, height: CoreSpace.space112, child: _Slide(index)),
      ],
    ),
    width: _relatedWidth,
  ),
  'diff/related-hover-gallery': () => _frame(
    HoverGallery(
      itemCount: 3,
      itemBuilder: (index) => _Slide(index),
      hoverGalleryStyle: const CoreHoverGalleryStyle(height: CoreSpace.space112),
    ),
    width: _relatedWidth,
  ),
};

/// 카드 안 장면의 폭 — 좁은 카드에서는 줄어든다.
const double _cardWidth = CoreLayout.layout240;

/// 관련 컴포넌트 그림의 폭.
const double _relatedWidth = CoreLayout.layout240;

Widget _diff(Map<String, String> props, String? label) {
  final position = diffPreviewInitialPosition(props);
  final labels = diffPreviewLabels(props);
  return _frame(
    Diff(
      // 시작 위치가 바뀌면 처음 상태로 다시 만든다 — Diff 는 한 번 옮긴 위치를
      // 기억해, 그대로 두면 새 시작 위치가 보이지 않는다.
      key: ValueKey('diff-$position'),
      ariaLabel: diffSceneName,
      beforeLabel: labels ? const Text(diffBeforeText) : null,
      afterLabel: labels ? const Text(diffAfterText) : null,
      interactive: diffPreviewInteractive(props),
      diffStyle: CoreDiffStyle(aspectRatio: diffPreviewAspectRatio(props), initialPosition: position),
      before: const _Landscape(vivid: false),
      after: const _Landscape(vivid: true),
    ),
  );
}

/// 장면의 틀 — Web 장면의 폭과 맞춘다. 좁은 무대에서는 줄어든다. 폭을 320 아래로
/// 두어, 가장 높은 1:1 비율도 플레이그라운드의 Flutter 칸에 다 들어간다.
Widget _frame(Widget child, {double width = CoreLayout.layout320}) => SizedBox(width: width, child: child);

/// 풍경 비교 하나.
Widget _scene({bool interactive = true, Widget? beforeLabel, Widget? afterLabel, CoreDiffStyle? style}) => Diff(
  ariaLabel: diffSceneName,
  beforeLabel: beforeLabel,
  afterLabel: afterLabel,
  interactive: interactive,
  diffStyle: style,
  before: const _Landscape(vivid: false),
  after: const _Landscape(vivid: true),
);

/// 시작 위치가 [position] 인 비교와 그 값을 적은 글.
Widget _positioned(double position) => _frame(
  Column(
    mainAxisSize: MainAxisSize.min,
    spacing: CoreSpace.space8,
    children: [
      _scene(style: CoreDiffStyle(initialPosition: position)),
      Text('initialPosition: $position').labelSmall.onSurfaceVariant,
    ],
  ),
  width: CoreLayout.layout160,
);

/// 색 토큰으로 그린 풍경 — 해 하나와 언덕 둘. 위치와 지름이 프레임 크기의
/// 비율이라 프레임과 함께 커지고 줄어든다.
class _Landscape extends StatelessWidget {
  const _Landscape({required this.vivid});

  /// false 면 흐린 색, true 면 선명한 색.
  final bool vivid;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    Color paint(CoreColorToken token) => colors.resolve(CoreColor.token(token)).toValue();

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        return Stacks(
          children: [
            Position.fill(child: ColoredBox(color: paint(vivid ? diffSkyVivid : diffSkyMuted))),
            for (final disc in diffLandscapeDiscs)
              Position(
                left: width * disc.left,
                top: height * disc.top,
                width: width * disc.size,
                height: width * disc.size,
                child: ClipOval(child: ColoredBox(color: paint(vivid ? disc.vivid : disc.muted))),
              ),
          ],
        );
      },
    );
  }
}

/// 글자 비교의 한쪽 면. 가운데의 손잡이가 글을 가리지 않도록 글을 아래쪽에
/// 둔다.
class _TextFace extends StatelessWidget {
  const _TextFace(this.fill, this.text);

  final CoreColorToken fill;
  final Widget text;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Theme.of(context).colorScheme.resolve(CoreColor.token(fill)).toValue(),
    child: Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: CoreSpace.space16),
        child: text,
      ),
    ),
  );
}

/// 관련 컴포넌트 그림의 항목 하나 — 번호를 적은 색 면.
class _Slide extends StatelessWidget {
  const _Slide(this.index);

  final int index;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Theme.of(context).colorScheme.resolve(const CoreColor.token(CoreColors.surfaceContainerHigh)).toValue(),
    child: Center(child: Text('${index + 1} / 3').titleLarge.onSurface),
  );
}
