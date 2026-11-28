/// DescriptionCard 페이지 — 플레이그라운드와 장면이 함께 쓰는 글. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `description_card_web.dart` · `description_card_flutter.dart` 가
/// 그린다. 이 폴더는 `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
library;

import 'package:coui_core/coui_core.dart';

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/description-card.md`.
const String slug = 'description-card';

/// 플레이그라운드. 없는 컴포넌트는 `null`.
DocsPlaygroundSpec? get playground => _playground;

/// 크기 축이 `CoreComponentSize` 가 아니라 `CoreDescriptionCardSize` 라 크기
/// 표를 등록하지 않는다 — 크기 섹션의 장면과 표가 그 자리를 맡는다.
DocsSizeSpec Function()? get sizeSpec => null;

/// 미리보기에 라벨을 주지 않았을 때의 카드 제목.
const String descriptionCardSampleTitle = '주문 상세';

/// 플레이그라운드의 행 — (라벨, 값). 값이 `null` 인 행은 빈 값 처리를 보이고,
/// 마지막 행은 강조를 보인다.
const List<(String, String?)> descriptionCardOrderRows = [
  ('주문번호', 'ORD-2025-00391'),
  ('상품', 'AirPods Pro 2'),
  ('요청 사항', null),
  ('합계', '369,000원'),
];

/// 카드를 여럿 나란히 놓는 장면의 짧은 행 — 좁은 칸에서도 한 줄에 들어간다.
const List<(String, String)> descriptionCardProfileRows = [('등급', 'Gold'), ('포인트', '1,200'), ('가입', '2025.03')];

/// 빈 값 처리 장면의 행 — 가운데 행에는 값이 없다.
const List<(String, String?)> descriptionCardEmptyRows = [('등급', 'Gold'), ('추천인', null), ('가입', '2025.03')];

/// 긴 값 장면의 글.
const String descriptionCardLongValue = '서울특별시 중구 예시로 123, 4층 401호 문서 보관실';

final DocsPlaygroundSpec _playground = DocsPlaygroundSpec(
  initial: const {
    'variant': 'outlined',
    'size': 'md',
    'layout': 'horizontal',
    'title': 'true',
    'emphasize': 'true',
  },
  controls: [
    DocsPlaygroundChoice(
      label: 'variant',
      prop: 'variant',
      options: [for (final variant in CoreDescriptionCardVariant.values) variant.name],
      segmented: true,
    ),
    DocsPlaygroundChoice(
      label: 'size',
      prop: 'size',
      options: [for (final size in CoreDescriptionCardStyle.defaultsBySize.keys) size.name],
      segmented: true,
    ),
    DocsPlaygroundChoice(
      label: 'layout',
      prop: 'layout',
      options: [for (final layout in CoreDescriptionCardLayout.values) layout.name],
      segmented: true,
    ),
    const DocsPlaygroundFlag(label: '제목', on: {'title': 'true'}),
    const DocsPlaygroundFlag(label: '합계 강조', on: {'emphasize': 'true'}),
    const DocsPlaygroundFlag(label: '빈 값 자리 표시', on: {'placeholder': 'true'}),
    const DocsPlaygroundFlag(label: '행 구분선 끄기', on: {'showRowDividers': 'false'}),
    const DocsPlaygroundFlag(label: '하단 액션', on: {'bottomAction': 'true'}),
  ],
  code: _descriptionCardCode,
);

/// 속성 → 코드. 기본값과 같은 속성은 적지 않는다.
String _descriptionCardCode(Map<String, String> props, String? label) {
  final variant = previewEnum(CoreDescriptionCardVariant.values, props['variant'], CoreDescriptionCardVariant.outlined);
  final size = previewEnum(CoreDescriptionCardSize.values, props['size'], CoreDescriptionCardSize.md);
  final layout = previewEnum(CoreDescriptionCardLayout.values, props['layout'], CoreDescriptionCardLayout.horizontal);
  final emphasize = previewFlag(props, 'emphasize');
  final lines = [
    if (variant != CoreDescriptionCardVariant.outlined) 'variant: CoreDescriptionCardVariant.${variant.name},',
    if (size != CoreDescriptionCardSize.md) 'size: CoreDescriptionCardSize.${size.name},',
    if (layout != CoreDescriptionCardLayout.horizontal) 'layout: CoreDescriptionCardLayout.${layout.name},',
    if (previewFlag(props, 'title')) "title: '${label ?? descriptionCardSampleTitle}',",
    if (!previewFlag(props, 'showRowDividers', fallback: true)) 'showRowDividers: false,',
    if (previewFlag(props, 'placeholder')) 'emptyValueBehavior: CoreDescriptionCardEmptyBehavior.placeholder,',
    'rows: [',
    for (final (index, (name, value)) in descriptionCardOrderRows.indexed)
      '  ${_rowCode(name, value, emphasized: emphasize && index == descriptionCardOrderRows.length - 1)},',
    '],',
    if (previewFlag(props, 'bottomAction')) ...[
      'bottomAction: Button(',
      '  variant: CoreButtonVariant.outline,',
      '  expanded: true,',
      '  onPressed: showDetails,',
      "  child: Text('상세 보기'),",
      '),',
    ],
  ];
  return 'DescriptionCard(\n${lines.map((l) => '  $l').join('\n')}\n)';
}

String _rowCode(String label, String? value, {required bool emphasized}) {
  final arguments = [
    "label: '$label'",
    if (value != null) "value: '$value'",
    if (emphasized) 'isEmphasized: true',
  ];
  return 'DescriptionRow(${arguments.join(', ')})';
}
