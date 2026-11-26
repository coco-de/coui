// The panels the kit places itself keep to one segment of a viewport a fold
// splits: a drawer docked to an edge, and a panel anchored to a trigger.
// Which segment is read against the table the Core rule and Flutter read
// (`coui_core/test/fixtures/fold_vectors.json`), so the platforms open a
// panel on the same side — and where nothing splits the viewport the markup
// is what it always was.
//
// The browser reports segments, not folds, so each case is fed in as the
// browser would report it. The VM has no `env(viewport-segment-*)`; what is
// held here is which segment the drawer names and the room the positioning
// engine is given. That a browser draws the panels there is the probe's
// (`tool/parity/test/web/fold_probe_test.dart`).
import 'dart:convert';
import 'dart:io';

import 'package:coui_web/coui_web.dart';
import 'package:coui_web/src/base/fold_reading.dart';
import 'package:coui_web/src/base/fold_scope.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../helpers/pump_with_theme.dart';

const String _kVectorsPath = '../coui_core/test/fixtures/fold_vectors.json';

CoreViewportRect _rect(List<dynamic> value) => CoreViewportRect(
  left: (value[0] as num).toDouble(),
  top: (value[1] as num).toDouble(),
  width: (value[2] as num).toDouble(),
  height: (value[3] as num).toDouble(),
);

List<CoreViewportRect> _segmentsOf(Map<String, dynamic> vector) => [
  for (final segment in vector['segments'] as List<dynamic>)
    _rect(segment as List<dynamic>),
];

/// The one posture a page sees: the state of the case's first fold.
CoreFoldState _stateOf(Map<String, dynamic> vector) {
  final folds = vector['folds'] as List<dynamic>;
  if (folds.isEmpty) return CoreFoldState.flat;

  return CoreFoldState.values.byName(
    (folds.first as Map<String, dynamic>)['state'] as String,
  );
}

CoreFoldLayout _layoutOf(Map<String, dynamic> vector) =>
    foldLayoutFromSegments(_segmentsOf(vector), state: _stateOf(vector));

/// The index the table names for a panel placed at ([x], [y]) of the
/// viewport, each -1, 0 or 1.
int _alignedIndex(
  Map<String, dynamic> vector,
  CoreTextDirection direction,
  int x,
  int y,
) {
  final grid =
      (vector['aligned'] as Map<String, dynamic>)[direction.name]
          as List<dynamic>;

  return (grid[y + 1] as List<dynamic>)[x + 1] as int;
}

/// How the browser names segment [index] of [segments] in
/// `env(viewport-segment-* <column> <row>)`.
String _envAt(List<CoreViewportRect> segments, int index) {
  final segment = segments[index];
  final column = {
    for (final other in segments)
      if (other.left < segment.left) other.left,
  }.length;
  final row = {
    for (final other in segments)
      if (other.top < segment.top) other.top,
  }.length;

  return '$column $row';
}

late ResolvedDrawer _seen;

class _Capture extends StatelessComponent {
  const _Capture(this.side);

  final CoreDrawerSide side;

  @override
  Component build(BuildContext context) {
    _seen = resolveDrawer(context, side: side, open: true, dragDelta: 0);

    return const Component.text('x');
  }
}

Future<Map<String, String>> _panelStyles(
  ComponentTester tester,
  CoreDrawerSide side, {
  CoreFoldLayout? layout,
  CoreTextDirection direction = CoreTextDirection.ltr,
}) async {
  pumpWithTheme(
    tester,
    layout == null
        ? _Capture(side)
        : FoldLayoutScope(
            layout: layout,
            direction: direction,
            child: _Capture(side),
          ),
  );
  await tester.pump();

  return _seen.panel.inlineStyles!.properties;
}

