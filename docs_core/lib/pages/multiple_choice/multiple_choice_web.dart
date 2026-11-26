/// MultipleChoice 페이지의 미리보기 — Jaspr Web.
///
/// 속성 빌더는 `<Preview props>` · `<Card props>` · 플레이그라운드가, 장면은
/// `<Preview demo="multiple-choice/...">` 가 읽는다. 같은 이름의 Flutter 파일
/// (`multiple_choice_flutter.dart`)과 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
library;

import 'package:coui_web/coui_web.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/web_prop_previews.dart';
import 'multiple_choice_page.dart';

/// 속성 → Component.
///
/// 선택은 눌러야 바뀌므로 빌더가 고른 값을 기억한다. 서버에서 그리는 블록에서는
/// 처음 선택만 보이고, 브라우저에서 깨어나는 플레이그라운드에서는 옵션을 눌러
/// 바꿀 수 있다.
WebPropPreviewBuilder? get propPreview =>
    (props, _) => _MultipleChoicePreview(props: props);

/// 장면 이름(`multiple-choice/<장면>`) → 장면.
final Map<String, Component Function()> demos = {
  // 구조 번호가 그룹 자체를 가리키도록 감싸지 않고 그린다.
  'multiple-choice/anatomy': () => _group(multipleChoiceSizeOptions, value: 'md'),
  'multiple-choice/states': _multipleChoiceStates,
  'multiple-choice/wrap': () => _box(_group(multipleChoiceManyOptions, value: 'md')),
  'multiple-choice/dont-many': () => _group(multipleChoiceTimeOptions, value: 'mon-am'),
  'multiple-choice/related-chip-group': () => _box(
    ChipGroup<String>(
      items: multipleChoiceRelatedChips,
      initialValue: {...multipleChoiceRelatedChips.take(2)},
      selectionMode: CoreChipGroupSelectionMode.multi,
      chipBuilder: (item, {required selected, required enabled, required onTap}) => Chip(
        label: item,
        selected: selected,
        enabled: enabled,
        chipColor: CoreChipColor.primary,
        onTap: onTap,
      ),
    ),
  ),
};

/// 값 · 라벨 쌍으로 그리는 정적 그룹.
Component _group(List<(String, String)> options, {String? value, bool enabled = true}) => MultipleChoice<String>(
  options: [for (final (optionValue, text) in options) (value: optionValue, label: text)],
  value: value,
  enabled: enabled,
  onChanged: (_) {},
);

/// 폭이 정해진 상자 — 옵션이 다음 줄로 넘어가는 모습을 보인다.
Component _box(Component child) => div(styles: Styles(raw: {'width': '14rem', 'max-width': '100%'}), [child]);

/// 상태 격자 — 옵션 하나짜리 그룹 넷. hover · 눌림 · 포커스는 브라우저가
/// 포인터나 키보드 없이 켤 수 없어 표의 설명으로 대신한다.
Component _multipleChoiceStates() {
  const columns = ['미선택', '선택', '비활성', '비활성 · 선택'];
  Component cell(String state) => _group(
    [multipleChoiceSizeOptions[1]],
    value: switch (state) {
      '선택' || '비활성 · 선택' => 'md',
      _ => null,
    },
    enabled: !state.startsWith('비활성'),
  );
  return div(
    classes: 'docs-demo-field-states',
    styles: Styles(raw: {'grid-template-columns': 'repeat(${columns.length}, max-content)'}),
    [
      for (final column in columns) span([Text(column).labelSmall.onSurfaceVariant]),
      for (final column in columns) cell(column),
    ],
  );
}

/// 속성으로 그리는 MultipleChoice — 눌러 고른 값을 기억한다.
///
/// 속성은 `multiple_choice_page.dart` 의 설명을 따른다.
class _MultipleChoicePreview extends StatefulComponent {
  const _MultipleChoicePreview({required this.props});

  final Map<String, String> props;

  @override
  State<_MultipleChoicePreview> createState() => _MultipleChoicePreviewState();
}

class _MultipleChoicePreviewState extends State<_MultipleChoicePreview> {
  String? _value;

  @override
  void initState() {
    super.initState();
    _value = multipleChoicePreviewValue(component.props);
  }

  @override
  void didUpdateComponent(covariant _MultipleChoicePreview oldComponent) {
    super.didUpdateComponent(oldComponent);
    if (oldComponent.props['value'] != component.props['value']) {
      _value = multipleChoicePreviewValue(component.props);
    }
  }

  void _handleChanged(String? next) => setState(() => _value = next);

  @override
  Component build(BuildContext context) {
    final props = component.props;
    return MultipleChoice<String>(
      options: [
        for (final (optionValue, text) in multipleChoicePreviewOptions(props)) (value: optionValue, label: text),
      ],
      value: _value,
      allowUnselect: multipleChoicePreviewAllowUnselect(props),
      enabled: previewFlag(props, 'enabled', fallback: true),
      onChanged: _handleChanged,
    );
  }
}
