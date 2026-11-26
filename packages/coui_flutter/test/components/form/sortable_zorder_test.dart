import 'dart:typed_data';

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/rendering.dart' as rendering;
import 'package:flutter_test/flutter_test.dart';

// A `Column` paints children in declaration order, so a row dragged
// downwards is drawn before — and under — every sibling it passes. Rows are
// opaque, so the occlusion is total. These tests read real pixels because
// paint order leaves no trace in the widget tree: any assertion about which
// one is on top that is not a pixel is an assertion about the code one
// believes is running.

const _kRowCount = 3;
const _kContentHeight = 60.0;
const _kViewportWidth = 300.0;
const _kViewportHeight = 400.0;

/// Sampled well right of the drag handle, inside the coloured column.
const _kSampleX = 250.0;

/// Far enough to overlap the next row, short of committing a reorder.
const _kDragFraction = 0.45;

/// Long enough for the lift animation to settle.
const _kSettle = Duration(milliseconds: 300);

const _kBytesPerPixel = 4;
const _kOpaque = 255;

const _kDragged = material.Color(0xFFFF0000);
const _kNeighbour = material.Color(0xFF0000FF);

final _boundaryKey = GlobalKey();

// The boundary sits *above* the app: the lifted copy renders in the
// `Overlay`, which lives above the route's content, so a boundary inside
// the page would photograph everything except the thing under test.
Widget _buildApp(Widget child) => RepaintBoundary(
  key: _boundaryKey,
  child: material.MaterialApp(
    home: material.Scaffold(body: _viewport(child)),
  ),
);

Widget _viewport(Widget child) => material.SizedBox(
  width: _kViewportWidth,
  height: _kViewportHeight,
  child: Theme(data: const ThemeData(), child: child),
);

/// Row 0 is the one dragged; every other row shares one contrasting colour,
/// so a sample only has to answer "dragged or not".
Widget _item(
  BuildContext context,
  int index,
  Widget dragHandle,
  Widget? removeButton,
) => material.Row(
  children: [
    dragHandle,
    material.Expanded(
      child: material.SizedBox(
        key: ValueKey('box-$index'),
        height: _kContentHeight,
        child: material.ColoredBox(
          color: index == 0 ? _kDragged : _kNeighbour,
        ),
      ),
    ),
  ],
);

Widget _sortable() => Sortable(
  itemCount: _kRowCount,
  itemBuilder: _item,
  onReorder: (oldIndex, newIndex) {},
);

Future<material.Color> _pixelAt(WidgetTester tester, Offset point) async {
  final boundary =
      _boundaryKey.currentContext!.findRenderObject()!
          as rendering.RenderRepaintBoundary;
  // `toImage` needs the real event loop; inside the fake-async zone of a
  // widget test the future never completes.
  Uint8List? bytes;
  var width = 0;
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    width = image.width;
    final data = await image.toByteData(format: .rawRgba);
    bytes = data!.buffer.asUint8List();
  });
  final at = ((point.dy.round() * width) + point.dx.round()) * _kBytesPerPixel;

  return material.Color.fromARGB(
    _kOpaque,
    bytes![at],
    bytes![at + 1],
    bytes![at + 2],
  );
}

/// A live downward drag of row 0, plus the geometry it started from.
///
/// Rects are captured *before* the gesture: once the row is lifted its key
/// matches twice (the vacated slot and the floating copy), and the slot no
/// longer moves — so mid-drag lookups answer a different question than the
/// one being asked.
class _Drag {
  const _Drag({
    required this.gesture,
    required this.shift,
    required this.draggedBox,
    required this.neighbourBox,
  });

  final TestGesture gesture;
  final double shift;
  final Rect draggedBox;
  final Rect neighbourBox;

  /// A point inside the band where the travelled copy covers row 1.
  Offset get overlapSample =>
      .new(_kSampleX, (neighbourBox.top + draggedBox.bottom + shift) / 2);

  /// A point inside row 0's original slot that the copy has moved past.
  Offset get vacatedSample => .new(_kSampleX, draggedBox.top + (shift / 2));

  /// Where the row ends up when it travels in-tree instead of into the
  /// overlay.
  Offset get travelledSample => .new(_kSampleX, draggedBox.center.dy + shift);
}

Future<_Drag> _dragFirstRowDown(WidgetTester tester) async {
  final handles = find.byType(Icon);
  final first = tester.getRect(handles.first);
  final second = tester.getRect(handles.at(1));
  final shift = (second.center.dy - first.center.dy) * _kDragFraction;
  final draggedBox = tester.getRect(find.byKey(const ValueKey('box-0')));
  final neighbourBox = tester.getRect(find.byKey(const ValueKey('box-1')));

  final gesture = await tester.startGesture(first.center, kind: .mouse);
  await gesture.moveBy(Offset(0, shift));
  await tester.pump();
  await tester.pump(_kSettle);

  return _Drag(
    gesture: gesture,
    shift: shift,
    draggedBox: draggedBox,
    neighbourBox: neighbourBox,
  );
}

void main() {
  group('Sortable drag z-order', () {
    testWidgets('the dragged row paints over the sibling below it', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp(_sortable()));
      await tester.pump();

      final drag = await _dragFirstRowDown(tester);

      expect(
        drag.draggedBox.bottom + drag.shift,
        greaterThan(drag.neighbourBox.top),
        reason: 'the drag must actually overlap the next row',
      );
      expect(await _pixelAt(tester, drag.overlapSample), _kDragged);

      await drag.gesture.up();
      final _ = await tester.pumpAndSettle();
    });

    testWidgets('the lifted row is not painted twice', (tester) async {
      await tester.pumpWidget(_buildApp(_sortable()));
      await tester.pump();

      final drag = await _dragFirstRowDown(tester);

      // The slot the row left keeps its size but shows nothing of its own,
      // so the surface behind it is what remains — a second copy drawn in
      // place would report the dragged colour here.
      expect(await _pixelAt(tester, drag.vacatedSample), isNot(_kDragged));

      await drag.gesture.up();
      final _ = await tester.pumpAndSettle();
    });

    testWidgets('without an Overlay the dragged row still renders', (
      tester,
    ) async {
      // `DragOverlay` fails quiet when no `Overlay` is in scope. Emptying
      // the row's slot on that path would erase the row entirely, so the
      // component keeps its in-tree lift instead — degraded, never absent.
      await tester.pumpWidget(
        Directionality(
          textDirection: .ltr,
          child: RepaintBoundary(
            key: _boundaryKey,
            child: _viewport(_sortable()),
          ),
        ),
      );
      await tester.pump();

      final drag = await _dragFirstRowDown(tester);

      expect(await _pixelAt(tester, drag.travelledSample), _kDragged);

      await drag.gesture.up();
      final _ = await tester.pumpAndSettle();
    });

    testWidgets('the copy is gone on the frame after the drop', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp(_sortable()));
      await tester.pump();

      final drag = await _dragFirstRowDown(tester);
      await drag.gesture.up();
      await tester.pump();
      final _ = await tester.pumpAndSettle();

      // Back at rest every row sits in its slot; a stale overlay copy would
      // still be floating over the gap between rows 0 and 1.
      final first = tester.getRect(find.byKey(const ValueKey('box-0')));
      final second = tester.getRect(find.byKey(const ValueKey('box-1')));
      final gap = Offset(_kSampleX, (first.bottom + second.top) / 2);

      expect(await _pixelAt(tester, gap), isNot(_kDragged));
    });
  });
}
