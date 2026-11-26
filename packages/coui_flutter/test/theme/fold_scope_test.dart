// The Flutter transport of the fold rule: what `FoldScope.of` reads from the
// display features the platform reports, and where a dialog opens across a
// fold. Both are read against the table the Core rule and the Web read
// (`coui_core/test/fixtures/fold_vectors.json`), so the platforms cannot give
// the same fold different answers.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/widgets.dart' as w;
import 'package:flutter_test/flutter_test.dart';

const String _kVectorsPath = '../coui_core/test/fixtures/fold_vectors.json';

const w.Key _content = w.ValueKey('content');

Rect _rect(List<dynamic> value) => Rect.fromLTWH(
  (value[0] as num).toDouble(),
  (value[1] as num).toDouble(),
  (value[2] as num).toDouble(),
  (value[3] as num).toDouble(),
);

/// Puts [vector]'s viewport and folds on the test view, the way Android
/// reports them: a line is a fold, a strip is a hinge.
void _showFolds(WidgetTester tester, Map<String, dynamic> vector) {
  final viewport = vector['viewport'] as List<dynamic>;
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = Size(
      (viewport[0] as num).toDouble(),
      (viewport[1] as num).toDouble(),
    )
    ..displayFeatures = [
      for (final raw in vector['folds'] as List<dynamic>)
        _feature(raw as Map<String, dynamic>),
    ];
  addTearDown(tester.view.reset);
}

ui.DisplayFeature _feature(Map<String, dynamic> fold) {
  final bounds = _rect(fold['bounds'] as List<dynamic>);

  return ui.DisplayFeature(
    bounds: bounds,
    type: bounds.shortestSide > 0
        ? ui.DisplayFeatureType.hinge
        : ui.DisplayFeatureType.fold,
    state: switch (fold['state'] as String) {
      'flat' => ui.DisplayFeatureState.postureFlat,
      'halfOpened' => ui.DisplayFeatureState.postureHalfOpened,
      _ => ui.DisplayFeatureState.unknown,
    },
  );
}

