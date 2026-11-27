/// ChipGroup 페이지의 미리보기 — Jaspr Web.
///
/// 속성 빌더는 `<VariantRow>` · 플레이그라운드가, 장면은
/// `<Preview demo="chip-group/...">` · `<Anatomy>` · `<Card demo>` 가 읽는다.
/// 같은 이름의 Flutter 파일(`chip_group_flutter.dart`)과 컴포넌트 · 속성 · 장면
/// 이름이 같아야 한다.
///
/// 줄바꿈과 가로 스크롤은 부모의 폭이 정한다. 그래서 속성 빌더와 그것을 보이는
/// 장면은 폭을 정한 상자 안에 놓는다.
library;

import 'package:coui_web/coui_web.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/web_prop_previews.dart';
import '../page_kit_web.dart';
import 'chip_group_page.dart';

/// 속성 → Component.
///
/// `layout` 은 위젯 enum 의 이름, `rule` 은 `선택 규칙` 컨트롤의 값, `header` 는
/// 켜면 제목과 안내를 단다.
WebPropPreviewBuilder? get propPreview => _chipGroup;

/// 장면 이름(`chip-group/<장면>`) → 장면.
final Map<String, Component Function()> demos = {
  // 구조 — 제목과 안내는 번호가 가리킬 수 있게 문서 표지를 단다.
  'chip-group/anatomy': () => ChipGroup<String>(
    items: chipGroupShortItems,
    initialValue: chipGroupSampleMulti,
    title: span(
      attributes: const {'data-docs-part': 'title'},
      [const Text(chipGroupSampleTitle)],
    ),
    selectionHint: span(
      attributes: const {'data-docs-part': 'hint'},
      [Text(chipGroupSampleHint(chipGroupRuleMulti))],
    ),
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
  'chip-group/related-chip': () => docsWebDemoRow([
    Chip(label: '디자인', chipColor: CoreChipColor.primary, selected: true, onTap: () {}),
    Chip(label: '백엔드', chipColor: CoreChipColor.primary, onTap: () {}),
  ]),
  'chip-group/related-chip-input': () => div(styles: Styles(raw: {'width': '15rem', 'max-width': '100%'}), [
    ChipInput(chips: const ['디자인', '백엔드'], placeholder: '태그 입력', onChanged: (_) {}),
  ]),
  'chip-group/related-radio-group': () => RadioGroup(
    value: 'email',
    onChanged: (_) {},
    options: const [(value: 'email', label: '이메일'), (value: 'sms', label: '문자')],
  ),
};

Component _chipGroup(Map<String, String> props, String? label) {
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
Component _frame(List<Component> children) => div(
  styles: Styles(
    raw: {
      'display': 'flex',
      'flex-direction': 'column',
      'gap': 'var(--coui-space-16)',
      'width': pinnedLengthCss(chipGroupSampleWidth),
      'max-width': '100%',
    },
  ),
  children,
);

/// 두 개를 고른 채 개수 제한에 닿은 묶음.
Component _limited(
  ChipGroupItemBuilder<String> chipBuilder, {
  Component? title,
  Component? selectionHint,
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

Component _chip(
  String item, {
  required bool selected,
  required bool enabled,
  required void Function() onTap,
}) => Chip(
  label: item,
  selected: selected,
  enabled: enabled,
  chipColor: CoreChipColor.primary,
  onTap: onTap,
);

/// `enabled` 를 칩에 넘기지 않은 빌더 — 사용 가이드의 하지 말아야 할 예.
Component _chipWithoutEnabled(
  String item, {
  required bool selected,
  required bool enabled,
  required void Function() onTap,
}) => Chip(
  label: item,
  selected: selected,
  chipColor: CoreChipColor.primary,
  onTap: onTap,
);
