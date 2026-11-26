// Keyboard reordering for the Web `Sortable`.
//
// What a key *does* — which slot an arrow lands on, what a drop commits,
// what gets said — is the shared `CoreSortableKeyboard` session, pinned
// in `coui_core/test/drag/core_sortable_keyboard_test.dart` against the
// same engine this list drives. The live keydown dispatch is not run here:
// `universal_web`'s `KeyboardEvent.key` throws on the VM this suite runs
// on, and the rows cannot measure themselves without a layout engine.
//
// What this file pins is what that path needs from the markup — one
// named, focusable handle per row and no second stop on the row around
// it. The live region the list speaks through is pinned beside the scope
// (`infra/drag_scope_test.dart`).
import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/server_test.dart';

Component _sortable({required bool reorderable}) => Sortable(
  itemCount: 3,
  itemBuilder: (index, handle, remove) => div([handle, Text('Item $index')]),
  onReorder: reorderable ? (oldIndex, newIndex) {} : null,
);

const _kHandle = '[data-sortable-handle]';
const _kFocusable = '[tabindex]';
const _kApplication = '[role="application"]';
const _kApplicationHandle = '[role="application"][data-sortable-handle]';
const _kGrabbed = '[aria-grabbed]';

/// Server-renders [child] under the app shell and returns, per selector,
/// the attributes of every element it matches.
Future<Map<String, List<Map<Object, String>>>> _render(
  ServerTester tester,
  Component child,
  List<String> selectors,
) async {
  tester.pumpComponent(CoUIWeb(theme: .coui, child: child));
  final document = (await tester.request('/')).document!;

  return {
    for (final selector in selectors)
      selector: [
        for (final element in document.querySelectorAll(selector))
          element.attributes,
      ],
  };
}

void main() {
  group('Sortable keyboard handle', () {
    testServer('every reorderable row hands out one named, focusable handle', (
      tester,
    ) async {
      final found = await _render(tester, _sortable(reorderable: true), [
        _kHandle,
      ]);
      final handles = found[_kHandle]!;

      expect(handles, hasLength(3));
      for (final (index, handle) in handles.indexed) {
        expect(handle['tabindex'], '0');
        // Browse mode would otherwise keep Space and the arrows for itself.
        expect(handle['role'], 'application');
        expect(handle['aria-label'], 'Reorder item ${index + 1} of 3');
        expect(
          handle['aria-description'],
          'Press Space or Enter to pick up and drop, the arrow keys to '
          'move, and Escape to cancel.',
        );
      }
    });

    testServer('the handle is the only tab stop in a row', (tester) async {
      final found = await _render(tester, _sortable(reorderable: true), [
        _kFocusable,
        _kGrabbed,
        _kApplication,
        _kApplicationHandle,
      ]);

      // The row wrapper used to be a pixel-stepping keyboard drag of its
      // own — a second stop in front of the handle, and an `application`
      // role over the row's whole content.
      expect(found[_kFocusable], hasLength(3));
      expect(found[_kGrabbed], isEmpty);
      // Every `application` region is a handle — none is left on a row.
      expect(found[_kApplication], hasLength(3));
      expect(found[_kApplicationHandle], hasLength(3));
    });

    testServer('a list that cannot reorder offers no keyboard handle', (
      tester,
    ) async {
      final found = await _render(tester, _sortable(reorderable: false), [
        _kHandle,
        _kFocusable,
      ]);

      expect(found[_kHandle], isEmpty);
      expect(found[_kFocusable], isEmpty);
    });

    testServer('a pointer-only DragItem keeps its own keyboard drag', (
      tester,
    ) async {
      // Opting out is per item — every other consumer keeps the row-level
      // keyboard drag it had.
      final found = await _render(
        tester,
        const DragScope(
          child: div([
            DragItem(id: CoreDragId('a'), child: Text('a')),
            DragItem(
              id: CoreDragId('b'),
              keyboardDraggable: false,
              child: Text('b'),
            ),
          ]),
        ),
        [_kApplication, _kFocusable],
      );

      expect(found[_kApplication], hasLength(1));
      expect(found[_kFocusable], hasLength(1));
    });
  });
}
