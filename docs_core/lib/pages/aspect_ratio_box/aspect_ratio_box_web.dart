/// AspectRatioBox 페이지의 미리보기 — Jaspr Web.
///
/// 속성 빌더는 `<Preview props>` · 플레이그라운드가, 장면은
/// `<Preview demo="aspect-ratio-box/...">` 가 읽는다. 같은 이름의 Flutter
/// 파일(`aspect_ratio_box_flutter.dart`)과 컴포넌트 · 속성 · 장면 이름이
/// 같아야 한다.
///
/// Web 의 상자는 폭을 부모에게서만 받는다 — 담긴 내용은 상자의 크기에
/// 들어가지 않는다. 그래서 모든 장면은 상자를 폭을 정한 부모 안에 둔다.
library;

import 'package:coui_web/coui_web.dart';

import '../../previews/props/web_prop_previews.dart';
import 'aspect_ratio_box_page.dart';

/// 속성 → Component.
WebPropPreviewBuilder? get propPreview => _aspectRatioBox;

/// 장면 이름(`aspect-ratio-box/<장면>`) → 장면.
final Map<String, Component Function()> demos = {
  'aspect-ratio-box/ratios': () => _topRow([
    for (final MapEntry(key: name, value: ratio) in aspectRatioBoxRatios.entries)
      _sized(112, _box(ratio, aspectRatioBoxRatioLabel(name))),
  ]),
  'aspect-ratio-box/fallback': () => _topRow([
    for (final (name, ratio) in aspectRatioBoxSceneInvalidRatios) _sized(72, _box(ratio, name)),
  ]),
  'aspect-ratio-box/widths': () => _topRow([
    for (final width in aspectRatioBoxSceneWidths) _sized(width, _box(16 / 9, aspectRatioBoxSizeLabel(width, 16 / 9))),
  ]),
  'aspect-ratio-box/split': () => _sized(
    256,
    div(styles: Styles(raw: {'display': 'flex', 'align-items': 'flex-start'}), [
      _grow(_box(4 / 3, 'A')),
      const Gap.space8(),
      _grow(_box(4 / 3, 'B')),
    ]),
  ),
  'aspect-ratio-box/related-card': () => _sized(
    176,
    Card(
      variant: CoreCardVariant.outlined,
      cardStyle: const CoreCardStyle(sizing: CoreCardSizing.expand),
      media: _box(16 / 9, '16 : 9', corners: CoreBorderRadius.zero),
      body: const Text('표지와 설명').bodySmall.onSurface,
    ),
  ),
  'aspect-ratio-box/related-responsive-container': () => _sized(
    208,
    ResponsiveContainer(maxWidth: CoreResponsiveContainerMaxWidth.sm, child: _box(21 / 9, '21 : 9')),
  ),
};

Component _aspectRatioBox(Map<String, String> props, String? label) {
  final name = aspectRatioBoxPreviewRatio(props);
  return _sized(
    aspectRatioBoxPreviewParentWidth(props).toDouble(),
    _box(aspectRatioBoxRatios[name]!, label ?? aspectRatioBoxRatioLabel(name)),
  );
}

/// 비율 상자 하나 — 상자의 모양이 보이도록 색을 채운 Card 를 담는다.
Component _box(double ratio, String text, {CoreBorderRadius? corners}) => AspectRatioBox(
  ratio: ratio,
  child: Card(
    cardStyle: CoreCardStyle(
      backgroundColor: const CoreColor.token(CoreColors.primaryContainer),
      borderRadius: corners,
      padding: CoreEdgeInsets.zero,
    ),
    child: div(classes: 'flex h-full items-center justify-center', [Text(text).titleSmall.onPrimaryContainer]),
  ),
);

/// 폭이 [width](logical px)인 부모.
Component _sized(double width, Component child) => div(styles: Styles(raw: {'width': pinnedLengthCss(width)}), [child]);

/// 가로 flex 안에서 남은 폭을 똑같이 나눠 갖는 자리.
Component _grow(Component child) => div(styles: Styles(raw: {'flex': '1'}), [child]);

/// 상자 여럿을 위를 맞춰 나란히 놓는다 — 높이의 차이가 보이게. 문서 시트의
/// `docs-demo-row` 는 세로 가운데를 맞추므로 쓰지 않는다.
Component _topRow(List<Component> children) => div(
  styles: Styles(
    raw: {
      'display': 'flex',
      'flex-wrap': 'wrap',
      'justify-content': 'center',
      'align-items': 'flex-start',
      'gap': 'var(--coui-space-8)',
    },
  ),
  children,
);
