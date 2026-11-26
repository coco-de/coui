/// Sortable 페이지의 미리보기 — Jaspr Web.
///
/// 속성 빌더는 `<Preview props>` · `<VariantRow>` · 플레이그라운드가, 장면은
/// `<Preview demo="sortable/...">` 가 읽는다. 같은 이름의 Flutter 파일
/// (`sortable_flutter.dart`)과 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
library;

import 'package:coui_web/coui_web.dart';

import '../../previews/props/web_prop_previews.dart';
import '../../shared/preview_props.dart';
import 'sortable_page.dart';

/// 속성 → Component.
///
/// 순서와 제거는 호출자가 반영해야 보이므로 빌더가 항목을 기억한다. 서버에서
/// 그리는 블록에서는 처음 순서만 보이고, 브라우저에서 깨어나는
/// 플레이그라운드에서는 끌어서 순서를 바꾸거나 지울 수 있다.
WebPropPreviewBuilder? get propPreview =>
    (props, _) => _SortablePreview(props: props);

/// 장면 이름(`sortable/<장면>`) → 장면.
final Map<String, Component Function()> demos = {
  'sortable/anatomy': () => _sized(_list(kSortablePreviewItems, removable: true)),
  'sortable/states': _sortableStates,
  'sortable/do-labeled': () => _sized(_list(kSortablePreviewItems), width: _kCardWidth),
  'sortable/dont-icon-only': () => _sized(_iconOnlyList(), width: _kCardWidth),
};

/// 권장 · 금지 카드 안의 목록 폭(logical px).
const double _kCardWidth = 224;

/// 정지 그림의 목록 — 콜백은 비어 있다.
Component _list(List<String> items, {bool removable = false, bool enabled = true}) => Sortable(
  itemCount: items.length,
  onReorder: (_, _) {},
  onRemove: (_) {},
  removable: removable,
  enabled: enabled,
  itemBuilder: (index, dragHandle, removeButton) =>
      _row(Text(items[index]), dragHandle, removeButton, axis: CoreSortableAxis.vertical),
);

/// 글자 없이 아이콘만 둔 항목 — 금지 카드의 그림.
Component _iconOnlyList() => Sortable(
  itemCount: kSortablePreviewItems.length,
  onReorder: (_, _) {},
  itemBuilder: (index, dragHandle, removeButton) =>
      _row(Icon(LucideIcons.file), dragHandle, removeButton, axis: CoreSortableAxis.vertical),
);

/// 항목 한 줄. 행의 상자는 `Sortable` 이 그리고, 여기서는 상자 안의 배치만
/// 정한다. 세로 목록은 내용이 남는 폭을 채운다.
Component _row(Component content, Component dragHandle, Component? removeButton, {required CoreSortableAxis axis}) {
  final vertical = axis == CoreSortableAxis.vertical;
  final layout = '${WebLayout.flexItemsCenter} gap-${CoreSpace.scale.space8}';
  return div(
    [
      dragHandle,
      if (vertical) div([content], classes: WebLayout.flex1) else content,
      ?removeButton,
    ],
    classes: vertical ? '$layout ${WebLayout.flex1}' : layout,
  );
}

/// 폭이 필요한 목록(세로 · 격자)을 놓는 상자. [width] 는 logical px.
Component _sized(Component child, {double width = kSortablePreviewWidth}) =>
    div(styles: Styles(raw: {'width': pinnedLengthCss(width), 'max-width': '100%'}), [child]);

/// 축에 맞는 상자 — 가로 목록은 내용만큼만 차지한다.
Component _framed(CoreSortableAxis axis, Component child) => switch (axis) {
  CoreSortableAxis.vertical => _sized(child),
  CoreSortableAxis.grid => _sized(child, width: kSortableGridPreviewWidth),
  CoreSortableAxis.horizontal => div(styles: Styles(raw: {'max-width': '100%'}), [child]),
};

/// 상태 장면 — 기본과 비활성. hover 와 끌기는 포인터 없이 켤 수 없어 표로만
/// 적는다.
Component _sortableStates() => div(
  classes: '${WebLayout.flex} ${WebLayout.flexCol} ${WebLayout.itemsStart} gap-${CoreSpace.scale.space16}',
  [
    _captioned('기본', _sized(_list(kSortablePreviewItems, removable: true))),
    _captioned('비활성', _sized(_list(kSortablePreviewItems, removable: true, enabled: false))),
  ],
);

/// 위에 이름을 단 장면 조각.
Component _captioned(String caption, Component child) => div(
  classes: '${WebLayout.flex} ${WebLayout.flexCol} ${WebLayout.itemsStart} gap-${CoreSpace.scale.space8}',
  [Text(caption).labelSmall.onSurfaceVariant, child],
);

/// 속성으로 그리는 목록 — 바꾼 순서와 지운 항목을 기억한다.
class _SortablePreview extends StatefulComponent {
  const _SortablePreview({required this.props});

  final Map<String, String> props;

  @override
  State<_SortablePreview> createState() => _SortablePreviewState();
}

class _SortablePreviewState extends State<_SortablePreview> {
  late List<String> _items;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  @override
  void didUpdateComponent(covariant _SortablePreview oldComponent) {
    super.didUpdateComponent(oldComponent);
    if (oldComponent.props['axis'] != component.props['axis'] ||
        oldComponent.props['removable'] != component.props['removable']) {
      _reset();
    }
  }

  void _reset() => _items = sortablePreviewItems(sortablePreviewAxis(component.props));

  void _handleReorder(int oldIndex, int newIndex) => setState(() => _items = sortableMoved(_items, oldIndex, newIndex));

  void _handleRemove(int index) => setState(() {
    _items = sortableRemoved(_items, index);
    // 마지막 항목을 지우면 처음 목록으로 돌아간다 — 미리보기가 비지 않게.
    if (_items.isEmpty) _reset();
  });

  @override
  Component build(BuildContext context) {
    final props = component.props;
    final axis = sortablePreviewAxis(props);
    return _framed(
      axis,
      Sortable(
        // 끄는 방향의 잠금은 목록이 처음 만들어질 때의 axis 로 정해지므로,
        // axis 가 바뀌면 새로 만든다.
        key: ValueKey(axis),
        itemCount: _items.length,
        axis: axis,
        removable: previewFlag(props, 'removable'),
        enabled: previewFlag(props, 'enabled', fallback: true),
        onReorder: _handleReorder,
        onRemove: _handleRemove,
        itemBuilder: (index, dragHandle, removeButton) =>
            _row(Text(_items[index]), dragHandle, removeButton, axis: axis),
      ),
    );
  }
}
