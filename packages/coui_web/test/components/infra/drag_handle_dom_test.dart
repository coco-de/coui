import 'package:coui_web/coui_web.dart';
import 'package:html/dom.dart' as html;
import 'package:jaspr_test/server_test.dart';

// `DragHandle` wraps its child in a `<div>` whose only jobs are carrying an
// id and a cursor. A bare block `<div>` is not neutral geometry, though: it
// inherits the row's line-height, opens a line box, and parks an
// inline-level child on the baseline — which pushed the 16px handle icon
// ~2.8px above the centre of its row. The Flutter twin wraps in a
// `MouseRegion` and adds no box at all, so the two platforms drew the same
// icon at different heights.
//
// SSR markup, not `testComponents`: the defect is DOM shape, and a resolver
// test sees only emitted values.

const _kItemCount = 2;

Component _sortable() => Sortable(
  itemCount: _kItemCount,
  itemBuilder: (index, handle, remove) => div([handle, Text("Item $index")]),
  onReorder: (oldIndex, newIndex) {},
);

Future<html.Element?> _handleOf(ServerTester tester) async =>
    (await tester.request('/')).document?.querySelector(
      '[id^="coui-drag-handle-"]',
    );

void main() {
  group('DragHandle wrapper geometry', () {
    testServer('the wrapper centres its child rather than baselining it', (
      tester,
    ) async {
      tester.pumpComponent(
        CoUIWeb(theme: .coui, child: _sortable()),
      );
      final handle = await _handleOf(tester);

      expect(handle, isNotNull);
      final classes = handle!.className.split(' ');
      expect(classes, contains('inline-flex'));
      expect(classes, contains('items-center'));
      // The cursor affordance is unchanged by the alignment fix.
      expect(classes, contains('cursor-grab'));
    });

    testServer('alignment does not depend on the drag registrar', (
      tester,
    ) async {
      // Standing outside any drag item there is no registrar and so no grab
      // cursor, but the wrapper still renders — so it still has to centre
      // its child. Making the alignment conditional would leave exactly this
      // path misaligned, and nothing else would say so.
      tester.pumpComponent(
        CoUIWeb(
          theme: .coui,
          child: DragHandle(child: Text('handle')),
        ),
      );
      final handle = await _handleOf(tester);

      expect(handle, isNotNull);
      final classes = handle!.className.split(' ');
      expect(classes, contains('inline-flex'));
      expect(classes, contains('items-center'));
    });
  });
}
