/// MockupFoldable 페이지의 미리보기 — Jaspr Web.
///
/// 속성 빌더는 `<Preview props>` · `<Card props>` · 플레이그라운드가, 장면은
/// `<Preview demo="mockup-foldable/...">` 가 읽는다. 같은 이름의 Flutter
/// 파일(`mockup_foldable_flutter.dart`)과 컴포넌트 · 속성 · 장면 이름이 같아야
/// 한다.
///
/// 기기는 부모가 좁아도 그림이 줄지 않는다. 그래서 장면은 문서 무대에
/// 들어가는 너비를 정해 둔다.
library;

import 'package:coui_web/coui_web.dart';

import '../../previews/props/web_prop_previews.dart';
import '../../shared/preview_props.dart';
import 'mockup_foldable_page.dart'
    show
        mockupFoldableAnatomyWidth,
        mockupFoldablePreviewAngle,
        mockupFoldablePreviewBrightness,
        mockupFoldablePreviewStyle,
        mockupFoldablePreviewWidth,
        mockupFoldableReadout;

/// 속성 → Component.
WebPropPreviewBuilder? get propPreview => _mockupFoldable;

/// 장면 이름(`mockup-foldable/<장면>`) → 장면.
final Map<String, Component Function()> demos = {
  // 구조 — 펼친 기기. child 의 자리를 칠해 아일랜드의 열이 비는 것을 보인다.
  'mockup-foldable/anatomy': () => MockupFoldable(
    width: mockupFoldableAnatomyWidth,
    child: div(
      classes: 'flex h-full w-full items-center justify-center bg-surface-container',
      attributes: const {'data-docs-part': 'content'},
      [Text('child').labelMedium.onSurfaceVariant],
    ),
  ),
  'mockup-foldable/fold-reading': () => const MockupFoldable(
    foldAngle: CoreMockupFold.halfOpen,
    width: 280,
    child: _FoldReadout(),
  ),
  'mockup-foldable/island-style': () => const MockupFoldable(
    foldAngle: CoreMockupFold.closed,
    width: 280,
    mockupFoldableStyle: CoreMockupFoldableStyle(
      islandWidth: CoreSize.size112,
      islandIconColor: CoreColor.token(CoreColors.primary),
    ),
    child: _FoldReadout(),
  ),
  'mockup-foldable/do-flat-controls': () => MockupFoldable(width: 240, child: _checkout()),
  'mockup-foldable/dont-bent-controls': () => MockupFoldable(
    foldAngle: CoreMockupFold.halfOpen,
    width: 240,
    child: _checkout(),
  ),
  'mockup-foldable/related-mockup-device': () => MockupDevice(
    device: CoreMockupDevice.tablet,
    orientation: CoreMockupOrientation.landscape,
    width: 200,
    child: _centered(Text('태블릿').labelMedium.onSurface),
  ),
  'mockup-foldable/related-mockup-browser': () => div(
    styles: Styles(raw: {'width': pinnedLengthCss(200), 'height': pinnedLengthCss(120)}),
    [MockupBrowser(addressBar: null, child: _centered(Text('앱 창').labelMedium.onSurface))],
  ),
};

Component _mockupFoldable(Map<String, String> props, String? label) => MockupFoldable(
  foldAngle: mockupFoldablePreviewAngle(props),
  width: mockupFoldablePreviewWidth(props),
  showCamera: previewFlag(props, 'showCamera', fallback: CoreMockupFoldableContract.defaultShowCamera),
  showStatus: previewFlag(props, 'showStatus', fallback: CoreMockupFoldableContract.defaultShowStatus),
  showGestureBar: previewFlag(props, 'showGestureBar'),
  screenBrightness: mockupFoldablePreviewBrightness(props),
  mockupFoldableStyle: mockupFoldablePreviewStyle(props),
  child: const _FoldReadout(),
);

/// 화면 가운데에 놓는 상자.
Component _centered(Component child) => div(classes: 'flex h-full w-full items-center justify-center', [child]);

/// 접힌 화면에서 조작을 보일 때와 펼친 화면에서 보일 때를 견주는 버튼.
Component _checkout() => _centered(
  Button(size: CoreComponentSize.sm, onPressed: () {}, child: const Text('결제하기')),
);

/// 화면 위의 장면이 `FoldScope` 로 읽은 접힘을 보인다. 화면이 두 칸으로
/// 갈라지면 첫 칸을 접힌 자리까지로 두어, 두 낱말이 접힘의 양쪽에 선다.
class _FoldReadout extends StatelessComponent {
  const _FoldReadout();

  @override
  Component build(BuildContext context) {
    final fold = FoldScope.of(context);
    final (posture, segments) = mockupFoldableReadout(fold.posture);
    final title = Text(posture).titleSmall.onSurface;
    final detail = Text(segments).bodySmall.onSurfaceVariant;
    if (!fold.isSplit) {
      return div(classes: 'flex h-full w-full flex-col items-center justify-center', [title, detail]);
    }
    return div(classes: 'flex h-full w-full', [
      div(
        classes: 'flex shrink-0 items-center justify-center',
        styles: Styles(raw: {'width': pinnedLengthCss(fold.segments.first.width)}),
        [title],
      ),
      div(classes: 'flex min-w-0 flex-1 items-center justify-center', [detail]),
    ]);
  }
}
