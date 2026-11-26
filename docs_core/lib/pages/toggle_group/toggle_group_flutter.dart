/// ToggleGroup 페이지의 미리보기 — Flutter.
///
/// 속성 빌더는 `<Preview props>` · `<Card props>` · `<SizeSpec>` · 플레이그라운드가,
/// 장면은 `<Preview demo="toggle-group/...">` 가 읽는다. 같은 이름의 Web 파일
/// (`toggle_group_web.dart`)과 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
library;

import 'package:coui_flutter/coui_flutter.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/flutter_prop_previews.dart';
import '../page_kit_flutter.dart';
import 'toggle_group_page.dart';

/// 속성 → Widget.
///
/// 선택은 눌러야 바뀌므로 빌더가 고른 값을 기억한다 — Web 빌더와 같다.
FlutterPropPreviewBuilder? get propPreview =>
    (props, _) => _ToggleGroupPreview(props: props);

/// 장면 이름(`toggle-group/<장면>`) → 장면.
final Map<String, Widget Function()> demos = {
  'toggle-group/anatomy': () => ToggleGroup<String>(
    value: 'grid',
    onChanged: (_) {},
    trailing: _resetButton(),
    items: _previewItems(toggleGroupPreviewItems.length, showIcon: true),
  ),
  'toggle-group/states': _toggleGroupStates,
  'toggle-group/trailing': () => ToggleGroup<String>(
    value: 'list',
    onChanged: (_) {},
    trailing: _resetButton(),
    items: _previewItems(2),
  ),
  'toggle-group/dont-many': () => ToggleGroup<String>(
    value: 'mon',
    size: CoreComponentSize.sm,
    onChanged: (_) {},
    items: [
      for (final (value, text) in toggleGroupWeekdayItems) CoreToggleGroupItem(value: value, label: text),
    ],
  ),
  'toggle-group/dont-empty': () => ToggleGroup<String>(value: null, onChanged: (_) {}, items: _periodItems()),
  'toggle-group/do-select': () => SizedBox(
    width: 192,
    child: Select<String>(
      label: '요일',
      value: 'mon',
      onChanged: (_) {},
      items: [
        for (final (value, text) in toggleGroupWeekdayItems) CoreSelectItem(value: value, label: '$text요일'),
      ],
    ),
  ),
  'toggle-group/related-filter': () => Filter<String>(
    groupValue: 'all',
    items: [
      for (final (value, text) in toggleGroupFilterItems) CoreFilterItem(value: value, label: text),
    ],
    onValueChanged: (_) {},
    showResetButton: true,
    onReset: () {},
  ),
};

List<CoreToggleGroupItem<String, Widget>> _previewItems(int count, {bool showIcon = false, bool showLabel = true}) => [
  for (final (value, text, icon) in toggleGroupPreviewItems.take(count))
    CoreToggleGroupItem(
      value: value,
      label: text,
      icon: showIcon ? docsFlutterIcon(icon) : null,
      showLabel: showLabel,
    ),
];

List<CoreToggleGroupItem<String, Widget>> _periodItems() => [
  for (final (value, text) in toggleGroupPeriodItems) CoreToggleGroupItem(value: value, label: text),
];

Widget _resetButton() => Semantics(
  button: true,
  label: toggleGroupResetLabel,
  child: Button(
    variant: CoreButtonVariant.ghost,
    size: CoreComponentSize.sm,
    shape: CoreButtonShape.square,
    onPressed: () {},
    child: Icon(LucideIcons.x),
  ),
);

/// 상태 장면 — Web 과 같은 세 상태.
Widget _toggleGroupStates() {
  const columns = ['선택', '선택 없음', '비활성'];
  Widget cell(String state) => ToggleGroup<String>(
    value: state == '선택 없음' ? null : 'am',
    enabled: state == '비활성' ? false : null,
    onChanged: (_) {},
    items: _periodItems(),
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

/// 속성으로 그리는 묶음 토글 — 눌러 고른 값을 기억한다. 속성은 Web 과 같다.
class _ToggleGroupPreview extends StatefulWidget {
  const _ToggleGroupPreview({required this.props});

  final Map<String, String> props;

  @override
  State<_ToggleGroupPreview> createState() => _ToggleGroupPreviewState();
}

class _ToggleGroupPreviewState extends State<_ToggleGroupPreview> {
  late String _value;

  @override
  void initState() {
    super.initState();
    _value = _initialValue();
  }

  @override
  void didUpdateWidget(covariant _ToggleGroupPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.props['value'] != widget.props['value']) _value = _initialValue();
  }

  String _initialValue() => widget.props['value'] ?? toggleGroupPreviewItems.first.$1;

  void _handleChanged(String next) => setState(() => _value = next);

  @override
  Widget build(BuildContext context) {
    final props = widget.props;
    final showLabel = previewFlag(props, 'showLabel', fallback: true);
    final fillWidth = previewFlag(props, 'fillWidth');
    final group = ToggleGroup<String>(
      value: _value,
      onChanged: _handleChanged,
      enabled: previewFlag(props, 'enabled', fallback: true) ? null : false,
      size: previewEnum(CoreComponentSize.values, props['size'], CoreComponentSize.md),
      direction: previewEnum(CoreAxis.values, props['direction'], CoreAxis.horizontal),
      fillWidth: fillWidth,
      items: _previewItems(
        int.tryParse(props['options'] ?? '') ?? toggleGroupPreviewItems.length,
        showIcon: previewFlag(props, 'icon') || !showLabel,
        showLabel: showLabel,
      ),
    );
    // 가로를 채우는 묶음은 채울 폭이 있어야 모양이 보인다.
    return fillWidth
        ? ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: SizedBox(width: double.infinity, child: group),
          )
        : group;
  }
}
