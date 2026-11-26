// A segmented `Progress` — the cells, their colours and gap, what the bar
// reports to assistive technology, and when it stays continuous. The Web twin
// (`progress_segments_test.dart`) reads the same rules from the emitted DOM.

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

const _kWidth = 300.0;

/// The cell `Container`s of a segmented bar, in order — the children of the
/// bar's `Row`.
List<material.Container> _cells(WidgetTester tester) => tester
    .widgetList<material.Container>(
      find.descendant(
        of: find.descendant(
          of: find.byType(Progress),
          matching: find.byType(material.Row),
        ),
        matching: find.byType(material.Container),
      ),
    )
    .toList();

material.Color _colour(material.Container cell) =>
    (cell.decoration! as material.BoxDecoration).color!;

material.Color _token(ThemeData theme, CoreColorToken token) =>
    theme.colorScheme.resolve(CoreColor.token(token)).toValue();

/// Pumps [progress] at [_kWidth] inside a `CoUIApp` and returns the active
/// theme.
Future<ThemeData> _pump(
  WidgetTester tester,
  Progress progress, {
  CoreDensity? density,
  Locale? locale,
  bool settle = true,
}) async {
  late ThemeData active;
  final home = material.Builder(
    builder: (context) {
      active = Theme.of(context);
      return material.Center(
        child: material.SizedBox(width: _kWidth, child: progress),
      );
    },
  );
  await tester.pumpWidget(
    CoUIApp(
      theme: const ThemeData(),
      density: density ?? CoreDensity.defaultDensity,
      locale: locale,
      supportedLocales: const [Locale('en'), Locale('ko')],
      home: home,
    ),
  );
  // An indeterminate bar animates forever — it never settles.
  if (settle) await tester.pumpAndSettle();
  return active;
}

