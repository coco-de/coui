/// AspectRatioBox 페이지의 미리보기 — Flutter.
///
/// 속성 빌더는 `<Preview props>` · 플레이그라운드가, 장면은
/// `<Preview demo="aspect-ratio-box/...">` 가 읽는다. 같은 이름의 Web
/// 파일(`aspect_ratio_box_web.dart`)과 컴포넌트 · 속성 · 장면 이름이 같아야
/// 한다.
///
/// 장면은 스크롤 안(높이 제한 없음)에서도 그려지므로, 모든 상자를 폭을 정한
/// 부모 안에 두어 높이가 폭에서 나오게 한다.
library;

import 'package:coui_flutter/coui_flutter.dart';

import '../../previews/props/flutter_prop_previews.dart';
import '../page_kit_flutter.dart';
import 'aspect_ratio_box_page.dart';

/// 속성 → Widget.
FlutterPropPreviewBuilder? get propPreview => _aspectRatioBox;

/// 장면 이름(`aspect-ratio-box/<장면>`) → 장면.
final Map<String, Widget Function()> demos = {
  'aspect-ratio-box/ratios': () => docsFlutterDemoRow([
    for (final MapEntry(key: name, value: ratio) in aspectRatioBoxRatios.entries)
      _sized(112, _box(ratio, aspectRatioBoxRatioLabel(name))),
  ]),
  'aspect-ratio-box/fallback': () => docsFlutterDemoRow([
    for (final (name, ratio) in aspectRatioBoxSceneInvalidRatios) _sized(72, _box(ratio, name)),
  ]),
  'aspect-ratio-box/widths': () => docsFlutterDemoRow([
    for (final width in aspectRatioBoxSceneWidths) _sized(width, _box(16 / 9, aspectRatioBoxSizeLabel(width, 16 / 9))),
  ]),
  'aspect-ratio-box/split': () => _sized(
    256,
    Row(
      children: [
        Expanded(child: _box(4 / 3, 'A')),
        const Gap.space8(),
        Expanded(child: _box(4 / 3, 'B')),
      ],
    ),
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

Widget _aspectRatioBox(Map<String, String> props, String? label) {
  final name = aspectRatioBoxPreviewRatio(props);
  return _sized(
    aspectRatioBoxPreviewParentWidth(props).toDouble(),
    _box(aspectRatioBoxRatios[name]!, label ?? aspectRatioBoxRatioLabel(name)),
  );
}

/// 비율 상자 하나 — 상자의 모양이 보이도록 색을 채운 Card 를 담는다.
Widget _box(double ratio, String text, {CoreBorderRadius? corners}) => AspectRatioBox(
  ratio: ratio,
  child: Card(
    cardStyle: CoreCardStyle(
      backgroundColor: const CoreColor.token(CoreColors.primaryContainer),
      borderRadius: corners,
      padding: CoreEdgeInsets.zero,
    ),
    child: Center(child: Text(text).titleSmall.onPrimaryContainer),
  ),
);

/// 폭이 [width](logical px)인 부모.
Widget _sized(double width, Widget child) => SizedBox(width: width, child: child);