void main() {
  final vectors = [
    for (final raw
        in (jsonDecode(File(_kVectorsPath).readAsStringSync())
                as Map<String, dynamic>)['cases']
            as List<dynamic>)
      raw as Map<String, dynamic>,
  ];

  group('a drawer docks to the segment its edge lies in', () {
    for (final vector in vectors) {
      final segments = _segmentsOf(vector);
      for (final direction in CoreTextDirection.values) {
        for (final side in CoreDrawerSide.values) {
          testComponents('${vector['name']}, ${direction.name}, '
              '${side.name}', (tester) async {
            final unfolded = Map.of(await _panelStyles(tester, side));
            final styles = await _panelStyles(
              tester,
              side,
              layout: _layoutOf(vector),
              direction: direction,
            );

            if (segments.length < 2) {
              // Nothing splits the viewport: the panel's markup is the
              // markup of a viewport with no fold scope at all.
              expect(styles, unfolded);
              expect(styles.values, everyElement(isNot(contains('env(view'))));

              return;
            }
            final (x, y) = switch (side) {
              CoreDrawerSide.left => (-1, 0),
              CoreDrawerSide.right => (1, 0),
              CoreDrawerSide.top => (0, -1),
              CoreDrawerSide.bottom => (0, 1),
            };
            final at = _envAt(
              segments,
              _alignedIndex(vector, direction, x, y),
            );
            String edge(String name) => 'env(viewport-segment-$name $at)';
            final right = 'calc(100% - ${edge('left')} - ${edge('width')})';
            final bottom = 'calc(100% - ${edge('top')} - ${edge('height')})';
            final docked = switch (side) {
              CoreDrawerSide.left => {
                'left': edge('left'),
                'top': edge('top'),
                'bottom': bottom,
                'max-width': edge('width'),
              },
              CoreDrawerSide.right => {
                'right': right,
                'top': edge('top'),
                'bottom': bottom,
                'max-width': edge('width'),
              },
              CoreDrawerSide.top => {
                'top': edge('top'),
                'left': edge('left'),
                'right': right,
                'max-height': edge('height'),
              },
              CoreDrawerSide.bottom => {
                'bottom': bottom,
                'left': edge('left'),
                'right': right,
                'max-height': edge('height'),
              },
            };

            for (final entry in docked.entries) {
              expect(styles[entry.key], entry.value, reason: entry.key);
            }
            // Everything else about the panel is what it was: only the
            // docking moved.
            expect(
              {
                for (final entry in styles.entries)
                  if (!docked.containsKey(entry.key)) entry.key: entry.value,
              },
              {
                for (final entry in unfolded.entries)
                  if (!docked.containsKey(entry.key)) entry.key: entry.value,
              },
            );
          });
        }
      }
    }
  });

  group("an anchored panel is given the room of its anchor's segment", () {
    const padding = 8.0;

    OverlayViewport viewportOf(CoreFoldLayout layout) => OverlayViewport.all(
      width: layout.width,
      height: layout.height,
      padding: padding,
    );

    for (final vector in vectors) {
      final layout = _layoutOf(vector);
      final segments = _segmentsOf(vector);

      test('${vector['name']} — the room', () {
        for (var index = 0; index < segments.length; index++) {
          final segment = segments[index];
          // A trigger in the middle of the segment.
          final anchor = OverlayRect(
            left: segment.left + segment.width / 2 - 20,
            top: segment.top + segment.height / 2 - 20,
            width: 40,
            height: 40,
          );

          final room = overlayViewportWithinFold(
            viewport: viewportOf(layout),
            fold: layout,
            anchor: anchor,
          );

          if (segments.length < 2) {
            expect(room.paddingLeft, padding);
            expect(room.paddingTop, padding);
            expect(room.paddingRight, padding);
            expect(room.paddingBottom, padding);
            continue;
          }
          expect(room.width, layout.width);
          expect(room.height, layout.height);
          expect(room.paddingLeft, padding + segment.left, reason: '$index');
          expect(room.paddingTop, padding + segment.top, reason: '$index');
          expect(
            room.paddingRight,
            padding + layout.width - segment.right,
            reason: '$index',
          );
          expect(
            room.paddingBottom,
            padding + layout.height - segment.bottom,
            reason: '$index',
          );
        }
      });

      if (segments.length < 2) continue;

      test('${vector['name']} — a panel that would cross the fold stays in '
          'the segment', () {
        // Wide enough to reach across a fold beside the trigger, and short
        // enough to fit the shortest viewport in the table on either side of
        // the trigger.
        const popover = OverlaySize(width: 280, height: 120);
        final centreX = layout.width / 2;
        final centreY = layout.height / 2;
        for (var index = 0; index < segments.length; index++) {
          final segment = segments[index];
          // A trigger beside the fold: the point of the segment nearest the
          // middle of the viewport, pulled in so it sits wholly inside.
          final anchor = OverlayRect(
            left: centreX.clamp(segment.left + 40, segment.right - 40) - 20,
            top: centreY.clamp(segment.top + 40, segment.bottom - 40) - 20,
            width: 40,
            height: 40,
          );

          final resolution = resolveOverlayCollision(
            trigger: anchor,
            popover: popover,
            placement: CorePopoverPlacement.bottom,
            viewport: overlayViewportWithinFold(
              viewport: viewportOf(layout),
              fold: layout,
              anchor: anchor,
            ),
            gap: 4,
          );

          final left = resolution.position.left;
          final top = resolution.position.top;
          expect(left, greaterThanOrEqualTo(segment.left), reason: '$index');
          expect(
            left + popover.width,
            lessThanOrEqualTo(segment.right),
            reason: '$index',
          );
          expect(top, greaterThanOrEqualTo(segment.top), reason: '$index');
          expect(
            top + popover.height,
            lessThanOrEqualTo(segment.bottom),
            reason: '$index',
          );
        }
      });
    }

    test('a viewport nothing has measured is the viewport', () {
      const viewport = OverlayViewport.all(
        width: 800,
        height: 600,
        padding: padding,
      );

      final room = overlayViewportWithinFold(
        viewport: viewport,
        fold: CoreFoldLayout.unmeasured,
        anchor: const OverlayRect(left: 380, top: 280, width: 40, height: 40),
      );

      expect(identical(room, viewport), isTrue);
    });
  });
}