void main() {
  group('Progress.segments — the cells', () {
    testWidgets('one cell per segment, the steps passed in the fill and the '
        'rest in the track', (tester) async {
      final theme = await _pump(
        tester,
        const Progress(value: 2, max: 3, segments: 3, disableAnimation: true),
      );
      final cells = _cells(tester);

      expect(cells, hasLength(3));
      expect(_colour(cells[0]), _token(theme, CoreColors.primary));
      expect(_colour(cells[1]), _token(theme, CoreColors.primary));
      expect(
        _colour(cells[2]),
        _token(theme, CoreColors.surfaceContainerHigh),
        reason: 'a step still to come takes the neutral track colour',
      );
    });

    testWidgets('a step counts once it is reached — no partial cell', (
      tester,
    ) async {
      final theme = await _pump(
        tester,
        const Progress(value: 0.99, segments: 2, disableAnimation: true),
      );
      final cells = _cells(tester);

      expect(_colour(cells[0]), _token(theme, CoreColors.primary));
      expect(
        _colour(cells[1]),
        _token(theme, CoreColors.surfaceContainerHigh),
        reason: '0.99 of two steps has passed one, not two',
      );
    });

    testWidgets('the tone colours the passed cells', (tester) async {
      final theme = await _pump(
        tester,
        const Progress(
          value: 1,
          max: 2,
          segments: 2,
          tone: CoreProgressTone.success,
          disableAnimation: true,
        ),
      );
      final cells = _cells(tester);

      expect(_colour(cells[0]), _token(theme, CoreColors.success));
      expect(_colour(cells[1]), _token(theme, CoreColors.surfaceContainerHigh));
    });

    testWidgets('cells share the width equally, 6 apart, at the track '
        'height and corner', (tester) async {
      final theme = await _pump(
        tester,
        const Progress(value: 1, max: 2, segments: 2, disableAnimation: true),
      );
      final rects = [
        for (final finder
            in find
                .descendant(
                  of: find.descendant(
                    of: find.byType(Progress),
                    matching: find.byType(material.Row),
                  ),
                  matching: find.byType(material.Container),
                )
                .evaluate())
          tester.getRect(find.byWidget(finder.widget)),
      ];
      final cell = _cells(tester).first;

      expect(
        rects[1].left - rects[0].right,
        CoreProgressStyle.defaultSegmentSpacing,
      );
      expect(
        rects[0].width,
        (_kWidth - CoreProgressStyle.defaultSegmentSpacing) / 2,
      );
      expect(rects[1].width, rects[0].width);
      expect(
        rects[0].height,
        CoreProgressStyle
            .defaultsBySize[CoreProgressSize.defaultSize]!
            .minHeight,
      );
      expect(
        (cell.decoration! as material.BoxDecoration).borderRadius,
        CoreProgressStyle.defaultBorderRadius.toValue(geometry: theme.geometry),
      );
    });

    testWidgets('a stated segmentSpacing sets the gap', (tester) async {
      await _pump(
        tester,
        const Progress(
          value: 1,
          max: 2,
          segments: 2,
          disableAnimation: true,
          progressStyle: CoreProgressStyle(segmentSpacing: CoreSpace.space12),
        ),
      );
      final row = tester.widget<material.Row>(
        find.descendant(
          of: find.byType(Progress),
          matching: find.byType(material.Row),
        ),
      );

      expect(row.spacing, CoreSpace.space12);
    });

    // `space4` sits on the density axis's floor (4 and below do not move —
    // they would press the cells together), so every density keeps the gap.
    for (final density in [
      CoreDensity.compact,
      CoreDensity.standard,
      CoreDensity.spacious,
    ]) {
      testWidgets('${density.name} density keeps the gap at space4', (
        tester,
      ) async {
        await _pump(
          tester,
          const Progress(value: 1, max: 2, segments: 2, disableAnimation: true),
          density: density,
        );
        final row = tester.widget<material.Row>(
          find.descendant(
            of: find.byType(Progress),
            matching: find.byType(material.Row),
          ),
        );

        expect(row.spacing, CoreSpace.space4);
      });
    }

    testWidgets('a cell eases its colour change on the bar duration, like '
        'the continuous fill', (tester) async {
      await _pump(tester, const Progress(value: 1, max: 2, segments: 2));
      final cells = tester
          .widgetList<material.AnimatedContainer>(
            find.descendant(
              of: find.byType(Progress),
              matching: find.byType(material.AnimatedContainer),
            ),
          )
          .toList();

      const move = CoreEasing.move;
      expect(cells, hasLength(2));
      for (final cell in cells) {
        expect(cell.duration, CoreProgressStyle.defaultDuration);
        // `Cubic` has no value equality — compare its control points.
        final curve = cell.curve as material.Cubic;
        expect(
          (curve.a, curve.b, curve.c, curve.d),
          (
            move.x1,
            move.y1,
            move.x2,
            move.y2,
          ),
        );
      }
    });

    testWidgets('disableAnimation draws plain cells', (tester) async {
      await _pump(
        tester,
        const Progress(value: 1, max: 2, segments: 2, disableAnimation: true),
      );

      expect(
        find.descendant(
          of: find.byType(Progress),
          matching: find.byType(material.AnimatedContainer),
        ),
        findsNothing,
      );
    });

    testWidgets('an indeterminate bar has no step to show and stays '
        'continuous', (tester) async {
      await _pump(tester, const Progress(segments: 3), settle: false);
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.descendant(
          of: find.byType(Progress),
          matching: find.byType(material.Row),
        ),
        findsNothing,
      );
    });

    testWidgets('without segments the bar is the continuous track', (
      tester,
    ) async {
      await _pump(
        tester,
        const Progress(value: 0.5, disableAnimation: true),
      );

      expect(
        find.descendant(
          of: find.byType(Progress),
          matching: find.byType(material.Row),
        ),
        findsNothing,
      );
    });

    testWidgets('the cells sit between the label row and the caption', (
      tester,
    ) async {
      await _pump(
        tester,
        const Progress(
          value: 1,
          max: 2,
          segments: 2,
          label: Text('STEP 1 / 2'),
          caption: Text('Account'),
          disableAnimation: true,
        ),
      );
      final row = tester.getRect(
        find.descendant(
          of: find.byType(Progress),
          matching: find.byType(material.Row).last,
        ),
      );

      expect(
        row.top - tester.getRect(find.text('STEP 1 / 2')).bottom,
        CoreProgressStyle.defaultLabelGapStyle.size,
      );
      expect(
        tester.getRect(find.text('Account')).top - row.bottom,
        CoreProgressStyle.defaultCaptionGapStyle.size,
      );
    });
  });

  group('Progress.segments — what the bar reports', () {
    testWidgets('the step reached, of how many', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(
        tester,
        const Progress(value: 1, max: 2, segments: 2, disableAnimation: true),
      );

      expect(tester.getSemantics(find.byType(Progress)).value, 'Step 1 of 2');
      handle.dispose();
    });

    testWidgets('in the active locale', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(
        tester,
        const Progress(value: 1, max: 2, segments: 2, disableAnimation: true),
        locale: const Locale('ko'),
      );

      expect(
        tester.getSemantics(find.byType(Progress)).value,
        '2단계 중 1단계',
      );
      handle.dispose();
    });

    testWidgets('a continuous bar still reports its percentage', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pump(
        tester,
        const Progress(value: 0.5, disableAnimation: true),
      );

      expect(tester.getSemantics(find.byType(Progress)).value, '50%');
      handle.dispose();
    });
  });

  test('copyWith carries segments', () {
    const original = Progress(value: 1, max: 2, segments: 2);

    expect(original.copyWith(value: 2).segments, 2);
    expect(original.copyWith(segments: 4).segments, 4);
  });
}
