/// ItemPicker 페이지의 미리보기 — Flutter.
///
/// 속성 빌더는 `<Preview props>` · `<Card props>` · 플레이그라운드가, 장면은
/// `<Preview demo="item-picker/...">` 가 읽는다. 같은 이름의 Web 파일
/// (`item_picker_web.dart`)과 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
///
/// `ItemPicker` 는 흐름 안에 놓이는 패널이라 무대에 실제 위젯을 그대로 그린다.
/// 폭이 정해지지 않은 부모에서는 그릴 수 없어 장면마다 폭을 정한다.
library;

import 'package:coui_flutter/coui_flutter.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/flutter_prop_previews.dart';
import 'item_picker_page.dart';

/// 속성 → Widget.
FlutterPropPreviewBuilder? get propPreview => _itemPicker;

/// 장면 이름(`item-picker/<장면>`) → 장면.
final Map<String, Widget Function()> demos = {
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
  ], width: 184),
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
Widget _sized(Widget child, {double width = 240}) => SizedBox(width: width, child: child);

/// 이름을 단 패널을 나란히 — Web 과 같은 칸.
Widget _columns(List<(String, Widget)> columns, {double width = 240}) => Wrap(
  alignment: WrapAlignment.center,
  crossAxisAlignment: WrapCrossAlignment.start,
  spacing: CoreSpace.space16,
  runSpacing: CoreSpace.space16,
  children: [
    for (final (caption, child) in columns)
      SizedBox(
        width: width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: CoreSpace.space8,
          children: [
            Text(caption).labelSmall.onSurfaceVariant,
            child,
          ],
        ),
      ),
  ],
);

Widget _itemPicker(Map<String, String> props, String? label) => _ItemPickerHost(props: props);

/// 고른 항목을 들고 있는 미리보기 — 누른 항목을 `selectedValue` 로 다시 넘긴다.
class _ItemPickerHost extends StatefulWidget {
  const _ItemPickerHost({required this.props});

  final Map<String, String> props;

  @override
  State<_ItemPickerHost> createState() => _ItemPickerHostState();
}

class _ItemPickerHostState extends State<_ItemPickerHost> {
  String _selected = itemPickerSelected;

  void _handleChanged(String value) => setState(() => _selected = value);

  @override
  Widget build(BuildContext context) {
    final props = widget.props;
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
