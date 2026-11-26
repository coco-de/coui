// The Web transport of the fold rule: what the browser's viewport segments
// and posture read as, what `FoldScope.of` answers, and where a dialog opens
// across a fold. Read against the table the Core rule and Flutter read
// (`coui_core/test/fixtures/fold_vectors.json`).
//
// The browser reports segments, not folds, and it reports more than one only
// while the fold splits the viewport. So each case is fed in as the browser
// would report it — the table's segments — and a case the fold does not split
// reads as no fold: the reach the docs state.
import 'dart:convert';
import 'dart:io';

import 'package:coui_web/coui_web.dart';
import 'package:coui_web/src/base/fold_reading.dart';
import 'package:coui_web/src/base/fold_scope.dart';
import 'package:coui_web/src/components/overlay/dialog/dialog_style.dart';
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

late ResolvedDialog _seen;

class _Capture extends StatelessComponent {
  const _Capture();

  @override
  Component build(BuildContext context) {
    _seen = resolveDialog(context);
    return const Component.text('x');
  }
}

Future<Map<String, String>> _panelStyles(
  ComponentTester tester,
  CoreFoldLayout layout,
  CoreTextDirection direction,
) async {
  pumpWithTheme(
    tester,
    FoldLayoutScope(
      layout: layout,
      direction: direction,
      child: const _Capture(),
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

  group('the browser segments read as', () {
    for (final vector in vectors) {
      test(vector['name'] as String, () {
        final segments = _segmentsOf(vector);
        final layout = foldLayoutFromSegments(
          segments,
          state: _stateOf(vector),
        );

        expect(layout.segments, segments);
        if (segments.length > 1) {
          expect(layout.kind?.name, vector['kind']);
          expect(layout.posture?.name, vector['posture']);
          expect(
            layout.startSegmentIndex(CoreTextDirection.ltr),
            (vector['start'] as Map<String, dynamic>)['ltr'],
          );
          expect(
            layout.startSegmentIndex(CoreTextDirection.rtl),
            (vector['start'] as Map<String, dynamic>)['rtl'],
          );
        } else {
          // One segment: the browser reported no fold.
          expect(layout.folds, isEmpty);
          expect(layout.kind, isNull);
          expect(layout.posture, isNull);
        }
      });
    }

    test('a seamless split the posture calls flat is one surface', () {
      // A browser that splits a seamless screen while the posture query says
      // continuous (an emulator does) is read by the rule, as Flutter reads
      // the same fold: it does not separate.
      final layout = foldLayoutFromSegments(
        _segmentsOf(
          vectors.firstWhere((v) => v['name'] == 'a fold, half open as a book'),
        ),
        state: CoreFoldState.flat,
      );

      expect(layout.isSplit, isFalse);
      expect(layout.kind, CoreFoldableKind.fold);
      expect(layout.posture, CoreFoldPosture.flat);
    });

    test('no segments is a viewport nothing measured', () {
      expect(
        foldLayoutFromSegments(const [], state: CoreFoldState.unknown),
        CoreFoldLayout.unmeasured,
      );
    });
  });

  test('the posture queries read as a fold state', () {
    expect(
      foldStateFromPosture(folded: true, continuous: false),
      CoreFoldState.halfOpened,
    );
    expect(
      foldStateFromPosture(folded: false, continuous: true),
      CoreFoldState.flat,
    );
    expect(
      foldStateFromPosture(folded: false, continuous: false),
      CoreFoldState.unknown,
    );
  });

  group('FoldScope.of', () {
    testComponents('reads an unmeasured viewport with no scope above', (
      tester,
    ) async {
      late CoreFoldLayout seen;
      tester.pumpComponent(
        Builder(
          builder: (context) {
            seen = FoldScope.of(context);
            return const Component.text('x');
          },
        ),
      );
      await tester.pump();

      expect(seen, CoreFoldLayout.unmeasured);
    });

    testComponents('reads the layout the root publishes', (tester) async {
      final layout = foldLayoutFromSegments(
        _segmentsOf(vectors[1]),
        state: CoreFoldState.halfOpened,
      );
      late CoreFoldLayout seen;
      tester.pumpComponent(
        FoldLayoutScope(
          layout: layout,
          child: Builder(
            builder: (context) {
              seen = FoldScope.of(context);
              return const Component.text('x');
            },
          ),
        ),
      );
      await tester.pump();

      expect(seen, layout);
      expect(seen.posture, CoreFoldPosture.tabletop);
      expect(seen.kind, CoreFoldableKind.flip);
    });
  });

  // The root mounts the scope a dialog reads, with the direction it writes on
  // `<html dir>`: that direction picks the segment a dialog opens in. The VM
  // has no viewport segments, so the layout below the root is unmeasured.
  group('CoUIWeb publishes the folds', () {
    for (final (locale, direction) in [
      (const Locale('ko', 'KR'), CoreTextDirection.ltr),
      (const Locale('ar', 'EG'), CoreTextDirection.rtl),
    ]) {
      testComponents('with its direction, ${direction.name}', (tester) async {
        FoldLayoutScope? seen;
        tester.pumpComponent(
          CoUIWeb(
            theme: .coui,
            locale: locale,
            child: Builder(
              builder: (context) {
                seen = context
                    .dependOnInheritedComponentOfExactType<FoldLayoutScope>();
                return const Component.text('x');
              },
            ),
          ),
        );
        await tester.pump();

        expect(seen, isNotNull, reason: 'CoUIWeb mounts the fold scope');
        expect(seen!.direction, direction);
        expect(seen!.layout, CoreFoldLayout.unmeasured);
      });
    }
  });

  group('a dialog opens in the segment the rule names', () {
    for (final vector in vectors) {
      final segments = _segmentsOf(vector);
      for (final direction in CoreTextDirection.values) {
        testComponents('${vector['name']}, $direction', (tester) async {
          final styles = await _panelStyles(
            tester,
            foldLayoutFromSegments(segments, state: _stateOf(vector)),
            direction,
          );

          if (segments.length < 2) {
            expect(styles.containsKey('left'), isFalse);
            expect(styles.containsKey('top'), isFalse);
            expect(styles['width'], isNot(contains('env(')));

            return;
          }
          final start =
              (vector['start'] as Map<String, dynamic>)[direction.name] as int;
          // Side by side the browser counts columns, stacked it counts rows.
          final sideBySide = segments[1].left > segments[0].left;
          final at = sideBySide ? '$start 0' : '0 $start';
          expect(
            styles['left'],
            'calc(env(viewport-segment-left $at) + '
            'env(viewport-segment-width $at) / 2)',
          );
          expect(
            styles['top'],
            'calc(env(viewport-segment-top $at) + '
            'env(viewport-segment-height $at) / 2)',
          );
          expect(
            styles['width'],
            startsWith('calc(env(viewport-segment-width $at) - 2 * '),
          );
          expect(
            styles['max-height'],
            startsWith('calc(env(viewport-segment-height $at) - 2 * '),
          );
        });
      }
    }

    testComponents('with no scope above, centres on the viewport', (
      tester,
    ) async {
      pumpWithTheme(tester, const _Capture());
      await tester.pump();

      final styles = _seen.panel.inlineStyles!.properties;
      expect(styles.containsKey('left'), isFalse);
      expect(styles['width'], isNot(contains('env(')));
    });
  });
}
