// The fold rule both platforms read: which folds cross the viewport, the
// segments they leave, the kind of device, how it is held, and where a panel
// opens — one that nothing anchors, and one placed at an alignment of the
// viewport. The cases are a table
// (`test/fixtures/fold_vectors.json`) that the Flutter and Web transports read
// too, so a change to the rule that one platform's tests would miss fails here.
import 'dart:convert';
import 'dart:io';

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

const String _kVectorsPath = 'test/fixtures/fold_vectors.json';

CoreViewportRect _rect(List<dynamic> value) => CoreViewportRect(
  left: (value[0] as num).toDouble(),
  top: (value[1] as num).toDouble(),
  width: (value[2] as num).toDouble(),
  height: (value[3] as num).toDouble(),
);

CoreFoldLayout _layoutOf(Map<String, dynamic> vector) {
  final viewport = vector['viewport'] as List<dynamic>;

  return CoreFoldLayout(
    width: (viewport[0] as num).toDouble(),
    height: (viewport[1] as num).toDouble(),
    folds: [
      for (final fold in vector['folds'] as List<dynamic>)
        CoreFold(
          bounds: _rect((fold as Map<String, dynamic>)['bounds'] as List),
          state: CoreFoldState.values.byName(fold['state'] as String),
        ),
    ],
  );
}

/// [layout] turned a quarter: every rectangle's axes swapped.
CoreFoldLayout _turned(CoreFoldLayout layout) => CoreFoldLayout(
  width: layout.height,
  height: layout.width,
  folds: [
    for (final fold in layout.folds)
      CoreFold(
        bounds: CoreViewportRect(
          left: fold.bounds.top,
          top: fold.bounds.left,
          width: fold.bounds.height,
          height: fold.bounds.width,
        ),
        state: fold.state,
      ),
  ],
);

