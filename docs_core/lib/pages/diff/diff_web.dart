/// Diff 페이지의 미리보기 — Jaspr Web.
///
/// 속성 빌더는 `<Preview props>` · 플레이그라운드가, 장면은
/// `<Preview demo="diff/...">` 가 읽는다. 같은 이름의 Flutter
/// 파일(`diff_flutter.dart`)과 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
///
/// Web 의 Diff 는 안의 층이 모두 절대 위치라 내용에서 나오는 폭이 없다.
/// 그래서 Diff 는 늘 폭을 정한 틀([_frame]) 안에 둔다. 두 콘텐츠는 층을 꽉
/// 채우도록 폭과 높이를 100% 로 둔다.
library;

import 'package:coui_web/coui_web.dart';

import '../../previews/props/web_prop_previews.dart';
import '../page_kit_web.dart';
import 'diff_page.dart';

/// 속성 → Component.
WebPropPreviewBuilder? get propPreview => _diff;

/// 장면 이름(`diff/<장면>`) → 장면.
final Map<String, Component Function()> demos = {
  // 구조 — `before` · `after` 번호가 찾을 표지는 그림 안의 작은 점에, 이름표
  // 번호가 찾을 표지는 왼쪽 이름표의 글을 감싼 칸에 둔다. 구조 표시를 감싼
  // 상자는 내용 폭이라, 폭을 화면에서 뺀 값으로 묶는다.
  'diff/anatomy': () => _frame(
    Diff(
      ariaLabel: diffSceneName,
      beforeLabel: const span([Text(diffBeforeText)], attributes: {'data-docs-part': 'diff-label'}),
      afterLabel: const Text(diffAfterText),
      before: _landscape(vivid: false, part: 'diff-before', partLeft: '18%'),
      after: _landscape(vivid: true, part: 'diff-after', partLeft: '82%'),
    ),
    // 20rem 이면 높이가 커져 분할선 위의 구조 번호가 무대 밖으로 나간다.
    width: 'min(18rem, calc(100vw - 8rem))',
  ),
  'diff/content-text': () => _frame(
    Diff(
      ariaLabel: diffTextSceneName,
      before: _textFace(CoreColors.primary, Text(diffTextSample).displaySmall.onPrimary),
      after: _textFace(CoreColors.surfaceContainer, Text(diffTextSample).displaySmall.onSurface),
    ),
  ),
  'diff/positions': () => docsWebDemoRow([_positioned(0.25), _positioned(0.75)]),
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
    Carousel(items: [for (var index = 0; index < 3; index++) _slide(index, height: '7rem')]),
    width: _relatedWidth,
  ),
  'diff/related-hover-gallery': () => _frame(
    HoverGallery(
      itemCount: 3,
      itemBuilder: (index) => _slide(index, height: '100%'),
      hoverGalleryStyle: const CoreHoverGalleryStyle(height: CoreSpace.space112),
    ),
    width: _relatedWidth,
  ),
};

/// 카드 안 장면의 폭 — 좁은 카드에서는 줄어든다.
const String _cardWidth = 'min(15rem, 100%)';

/// 관련 컴포넌트 그림의 폭.
const String _relatedWidth = 'min(15rem, 100%)';

Component _diff(Map<String, String> props, String? label) {
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
      before: _landscape(vivid: false),
      after: _landscape(vivid: true),
    ),
  );
}

/// 폭을 정한 틀 — Flutter 장면의 `SizedBox(width: …)` 자리다.
Component _frame(Component child, {String width = 'min(20rem, 100%)'}) =>
    div(styles: Styles(raw: {'width': width}), [child]);

/// 풍경 비교 하나.
Component _scene({bool interactive = true, Component? beforeLabel, Component? afterLabel, CoreDiffStyle? style}) =>
    Diff(
      ariaLabel: diffSceneName,
      beforeLabel: beforeLabel,
      afterLabel: afterLabel,
      interactive: interactive,
      diffStyle: style,
      before: _landscape(vivid: false),
      after: _landscape(vivid: true),
    );

/// 시작 위치가 [position] 인 비교와 그 값을 적은 글.
Component _positioned(double position) => div(
  styles: Styles(
    raw: {'display': 'flex', 'flex-direction': 'column', 'gap': 'var(--coui-space-8)', 'width': '10rem'},
  ),
  [
    _scene(style: CoreDiffStyle(initialPosition: position)),
    Text('initialPosition: $position').labelSmall.onSurfaceVariant,
  ],
);

/// 색 토큰으로 그린 풍경 — 해 하나와 언덕 둘. [part] 를 주면 [partLeft] 자리에
/// 구조 번호가 찾을 작은 점을 둔다.
Component _landscape({required bool vivid, String? part, String partLeft = '50%'}) => div(
  styles: Styles(
    raw: {
      'position': 'relative',
      'width': '100%',
      'height': '100%',
      'overflow': 'hidden',
      'background-color': CoreColor.token(vivid ? diffSkyVivid : diffSkyMuted).toValue(),
    },
  ),
  [
    for (final disc in diffLandscapeDiscs)
      div(
        styles: Styles(
          raw: {
            'position': 'absolute',
            'left': '${disc.left * 100}%',
            'top': '${disc.top * 100}%',
            'width': '${disc.size * 100}%',
            'aspect-ratio': '1',
            'border-radius': '50%',
            'background-color': CoreColor.token(vivid ? disc.vivid : disc.muted).toValue(),
          },
        ),
        const [],
      ),
    if (part != null)
      div(
        attributes: {'data-docs-part': part},
        styles: Styles(raw: {'position': 'absolute', 'left': partLeft, 'top': '74%', 'width': '1px', 'height': '1px'}),
        const [],
      ),
  ],
);

/// 글자 비교의 한쪽 면. 가운데의 손잡이가 글을 가리지 않도록 글을 아래쪽에
/// 둔다.
Component _textFace(CoreColorToken fill, Component text) => div(
  styles: Styles(
    raw: {
      'display': 'flex',
      'align-items': 'flex-end',
      'justify-content': 'center',
      'box-sizing': 'border-box',
      'width': '100%',
      'height': '100%',
      'padding-bottom': 'var(--coui-space-16)',
      'background-color': CoreColor.token(fill).toValue(),
    },
  ),
  [text],
);

/// 관련 컴포넌트 그림의 항목 하나 — 번호를 적은 색 면.
Component _slide(int index, {required String height}) => div(
  styles: Styles(
    raw: {
      'display': 'flex',
      'align-items': 'center',
      'justify-content': 'center',
      'width': '100%',
      'height': height,
      'pointer-events': 'none',
      'background-color': const CoreColor.token(CoreColors.surfaceContainerHigh).toValue(),
    },
  ),
  [Text('${index + 1} / 3').titleLarge.onSurface],
);
