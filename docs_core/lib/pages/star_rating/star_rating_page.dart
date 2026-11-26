/// StarRating 페이지 — 플레이그라운드와 크기 표. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `star_rating_web.dart` · `star_rating_flutter.dart` 가 그린다. 이 폴더는
/// `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
library;

import 'package:coui_core/coui_core.dart';

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/star-rating.md`.
const String slug = 'star-rating';

/// 속성에 값이 없을 때 미리보기가 그리는 별점 — 반별이 보이는 값.
const double starRatingPreviewValue = 3.5;

/// 개수를 켤 때 미리보기 · 코드가 함께 쓰는 평가 개수.
const int starRatingSampleCount = 128;

/// 표시 전용 장면(`star-rating/display-only`)의 평균 평점 — 두 플랫폼 장면이
/// 함께 읽는다.
const double starRatingAverageValue = 4.5;

/// 상태 장면의 칸 — 두 플랫폼 장면이 함께 읽는다. 표시 전용(`onChanged`
/// 없음)은 활성과 같은 색이라 칸으로 두지 않는다.
const List<String> starRatingStateLabels = ['활성', '비활성'];

/// 별 모양 장면의 세 모양 — 두 플랫폼 장면이 함께 읽는다. 값을 비운 칸은
/// 위젯의 기본값(꼭짓점 5 · 안쪽 반지름 0.4 · 꼭짓점 둥글기 0.15 · 골짜기 0)을 쓴다.
///
/// 꼭짓점 둥글기 + 골짜기 둥글기는 1 을 넘지 않는다 — Flutter 의 `StarBorder`
/// 가 그 합을 assert 한다.
const List<({String label, double? points, double? innerRadiusRatio, double? pointRounding, double? valleyRounding})>
starRatingShapes = [
  (label: '기본', points: null, innerRadiusRatio: null, pointRounding: null, valleyRounding: null),
  (label: '꼭짓점 6개', points: 6, innerRadiusRatio: 0.5, pointRounding: null, valleyRounding: null),
  (label: '둥근 별', points: null, innerRadiusRatio: null, pointRounding: 0.4, valleyRounding: 0.2),
];

/// 속성의 별점 — 없거나 숫자가 아니면 [starRatingPreviewValue].
double starRatingValueOf(Map<String, String> props) => double.tryParse(props['value'] ?? '') ?? starRatingPreviewValue;

/// 속성의 평가 개수 — 없거나 정수가 아니면 `null`.
int? starRatingCountOf(Map<String, String> props) => int.tryParse(props['count'] ?? '');

/// 플레이그라운드. 없는 컴포넌트는 `null`.
///
/// 별점에는 variant 가 없다. 크기 선택지는 크기 행이 있는 sm · md · lg · xl
/// 이다 — `xs` 는 크기 행이 없어 가장 작은 행(`sm`), `xl2` 는 바로 아래 행
/// (`xl`)으로 그려지고, assert 가 켜진 실행에서는 assert 가 실패한다.
///
/// 세로 배치(`direction`)는 컨트롤로 두지 않는다 — 세로 별점(`lg` 136 ·
/// `xl` 176)은 Flutter 칸의 기본 높이(80, `preview_constraints.dart`)를
/// 넘는다. 세로는 페이지의 `<Preview props="direction=vertical">` 가 보인다.
DocsPlaygroundSpec? get playground => const DocsPlaygroundSpec(
  initial: {'value': '3.5', 'size': 'lg'},
  controls: [
    DocsPlaygroundChoice(label: 'value', prop: 'value', options: ['0', '1.5', '3.5', '5'], segmented: true),
    DocsPlaygroundChoice(label: 'size', prop: 'size', options: ['sm', 'md', 'lg', 'xl'], segmented: true),
    DocsPlaygroundFlag(label: '값 표시', on: {'showValue': 'true'}),
    DocsPlaygroundFlag(label: '개수 표시', on: {'showCount': 'true', 'count': '$starRatingSampleCount'}),
    DocsPlaygroundFlag(label: '비활성', on: {'enabled': 'false'}),
  ],
  code: _starRatingCode,
);

/// 크기 표. 크기 축이 없는 컴포넌트는 `null`.
DocsSizeSpec Function()? get sizeSpec => _starRatingSpec;

String _starRatingCode(Map<String, String> props, String? label) {
  final count = starRatingCountOf(props);
  final lines = [
    'value: ${props['value'] ?? '$starRatingPreviewValue'},',
    "size: CoreComponentSize.${props['size'] ?? CoreStarRatingStyle.defaultSize.name},",
    if (previewFlag(props, 'showValue')) 'showValue: true,',
    if (previewFlag(props, 'showCount')) 'showCount: true,',
    if (count != null) 'count: $count,',
    if (props['direction'] == CoreAxis.vertical.name) 'direction: CoreAxis.vertical,',
    if (!previewFlag(props, 'enabled', fallback: true)) 'enabled: false,',
    'onChanged: setRating,',
  ];
  return 'StarRating(\n${lines.map((l) => '  $l').join('\n')}\n)';
}

DocsSizeSpec _starRatingSpec() {
  return DocsSizeSpec(
    columns: const ['size', '별', '별 사이 간격', '값 · 개수 글자'],
    rows: [
      for (final MapEntry(key: size, value: row) in CoreStarRatingStyle.defaultsBySize.entries)
        DocsSizeSpecRow(
          size: size,
          cells: [
            docsSizeNumber(row.starSize),
            docsSizeNumber(row.starSpacing),
            docsSizeLabel(row.valueStyle),
          ],
        ),
    ],
  );
}
