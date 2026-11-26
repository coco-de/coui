/// ItemPicker 페이지의 미리보기 — Jaspr Web.
///
/// 속성 빌더는 `<Preview props>` · `<Card props>` · 플레이그라운드가, 장면은
/// `<Preview demo="item-picker/...">` 가 읽는다. 같은 이름의 Flutter 파일
/// (`item_picker_flutter.dart`)과 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
///
/// `ItemPicker` 는 흐름 안에 놓이는 패널이라 무대에 실제 위젯을 그대로 그린다.
library;

import 'package:coui_web/coui_web.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/web_prop_previews.dart';
import 'item_picker_page.dart';

/// 속성 → Component.
WebPropPreviewBuilder? get propPreview => _itemPicker;

/// 장면 이름(`item-picker/<장면>`) → 장면.
final Map<String, Component Function()> demos = {
  'item-picker/anatomy': () => _sized(
    const ItemPicker(items: itemPickerShortCities, selectedValue: itemPickerSelected, title: itemPickerTitle),
  ),
  'item-picker/layouts': () => _columns([
    (itemPickerListCaption, const ItemPicker(items: itemPickerCities, selectedValue: itemPickerSelected)),
    (
      itemPickerGridCaption,
      const ItemPicker(
        items: itemPickerCities,
        selectedValue: itemPickerSelected,
        layout: CoreItemPickerLayout.grid,
        gridColumns: itemPickerSceneColumns,
      ),
    ),
  ]),
  'item-picker/states': () => _columns([
    (
      itemPickerSelectedCaption,
      const ItemPicker(items: itemPickerShortCities, selectedValue: itemPickerSelected, title: itemPickerTitle),
    ),
    (
      itemPickerDisabledCaption,
      const ItemPicker(
        items: itemPickerShortCities,
        selectedValue: itemPickerSelected,
        title: itemPickerTitle,
        enabled: false,
      ),
    ),
    (itemPickerEmptyCaption, const ItemPicker(title: itemPickerTitle)),
  ], width: '11.5rem'),
  'item-picker/do-short-list': () => _sized(
    const ItemPicker(
      items: itemPickerTextSizes,
      selectedValue: itemPickerTextSizeSelected,
      title: itemPickerTextSizeTitle,
      showSearch: false,
    ),
  ),
  'item-picker/dont-search-short': () => _sized(
    const ItemPicker(
      items: itemPickerTextSizes,
      selectedValue: itemPickerTextSizeSelected,
      title: itemPickerTextSizeTitle,
    ),
  ),
  'item-picker/do-distinct': () => _sized(
    const ItemPicker(
      items: itemPickerBranches,
      selectedValue: itemPickerBranchSelected,
      title: itemPickerBranchTitle,
      showSearch: false,
    ),
  ),
  'item-picker/dont-duplicate': () => _sized(
    const ItemPicker(
      items: itemPickerDuplicates,
      selectedValue: itemPickerDuplicateSelected,
      title: itemPickerBranchTitle,
      showSearch: false,
    ),
  ),
};

/// 폭이 정해진 틀 — 패널은 받은 폭을 채운다.
Component _sized(Component child, {String width = '15rem'}) =>
    div(styles: Styles(raw: {'width': width, 'max-width': '100%'}), [child]);

/// 이름을 단 패널을 나란히 — 폭이 모자라면 아래로 넘어간다.
Component _columns(List<(String, Component)> columns, {String width = '15rem'}) => div(
  styles: Styles(
    raw: {
      'display': 'flex',
      'flex-wrap': 'wrap',
      'justify-content': 'center',
      'align-items': 'flex-start',
      'gap': '1rem',
      'width': '100%',
    },
  ),
  [
    for (final (caption, child) in columns)
      div(
        styles: Styles(
          raw: {
            'display': 'flex',
            'flex-direction': 'column',
            'gap': '0.5rem',
            'width': width,
            'max-width': '100%',
          },
        ),
        [
          span([Text(caption).labelSmall.onSurfaceVariant]),
          child,
        ],
      ),
  ],
);

Component _itemPicker(Map<String, String> props, String? label) => _ItemPickerHost(props: props);

/// 고른 항목을 들고 있는 미리보기 — 누른 항목을 `selectedValue` 로 다시 넘긴다.
class _ItemPickerHost extends StatefulComponent {
  const _ItemPickerHost({required this.props});

  final Map<String, String> props;

  @override
  State<_ItemPickerHost> createState() => _ItemPickerHostState();
}

class _ItemPickerHostState extends State<_ItemPickerHost> {
  String _selected = itemPickerSelected;

  void _handleChanged(String value) => setState(() => _selected = value);

  @override
  Component build(BuildContext context) {
    final props = component.props;
    return _sized(
      ItemPicker(
        items: itemPickerCities,
        selectedValue: _selected,
        title: props['title'],
        layout: itemPickerPreviewLayout(props),
        gridColumns: itemPickerPreviewColumns(props),
        showSearch: previewFlag(props, 'showSearch', fallback: true),
        enabled: previewFlag(props, 'enabled', fallback: true),
        onChanged: _handleChanged,
      ),
    );
  }
}