void main() {
  final vectors = [
    for (final raw
        in (jsonDecode(File(_kVectorsPath).readAsStringSync())
                as Map<String, dynamic>)['cases']
            as List<dynamic>)
      raw as Map<String, dynamic>,
  ];

  group('FoldScope reads the display features', () {
    for (final vector in vectors) {
      testWidgets(vector['name'] as String, (tester) async {
        _showFolds(tester, vector);
        late CoreFoldLayout layout;
        await tester.pumpWidget(
          w.Builder(
            builder: (context) {
              layout = FoldScope.of(context);

              return const w.SizedBox.shrink();
            },
          ),
        );

        expect(layout.folds, hasLength(vector['crossing'] as int));
        expect(
          [
            for (final segment in layout.segments)
              Rect.fromLTWH(
                segment.left,
                segment.top,
                segment.width,
                segment.height,
              ),
          ],
          [
            for (final segment in vector['segments'] as List<dynamic>)
              _rect(segment as List<dynamic>),
          ],
        );
        expect(layout.kind?.name, vector['kind']);
        expect(layout.posture?.name, vector['posture']);
      });
    }

    for (final state in ui.DisplayFeatureState.values.where(
      (state) =>
          state != ui.DisplayFeatureState.postureFlat &&
          state != ui.DisplayFeatureState.postureHalfOpened,
    )) {
      for (final hingeWidth in [0.0, 34.0]) {
        testWidgets(
          '${state.name} keeps fold geometry without inventing a posture '
          '(hinge width $hingeWidth)',
          (tester) async {
            tester.view
              ..devicePixelRatio = 1
              ..physicalSize = const Size(1114, 720)
              ..displayFeatures = [
                ui.DisplayFeature(
                  bounds: Rect.fromLTWH(540, 0, hingeWidth, 720),
                  type: hingeWidth == 0
                      ? ui.DisplayFeatureType.fold
                      : ui.DisplayFeatureType.hinge,
                  state: state,
                ),
              ];
            addTearDown(tester.view.reset);
            late CoreFoldLayout layout;
            await tester.pumpWidget(
              w.Builder(
                builder: (context) {
                  layout = FoldScope.of(context);

                  return const w.SizedBox.shrink();
                },
              ),
            );

            expect(layout.width, 1114);
            expect(layout.height, 720);
            expect(layout.folds.single.state, CoreFoldState.unknown);
            expect(
              layout.folds.single.bounds,
              CoreViewportRect(
                left: 540,
                top: 0,
                width: hingeWidth,
                height: 720,
              ),
            );
            expect(layout.kind, CoreFoldableKind.fold);
            expect(layout.posture, isNull);
            expect(
              layout.segments,
              hingeWidth == 0
                  ? const [
                      CoreViewportRect(
                        left: 0,
                        top: 0,
                        width: 1114,
                        height: 720,
                      ),
                    ]
                  : const [
                      CoreViewportRect(
                        left: 0,
                        top: 0,
                        width: 540,
                        height: 720,
                      ),
                      CoreViewportRect(
                        left: 574,
                        top: 0,
                        width: 540,
                        height: 720,
                      ),
                    ],
            );
          },
        );
      }
    }

    testWidgets('a cutout is not a fold', (tester) async {
      tester.view
        ..devicePixelRatio = 1
        ..physicalSize = const Size(400, 800)
        ..displayFeatures = const [
          ui.DisplayFeature(
            bounds: Rect.fromLTWH(0, 0, 400, 30),
            type: ui.DisplayFeatureType.cutout,
            state: ui.DisplayFeatureState.unknown,
          ),
        ];
      addTearDown(tester.view.reset);
      late CoreFoldLayout layout;
      await tester.pumpWidget(
        w.Builder(
          builder: (context) {
            layout = FoldScope.of(context);

            return const w.SizedBox.shrink();
          },
        ),
      );

      expect(layout.folds, isEmpty);
      expect(layout.kind, isNull);
    });

    testWidgets('is rebuilt when the device folds', (tester) async {
      final vector = vectors.firstWhere(
        (vector) => vector['name'] == 'a fold, open flat',
      );
      _showFolds(tester, vector);
      final seen = <CoreFoldPosture?>[];
      await tester.pumpWidget(
        w.Builder(
          builder: (context) {
            seen.add(FoldScope.of(context).posture);

            return const w.SizedBox.shrink();
          },
        ),
      );
      _showFolds(
        tester,
        vectors.firstWhere(
          (vector) => vector['name'] == 'a fold, half open as a book',
        ),
      );
      await tester.pump();

      expect(seen, [CoreFoldPosture.flat, CoreFoldPosture.book]);
    });
  });

  group('a dialog opens in the segment the rule names', () {
    // Flutter's dialog route keeps its page to one segment by its own rule
    // (`DisplayFeatureSubScreen`). The Core rule is written to be that rule;
    // these hold the two together, one fold at a time. With two folds that
    // run the same way they part (see `CoreFoldLayout`'s split).
    for (final vector in vectors.where(
      (vector) => (vector['crossing'] as int) <= 1,
    )) {
      for (final direction in w.TextDirection.values) {
        testWidgets('${vector['name']}, $direction', (tester) async {
          _showFolds(tester, vector);
          late w.BuildContext app;
          await tester.pumpWidget(
            CoUIApp(
              locale: direction == w.TextDirection.rtl
                  ? const Locale('ar')
                  : const Locale('en', 'US'),
              supportedLocales: const [Locale('ar'), Locale('en', 'US')],
              theme: ThemeData.fromCore(CoreThemePresets.light),
              home: w.Builder(
                builder: (context) {
                  app = context;

                  return const w.SizedBox.shrink();
                },
              ),
            ),
          );
          unawaited(
            showDialog<void>(
              context: app,
              builder: (_) => const Dialog(
                content: w.SizedBox(key: _content, width: 120, height: 60),
              ),
            ),
          );
          await tester.pumpAndSettle();

          final start =
              (vector['start'] as Map<String, dynamic>)[direction ==
                      w.TextDirection.rtl
                  ? 'rtl'
                  : 'ltr'];
          final segment = _rect(
            (vector['segments'] as List<dynamic>)[start as int]
                as List<dynamic>,
          );
          final content = tester.getRect(find.byKey(_content));
          expect(
            segment.contains(content.topLeft) &&
                segment.contains(content.bottomRight - const Offset(1, 1)),
            isTrue,
            reason:
                'the dialog ($content) lies inside segment $start '
                '($segment)',
          );
        });
      }
    }
  });
}
