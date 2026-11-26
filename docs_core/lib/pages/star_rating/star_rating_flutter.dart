/// StarRating 페이지의 미리보기 — Flutter.
///
/// 속성 빌더는 `<Preview props>` · `<SizeSpec>` · `<Card props>` · 플레이그라운드가, 장면은
/// `<Preview demo="star-rating/...">` 가 읽는다. 같은 이름의 Web 파일(`star_rating_web.dart`)과
/// 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
library;

import 'package:coui_flutter/coui_flutter.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/flutter_prop_previews.dart';
import 'star_rating_page.dart';

/// 속성 → Widget.
FlutterPropPreviewBuilder? get propPreview => _starRating;

/// 장면 이름(`star-rating/<장면>`) → 장면.
///
/// 장면은 정지 그림이다 — 값이 바뀌는 데모도 고정값으로 그린다.
final Map<String, Widget Function()> demos = {
  'star-rating/anatomy': () => StarRating(
    value: starRatingPreviewValue,
    size: CoreComponentSize.xl,
    showValue: true,
    showCount: true,
    count: starRatingSampleCount,
    onChanged: (_) {},
  ),
  // 표시 전용 — `onChanged` 를 넘기지 않아 포인터에 반응하지 않는다.
  'star-rating/display-only': () => const StarRating(
    value: starRatingAverageValue,
    showValue: true,
    showCount: true,
    count: starRatingSampleCount,
  ),
  'star-rating/states': _starRatingStates,
  'star-rating/star': _starStates,
  'star-rating/shapes': _starRatingShapes,
  'star-rating/related-slider': () => _sized(Slider(value: 60, min: 0, max: 100, onChanged: (_) {})),
  'star-rating/related-range': () => _sized(Range(minValue: 20, maxValue: 70, onChanged: (_, _) {})),
  'star-rating/related-text-field': () => _sized(TextField(label: '평점', placeholder: const Text('0.0 ~ 5.0'))),
};

Widget _starRating(Map<String, String> props, String? label) => StarRating(
  value: starRatingValueOf(props),
  onChanged: (_) {},
  enabled: previewFlag(props, 'enabled', fallback: true),
  direction: previewEnum(CoreAxis.values, props['direction'], CoreAxis.horizontal),
  size: previewEnum(CoreComponentSize.values, props['size'], CoreStarRatingStyle.defaultSize),
  showValue: previewFlag(props, 'showValue'),
  showCount: previewFlag(props, 'showCount'),
  count: starRatingCountOf(props),
);

Widget _sized(Widget child, {double width = 192}) => SizedBox(width: width, child: child);

/// 라벨 아래에 칸을 하나씩 두고 나란히 놓는다 — Web 의 `.docs-demo-field-states`
/// 격자와 같은 배치.
Widget _labelledRow(List<String> labels, List<Widget> cells) => Wrap(
  spacing: CoreSpace.space16,
  runSpacing: CoreSpace.space12,
  children: [
    for (final (index, label) in labels.indexed)
      Column(
        mainAxisSize: MainAxisSize.min,
        spacing: CoreSpace.space8,
        children: [Text(label).labelSmall.onSurfaceVariant, cells[index]],
      ),
  ],
);

/// 상태 격자 — Web 과 같은 두 칸.
Widget _starRatingStates() => _labelledRow(starRatingStateLabels, [
  for (final label in starRatingStateLabels)
    StarRating(
      value: starRatingPreviewValue,
      showValue: true,
      enabled: label == starRatingStateLabels.first,
      onChanged: (_) {},
    ),
]);

/// 별 하나의 세 채움 — `filled` · `half` · `empty`.
Widget _starStates() => _labelledRow(
  [for (final state in CoreStarState.values) state.name],
  [for (final state in CoreStarState.values) Star(state: state, size: CoreComponentSize.xl)],
);

/// 별 모양 — 기본 · 꼭짓점 6개 · 둥근 별.
Widget _starRatingShapes() => _labelledRow(
  [for (final shape in starRatingShapes) shape.label],
  [
    for (final shape in starRatingShapes)
      StarRating(
        value: starRatingPreviewValue,
        onChanged: (_) {},
        starPoints: shape.points,
        starInnerRadiusRatio: shape.innerRadiusRatio,
        starPointRounding: shape.pointRounding,
        starValleyRounding: shape.valleyRounding,
      ),
  ],
);
