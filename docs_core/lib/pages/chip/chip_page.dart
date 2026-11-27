/// Chip 페이지 — 플레이그라운드와 장면이 함께 쓰는 값. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `chip_web.dart` · `chip_flutter.dart` 가 그린다. 이 폴더는
/// `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
///
/// Chip 의 크기 축은 `CoreChipSize` 세 단계다. 크기 표의 행은
/// `CoreComponentSize` 만 받으므로 크기 표를 두지 않고, 페이지가 장면과 표로
/// 크기를 보인다.
library;

import 'package:coui_core/coui_core.dart';

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/chip.md`.
const String slug = 'chip';

/// 플레이그라운드. 없는 컴포넌트는 `null`.
DocsPlaygroundSpec? get playground => _playground;

/// 크기 표. 크기 축이 없는 컴포넌트는 `null`.
DocsSizeSpec Function()? get sizeSpec => null;

/// 미리보기에 라벨을 주지 않았을 때 칩 안에 넣는 글 — 두 플랫폼의 속성 빌더와
/// 플레이그라운드 코드가 같은 글을 쓴다.
const String chipSampleLabel = '진행 중';

/// 플레이그라운드의 `키 글자` 컨트롤이 넣는 `prefixLabel`.
const String chipSamplePrefix = '상태';

/// `chipColor: custom` 미리보기의 씨드 색 — 두 플랫폼의 빌더와 장면이 같은
/// 색을 쓴다. 플레이그라운드 코드의 `seedColor` 줄도 이 색을 적는다.
const CoreColor chipSampleSeed = CoreColor.token(CoreColors.success);

/// 태그 묶음 장면의 태그.
const List<String> chipSampleTags = ['디자인', '개발', '마케팅'];

/// 필터 칩 장면의 (키, 지금 값, 걸렸는가).
const List<(String, String, bool)> chipFilterSamples = [
  ('상태', '진행 중', true),
  ('담당자', '전체', false),
];

/// 긴 라벨 장면의 글.
const String chipLongLabel = '최근에 방문한 카테고리 항목';

/// 그림자 모션 장면의 (값, 라벨).
const List<(CoreCastMotion, String)> chipCastSamples = [
  (CoreCastMotion.defaultMotion, '기본'),
  (CoreCastMotion.noShadow, '그림자 없음'),
  (CoreCastMotion.reverse, '반대로'),
];

/// 값이 정해지는 순서의 단계 — 뒤로 갈수록 우선한다. 두 플랫폼 장면이 함께 읽는다.
const List<String> chipThemeOrder = [
  '크기 · 모양 기본값',
  '테마 style',
  '테마 colorStyles',
  '테마 variantStyles',
  '인스턴스 chipStyle',
];

// 선택지는 enum 에서 읽는다. `chipColor` 만 선택지가 아니라 켜고 끄는
// 컨트롤이다 — 기본 CoUI 팔레트에서는 neutral 과 primary 의 켜진 칩이 거의
// 같게 보여, 미리보기가 달라지는 custom 만 컨트롤로 둔다.
//
// 미리보기는 꺼진 칩과 켜진 칩을 나란히 그린다(`pair`). `variant` 는 꺼진
// 칩에만, 색은 켜진 칩에만 닿아, 칩 하나로는 선택에 따라 아무것도 바꾸지
// 않는 컨트롤이 생긴다.
final DocsPlaygroundSpec _playground = DocsPlaygroundSpec(
  initial: {
    'variant': CoreChipVariant.defaultVariant.name,
    'emphasis': CoreChipEmphasis.defaultEmphasis.name,
    'shape': CoreChipShape.defaultShape.name,
    'size': CoreChipSize.defaultSize.name,
    'pair': 'true',
  },
  label: chipSampleLabel,
  controls: [
    DocsPlaygroundChoice(
      label: 'variant',
      prop: 'variant',
      options: [for (final variant in CoreChipVariant.values) variant.name],
      segmented: true,
    ),
    DocsPlaygroundChoice(
      label: 'emphasis',
      prop: 'emphasis',
      options: [for (final emphasis in CoreChipEmphasis.values) emphasis.name],
      segmented: true,
    ),
    DocsPlaygroundChoice(
      label: 'shape',
      prop: 'shape',
      options: [for (final shape in CoreChipShape.values) shape.name],
      segmented: true,
    ),
    DocsPlaygroundChoice(
      label: 'size',
      prop: 'size',
      options: [for (final size in CoreChipSize.values) size.name],
      segmented: true,
    ),
    const DocsPlaygroundFlag(label: '키 글자', on: {'prefixLabel': chipSamplePrefix}),
    const DocsPlaygroundFlag(label: 'leading 아이콘', on: {'leading': 'star'}),
    const DocsPlaygroundFlag(label: 'trailing 아이콘', on: {'trailing': 'chevron-down'}),
    const DocsPlaygroundFlag(label: '지우기 버튼', on: {'removable': 'true'}),
    const DocsPlaygroundFlag(label: '직접 지정한 색', on: {'chipColor': 'custom'}),
    const DocsPlaygroundFlag(label: '비활성', on: {'enabled': 'false'}),
  ],
  code: _chipCode,
);

/// 속성 → 코드. 기본값과 같은 축은 적지 않는다. 선택 여부는 부모가 가진
/// 값(`isSelected`)으로 적는다. 두 플랫폼의 코드가 같다.
String _chipCode(Map<String, String> props, String? label) {
  final variant = previewEnum(CoreChipVariant.values, props['variant'], CoreChipVariant.defaultVariant);
  final emphasis = previewEnum(CoreChipEmphasis.values, props['emphasis'], CoreChipEmphasis.defaultEmphasis);
  final shape = previewEnum(CoreChipShape.values, props['shape'], CoreChipShape.defaultShape);
  final size = previewEnum(CoreChipSize.values, props['size'], CoreChipSize.defaultSize);
  final chipColor = previewEnum(CoreChipColor.values, props['chipColor'], CoreChipColor.defaultColor);
  final prefixLabel = props['prefixLabel'];
  final leading = props['leading'];
  final trailing = props['trailing'];
  final lines = [
    if (prefixLabel != null) "prefixLabel: '$prefixLabel',",
    "label: '${label ?? chipSampleLabel}',",
    if (variant != CoreChipVariant.defaultVariant) 'variant: CoreChipVariant.${variant.name},',
    if (emphasis != CoreChipEmphasis.defaultEmphasis) 'emphasis: CoreChipEmphasis.${emphasis.name},',
    if (shape != CoreChipShape.defaultShape) 'shape: CoreChipShape.${shape.name},',
    if (size != CoreChipSize.defaultSize) 'size: CoreChipSize.${size.name},',
    if (chipColor != CoreChipColor.defaultColor) 'chipColor: CoreChipColor.${chipColor.name},',
    if (chipColor == CoreChipColor.custom) 'seedColor: CoreColor.token(CoreColors.success),',
    if (leading != null) 'leading: Icon(LucideIcons.${docsIconIdentifier(leading)}),',
    if (trailing != null) 'trailing: Icon(LucideIcons.${docsIconIdentifier(trailing)}),',
    'selected: isSelected,',
    if (!previewFlag(props, 'enabled', fallback: true)) 'enabled: false,',
    'onTap: toggleSelected,',
    if (previewFlag(props, 'removable')) 'onRemove: removeChip,',
  ];
  return 'Chip(\n${lines.map((line) => '  $line').join('\n')}\n)';
}
