// A segmented `Progress` — the row of cells the Web resolver emits and the
// widget renders, and what the bar reports to assistive technology. The
// Flutter twin (`progress_segments_test.dart`) measures the same rules as
// laid out.

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/components/display/progress/progress.dart';
import 'package:coui_web/src/components/display/progress/progress_style.dart';
import 'package:coui_web/src/components/locale/coui_localizations/coui_localizations_scope.dart';
import 'package:coui_web/src/components/locale/coui_localizations/ko_coui_localizations.dart';
import 'package:coui_web/src/components/text/text.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:jaspr/dom.dart' show Styles;
import 'package:jaspr/jaspr.dart' hide Text;
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

late ResolvedProgress _seen;

class _Capture extends StatelessComponent {
  const _Capture({
    this.segmented = false,
    this.labelled = false,
    this.animated = true,
    this.tone = CoreProgressTone.defaultTone,
    this.progressStyle,
  });

  final bool segmented;
  final bool labelled;
  final bool animated;
  final CoreProgressTone tone;
  final CoreProgressStyle? progressStyle;

  @override
  Component build(BuildContext context) {
    _seen = resolveProgress(
      context: context,
      size: CoreProgressSize.defaultSize,
      tone: tone,
      isIndeterminate: false,
      widthPercent: 50,
      animated: animated,
      labelled: labelled,
      segmented: segmented,
      progressStyle: progressStyle,
    );
    return const Component.text('x');
  }
}

Future<ResolvedProgress> _resolve(
  ComponentTester tester, {
  bool segmented = true,
  bool labelled = false,
  bool animated = true,
  CoreProgressTone tone = CoreProgressTone.defaultTone,
  CoreProgressStyle? progressStyle,
}) async {
  pumpWithTheme(
    tester,
    _Capture(
      segmented: segmented,
      labelled: labelled,
      animated: animated,
      tone: tone,
      progressStyle: progressStyle,
    ),
  );
  await tester.pump();
  return _seen;
}

Set<String> _classesOf(String? className) =>
    (className ?? '').split(' ').where((c) => c.isNotEmpty).toSet();

Map<String, String> _inlineOf(Styles? styles) => styles?.properties ?? const {};

String _bg(CoreColor token) => 'bg-${token.tailwindColor}';

Iterable<DomComponent> _doms(ComponentTester tester) => find
    .byType(DomComponent)
    .evaluate()
    .map((e) => e.component as DomComponent);

DomComponent _bar(ComponentTester tester) =>
    _doms(tester).singleWhere((c) => c.attributes?['role'] == 'progressbar');

/// The cells of the bar, in order — every `flex-1 h-full` `<div>`.
List<DomComponent> _cells(ComponentTester tester) => _doms(tester)
    .where(
      (c) =>
          _classesOf(c.classes).contains('flex-1') &&
          _classesOf(c.classes).contains('h-full'),
    )
    .toList();

