/// Filter 페이지의 미리보기 — Flutter.
///
/// 속성 빌더는 `<VariantRow>` · `<SizeSpec>` · 플레이그라운드가, 장면은
/// `<Preview demo="filter/...">` 가 읽는다. 같은 이름의 Web 파일(`filter_web.dart`)과
/// 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
library;

import 'package:coui_flutter/coui_flutter.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/flutter_prop_previews.dart';
import '../page_kit_flutter.dart';
import 'filter_page.dart';

/// 속성 → Widget.
///
/// Filter 는 선택을 스스로 기억하지 않으므로 빌더가 기억한다 — Web 빌더와 같다.
FlutterPropPreviewBuilder? get propPreview =>
    (props, _) => _FilterPreview(props: props);

/// 장면 이름(`filter/<장면>`) → 장면.
final Map<String, Widget Function()> demos = {
  'filter/anatomy': () => _filter(value: 'upcoming', reset: true),
  'filter/item-shapes': () => Filter<String>(
    groupValue: 'upcoming',
    onValueChanged: (_) {},
    items: [
      CoreFilterItem(value: 'all', label: '전체'),
      CoreFilterItem(value: 'upcoming', label: '예정', icon: Icon(LucideIcons.calendar)),
      CoreFilterItem(value: 'starred', label: '관심', icon: Icon(LucideIcons.star), showLabel: false),
    ],
  ),
  'filter/states': _filterStates,
  'filter/do-reset': () => _filter(value: 'upcoming', reset: true),
  'filter/do-short-labels': () => _filter(value: 'all'),
  'filter/dont-long-labels': () => _pairs(kFilterLongItems, kFilterLongItems.first.$1),
  'filter/do-multi': () => _multiChips(),
  'filter/dont-multi': () => _pairs(kFilterFeatureItems, kFilterFeatureItems.first.$1),
  'filter/placement-toolbar': () => docsFlutterDemoRow([
    _filter(value: 'all'),
    SizedBox(width: 200, child: TextField(placeholder: Text('검색'))),
  ]),
  'filter/placement-fill': () => SizedBox(
    width: kFilterPreviewFillWidth,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _filter(value: 'all', fillWidth: true),
        const Gap.space12(),
        Button(expanded: true, onPressed: () {}, child: const Text('결과 보기')),
      ],
    ),
  ),
  'filter/related-toggle-group': () => ToggleGroup<String>(
    value: 'am',
    onChanged: (_) {},
    items: const [
      CoreToggleGroupItem(value: 'am', label: '오전'),
      CoreToggleGroupItem(value: 'pm', label: '오후'),
    ],
  ),
  'filter/related-chip-group': () => _multiChips(),
};

/// 공통 항목으로 그리는 Filter.
Widget _filter({required String? value, bool reset = false, bool enabled = true, bool fillWidth = false}) =>
    Filter<String>(
      groupValue: value,
      onValueChanged: (_) {},
      showResetButton: reset,
      onReset: reset ? () {} : null,
      enabled: enabled,
      fillWidth: fillWidth,
      items: [for (final (id, label, _) in kFilterPreviewItems) CoreFilterItem(value: id, label: label)],
    );

/// 값 · 라벨 쌍으로 그리는 Filter.
Widget _pairs(List<(String, String)> entries, String value) => Filter<String>(
  groupValue: value,
  onValueChanged: (_) {},
  items: [for (final (id, label) in entries) CoreFilterItem(value: id, label: label)],
);

/// 함께 켤 수 있는 조건을 고르는 ChipGroup — 처음에 둘을 켜 둔다.
Widget _multiChips() => ChipGroup<String>(
  items: [for (final (_, label) in kFilterFeatureItems) label],
  initialValue: {for (final (_, label) in kFilterFeatureItems.take(2)) label},
  selectionMode: CoreChipGroupSelectionMode.multi,
  chipBuilder: (item, {required selected, required enabled, required onTap}) => Chip(
    label: item,
    selected: selected,
    enabled: enabled,
    chipColor: CoreChipColor.primary,
    onTap: onTap,
  ),
);

/// 상태 장면 — 선택이 있을 때 · 없을 때 · 비활성.
Widget _filterStates() => Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    for (final (index, (caption, value, enabled)) in const [
      ('선택 있음', 'upcoming', true),
      ('선택 없음', null, true),
      ('비활성', 'upcoming', false),
    ].indexed) ...[
      if (index > 0) const Gap.space16(),
      Text(caption).labelSmall.onSurfaceVariant,
      const Gap.space8(),
      _filter(value: value, reset: true, enabled: enabled),
    ],
  ],
);

/// 속성으로 그리는 Filter — 선택을 기억한다.
///
/// 속성: `variant` · `size` · `showResetButton` · `showLabel` · `fillWidth` ·
/// `enabled` 는 위젯(과 항목) 속성 그대로, `value` 는 처음 선택(`none` 은 선택
/// 없음), `icon` 은 모든 칸에 아이콘.
class _FilterPreview extends StatefulWidget {
  const _FilterPreview({required this.props});

  final Map<String, String> props;

  @override
  State<_FilterPreview> createState() => _FilterPreviewState();
}

class _FilterPreviewState extends State<_FilterPreview> {
  String? _selected;

  @override
  void initState() {
    super.initState();
    _selected = filterPreviewValue(widget.props);
  }

  @override
  void didUpdateWidget(covariant _FilterPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.props['value'] != widget.props['value']) _selected = filterPreviewValue(widget.props);
  }

  void _handleValueChanged(String value) => setState(() => _selected = value);

  void _handleReset() => setState(() => _selected = null);

  @override
  Widget build(BuildContext context) {
    final props = widget.props;
    final showReset = previewFlag(props, 'showResetButton');
    final showIcon = filterPreviewShowsIcon(props);
    final showLabel = previewFlag(props, 'showLabel', fallback: true);
    final fillWidth = previewFlag(props, 'fillWidth');
    final filter = Filter<String>(
      variant: previewEnum(CoreFilterVariant.values, props['variant'], CoreFilterVariant.defaultVariant),
      size: previewEnum(CoreComponentSize.values, props['size'], CoreFilterContract.defaultSize),
      groupValue: _selected,
      onValueChanged: _handleValueChanged,
      showResetButton: showReset,
      onReset: showReset ? _handleReset : null,
      fillWidth: fillWidth,
      enabled: previewFlag(props, 'enabled', fallback: true),
      items: [
        for (final (value, label, icon) in kFilterPreviewItems)
          CoreFilterItem(
            value: value,
            label: label,
            icon: showIcon ? docsFlutterIcon(icon) : null,
            showLabel: showLabel,
          ),
      ],
    );
    return fillWidth ? SizedBox(width: kFilterPreviewFillWidth, child: filter) : filter;
  }
}
