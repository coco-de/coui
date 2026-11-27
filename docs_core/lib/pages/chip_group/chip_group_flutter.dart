/// ChipGroup 페이지의 미리보기 — Flutter.
///
/// 속성 빌더는 `<VariantRow>` · 플레이그라운드가, 장면은
/// `<Preview demo="chip-group/...">` · `<Anatomy>` · `<Card demo>` 가 읽는다.
/// 같은 이름의 Web 파일(`chip_group_web.dart`)과 컴포넌트 · 속성 · 장면 이름이
/// 같아야 한다.
///
/// 줄바꿈과 가로 스크롤은 부모의 폭이 정한다. 그래서 속성 빌더와 그것을 보이는
/// 장면은 폭을 정한 상자 안에 놓는다.
library;

import 'package:coui_flutter/coui_flutter.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/flutter_prop_previews.dart';
import '../page_kit_flutter.dart';
import 'chip_group_page.dart';

/// 속성 → Widget.
///
/// `layout` 은 위젯 enum 의 이름, `rule` 은 `선택 규칙` 컨트롤의 값, `header` 는
/// 켜면 제목과 안내를 단다.
FlutterPropPreviewBuilder? get propPreview => _chipGroup;

/// 장면 이름(`chip-group/<장면>`) → 장면.
final Map<String, Widget Function()> demos = {
  'chip-group/anatomy': () => ChipGroup<String>(
    items: chipGroupShortItems,
    initialValue: chipGroupSampleMulti,
    title: const Text(chipGroupSampleTitle),
    selectionHint: Text(chipGroupSampleHint(chipGroupRuleMulti)),
    chipBuilder: _chip,
  ),
  'chip-group/scroll-fade': () => _frame([
    for (final showFade in const [true, false])
      ChipGroup<String>(
        items: chipGroupSampleItems,
        initialValue: chipGroupSampleSingle,
        layout: CoreChipGroupLayout.scroll,
        showFade: showFade,
        title: Text('showFade: $showFade'),
        chipBuilder: _chip,
      ),
  ]),
  'chip-group/max-selection': () => _frame([
    for (final behavior in CoreChipGroupMaxBehavior.values)
      ChipGroup<String>(
        items: chipGroupShortItems,
        initialValue: chipGroupSampleMulti,
        maxSelection: chipGroupSampleMax,
        maxSelectionBehavior: behavior,
        title: Text(behavior.name),
        chipBuilder: _chip,
      ),
  ]),
  'chip-group/do-forward': () => _limited(_chip),
  'chip-group/dont-forward': () => _limited(_chipWithoutEnabled),
  'chip-group/do-hint': () => _limited(
    _chip,
    title: const Text(chipGroupSampleTitle),
    selectionHint: Text(chipGroupSampleHint(chipGroupRuleMax)),
  ),
  'chip-group/dont-hint': () => _limited(_chip, title: const Text(chipGroupSampleTitle)),
  'chip-group/styled': () => _frame([
    ChipGroup<String>(
      items: chipGroupShortItems,
      initialValue: chipGroupSampleMulti,
      title: const Text(chipGroupSampleTitle),
      chipGroupStyle: chipGroupSampleStyle,
      chipBuilder: _chip,
    ),
  ]),
  'chip-group/related-chip': () => docsFlutterDemoRow([
    Chip(label: '디자인', chipColor: CoreChipColor.primary, selected: true, onTap: () {}),
    Chip(label: '백엔드', chipColor: CoreChipColor.primary, onTap: () {}),
  ]),
  'chip-group/related-chip-input': () => SizedBox(
    width: 240,
    child: ChipInput(chips: const ['디자인', '백엔드'], placeholder: '태그 입력', onChanged: (_) {}),
  ),
  'chip-group/related-radio-group': () => RadioGroup<String>(
    value: 'email',
    onChanged: (_) {},
    options: const [(value: 'email', label: '이메일'), (value: 'sms', label: '문자')],
  ),
};

Widget _chipGroup(Map<String, String> props, String? label) {
  final rule = props['rule'] ?? chipGroupRuleMulti;
  final header = previewFlag(props, 'header');
  return _frame([
    ChipGroup<String>(
      items: chipGroupSampleItems,
      // 새 집합을 넘겨야 컨트롤을 바꿀 때 선택이 그 설정의 처음 값으로 돌아간다.
      initialValue: {...chipGroupSampleSelection(rule)},
      selectionMode: rule == chipGroupRuleSingle ? CoreChipGroupSelectionMode.single : null,
      maxSelection: rule == chipGroupRuleMax ? chipGroupSampleMax : null,
      layout: previewEnum(CoreChipGroupLayout.values, props['layout'], CoreChipGroupLayout.wrap),
      title: header ? const Text(chipGroupSampleTitle) : null,
      selectionHint: header ? Text(chipGroupSampleHint(rule)) : null,
      chipBuilder: _chip,
    ),
  ]);
}

/// 미리보기 폭의 상자 — 여러 묶음은 위아래로 놓는다.
Widget _frame(List<Widget> children) => SizedBox(
  width: chipGroupSampleWidth,
  child: Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: CoreSpace.space16,
    children: children,
  ),
);

/// 두 개를 고른 채 개수 제한에 닿은 묶음.
Widget _limited(
  ChipGroupItemBuilder<String> chipBuilder, {
  Widget? title,
  Widget? selectionHint,
}) => _frame([
  ChipGroup<String>(
    items: chipGroupShortItems,
    initialValue: chipGroupSampleMulti,
    maxSelection: chipGroupSampleMax,
    title: title,
    selectionHint: selectionHint,
    chipBuilder: chipBuilder,
  ),
]);

Widget _chip(
  String item, {
  required bool selected,
  required bool enabled,
  required VoidCallback onTap,
}) => Chip(
  label: item,
  selected: selected,
  enabled: enabled,
  chipColor: CoreChipColor.primary,
  onTap: onTap,
);

/// `enabled` 를 칩에 넘기지 않은 빌더 — 사용 가이드의 하지 말아야 할 예.
Widget _chipWithoutEnabled(
  String item, {
  required bool selected,
  required bool enabled,
  required VoidCallback onTap,
}) => Chip(
  label: item,
  selected: selected,
  chipColor: CoreChipColor.primary,
  onTap: onTap,
);
