/// MultipleChoice 페이지의 미리보기 — Flutter.
///
/// 속성 빌더는 `<Preview props>` · `<Card props>` · 플레이그라운드가, 장면은
/// `<Preview demo="multiple-choice/...">` 가 읽는다. 같은 이름의 Web 파일
/// (`multiple_choice_web.dart`)과 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
library;

import 'package:coui_flutter/coui_flutter.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/flutter_prop_previews.dart';
import 'multiple_choice_page.dart';

/// 속성 → Widget.
///
/// 선택은 눌러야 바뀌므로 빌더가 고른 값을 기억한다 — Web 빌더와 같다.
FlutterPropPreviewBuilder? get propPreview =>
    (props, _) => _MultipleChoicePreview(props: props);

/// 장면 이름(`multiple-choice/<장면>`) → 장면.
final Map<String, Widget Function()> demos = {
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
Widget _group(List<(String, String)> options, {String? value, bool enabled = true}) => MultipleChoice<String>(
  options: [for (final (optionValue, text) in options) (value: optionValue, label: text)],
  value: value,
  enabled: enabled,
  onChanged: (_) {},
);

/// 폭이 정해진 상자 — 옵션이 다음 줄로 넘어가는 모습을 보인다.
Widget _box(Widget child) => SizedBox(width: 224, child: child);

/// 상태 격자 — Web 과 같은 네 상태.
Widget _multipleChoiceStates() {
  const columns = ['미선택', '선택', '비활성', '비활성 · 선택'];
  Widget cell(String state) => _group(
    [multipleChoiceSizeOptions[1]],
    value: switch (state) {
      '선택' || '비활성 · 선택' => 'md',
      _ => null,
    },
    enabled: !state.startsWith('비활성'),
  );
  return Wrap(
    spacing: CoreSpace.space16,
    runSpacing: CoreSpace.space12,
    children: [
      for (final column in columns)
        Column(
          mainAxisSize: MainAxisSize.min,
          spacing: CoreSpace.space8,
          children: [Text(column).labelSmall.onSurfaceVariant, cell(column)],
        ),
    ],
  );
}

/// 속성으로 그리는 MultipleChoice — 눌러 고른 값을 기억한다. 속성은 Web 과 같다.
class _MultipleChoicePreview extends StatefulWidget {
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
    _value = multipleChoicePreviewValue(widget.props);
  }

  @override
  void didUpdateWidget(covariant _MultipleChoicePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.props['value'] != widget.props['value']) {
      _value = multipleChoicePreviewValue(widget.props);
    }
  }

  void _handleChanged(String? next) => setState(() => _value = next);

  @override
  Widget build(BuildContext context) {
    final props = widget.props;
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
