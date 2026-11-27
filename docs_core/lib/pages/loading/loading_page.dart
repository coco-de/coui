/// Loading 페이지 — 플레이그라운드와 크기 표. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `loading_web.dart` · `loading_flutter.dart` 가 그린다. 이 폴더는
/// `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
///
/// 속성 `size` 는 위젯의 `componentSize` 다(크기 표 블록이 `size` 로 넘긴다).
/// `duration` 은 `loadingStyle.duration` 을 밀리초로 받는다. 두 플랫폼 빌더와
/// 코드가 같은 뜻으로 읽도록 해석은 이 파일의 함수에 둔다.
library;

import 'package:coui_core/coui_core.dart';

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/loading.md`.
const String slug = 'loading';

/// 플레이그라운드. 없는 컴포넌트는 `null`.
DocsPlaygroundSpec? get playground => _playground;

/// 크기 표. 크기 축이 없는 컴포넌트는 `null`.
DocsSizeSpec Function()? get sizeSpec => _loadingSpec;

/// 속성의 `size` → `componentSize`. 없거나 모르는 이름이면 `null` — 크기를
/// 정하지 않은 `Loading` 이다.
CoreComponentSize? loadingPreviewSize(Map<String, String> props) => CoreComponentSize.values.asNameMap()[props['size']];

/// 속성의 `duration` → 느린 주기(2000ms). 다른 값은 `null`(variant 의 기본 주기).
Duration? loadingPreviewDuration(Map<String, String> props) =>
    props['duration'] == CoreDuration.scale.ms2000 ? const Duration(milliseconds: CoreDuration.ms2000) : null;

/// 속성 → `loadingStyle`. 바꾼 값이 없으면 `null`.
CoreLoadingStyle? loadingPreviewStyle(Map<String, String> props) {
  final duration = loadingPreviewDuration(props);
  return duration == null ? null : CoreLoadingStyle(duration: duration);
}

/// `loading/do-caption` 장면의 설명 글.
const String loadingDemoCaption = '파일을 올리는 중입니다';

/// 버튼 장면의 글.
const String loadingDemoBusyLabel = '저장 중';

/// `loading/dont-many` 장면의 행 — 행마다 표시를 하나씩 둔 모습.
const List<String> loadingDemoRows = ['주문 내역', '결제 수단', '배송지'];

/// `loading/related-loading-region` 장면이 알리는 문구.
const String loadingDemoRegionLabel = '주문 목록을 불러오는 중';

/// `loading/related-empty-state` 장면의 제목.
const String loadingDemoEmptyTitle = '결과가 없습니다';

/// `loading/pixel-size` 장면의 두 설명 — 선 두께를 비운 것과 적은 것.
const String loadingDemoDefaultStrokeCaption = '선 두께 2 (기본)';

/// `loading/pixel-size` 장면의 두 번째 설명.
const String loadingDemoThickStrokeCaption = '선 두께 6';

// 선택지는 enum 과 크기 행에서 읽는다 — 변형 · 톤 · 크기 행이 늘면
// 플레이그라운드도 따라온다.
final DocsPlaygroundSpec _playground = DocsPlaygroundSpec(
  initial: {
    'variant': CoreLoadingVariant.spinner.name,
    'tone': CoreLoadingTone.defaultTone.name,
    'size': CoreComponentSize.lg.name,
  },
  controls: [
    DocsPlaygroundChoice(
      label: 'variant',
      prop: 'variant',
      options: [for (final variant in CoreLoadingVariant.values) variant.name],
      segmented: true,
    ),
    DocsPlaygroundChoice(
      label: 'tone',
      prop: 'tone',
      options: [for (final tone in CoreLoadingTone.values) tone.name],
      segmented: true,
    ),
    DocsPlaygroundChoice(
      label: 'componentSize',
      prop: 'size',
      options: [for (final size in CoreLoadingStyle.defaultsBySize.keys) size.name],
      segmented: true,
    ),
    DocsPlaygroundFlag(label: '느리게 (주기 2초)', on: {'duration': CoreDuration.scale.ms2000}),
  ],
  code: _loadingCode,
);

/// 속성 → 코드. 기본값과 같은 축은 적지 않는다. `componentSize` 는 기본값이
/// `null` 이라 고른 크기를 늘 적는다.
String _loadingCode(Map<String, String> props, String? label) {
  final variant = previewEnum(CoreLoadingVariant.values, props['variant'], CoreLoadingVariant.spinner);
  final tone = previewEnum(CoreLoadingTone.values, props['tone'], CoreLoadingTone.defaultTone);
  final size = loadingPreviewSize(props);
  final lines = [
    if (variant != CoreLoadingVariant.spinner) 'variant: CoreLoadingVariant.${variant.name},',
    if (tone != CoreLoadingTone.defaultTone) 'tone: CoreLoadingTone.${tone.name},',
    if (size != null) 'componentSize: CoreComponentSize.${size.name},',
    if (loadingPreviewDuration(props) != null) ...[
      'loadingStyle: CoreLoadingStyle(',
      '  duration: Duration(milliseconds: CoreDuration.ms2000),',
      '),',
    ],
  ];
  final call = lines.isEmpty ? 'Loading()' : 'Loading(\n${lines.map((l) => '  $l').join('\n')}\n)';
  return tone == CoreLoadingTone.inverse ? '// primary 로 채운 면 위에 둡니다.\n$call' : call;
}

/// 계산한 치수를 소수 첫째 자리까지만 남긴다 — 곱셈의 부동소수점 꼬리를 뗀다.
double _tenths(double value) => (value * 10).roundToDouble() / 10;

DocsSizeSpec _loadingSpec() {
  return DocsSizeSpec(
    columns: const ['size', '상자 한 변', 'spinner 선 두께', 'dots 점 지름', 'bar 길이 × 두께', 'pulse 가운데 점'],
    rows: [
      for (final MapEntry(key: size, value: row) in CoreLoadingStyle.defaultsBySize.entries)
        DocsSizeSpecRow(
          size: size,
          cells: [
            docsSizeNumber(row.size),
            docsSizeNumber(row.strokeWidth),
            docsSizeNumber(row.dotSize),
            '${docsSizeNumber(row.size! * CoreLoadingStyle.defaultBarLengthRatio)} × ${docsSizeNumber(row.barHeight)}',
            docsSizeNumber(_tenths(row.size! * CoreLoadingStyle.defaultPulseDotRatio)),
          ],
        ),
    ],
  );
}
