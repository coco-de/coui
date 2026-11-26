import 'package:coui_web/coui_web.dart';
import 'package:html/dom.dart' as html;
import 'package:jaspr_test/server_test.dart';

// The list container carries the inter-row `gap` inline, and CSS `gap` only
// separates the children that container owns. A wrapper element between it
// and the rows therefore leaves the rows touching while the declared gap
// still reads as 8px on the container — which is what a resolver-level test
// sees, and why the regression these tests pin went unnoticed.
//
// `testServer` (not `testComponents`) because only the real SSR binding
// hands back markup; the assertion here is about DOM shape, not emit.

const _kItemCount = 3;

Component _sortable({
  required bool reorderable,
  CoreSortableAxis axis = .vertical,
  String? id,
  String? classes,
  Styles? css,
  Map<String, String>? attributes,
}) => Sortable(
  itemCount: _kItemCount,
  itemBuilder: (index, handle, remove) => div([handle, Text('Item $index')]),
  axis: axis,
  attributes: attributes,
  classes: classes,
  css: css,
  id: id,
  onReorder: reorderable ? (oldIndex, newIndex) {} : null,
);

/// The rows the list container actually owns — `<style>` is `display: none`
/// and never participates in the flex layout, so it is not one of them.
List<html.Element> _rowsOf(html.Element list) => list.children
    .where((html.Element child) => child.localName != 'style')
    .toList();

/// Inline chrome of the `listitem` a row wraps.
String? _itemStyleOf(html.Element row) =>
    row.querySelector('[role="listitem"]')?.attributes['style'];

void main() {
  group('Sortable list container owns its rows', () {
    testServer('interactive rows are direct children of the gap owner', (
      tester,
    ) async {
      tester.pumpComponent(
        CoUIWeb(theme: .coui, child: _sortable(reorderable: true)),
      );
      final response = await tester.request('/');
      final list = response.document?.querySelector('[role="list"]');

      expect(list, isNotNull);
      expect(list!.attributes['style'], contains('gap'));
      expect(_rowsOf(list).length, _kItemCount);
    });

    testServer('non-interactive rows are too — both paths agree', (
      tester,
    ) async {
      // Pinning the two branches under one assertion is what stops a fix
      // that only reaches the branch someone happened to open.
      tester.pumpComponent(
        CoUIWeb(theme: .coui, child: _sortable(reorderable: false)),
      );
      final response = await tester.request('/');
      final list = response.document?.querySelector('[role="list"]');

      expect(list, isNotNull);
      expect(_rowsOf(list!).length, _kItemCount);
    });

    for (final axis in CoreSortableAxis.values) {
      testServer('${axis.name} keeps rows directly under the container', (
        tester,
      ) async {
        tester.pumpComponent(
          CoUIWeb(
            theme: .coui,
            child: _sortable(reorderable: true, axis: axis),
          ),
        );
        final response = await tester.request('/');
        final list = response.document?.querySelector('[role="list"]');

        expect(list, isNotNull);
        expect(list!.className, contains('w-full'));
        expect(_rowsOf(list).length, _kItemCount);
      });
    }

    testServer('the drag scope contributes no element of its own', (
      tester,
    ) async {
      tester.pumpComponent(
        CoUIWeb(theme: .coui, child: _sortable(reorderable: true)),
      );
      final response = await tester.request('/');

      // The scope adopts the list as its measurement origin, so it renders
      // nothing. A box here is the regression: it would sit between the
      // container and its rows and swallow the gap.
      expect(
        response.document?.querySelector('[id^="coui-drag-scope"]'),
        isNull,
      );
    });

    testServer('inter-row spacing lives on the container, not the row', (
      tester,
    ) async {
      // `itemSpacing` means the distance *between* rows. It used to be spent
      // twice — once as the container's gap and again as each row's own
      // inner gap — so adjusting row spacing would have moved the row's
      // contents too. The second use paid for nothing: a row owns a single
      // child, and the Flutter twin emits no inner gap at all.
      tester.pumpComponent(
        CoUIWeb(theme: .coui, child: _sortable(reorderable: true)),
      );
      final response = await tester.request('/');
      final list = response.document?.querySelector('[role="list"]');

      expect(list, isNotNull);
      expect(list!.attributes['style'], contains('gap'));
      final rowStyles = _rowsOf(list).map(_itemStyleOf).toList();

      expect(rowStyles, hasLength(_kItemCount));
      expect(rowStyles, everyElement(isNot(contains('gap'))));
      // The rest of the row's inline chrome is untouched.
      expect(
        rowStyles,
        everyElement(allOf(contains('padding'), contains('border-radius'))),
      );
    });

    testServer('caller chrome still lands on the list element', (
      tester,
    ) async {
      tester.pumpComponent(
        CoUIWeb(
          theme: .coui,
          child: _sortable(
            reorderable: true,
            id: 'my-list',
            classes: 'my-class',
            css: const Styles(raw: {'margin': '1rem'}),
            attributes: const {'data-testid': 'sortable'},
          ),
        ),
      );
      final response = await tester.request('/');
      final root = response.document?.querySelector('#my-list');

      expect(root, isNotNull);
      expect(root!.attributes['role'], 'list');
      expect(root.className, allOf(contains('my-class'), contains('w-full')));
      expect(
        root.attributes['style'],
        allOf(contains('gap'), contains('margin')),
      );
      expect(root.attributes['data-testid'], 'sortable');
      expect(_rowsOf(root).length, _kItemCount);
    });
  });
}
