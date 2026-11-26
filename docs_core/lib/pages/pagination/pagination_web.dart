/// Pagination 페이지의 미리보기 — Jaspr Web.
///
/// 속성 빌더는 `<Preview props>` · 플레이그라운드가, 장면은
/// `<Preview demo="pagination/...">` · `<Card demo>` · `<Anatomy>` 가 읽는다. 같은
/// 이름의 Flutter 파일(`pagination_flutter.dart`)과 컴포넌트 · 속성 · 장면 이름이
/// 같아야 한다.
library;

import 'package:coui_web/coui_web.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/web_prop_previews.dart';
import 'pagination_page.dart';

/// 속성 → Component.
///
/// 페이지는 눌러야 바뀌므로 빌더가 현재 페이지를 기억한다. 서버에서 그리는
/// 블록에서는 처음 페이지의 줄 전체가 보이고, 브라우저에서 깨어나는
/// 플레이그라운드에서는 버튼을 눌러 옮기고 폭에 맞춰 줄어든다.
WebPropPreviewBuilder? get propPreview =>
    (props, _) => _PaginationPreview(props: props);

/// 장면 이름(`pagination/<장면>`) → 장면.
final Map<String, Component Function()> demos = {
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
  'pagination/related-select': () => div(styles: Styles(raw: {'width': '12rem'}), [
    Select<String>(
      label: '페이지당 개수',
      value: paginationPageSizeItems.first.$1,
      onChanged: (_) {},
      items: [
        for (final (value, text) in paginationPageSizeItems) CoreSelectItem(value: value, label: text),
      ],
    ),
  ]),
  'pagination/related-dot-indicator': () => DotIndicator(index: 1, length: 4, onChanged: (_) {}),
};

/// 이름표를 단 줄들을 세로로 — Flutter 장면과 같은 모양.
Component _labelled(List<(String, Component)> rows) =>
    div(classes: '${WebLayout.flex} ${WebLayout.flexCol} ${WebLayout.itemsCenter}', [
      for (final (index, (name, row)) in rows.indexed) ...[
        if (index > 0) Gap.space16(),
        Text(name).labelSmall.onSurfaceVariant,
        Gap.space8(),
        row,
      ],
    ]);

Component _relatedTable() => div(styles: Styles(raw: {'width': '12rem'}), [
  Table(
    rows: [
      CoreTableRowData<Component>.header(
        cells: [
          CoreTableCellData<Component>(child: Text(paginationTableHeader.$1)),
          CoreTableCellData<Component>(child: Text(paginationTableHeader.$2)),
        ],
      ),
      for (final (order, amount) in paginationTableRows)
        CoreTableRowData<Component>(
          cells: [
            CoreTableCellData<Component>(child: Text(order)),
            CoreTableCellData<Component>(child: Text(amount)),
          ],
        ),
    ],
  ),
]);

/// 속성으로 그리는 페이지 줄 — 눌러 옮긴 페이지를 기억한다.
///
/// 속성: `totalPages` · `maxPages` · `showLabel` · `showSkipToFirstPage` ·
/// `showSkipToLastPage` · `hidePreviousOnFirstPage` · `hideNextOnLastPage` ·
/// `enabled` 는 위젯 속성 그대로, `page` 는 처음 보일 페이지, `narrow` 는 좁은
/// 상자에 놓기.
class _PaginationPreview extends StatefulComponent {
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
    _page = paginationPreviewPage(component.props);
  }

  @override
  void didUpdateComponent(covariant _PaginationPreview oldComponent) {
    super.didUpdateComponent(oldComponent);
    if (oldComponent.props['page'] != component.props['page']) {
      _page = paginationPreviewPage(component.props);
    }
    _page = _page.clamp(1, paginationPreviewTotal(component.props));
  }

  void _handlePageChanged(int next) => setState(() => _page = next);

  @override
  Component build(BuildContext context) {
    final props = component.props;
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
    // 줄은 폭을 부모의 바깥 상자에서 잰다 — flex 항목은 건너뛰므로, 폭을 정하는
    // 상자 안에 상자를 하나 더 두어야 그 폭이 재진다. `max-width` 는 플레이그라운드
    // 칸이 자식에 거는 상한(20rem)을 푼다.
    final width = previewFlag(props, 'narrow') ? '${paginationPreviewNarrowWidth / 16}rem' : '100%';
    return div(styles: Styles(raw: {'width': width, 'max-width': '100%'}), [
      div(styles: Styles(raw: {'display': 'flex', 'justify-content': 'center'}), [pagination]),
    ]);
  }
}
