/// ChipGroup 페이지 — 플레이그라운드와 장면이 함께 쓰는 값. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `chip_group_web.dart` · `chip_group_flutter.dart` 가 그린다. 이
/// 폴더는 `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
///
/// ChipGroup 에는 크기 축이 없다. 칩의 크기는 `chipBuilder` 가 돌려주는 칩이
/// 정한다.
library;

import 'package:coui_core/coui_core.dart';

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/chip-group.md`.
const String slug = 'chip-group';

/// 플레이그라운드. 없는 컴포넌트는 `null`.
DocsPlaygroundSpec? get playground => _playground;

/// 크기 표. 크기 축이 없는 컴포넌트는 `null`.
DocsSizeSpec Function()? get sizeSpec => null;

/// 플레이그라운드와 가로 스크롤 장면의 항목 — 미리보기 폭에서 한 줄을 넘는다.
const List<String> chipGroupSampleItems = ['디자인', '프런트엔드', '백엔드', '모바일', '데이터', 'DevOps', '품질 관리', '기획'];

/// 구조 · 상태 · 사용 가이드 장면의 짧은 항목.
const List<String> chipGroupShortItems = ['디자인', '프런트엔드', '백엔드', '모바일'];

/// 여러 개를 고른 처음 값.
const Set<String> chipGroupSampleMulti = {'프런트엔드', '모바일'};

/// 하나를 고른 처음 값.
const Set<String> chipGroupSampleSingle = {'프런트엔드'};

/// 개수 제한을 보이는 미리보기의 `maxSelection`.
const int chipGroupSampleMax = 2;

/// 헤더를 보이는 미리보기의 제목.
const String chipGroupSampleTitle = '관심 분야';

/// 미리보기를 놓는 상자의 폭(logical px) — 줄바꿈과 가로 스크롤이 보이는 좁은
/// 폭이다.
const double chipGroupSampleWidth = 280;

/// `선택 규칙` 컨트롤의 값 — 여러 개 고르기(기본).
const String chipGroupRuleMulti = 'multi';

/// `선택 규칙` 컨트롤의 값 — 하나만 고르기.
const String chipGroupRuleSingle = 'single';

/// `선택 규칙` 컨트롤의 값 — 여러 개 고르기에 개수 제한을 더한 것.
const String chipGroupRuleMax = 'max-2';

/// 테마와 스타일 장면의 인스턴스 스타일 — 두 플랫폼 장면이 함께 읽는다.
const CoreChipGroupStyle chipGroupSampleStyle = CoreChipGroupStyle(
  itemSpacing: CoreSpace.space12,
  rowSpacing: CoreSpace.space12,
  titleGapStyle: CoreGapStyle(size: CoreSpace.space12),
  titleTextStyle: CoreTextStyle.token(
    CoreTextStyles.labelLarge,
    color: CoreColor.token(CoreColors.onSurfaceVariant),
  ),
);

/// [rule] 의 처음 선택.
Set<String> chipGroupSampleSelection(String rule) =>
    rule == chipGroupRuleSingle ? chipGroupSampleSingle : chipGroupSampleMulti;

/// [rule] 을 설명하는 `selectionHint` 글. 컴포넌트가 만드는 글이 아니라 직접
/// 넘기는 글이다.
String chipGroupSampleHint(String rule) => switch (rule) {
  chipGroupRuleSingle => '하나만 고를 수 있어요',
  chipGroupRuleMax => '최대 $chipGroupSampleMax개까지 고를 수 있어요',
  _ => '여러 개를 고를 수 있어요',
};

// 선택 모드와 개수 제한은 컨트롤 하나(`선택 규칙`)로 묶는다. 하나만 고르는
// 모드에서는 2개 제한이 아무것도 바꾸지 않아, 둘을 따로 두면 미리보기를 바꾸지
// 않는 조합이 생긴다.
final DocsPlaygroundSpec _playground = DocsPlaygroundSpec(
  initial: {'layout': CoreChipGroupLayout.wrap.name, 'rule': chipGroupRuleMulti, 'header': 'true'},
  controls: [
    DocsPlaygroundChoice(
      label: 'layout',
      prop: 'layout',
      options: [for (final layout in CoreChipGroupLayout.values) layout.name],
      segmented: true,
    ),
    const DocsPlaygroundChoice(
      label: '선택 규칙',
      prop: 'rule',
      options: [chipGroupRuleMulti, chipGroupRuleSingle, chipGroupRuleMax],
      segmented: true,
    ),
    const DocsPlaygroundFlag(label: '제목 · 안내', on: {'header': 'true'}),
  ],
  code: _chipGroupCode,
);

/// 속성 → 코드. 기본값과 같은 파라미터는 적지 않는다. `saveTopics` 는 고른
/// 집합(`Set<String>`)을 받는 함수 자리다. 두 플랫폼의 코드가 같다.
String _chipGroupCode(Map<String, String> props, String? label) {
  final rule = props['rule'] ?? chipGroupRuleMulti;
  final layout = previewEnum(CoreChipGroupLayout.values, props['layout'], CoreChipGroupLayout.wrap);
  String quoted(Iterable<String> values) => values.map((value) => "'$value'").join(', ');
  final lines = [
    'items: const [${quoted(chipGroupSampleItems)}],',
    'initialValue: const {${quoted(chipGroupSampleSelection(rule))}},',
    if (rule == chipGroupRuleSingle) 'selectionMode: CoreChipGroupSelectionMode.single,',
    if (rule == chipGroupRuleMax) 'maxSelection: $chipGroupSampleMax,',
    if (layout != CoreChipGroupLayout.wrap) 'layout: CoreChipGroupLayout.${layout.name},',
    if (previewFlag(props, 'header')) ...[
      "title: Text('$chipGroupSampleTitle'),",
      "selectionHint: Text('${chipGroupSampleHint(rule)}'),",
    ],
    'onChanged: saveTopics,',
    'chipBuilder: (item, {required selected, required enabled, required onTap}) => Chip(',
    '  label: item,',
    '  selected: selected,',
    '  enabled: enabled,',
    '  chipColor: CoreChipColor.primary,',
    '  onTap: onTap,',
    '),',
  ];
  return 'ChipGroup<String>(\n${lines.map((line) => '  $line').join('\n')}\n)';
}