void main() {
  final vectors =
      (jsonDecode(File(_kVectorsPath).readAsStringSync())
              as Map<String, dynamic>)['cases']
          as List<dynamic>;

  test('the table has cases for every kind and posture', () {
    final kinds = {for (final v in vectors) (v as Map)['kind']};
    final postures = {for (final v in vectors) (v as Map)['posture']};
    expect(kinds, containsAll(<Object?>[null, 'flip', 'fold']));
    expect(
      postures,
      containsAll(<Object?>[null, 'flat', 'tabletop', 'book']),
    );
  });

  group('the table', () {
    for (final raw in vectors) {
      final vector = raw as Map<String, dynamic>;
      final name = vector['name'] as String;
      final layout = _layoutOf(vector);

      test(name, () {
        expect(layout.folds, hasLength(vector['crossing'] as int));
        expect(layout.segments, [
          for (final segment in vector['segments'] as List<dynamic>)
            _rect(segment as List<dynamic>),
        ]);
        expect(layout.kind?.name, vector['kind']);
        expect(layout.posture?.name, vector['posture']);
        final start = vector['start'] as Map<String, dynamic>;
        expect(layout.startSegmentIndex(CoreTextDirection.ltr), start['ltr']);
        expect(layout.startSegmentIndex(CoreTextDirection.rtl), start['rtl']);
        expect(layout.isSplit, layout.segments.length > 1);
      });

      test('$name — a panel placed at an alignment of the viewport', () {
        final aligned = vector['aligned'] as Map<String, dynamic>;
        for (final direction in CoreTextDirection.values) {
          final grid = aligned[direction.name] as List<dynamic>;
          for (var row = 0; row < 3; row++) {
            for (var column = 0; column < 3; column++) {
              expect(
                layout.segmentIndexAligned(
                  column - 1.0,
                  row - 1.0,
                  direction,
                ),
                (grid[row] as List<dynamic>)[column],
                reason:
                    '${direction.name}, row $row (top to bottom), '
                    'column $column (left to right)',
              );
            }
          }
        }
      });

      test('$name — a panel aligned to the top of the reading start opens '
          'where one that nothing anchors does', () {
        for (final direction in CoreTextDirection.values) {
          expect(
            layout.segmentIndexAligned(
              direction == CoreTextDirection.rtl ? 1 : -1,
              -1,
              direction,
            ),
            layout.startSegmentIndex(direction),
            reason: direction.name,
          );
        }
      });

      test('$name — keeps its kind when the device is turned', () {
        expect(_turned(layout).kind, layout.kind);
      });
    }
  });

  group('a fold', () {
    CoreFold at(double width, double height, CoreFoldState state) => CoreFold(
      bounds: CoreViewportRect(
        left: 100,
        top: 0,
        width: width,
        height: height,
      ),
      state: state,
    );

    test('a line that lies flat does not separate the viewport', () {
      expect(at(0, 800, CoreFoldState.flat).separates, isFalse);
      expect(at(0, 800, CoreFoldState.unknown).separates, isFalse);
    });

    test('a line that is half opened separates it', () {
      expect(at(0, 800, CoreFoldState.halfOpened).separates, isTrue);
    });

    test('a strip separates it however far it is folded', () {
      for (final state in CoreFoldState.values) {
        expect(at(34, 800, state).separates, isTrue, reason: '$state');
      }
    });

    test('runs the way it is longer', () {
      expect(at(0, 800, CoreFoldState.flat).axis, CoreAxis.vertical);
      expect(at(34, 800, CoreFoldState.flat).axis, CoreAxis.vertical);
      expect(
        const CoreFold(
          bounds: CoreViewportRect(left: 0, top: 300, width: 400, height: 0),
        ).axis,
        CoreAxis.horizontal,
      );
    });
  });

  group('the distance to a segment', () {
    const segment = CoreViewportRect(
      left: 100,
      top: 100,
      width: 200,
      height: 100,
    );

    test('is nothing inside it and on its edge', () {
      expect(segment.distanceTo(150, 150), 0);
      expect(segment.distanceTo(100, 100), 0);
      expect(segment.distanceTo(300, 200), 0);
    });

    test('is the gap along one axis level with an edge', () {
      expect(segment.distanceTo(40, 150), 60);
      expect(segment.distanceTo(150, 230), 30);
    });

    test('is the distance to the corner beyond one', () {
      expect(segment.distanceTo(70, 60), 50);
    });
  });

  group('a viewport nothing has measured', () {
    const layout = CoreFoldLayout.unmeasured;

    test('has no fold, no segment and no answers', () {
      expect(layout.folds, isEmpty);
      expect(layout.segments, isEmpty);
      expect(layout.isSplit, isFalse);
      expect(layout.kind, isNull);
      expect(layout.posture, isNull);
      expect(layout.segmentIndexAt(0, 0), isNull);
      expect(layout.startSegmentIndex(CoreTextDirection.ltr), isNull);
      expect(
        layout.segmentIndexAligned(0, 1, CoreTextDirection.ltr),
        isNull,
      );
    });

    test('is not a measured viewport with no fold', () {
      expect(layout, isNot(CoreFoldLayout(width: 400, height: 800)));
    });
  });

  test('two layouts of the same folds are equal, and of others are not', () {
    final a = _layoutOf(vectors[1] as Map<String, dynamic>);
    final b = _layoutOf(vectors[1] as Map<String, dynamic>);
    final c = _layoutOf(vectors[2] as Map<String, dynamic>);
    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(a, isNot(c));
  });

  test('the first of two equally near segments wins', () {
    // The fold's own line is as near to both halves.
    final layout = _layoutOf(vectors[4] as Map<String, dynamic>);
    expect(layout.segmentIndexAt(345, 400), 0);
  });

  group('a panel placed at an alignment of the viewport', () {
    test('opens in the nearer half when the fold is off centre', () {
      // The middle of the viewport is 400; the fold leaves 300 before it
      // and 440 after, so the middle lies inside the second half.
      final layout = CoreFoldLayout(
        width: 800,
        height: 600,
        folds: const [
          CoreFold(
            bounds: CoreViewportRect(left: 300, top: 0, width: 60, height: 600),
          ),
        ],
      );

      for (final direction in CoreTextDirection.values) {
        expect(layout.segmentIndexAligned(0, 1, direction), 1);
        expect(layout.segmentIndexAligned(-1, 1, direction), 0);
      }
    });

    test('halves that differ by rounding are still equally near', () {
      // A folding phone reports 951 wide with the strip from 455.5 to 495.5:
      // the halves are equal only as far as the platform rounds them.
      final layout = CoreFoldLayout(
        width: 951,
        height: 669,
        folds: const [
          CoreFold(
            bounds: CoreViewportRect(
              left: 455.5000001,
              top: 0,
              width: 40,
              height: 669,
            ),
            state: CoreFoldState.halfOpened,
          ),
        ],
      );

      expect(layout.segmentIndexAligned(0, 1, CoreTextDirection.ltr), 0);
      expect(layout.segmentIndexAligned(0, 1, CoreTextDirection.rtl), 1);
    });

    group('in a box that is not the viewport', () {
      // The same phone: its controls stand in an 84 strip down the right
      // edge, and a layer inside the app's frame stops short of it.
      final layout = CoreFoldLayout(
        width: 951,
        height: 669,
        folds: const [
          CoreFold(
            bounds: CoreViewportRect(
              left: 455.5,
              top: 0,
              width: 40,
              height: 669,
            ),
            state: CoreFoldState.halfOpened,
          ),
        ],
      );
      const frame = CoreViewportRect(left: 0, top: 60, width: 867, height: 609);

      test('the point is the alignment of the box', () {
        for (final direction in CoreTextDirection.values) {
          // The frame's middle is at 433.5, left of the fold: a panel
          // centred in it lies in the left half whichever way the page
          // reads — it is not on the fold, so nothing is tied.
          expect(
            layout.segmentIndexAligned(0, 1, direction, within: frame),
            0,
            reason: direction.name,
          );
          expect(
            layout.segmentIndexAligned(-1, 1, direction, within: frame),
            0,
            reason: direction.name,
          );
          expect(
            layout.segmentIndexAligned(1, 1, direction, within: frame),
            1,
            reason: direction.name,
          );
        }
      });

      test('a box that is the viewport reads as no box', () {
        const whole = CoreViewportRect(
          left: 0,
          top: 0,
          width: 951,
          height: 669,
        );
        for (final direction in CoreTextDirection.values) {
          for (final x in [-1.0, 0.0, 1.0]) {
            for (final y in [-1.0, 0.0, 1.0]) {
              expect(
                layout.segmentIndexAligned(x, y, direction, within: whole),
                layout.segmentIndexAligned(x, y, direction),
                reason: '${direction.name} $x $y',
              );
            }
          }
        }
      });

      test('a box centred on the fold is tied as the viewport is', () {
        // 120 wide about the fold's middle: its own middle is on the fold.
        const astride = CoreViewportRect(
          left: 415.5,
          top: 100,
          width: 120,
          height: 200,
        );

        expect(
          layout.segmentIndexAligned(
            0,
            0,
            CoreTextDirection.ltr,
            within: astride,
          ),
          0,
        );
        expect(
          layout.segmentIndexAligned(
            0,
            0,
            CoreTextDirection.rtl,
            within: astride,
          ),
          1,
        );
      });

      test('a box in one segment opens there from every alignment', () {
        const inRight = CoreViewportRect(
          left: 520,
          top: 40,
          width: 300,
          height: 400,
        );
        for (final direction in CoreTextDirection.values) {
          for (final x in [-1.0, 0.0, 1.0]) {
            for (final y in [-1.0, 0.0, 1.0]) {
              expect(
                layout.segmentIndexAligned(x, y, direction, within: inRight),
                1,
                reason: '${direction.name} $x $y',
              );
            }
          }
        }
      });
    });

    test('four segments: the upper before the lower, then the reading '
        'start', () {
      final layout = CoreFoldLayout(
        width: 800,
        height: 800,
        folds: const [
          CoreFold(
            bounds: CoreViewportRect(left: 400, top: 0, width: 0, height: 800),
            state: CoreFoldState.halfOpened,
          ),
          CoreFold(
            bounds: CoreViewportRect(left: 0, top: 400, width: 800, height: 0),
            state: CoreFoldState.halfOpened,
          ),
        ],
      );

      expect(layout.segments, hasLength(4));
      final ltr = layout.segmentIndexAligned(0, 0, CoreTextDirection.ltr)!;
      final rtl = layout.segmentIndexAligned(0, 0, CoreTextDirection.rtl)!;
      expect(layout.segments[ltr].top, 0);
      expect(layout.segments[ltr].left, 0);
      expect(layout.segments[rtl].top, 0);
      expect(layout.segments[rtl].left, 400);
    });
  });
}
