/// Tag 페이지 — 플레이그라운드와 크기 표. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `tag_web.dart` · `tag_flutter.dart` 가 그린다. 이 폴더는
/// `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
///
/// 속성은 넷이다: `color` · `emphasis` · `size`(enum 값의 이름)와
/// `pill`(`true` 면 [tagPillStyle] 을 `tagStyle` 로 넘긴다).
library;

import 'package:coui_core/coui_core.dart';

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/tag.md`.
const String slug = 'tag';

/// 플레이그라운드. 없는 컴포넌트는 `null`.
DocsPlaygroundSpec? get playground => _playground;

/// 크기 표. 크기 축이 없는 컴포넌트는 `null`.
DocsSizeSpec Function()? get sizeSpec => _tagSpec;

/// 미리보기에 라벨을 주지 않았을 때 태그 안에 넣는 글.
const String tagSampleText = '디자인';

/// 알약 모양 — 두 플랫폼의 속성 빌더가 같은 값을 쓴다.
const CoreTagStyle tagPillStyle = CoreTagStyle(borderRadius: CoreBorderRadius.all(CoreRadius.radius9999));

/// 분류색마다 태그에 적는 낱말 — 분류색 장면의 두 플랫폼이 함께 읽는다.
const Map<CoreCategoryColor, String> tagColorWords = {
  CoreCategoryColor.red: '빨강',
  CoreCategoryColor.orange: '주황',
  CoreCategoryColor.yellow: '노랑',
  CoreCategoryColor.green: '초록',
  CoreCategoryColor.blue: '파랑',
  CoreCategoryColor.purple: '보라',
  CoreCategoryColor.pink: '분홍',
  CoreCategoryColor.brown: '갈색',
  CoreCategoryColor.gray: '회색',
};

/// 좁은 부모에 여러 태그를 놓는 장면의 색과 글.
const List<(CoreCategoryColor, String)> tagWrapSamples = [
  (CoreCategoryColor.blue, '디자인'),
  (CoreCategoryColor.green, '개발'),
  (CoreCategoryColor.purple, '리서치'),
  (CoreCategoryColor.orange, '마케팅'),
  (CoreCategoryColor.pink, '콘텐츠'),
  (CoreCategoryColor.brown, '운영'),
  (CoreCategoryColor.gray, '기타'),
];

/// 목록 한 줄 장면의 제목.
const String tagRowTitle = '디자인 시스템 개편';

/// 목록 한 줄 장면의 태그.
const List<(CoreCategoryColor, String)> tagRowSamples = [
  (CoreCategoryColor.blue, '디자인'),
  (CoreCategoryColor.green, '개발'),
];

/// 같은 분류에 같은 색을 쓴 예.
const List<(CoreCategoryColor, String)> tagConsistentSamples = [
  (CoreCategoryColor.blue, '디자인'),
  (CoreCategoryColor.green, '개발'),
  (CoreCategoryColor.blue, '디자인'),
];

/// 같은 분류에 색을 섞은 예.
const List<(CoreCategoryColor, String)> tagMixedSamples = [
  (CoreCategoryColor.blue, '디자인'),
  (CoreCategoryColor.pink, '디자인'),
  (CoreCategoryColor.orange, '디자인'),
];

/// 상태를 분류색으로 말한 예.
const List<(CoreCategoryColor, String)> tagStatusMisuseSamples = [
  (CoreCategoryColor.green, '완료'),
  (CoreCategoryColor.red, '실패'),
];

/// 같은 상태를 Badge 의 톤으로 말한 예.
const List<(CoreBadgeTone, String)> tagStatusBadgeSamples = [
  (CoreBadgeTone.success, '완료'),
  (CoreBadgeTone.destructive, '실패'),
];

// 선택지는 enum 과 크기 행에서 읽는다 — 분류색이나 크기 행이 늘면
// 플레이그라운드도 따라온다.
final DocsPlaygroundSpec _playground = DocsPlaygroundSpec(
  initial: {
    'color': CoreCategoryColor.blue.name,
    'emphasis': CoreTagEmphasis.defaultEmphasis.name,
    'size': CoreTagSize.defaultSize.name,
  },
  controls: [
    DocsPlaygroundChoice(label: 'color', prop: 'color', options: [for (final c in CoreCategoryColor.values) c.name]),
    DocsPlaygroundChoice(
      label: 'emphasis',
      prop: 'emphasis',
      options: [for (final emphasis in CoreTagEmphasis.values) emphasis.name],
      segmented: true,
    ),
    DocsPlaygroundChoice(
      label: 'size',
      prop: 'size',
      options: [for (final size in CoreTagStyle.defaultsBySize.keys) size.name],
      segmented: true,
    ),
    const DocsPlaygroundFlag(label: '알약 모양', on: {'pill': 'true'}),
  ],
  code: _tagCode,
  label: tagSampleText,
);

/// 속성 → 코드. 기본값과 같은 축은 적지 않는다.
String _tagCode(Map<String, String> props, String? label) {
  final color = previewEnum(CoreCategoryColor.values, props['color'], CoreTagContract.defaultColor);
  final emphasis = previewEnum(CoreTagEmphasis.values, props['emphasis'], CoreTagEmphasis.defaultEmphasis);
  final size = previewEnum(CoreTagSize.values, props['size'], CoreTagSize.defaultSize);
  final lines = [
    if (color != CoreTagContract.defaultColor) 'color: CoreCategoryColor.${color.name},',
    if (emphasis != CoreTagEmphasis.defaultEmphasis) 'emphasis: CoreTagEmphasis.${emphasis.name},',
    if (size != CoreTagSize.defaultSize) 'size: CoreTagSize.${size.name},',
    if (previewFlag(props, 'pill'))
      'tagStyle: CoreTagStyle(\n    borderRadius: CoreBorderRadius.all(CoreRadius.radius9999),\n  ),',
    "child: Text('${label ?? tagSampleText}'),",
  ];
  return 'Tag(\n${lines.map((l) => '  $l').join('\n')}\n)';
}

DocsSizeSpec _tagSpec() {
  return DocsSizeSpec(
    columns: const ['size', '최소 높이', '좌우 여백', '모서리', '라벨 글자'],
    rows: [
      for (final MapEntry(key: size, value: row) in CoreTagStyle.defaultsBySize.entries)
        DocsSizeSpecRow(
          size: CoreComponentSize.values.byName(size.name),
          cells: [
            docsSizeNumber(row.minHeight),
            docsSizeNumber(row.padding?.left),
            docsSizeNumber(row.borderRadius?.topLeft),
            docsSizeLabel(row.labelStyle),
          ],
        ),
    ],
  );
}
