/// Pagination 페이지의 미리보기 — Flutter.
///
/// 속성 빌더는 `<Preview props>` · 플레이그라운드가, 장면은
/// `<Preview demo="pagination/...">` · `<Card demo>` · `<Anatomy>` 가 읽는다. 같은
/// 이름의 Web 파일(`pagination_web.dart`)과 컴포넌트 · 속성 · 장면 이름이
/// 같아야 한다.
library;

import 'package:coui_flutter/coui_flutter.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/flutter_prop_previews.dart';
import 'pagination_page.dart';

/// 속성 → Widget.
///
/// 페이지는 눌러야 바뀌므로 빌더가 현재 페이지를 기억한다 — Web 빌더와 같다.
FlutterPropPreviewBuilder? get propPreview =>
    (props, _) => _PaginationPreview(props: props);

/// 장면 이름(`pagination/<장면>`) → 장면.
final Map<String, Widget Function()> demos = {
  'pagination/anatomy': () => Pagination(page: 5, totalPages: paginationPreviewTotalPages, onPageChanged: (_) {}),
  'pagination/window': () => _labelled([
    for (final page in paginationWindowPages)
      ('page: $page', Pagination(page: page, totalPages: paginationPreviewTotalPages, onPageChanged: (_) {})),
  ]),
  'pagination/states': () => _labelled([
    for (final (name, page, enabled) in paginationStateRows)
      (
        name,
        Pagination(
          page: page,
          totalPages: paginationPreviewTotalPages,
          enabled: enabled ? null : false,
          onPageChanged: (_) {},
        ),
      ),
  ]),
  'pagination/do-multiple-pages': () => Pagination(page: 2, totalPages: 3, onPageChanged: (_) {}),
  'pagination/dont-single-page': () => Pagination(page: 1, totalPages: 1, onPageChanged: (_) {}),
  'pagination/related-table': _relatedTable,
  'pagination/related-select': () => SizedBox(
    width: 192,
    child: Select<String>(
      label: '페이지당 개수',
      value: paginationPageSizeItems.first.$1,
      onChanged: (_) {},
      items: [
        for (final (value, text) in paginationPageSizeItems) CoreSelectItem(value: value, label: text),
      ],
    ),
  ),
  'pagination/related-dot-indicator': () => DotIndicator(index: 1, length: 4, onChanged: (_) {}),
};

/// 이름표를 단 줄들을 세로로 — Web 장면과 같은 모양.
Widget _labelled(List<(String, Widget)> rows) => Column(
  mainAxisSize: MainAxisSize.min,
  spacing: CoreSpace.space16,
  children: [
    for (final (name, row) in rows)
      Column(
        mainAxisSize: MainAxisSize.min,
        spacing: CoreSpace.space8,
        children: [Text(name).labelSmall.onSurfaceVariant, row],
      ),
  ],
);

Widget _relatedTable() => SizedBox(
  width: 192,
  child: Table(
    rows: [
      CoreTableRowData<Widget>.header(
        cells: [
          CoreTableCellData<Widget>(child: Text(paginationTableHeader.$1)),
          CoreTableCellData<Widget>(child: Text(paginationTableHeader.$2)),
        ],
      ),
      for (final (order, amount) in paginationTableRows)
        CoreTableRowData<Widget>(
          cells: [
            CoreTableCellData<Widget>(child: Text(order)),
            CoreTableCellData<Widget>(child: Text(amount)),
          ],
        ),
    ],
  ),
);

/// 속성으로 그리는 페이지 줄 — 눌러 옮긴 페이지를 기억한다.
///
/// 속성: `totalPages` · `maxPages` · `showLabel` · `showSkipToFirstPage` ·
/// `showSkipToLastPage` · `hidePreviousOnFirstPage` · `hideNextOnLastPage` ·
/// `enabled` 는 위젯 속성 그대로, `page` 는 처음 보일 페이지, `narrow` 는 좁은
/// 상자에 놓기.
class _PaginationPreview extends StatefulWidget {
  const _PaginationPreview({required this.props});

  final Map<String, String> props;

  @override
  State<_PaginationPreview> createState() => _PaginationPreviewState();
}

class _PaginationPreviewState extends State<_PaginationPreview> {
  late int _page;

  @override
  void initState() {
    super.initState();
    _page = paginationPreviewPage(widget.props);
  }

  @override
  void didUpdateWidget(covariant _PaginationPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.props['page'] != widget.props['page']) {
      _page = paginationPreviewPage(widget.props);
    }
    _page = _page.clamp(1, paginationPreviewTotal(widget.props));
  }

  void _handlePageChanged(int next) => setState(() => _page = next);

  @override
  Widget build(BuildContext context) {
    final props = widget.props;
    final pagination = Pagination(
      page: _page,
      totalPages: paginationPreviewTotal(props),
      onPageChanged: _handlePageChanged,
      enabled: previewFlag(props, 'enabled', fallback: true) ? null : false,
      maxPages: paginationPreviewMaxPages(props),
      showSkipToFirstPage: previewFlag(props, 'showSkipToFirstPage', fallback: true),
      showSkipToLastPage: previewFlag(props, 'showSkipToLastPage', fallback: true),
      hidePreviousOnFirstPage: previewFlag(props, 'hidePreviousOnFirstPage'),
      hideNextOnLastPage: previewFlag(props, 'hideNextOnLastPage'),
      showLabel: previewFlag(props, 'showLabel'),
    );
    if (!previewFlag(props, 'narrow')) return pagination;
    // `Center` 는 폭의 상한만 넘긴다 — 줄은 그 상한에 맞는 단계를 고른다.
    return SizedBox(
      width: paginationPreviewNarrowWidth,
      child: Center(child: pagination),
    );
  }
}
