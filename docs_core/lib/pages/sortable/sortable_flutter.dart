/// Sortable 페이지의 미리보기 — Flutter.
///
/// 속성 빌더는 `<Preview props>` · `<VariantRow>` · 플레이그라운드가, 장면은
/// `<Preview demo="sortable/...">` 가 읽는다. 같은 이름의 Web 파일
/// (`sortable_web.dart`)과 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
library;

import 'package:coui_flutter/coui_flutter.dart';

import '../../previews/props/flutter_prop_previews.dart';
import '../../shared/preview_props.dart';
import 'sortable_page.dart';

/// 속성 → Widget.
///
/// 순서와 제거는 호출자가 반영해야 보이므로 빌더가 항목을 기억한다 — Web
/// 빌더와 같다.
FlutterPropPreviewBuilder? get propPreview =>
    (props, _) => _SortablePreview(props: props);

/// 장면 이름(`sortable/<장면>`) → 장면.
final Map<String, Widget Function()> demos = {
  'sortable/anatomy': () => _sized(_list(kSortablePreviewItems, removable: true)),
  'sortable/states': _sortableStates,
  'sortable/do-labeled': () => _sized(_list(kSortablePreviewItems), width: _kCardWidth),
  'sortable/dont-icon-only': () => _sized(_iconOnlyList(), width: _kCardWidth),
};

/// 권장 · 금지 카드 안의 목록 폭(logical px).
const double _kCardWidth = 224;

/// 정지 그림의 목록 — 콜백은 비어 있다.
Widget _list(List<String> items, {bool removable = false, bool enabled = true}) => Sortable(
  itemCount: items.length,
  onReorder: (_, _) {},
  onRemove: (_) {},
  removable: removable,
  enabled: enabled,
  itemBuilder: (context, index, dragHandle, removeButton) =>
      _row(Text(items[index]), dragHandle, removeButton, axis: CoreSortableAxis.vertical),
);

/// 글자 없이 아이콘만 둔 항목 — 금지 카드의 그림.
Widget _iconOnlyList() => Sortable(
  itemCount: kSortablePreviewItems.length,
  onReorder: (_, _) {},
  itemBuilder: (context, index, dragHandle, removeButton) => _row(
    Align(alignment: AlignmentDirectional.centerStart, child: Icon(LucideIcons.file)),
    dragHandle,
    removeButton,
    axis: CoreSortableAxis.vertical,
  ),
);

/// 항목 한 줄. 행의 상자는 `Sortable` 이 그리고, 여기서는 상자 안의 배치만
/// 정한다. 가로 · 격자 목록은 항목이 받는 폭이 정해지지 않을 수 있어
/// `Expanded` 를 쓰지 않는다.
Widget _row(Widget content, Widget dragHandle, Widget? removeButton, {required CoreSortableAxis axis}) {
  final vertical = axis == CoreSortableAxis.vertical;
  return Row(
    mainAxisSize: vertical ? MainAxisSize.max : MainAxisSize.min,
    spacing: CoreSpace.space8,
    children: [
      dragHandle,
      if (vertical) Expanded(child: content) else content,
      ?removeButton,
    ],
  );
}

/// 폭이 필요한 목록(세로 · 격자)을 놓는 상자.
Widget _sized(Widget child, {double width = kSortablePreviewWidth}) => SizedBox(width: width, child: child);

/// 축에 맞는 상자 — 가로 목록은 내용만큼 차지하고, 좁은 화면에서는 가로로
/// 스크롤한다(`Sortable` 은 스스로 스크롤하지 않는다). 가로 목록의 행은 높이가
/// 정해진 부모를 끝까지 채우므로, `Column` 으로 높이를 열어 둔다 — 임베드
/// 뷰는 높이가 정해져 있다.
Widget _framed(CoreSortableAxis axis, Widget child) => switch (axis) {
  CoreSortableAxis.vertical => _sized(child),
  CoreSortableAxis.grid => _sized(child, width: kSortableGridPreviewWidth),
  CoreSortableAxis.horizontal => Column(
    mainAxisSize: MainAxisSize.min,
    children: [SingleChildScrollView(scrollDirection: Axis.horizontal, child: child)],
  ),
};

/// 상태 장면 — Web 과 같은 두 목록.
Widget _sortableStates() => Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.start,
  spacing: CoreSpace.space16,
  children: [
    _captioned('기본', _sized(_list(kSortablePreviewItems, removable: true))),
    _captioned('비활성', _sized(_list(kSortablePreviewItems, removable: true, enabled: false))),
  ],
);

/// 위에 이름을 단 장면 조각.
Widget _captioned(String caption, Widget child) => Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.start,
  spacing: CoreSpace.space8,
  children: [Text(caption).labelSmall.onSurfaceVariant, child],
);

/// 속성으로 그리는 목록 — 바꾼 순서와 지운 항목을 기억한다.
class _SortablePreview extends StatefulWidget {
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
  void didUpdateWidget(covariant _SortablePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.props['axis'] != widget.props['axis'] || oldWidget.props['removable'] != widget.props['removable']) {
      _reset();
    }
  }

  void _reset() => _items = sortablePreviewItems(sortablePreviewAxis(widget.props));

  void _handleReorder(int oldIndex, int newIndex) => setState(() => _items = sortableMoved(_items, oldIndex, newIndex));

  void _handleRemove(int index) => setState(() {
    _items = sortableRemoved(_items, index);
    // 마지막 항목을 지우면 처음 목록으로 돌아간다 — 미리보기가 비지 않게.
    if (_items.isEmpty) _reset();
  });

  @override
  Widget build(BuildContext context) {
    final props = widget.props;
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
        itemBuilder: (context, index, dragHandle, removeButton) =>
            _row(Text(_items[index]), dragHandle, removeButton, axis: axis),
      ),
    );
  }
}
