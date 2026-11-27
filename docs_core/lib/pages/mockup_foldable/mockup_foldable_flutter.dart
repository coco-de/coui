/// MockupFoldable 페이지의 미리보기 — Flutter.
///
/// 속성 빌더는 `<Preview props>` · `<Card props>` · 플레이그라운드가, 장면은
/// `<Preview demo="mockup-foldable/...">` 가 읽는다. 같은 이름의 Web
/// 파일(`mockup_foldable_web.dart`)과 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
///
/// Flutter 의 목업은 부모가 높이를 정해 주면 그 높이를 다 차지하고 기기를
/// 위에 둔다. 그래서 장면은 내용 높이만 차지하는 `Column` 에 담는다([_hug]).
library;

import 'package:coui_flutter/coui_flutter.dart';

import '../../previews/props/flutter_prop_previews.dart';
import '../../shared/preview_props.dart';
import 'mockup_foldable_page.dart'
    show
        mockupFoldableAnatomyWidth,
        mockupFoldablePreviewAngle,
        mockupFoldablePreviewBrightness,
        mockupFoldablePreviewStyle,
        mockupFoldablePreviewWidth,
        mockupFoldableReadout;

/// 속성 → Widget.
FlutterPropPreviewBuilder? get propPreview => _mockupFoldable;

/// 장면 이름(`mockup-foldable/<장면>`) → 장면.
final Map<String, Widget Function()> demos = {
  // 구조 — 펼친 기기. child 의 자리를 칠해 아일랜드의 열이 비는 것을 보인다.
  'mockup-foldable/anatomy': () => _hug(
    const MockupFoldable(width: mockupFoldableAnatomyWidth, child: _ContentArea()),
  ),
  'mockup-foldable/fold-reading': () => _hug(
    const MockupFoldable(
      foldAngle: CoreMockupFold.halfOpen,
      width: 280,
      child: _FoldReadout(),
    ),
  ),
  'mockup-foldable/island-style': () => _hug(
    const MockupFoldable(
      foldAngle: CoreMockupFold.closed,
      width: 280,
      mockupFoldableStyle: CoreMockupFoldableStyle(
        islandWidth: CoreSize.size112,
        islandIconColor: CoreColor.token(CoreColors.primary),
      ),
      child: _FoldReadout(),
    ),
  ),
  'mockup-foldable/do-flat-controls': () => _hug(MockupFoldable(width: 240, child: _checkout())),
  'mockup-foldable/dont-bent-controls': () => _hug(
    MockupFoldable(
      foldAngle: CoreMockupFold.halfOpen,
      width: 240,
      child: _checkout(),
    ),
  ),
  'mockup-foldable/related-mockup-device': () => _hug(
    MockupDevice(
      device: CoreMockupDevice.tablet,
      orientation: CoreMockupOrientation.landscape,
      width: 200,
      child: Center(child: const Text('태블릿').labelMedium.onSurface),
    ),
  ),
  'mockup-foldable/related-mockup-browser': () => SizedBox(
    width: 200,
    height: 120,
    child: MockupBrowser(addressBar: null, child: Center(child: const Text('앱 창').labelMedium.onSurface)),
  ),
};

/// 플레이그라운드 — 좁은 칸(두 플랫폼을 나란히 볼 때)에서는 그림 전체를 줄인다.
Widget _mockupFoldable(Map<String, String> props, String? label) => FittedBox(
  fit: BoxFit.scaleDown,
  child: SizedBox(
    width: mockupFoldablePreviewWidth(props),
    child: _hug(
      MockupFoldable(
        foldAngle: mockupFoldablePreviewAngle(props),
        width: mockupFoldablePreviewWidth(props),
        showCamera: previewFlag(props, 'showCamera', fallback: CoreMockupFoldableContract.defaultShowCamera),
        showStatus: previewFlag(props, 'showStatus', fallback: CoreMockupFoldableContract.defaultShowStatus),
        showGestureBar: previewFlag(props, 'showGestureBar'),
        screenBrightness: mockupFoldablePreviewBrightness(props),
        mockupFoldableStyle: mockupFoldablePreviewStyle(props),
        child: const _FoldReadout(),
      ),
    ),
  ),
);

/// [child] 를 내용 높이만큼만 차지하게 한다.
Widget _hug(Widget child) => Column(mainAxisSize: MainAxisSize.min, children: [child]);

/// 접힌 화면에서 조작을 보일 때와 펼친 화면에서 보일 때를 견주는 버튼.
Widget _checkout() => Center(
  child: Button(size: CoreComponentSize.sm, onPressed: () {}, child: const Text('결제하기')),
);

/// child 가 받는 자리를 면으로 칠한다.
class _ContentArea extends StatelessWidget {
  const _ContentArea();

  @override
  Widget build(BuildContext context) {
    final fill = Theme.of(context).colorScheme.resolve(const CoreColor.token(CoreColors.surfaceContainer)).toValue();

    return ColoredBox(
      color: fill,
      child: Center(child: const Text('child').labelMedium.onSurfaceVariant),
    );
  }
}

/// 화면 위의 장면이 `FoldScope` 로 읽은 접힘을 보인다. 화면이 두 칸으로
/// 갈라지면 첫 칸을 접힌 자리까지로 두어, 두 낱말이 접힘의 양쪽에 선다.
class _FoldReadout extends StatelessWidget {
  const _FoldReadout();

  @override
  Widget build(BuildContext context) {
    final fold = FoldScope.of(context);
    final (posture, segments) = mockupFoldableReadout(fold.posture);
    final title = Text(posture).titleSmall.onSurface;
    final detail = Text(segments).bodySmall.onSurfaceVariant;
    if (!fold.isSplit) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [title, detail]),
      );
    }

    return Row(
      children: [
        SizedBox(
          width: fold.segments.first.width,
          child: Center(child: title),
        ),
        Expanded(child: Center(child: detail)),
      ],
    );
  }
}
