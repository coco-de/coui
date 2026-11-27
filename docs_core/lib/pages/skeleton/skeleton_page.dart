/// Skeleton 페이지 — 플레이그라운드. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `skeleton_web.dart` · `skeleton_flutter.dart` 가 그린다. 이 폴더는
/// `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
///
/// 속성은 셋이다: `variant`(모양), `lines`(`text` 의 줄 수), `fromOpacity`
/// (맥동의 쉼 끝). `lines` 와 `fromOpacity` 는 `skeletonStyle` 의 값이다. 두
/// 플랫폼 빌더와 코드가 같은 뜻으로 읽도록 해석은 이 파일 한 곳에 둔다.
/// Skeleton 에는 크기 단계가 없어 크기 표를 두지 않는다.
library;

import 'package:coui_core/coui_core.dart';

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/skeleton.md`.
const String slug = 'skeleton';

/// 미리보기와 장면의 폭(logical px).
const double skeletonPreviewWidth = 240;

/// 플레이그라운드에서 맥동 폭을 키웠을 때의 `fromOpacity`.
const double skeletonStrongFromOpacity = CoreOpacity.opacity20;

/// 목록 장면의 행 수.
const int skeletonListRows = 3;

/// 겉모습을 바꾸는 장면의 마지막 줄 폭 비율.
const double skeletonShortLastLine = 0.4;

/// 속성의 `variant`.
CoreSkeletonVariant skeletonPreviewVariant(Map<String, String> props) =>
    previewEnum(CoreSkeletonVariant.values, props['variant'], CoreSkeletonVariant.defaultVariant);

/// 속성 → `skeletonStyle`. 바꿀 값이 없으면 `null`.
///
/// 줄 수는 `text` 에만 닿으므로 다른 모양에서는 싣지 않는다.
CoreSkeletonStyle? skeletonPreviewStyle(Map<String, String> props) {
  final lines = skeletonPreviewVariant(props) == CoreSkeletonVariant.text ? int.tryParse(props['lines'] ?? '') : null;
  final fromOpacity = double.tryParse(props['fromOpacity'] ?? '');
  if (lines == null && fromOpacity == null) return null;
  return CoreSkeletonStyle(lines: lines, fromOpacity: fromOpacity);
}

/// 플레이그라운드. 없는 컴포넌트는 `null`.
DocsPlaygroundSpec? get playground => _playground;

/// 크기 표. 크기 축이 없는 컴포넌트는 `null`.
DocsSizeSpec Function()? get sizeSpec => null;

final DocsPlaygroundSpec _playground = DocsPlaygroundSpec(
  initial: {'variant': CoreSkeletonVariant.defaultVariant.name, 'lines': '${CoreSkeletonStyle.defaultLines}'},
  controls: [
    DocsPlaygroundChoice(
      label: 'variant',
      prop: 'variant',
      options: [for (final variant in CoreSkeletonVariant.values) variant.name],
      segmented: true,
    ),
    const DocsPlaygroundChoice(label: 'lines', prop: 'lines', options: ['2', '3', '4', '5'], segmented: true),
    const DocsPlaygroundFlag(label: '맥동 폭 키우기', on: {'fromOpacity': '$skeletonStrongFromOpacity'}),
  ],
  code: _skeletonCode,
  webCode: _skeletonWebCode,
);

String _skeletonCode(Map<String, String> props, String? label) => _code(props, web: false);

String _skeletonWebCode(Map<String, String> props, String? label) => _code(props, web: true);

/// 속성 → 코드. 크기는 Flutter 가 숫자, Web 이 CSS 문자열로 받는다. 기본값과
/// 같은 줄 수는 적지 않는다.
String _code(Map<String, String> props, {required bool web}) {
  String length(double value) => web ? "'${value.toInt()}px'" : '${value.toInt()}';

  final style = skeletonPreviewStyle(props);
  final lines = style?.lines;
  final styleArgs = [
    if (lines != null && lines != CoreSkeletonStyle.defaultLines) 'lines: $lines,',
    if (style?.fromOpacity == skeletonStrongFromOpacity) 'fromOpacity: CoreOpacity.opacity20,',
  ];
  final (name, sizeArgs) = switch (skeletonPreviewVariant(props)) {
    CoreSkeletonVariant.rectangular => (
      'Skeleton',
      ['width: ${length(skeletonPreviewWidth)},', 'height: ${length(CoreSize.size40)},'],
    ),
    CoreSkeletonVariant.circular => ('Skeleton.circle', ['size: ${length(CoreSize.size48)},']),
    CoreSkeletonVariant.text => ('Skeleton.text', <String>[]),
  };
  final args = [
    ...sizeArgs,
    if (styleArgs.isNotEmpty)
      'skeletonStyle: CoreSkeletonStyle(\n${styleArgs.map((arg) => '    $arg').join('\n')}\n  ),',
  ];
  if (args.isEmpty) return '$name()';
  return '$name(\n${args.map((arg) => '  $arg').join('\n')}\n)';
}
