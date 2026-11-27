/// LoadingRegion 페이지 — 플레이그라운드. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `loading_region_web.dart` · `loading_region_flutter.dart` 가 그린다.
/// 이 폴더는 `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
///
/// LoadingRegion 은 화면에 아무것도 그리지 않는다. 그래서 미리보기는
/// Skeleton 아래에 지금 설정에서 만들어지는 라이브 영역의 수와 문구를 문서의
/// 글로 적는다. 속성은 둘이다: `semanticLabel`(알릴 문구)과
/// `region`(`false` 면 영역 없이 Skeleton 만 둔다). 두 플랫폼 빌더와 코드가
/// 같은 뜻으로 읽도록 해석과 글은 이 파일 한 곳에 둔다.
library;

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/loading-region.md`.
const String slug = 'loading-region';

/// 장면과 코드에서 쓰는 주문 영역의 문구.
const String loadingRegionOrdersLabel = '주문 목록 불러오는 중';

/// 장면에서 쓰는 추천 상품 영역의 문구.
const String loadingRegionProductsLabel = '추천 상품 불러오는 중';

/// 영역 하나에 두는 Skeleton 수.
const int loadingRegionSkeletonCount = 3;

/// 미리보기 영역의 폭(logical px).
const double loadingRegionPreviewWidth = 240;

/// 속성의 `semanticLabel` — 없거나 빈 값이면 `null`(로케일 문구).
String? loadingRegionPreviewLabel(Map<String, String> props) {
  final value = props['semanticLabel'];
  return value == null || value.isEmpty ? null : value;
}

/// 속성의 `region` — `false` 가 아니면 LoadingRegion 으로 감싼다.
bool loadingRegionPreviewWrapped(Map<String, String> props) => previewFlag(props, 'region', fallback: true);

/// 미리보기 아래의 설명 글. [label] 은 실제로 알리는 문구다.
///
/// 영역으로 감싸면 라이브 영역이 하나이고, 감싸지 않으면 Skeleton 마다 하나씩
/// 생긴다.
String loadingRegionCaption({required bool wrapped, required String label}) =>
    wrapped ? '라이브 영역 1개 · “$label”' : '라이브 영역 $loadingRegionSkeletonCount개 · 각각 “$label”';

/// 플레이그라운드. 없는 컴포넌트는 `null`.
///
/// 겉모습이 없어 바꿔 볼 값은 문구 하나이고, 영역이 하는 일은 감쌌을 때와
/// 감싸지 않았을 때를 견주어 보인다.
DocsPlaygroundSpec? get playground => const DocsPlaygroundSpec(
  initial: {'semanticLabel': loadingRegionOrdersLabel},
  controls: [
    DocsPlaygroundFlag(label: '무엇이 로딩 중인지 말하기', on: {'semanticLabel': loadingRegionOrdersLabel}),
    DocsPlaygroundFlag(label: '영역 없이 Skeleton만 두기', on: {'region': 'false'}),
  ],
  code: _loadingRegionCode,
  webCode: _loadingRegionWebCode,
);

/// 크기 표. 크기 축이 없는 컴포넌트는 `null`.
DocsSizeSpec Function()? get sizeSpec => null;

String _loadingRegionCode(Map<String, String> props, String? label) {
  final rows = List.filled(loadingRegionSkeletonCount, '    Skeleton(height: 16),').join('\n');
  return _wrapped(props, 'Column(\n  spacing: CoreSpace.space8,\n  children: [\n$rows\n  ],\n)');
}

String _loadingRegionWebCode(Map<String, String> props, String? label) {
  final rows = List.filled(loadingRegionSkeletonCount, "    Skeleton(height: '16px'),").join('\n');
  return _wrapped(props, "div(\n  [\n$rows\n  ],\n  classes: 'flex flex-col gap-space8',\n)");
}

/// 영역으로 감싸는 설정이면 [skeletons] 를 `LoadingRegion` 안에 넣는다.
String _wrapped(Map<String, String> props, String skeletons) {
  if (!loadingRegionPreviewWrapped(props)) return skeletons;
  final semanticLabel = loadingRegionPreviewLabel(props);
  return [
    'LoadingRegion(',
    if (semanticLabel != null) "  semanticLabel: '$semanticLabel',",
    '  child: ${skeletons.replaceAll('\n', '\n  ')},',
    ')',
  ].join('\n');
}