void main() {
  const fill = CoreColor.token(CoreColors.primary);
  const track = CoreProgressStyle.defaultBackgroundColor;
  final moveEasing = CoreEasing.move.toVarCss();

  group('Progress.segments — resolver', () {
    testComponents('the row of cells — full width, the track height, the '
        'cell gap', (tester) async {
      final row = (await _resolve(tester)).segmentRow;
      final sizeRow =
          CoreProgressStyle.defaultsBySize[CoreProgressSize.defaultSize]!;
      final height = '${sizeRow.minHeight! / 16}rem';

      expect(_classesOf(row.className), containsAll(['flex', 'w-full']));
      expect(_inlineOf(row.inlineStyles)['height'], height);
      expect(
        _inlineOf(row.inlineStyles)['column-gap'],
        spaceCss(CoreProgressStyle.defaultSegmentSpacing),
      );
    });

    testComponents('a stated segmentSpacing sets the gap', (tester) async {
      final row = (await _resolve(
        tester,
        progressStyle: const CoreProgressStyle(
          segmentSpacing: CoreSpace.space12,
        ),
      )).segmentRow;

      expect(
        _inlineOf(row.inlineStyles)['column-gap'],
        spaceCss(CoreSpace.space12),
      );
    });

    testComponents('a passed cell takes the fill, a coming one the track — '
        'each an equal share at the track corner', (tester) async {
      final resolved = await _resolve(tester);
      final radius = CoreProgressStyle.defaultBorderRadius.toValue();

      for (final (cell, colour) in [
        (resolved.filledSegment, fill),
        (resolved.emptySegment, track),
      ]) {
        expect(
          _classesOf(cell.className),
          containsAll(['flex-1', 'min-w-0', 'h-full', _bg(colour)]),
        );
        expect(_inlineOf(cell.inlineStyles)['border-radius'], radius);
      }
      expect(
        _classesOf(resolved.emptySegment.className),
        isNot(contains(_bg(fill))),
      );
    });

    testComponents('the tone colours the passed cell', (tester) async {
      final resolved = await _resolve(
        tester,
        tone: CoreProgressTone.success,
      );

      expect(
        _classesOf(resolved.filledSegment.className),
        contains(_bg(const CoreColor.token(CoreColors.success))),
      );
      expect(
        _classesOf(resolved.emptySegment.className),
        contains(_bg(track)),
      );
    });

    testComponents('a raw fill goes inline on the passed cell', (
      tester,
    ) async {
      const raw = CoreColor(0xFFFF0000);
      final cell = (await _resolve(
        tester,
        progressStyle: const CoreProgressStyle(color: raw),
      )).filledSegment;

      expect(
        _classesOf(cell.className).where((c) => c.startsWith('bg-')),
        isEmpty,
      );
      expect(_inlineOf(cell.inlineStyles)['background-color'], isNotNull);
    });

    testComponents('a cell eases its colour change on the bar duration and '
        'the move curve', (tester) async {
      final cell = (await _resolve(tester)).filledSegment;
      final ms = CoreProgressStyle.defaultDuration.inMilliseconds;

      expect(
        _inlineOf(cell.inlineStyles)['transition'],
        'background-color ${durationMsCss(ms)} $moveEasing',
      );
    });

    testComponents('disabled animation draws no transition', (tester) async {
      final cell = (await _resolve(tester, animated: false)).filledSegment;

      expect(_inlineOf(cell.inlineStyles)['transition'], 'none');
    });

    testComponents('the continuous fill eases on the same move curve as the '
        'Flutter twin', (tester) async {
      final indicator = (await _resolve(tester, segmented: false)).indicator;
      final ms = CoreProgressStyle.defaultDuration.inMilliseconds;

      expect(
        _inlineOf(indicator.inlineStyles)['transition'],
        'width ${durationMsCss(ms)} $moveEasing',
      );
    });

    testComponents('without a label cell the row of cells is the root', (
      tester,
    ) async {
      final resolved = await _resolve(tester);

      expect(resolved.root.className, resolved.segmentRow.className);
      expect(
        _inlineOf(resolved.root.inlineStyles),
        _inlineOf(resolved.segmentRow.inlineStyles),
      );
    });

    testComponents('with a label cell the root stays the column', (
      tester,
    ) async {
      final resolved = await _resolve(tester, labelled: true);

      expect(
        _classesOf(resolved.root.className),
        containsAll(['flex', 'flex-col', 'w-full']),
      );
      expect(resolved.root.inlineStyles, isNull);
    });

    testComponents('a continuous bar keeps the track as its root', (
      tester,
    ) async {
      final resolved = await _resolve(tester, segmented: false);

      expect(resolved.root.className, resolved.track.className);
    });
  });

  group('Progress.segments — rendered', () {
    testComponents('one cell per segment, the steps passed in the fill', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const Progress(value: 2, max: 3, segments: 3),
      );
      final cells = _cells(tester);

      expect(cells, hasLength(3));
      expect(_classesOf(cells[0].classes), contains(_bg(fill)));
      expect(_classesOf(cells[1].classes), contains(_bg(fill)));
      expect(_classesOf(cells[2].classes), contains(_bg(track)));
      // The bar is the row itself — no track or fill element around them.
      expect(
        _doms(tester).where((c) => c.tag == 'div').length,
        4,
        reason: 'the bar grew elements it does not need',
      );
    });

    testComponents('a step counts once it is reached — no partial cell', (
      tester,
    ) async {
      pumpWithTheme(tester, const Progress(value: 0.99, segments: 2));
      final cells = _cells(tester);

      expect(_classesOf(cells[0].classes), contains(_bg(fill)));
      expect(_classesOf(cells[1].classes), contains(_bg(track)));
    });

    testComponents('reads its step, of how many', (tester) async {
      pumpWithTheme(tester, const Progress(value: 1, max: 2, segments: 2));
      final bar = _bar(tester);

      expect(bar.attributes?['aria-valuetext'], 'Step 1 of 2');
      expect(bar.attributes?['aria-valuenow'], '1.0');
      expect(bar.attributes?['aria-valuemax'], '2.0');
    });

    testComponents('in the active locale', (tester) async {
      pumpWithTheme(
        tester,
        const CouiLocalizationsScope(
          localizations: KoCouiLocalizations.instance,
          child: Progress(value: 1, max: 2, segments: 2),
        ),
      );

      expect(_bar(tester).attributes?['aria-valuetext'], '2단계 중 1단계');
    });

    testComponents('a continuous bar states no value text', (tester) async {
      pumpWithTheme(tester, const Progress(value: 0.5));

      expect(_bar(tester).attributes, isNot(contains('aria-valuetext')));
      expect(_cells(tester), isEmpty);
    });

    testComponents('an indeterminate bar has no step to show and stays '
        'continuous', (tester) async {
      pumpWithTheme(tester, const Progress(segments: 3));

      expect(_cells(tester), isEmpty);
      expect(_bar(tester).attributes, isNot(contains('aria-valuetext')));
      expect(
        _doms(tester).where((c) => c.tag == 'style'),
        hasLength(1),
        reason: 'the indeterminate slide rule is still emitted',
      );
    });

    testComponents('the cells sit between the label row and the caption', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const Progress(
          value: 1,
          max: 2,
          segments: 2,
          label: Text('STEP 1 / 2'),
          caption: Text('Account'),
        ),
      );
      final doms = _doms(tester).toList();
      final bar = _bar(tester);
      final row = doms.singleWhere(
        (c) => c != bar && _inlineOf(c.styles).containsKey('column-gap'),
      );
      final cells = _cells(tester);

      expect(_classesOf(bar.classes), containsAll(['flex', 'flex-col']));
      expect(cells, hasLength(2));
      // Depth-first: the row comes before its cells and after the label row.
      expect(doms.indexOf(row), lessThan(doms.indexOf(cells.first)));
      expect(
        doms.indexWhere((c) => c.id == '${bar.id}-label'),
        lessThan(doms.indexOf(row)),
      );
      expect(
        doms.indexWhere((c) => c.id == '${bar.id}-caption'),
        greaterThan(doms.indexOf(cells.last)),
      );
    });
  });

  test('copyWith carries segments', () {
    const original = Progress(value: 1, max: 2, segments: 2);

    expect(original.copyWith(value: 2).segments, 2);
    expect(original.copyWith(segments: 4).segments, 4);
  });
}
