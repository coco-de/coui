/// ToggleGroup 페이지의 미리보기 — Jaspr Web.
///
/// 속성 빌더는 `<Preview props>` · `<Card props>` · `<SizeSpec>` · 플레이그라운드가,
/// 장면은 `<Preview demo="toggle-group/...">` 가 읽는다. 같은 이름의 Flutter 파일
/// (`toggle_group_flutter.dart`)과 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
library;

import 'package:coui_web/coui_web.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/web_prop_previews.dart';
import '../page_kit_web.dart';
import 'toggle_group_page.dart';

/// 속성 → Component.
///
/// 선택은 눌러야 바뀌므로 빌더가 고른 값을 기억한다. 서버에서 그리는 블록에서는
/// 처음 선택만 보이고, 브라우저에서 깨어나는 플레이그라운드에서는 칸을 눌러 바꿀 수 있다.
WebPropPreviewBuilder? get propPreview =>
    (props, _) => _ToggleGroupPreview(props: props);

/// 장면 이름(`toggle-group/<장면>`) → 장면.
final Map<String, Component Function()> demos = {
  'toggle-group/anatomy': () => ToggleGroup<String>(
    value: 'grid',
    onChanged: (_) {},
    // `data-docs-part` 는 구조 번호가 이 자리를 찾는 표지다.
    trailing: div(attributes: const {'data-docs-part': 'trailing'}, [_resetButton()]),
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
  'toggle-group/do-select': () => div(styles: Styles(raw: {'width': '12rem'}), [
    Select<String>(
      label: '요일',
      value: 'mon',
      onChanged: (_) {},
      items: [
        for (final (value, text) in toggleGroupWeekdayItems) CoreSelectItem(value: value, label: '$text요일'),
      ],
    ),
  ]),
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

List<CoreToggleGroupItem<String, Component>> _previewItems(int count, {bool showIcon = false, bool showLabel = true}) =>
    [
      for (final (value, text, icon) in toggleGroupPreviewItems.take(count))
        CoreToggleGroupItem(
          value: value,
          label: text,
          icon: showIcon ? docsWebIcon(icon) : null,
          showLabel: showLabel,
        ),
    ];

List<CoreToggleGroupItem<String, Component>> _periodItems() => [
  for (final (value, text) in toggleGroupPeriodItems) CoreToggleGroupItem(value: value, label: text),
];

Component _resetButton() => Button(
  variant: CoreButtonVariant.ghost,
  size: CoreComponentSize.sm,
  shape: CoreButtonShape.square,
  attributes: const {'aria-label': toggleGroupResetLabel},
  onPressed: () {},
  child: Icon(LucideIcons.x),
);

/// 상태 장면 — 선택 · 선택 없음 · 비활성. hover · 눌림 · 포커스는 브라우저가
/// 포인터나 키보드 없이 켤 수 없어 표의 설명으로 대신한다.
Component _toggleGroupStates() {
  const columns = ['선택', '선택 없음', '비활성'];
  Component cell(String state) => ToggleGroup<String>(
    value: state == '선택 없음' ? null : 'am',
    enabled: state == '비활성' ? false : null,
    onChanged: (_) {},
    items: _periodItems(),
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

/// 속성으로 그리는 묶음 토글 — 눌러 고른 값을 기억한다.
///
/// 속성: `size` · `direction` · `fillWidth` · `enabled` 는 위젯 속성 그대로,
/// `value` 는 처음 고른 값, `options` 는 칸 수, `icon` 은 칸에 아이콘,
/// `showLabel=false` 는 아이콘만 있는 칸.
class _ToggleGroupPreview extends StatefulComponent {
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
  void didUpdateComponent(covariant _ToggleGroupPreview oldComponent) {
    super.didUpdateComponent(oldComponent);
    if (oldComponent.props['value'] != component.props['value']) _value = _initialValue();
  }

  String _initialValue() => component.props['value'] ?? toggleGroupPreviewItems.first.$1;

  void _handleChanged(String next) => setState(() => _value = next);

  @override
  Component build(BuildContext context) {
    final props = component.props;
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
    return fillWidth ? div(styles: Styles(raw: {'width': '20rem', 'max-width': '100%'}), [group]) : group;
  }
}
