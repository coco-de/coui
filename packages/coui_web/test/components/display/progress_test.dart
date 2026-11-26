// Progress colour chain — what each getter paints, read off the DOM.
//
// A palette getter names the FILL: the track is left unset so it stays the
// neutral track, and `.success` reads as a success bar rather than a primary
// bar on a solid success track. `.transparent` clears the track and keeps
// the fill — a transparent fill would leave nothing on screen. A raw fill
// keeps the neutral track too; a stated `backgroundAlpha` fades a track of
// the fill's own hue, the way the Flutter twin scales any colour. The
// Flutter twin holds the same contract in its own test.

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/components/display/progress/progress.dart';
import 'package:coui_web/src/components/layout/gap/gap.dart';
import 'package:coui_web/src/components/text/text.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/theme/theme_data.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:jaspr/dom.dart' show RawText;
import 'package:jaspr/jaspr.dart' hide Text;
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

const _kRaw = CoreColor(0xFFFF0000);
const _kTrackAlpha = 0.2;
const _kMarker = 'co-progress-indeterminate';

Iterable<DomComponent> _doms(ComponentTester tester) => find
    .byType(DomComponent)
    .evaluate()
    .map((e) => e.component as DomComponent);

DomComponent _track(ComponentTester tester) =>
    _doms(tester).singleWhere((c) => c.attributes?['role'] == 'progressbar');

/// The indicator — the one `<div>` the track holds (the DOM walk is
/// depth-first, so it is the first `<div>` after the track).
DomComponent _fill(ComponentTester tester) {
  final doms = _doms(tester).toList();
  return doms
      .skip(doms.indexOf(_track(tester)) + 1)
      .firstWhere((c) => c.tag == 'div');
}

List<String> _classes(DomComponent c) => (c.classes ?? '').split(' ');

/// The indicator wherever the bar puts its track — the one `block h-full`
/// `<div>` (with label cells the first `<div>` under the root is the label
/// row, not the track).
DomComponent _indicator(ComponentTester tester) => _doms(tester).singleWhere(
  (c) => _classes(c).contains('block') && _classes(c).contains('h-full'),
);

Map<String, String> _inline(DomComponent c) => c.styles?.properties ?? const {};

String _bg(CoreColor token) => 'bg-${token.tailwindColor}';

void main() {
  final palette = <String, (Progress Function(Progress), CoreColor)>{
    'primary': ((p) => p.primary, const .token(CoreColors.primary)),
    'secondary': ((p) => p.secondary, const .token(CoreColors.secondary)),
    'tertiary': ((p) => p.tertiary, const .token(CoreColors.tertiary)),
    'surface': ((p) => p.surface, const .token(CoreColors.surface)),
    'surfaceContainer': (
      (p) => p.surfaceContainer,
      const .token(CoreColors.surfaceContainer),
    ),
    'error': ((p) => p.error, const .token(CoreColors.error)),
    'success': ((p) => p.success, const .token(CoreColors.success)),
    'warning': ((p) => p.warning, const .token(CoreColors.warning)),
    'info': ((p) => p.info, const .token(CoreColors.info)),
    'outline': ((p) => p.outline, const .token(CoreColors.outline)),
  };

  group('Progress colour chain — what each getter paints', () {
    for (final MapEntry(key: name, value: (getter, token)) in palette.entries) {
      test('.$name patches the fill, leaves the track unset', () {
        final style = getter(const Progress(value: 0.5)).progressStyle!;

        expect(style.color, token);
        expect(style.backgroundColor, isNull);
      });
    }

    test('.transparent patches the track, leaves the fill unset', () {
      final style = const Progress(value: 0.5).transparent.progressStyle!;

      expect(style.backgroundColor, CoreColor.transparent);
      expect(style.color, isNull);
    });

    testComponents('.success paints a success fill on the neutral track', (
      tester,
    ) async {
      pumpWithTheme(tester, const Progress(value: 0.5).success);
      const success = CoreColor.token(CoreColors.success);

      expect(_classes(_fill(tester)), contains(_bg(success)));
      final track = _classes(_track(tester));
      expect(
        track,
        isNot(contains(_bg(success))),
        reason: 'the track is painted solid success',
      );
      expect(
        track,
        contains(_bg(CoreProgressStyle.defaultBackgroundColor)),
        reason: 'the track took the fill hue instead of staying neutral',
      );
    });

    testComponents('.transparent keeps the default fill on a clear track', (
      tester,
    ) async {
      pumpWithTheme(tester, const Progress(value: 0.5).transparent);

      expect(
        _classes(_fill(tester)),
        contains(_bg(CoreProgressStyle.defaultColor)),
        reason: 'the bar lost its fill — nothing left to see',
      );
      final track = _track(tester);
      expect(
        _classes(track).where((c) => c.startsWith('bg-')),
        isEmpty,
        reason: 'the track still carries a colour class',
      );
      expect(
        _inline(track)['background-color'],
        CoreColor.transparent.toValue(),
      );
    });

    testComponents('a raw fill keeps the neutral track', (tester) async {
      pumpWithTheme(
        tester,
        const Progress(
          value: 0.5,
        ).withStyle(const CoreProgressStyle(color: _kRaw)),
      );

      expect(_inline(_fill(tester))['background-color'], _kRaw.toValue());
      final track = _track(tester);
      expect(
        _classes(track),
        contains(_bg(CoreProgressStyle.defaultBackgroundColor)),
      );
      expect(_inline(track)['background-color'], isNull);
    });

    testComponents('a stated backgroundAlpha fades a track of the fill hue', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const Progress(value: 0.5).withStyle(
          const CoreProgressStyle(color: _kRaw, backgroundAlpha: _kTrackAlpha),
        ),
      );

      final track = _track(tester);
      expect(
        _classes(track).where((c) => c.startsWith('bg-')),
        isEmpty,
        reason: 'the track fell back to a token',
      );
      expect(
        _inline(track)['background-color'],
        _kRaw.scaleAlpha(_kTrackAlpha).toValue(),
      );
    });

    testComponents('a raw radial arc keeps the neutral track ring', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const RadialProgress(
          value: 50,
          radialProgressStyle: CoreRadialProgressStyle(color: _kRaw),
        ),
      );
      final circles = _doms(tester).where((c) => c.tag == 'circle').toList();
      final (track, arc) = (circles.first, circles.last);

      expect(arc.attributes?['stroke'], _kRaw.toValue());
      const neutral = CoreRadialProgressStyle.defaultBackgroundColor;
      expect(
        track.attributes?['class'],
        contains('stroke-${neutral.tailwindColor}'),
      );
      expect(track.attributes?['stroke'], isNull);
    });

    testComponents('a stated backgroundAlpha fades a ring of the arc hue', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const RadialProgress(
          value: 50,
          radialProgressStyle: CoreRadialProgressStyle(
            color: _kRaw,
            backgroundAlpha: _kTrackAlpha,
          ),
        ),
      );
      final circles = _doms(tester).where((c) => c.tag == 'circle').toList();

      expect(
        circles.first.attributes?['stroke'],
        _kRaw.scaleAlpha(_kTrackAlpha).toValue(),
      );
    });
  });

  group('Progress tone — what the fill means', () {
    test('defaults to primary', () {
      expect(const Progress().tone, CoreProgressTone.primary);
    });

    final fills = <CoreProgressTone, CoreColor>{
      CoreProgressTone.primary: const .token(CoreColors.primary),
      CoreProgressTone.success: const .token(CoreColors.success),
      CoreProgressTone.warning: const .token(CoreColors.warning),
      CoreProgressTone.destructive: const .token(CoreColors.error),
    };
    for (final MapEntry(key: tone, value: fill) in fills.entries) {
      testComponents('${tone.name} paints ${_bg(fill)} on the neutral track', (
        tester,
      ) async {
        pumpWithTheme(tester, Progress(value: 0.5, tone: tone));

        expect(_classes(_fill(tester)), contains(_bg(fill)));
        expect(
          _classes(_track(tester)),
          contains(_bg(CoreProgressStyle.defaultBackgroundColor)),
          reason: 'the track followed the tone',
        );
      });
    }

    testComponents('the indeterminate bar slides in the tone fill', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const Progress(tone: CoreProgressTone.destructive),
      );

      expect(
        _classes(_fill(tester)),
        containsAll([_bg(fills[CoreProgressTone.destructive]!), _kMarker]),
      );
    });

    testComponents('a stated colour wins over the tone', (tester) async {
      pumpWithTheme(
        tester,
        const Progress(
          value: 0.5,
          tone: CoreProgressTone.warning,
          progressStyle: CoreProgressStyle(color: _kRaw),
        ),
      );

      final fill = _fill(tester);
      expect(_inline(fill)['background-color'], _kRaw.toValue());
      expect(_classes(fill).where((c) => c.startsWith('bg-')), isEmpty);
    });

    testComponents('a backgroundAlpha track fades the tone fill', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const Progress(
          value: 0.5,
          tone: CoreProgressTone.success,
          progressStyle: CoreProgressStyle(backgroundAlpha: _kTrackAlpha),
        ),
      );

      expect(
        _classes(_track(tester)),
        contains(
          _bg(fills[CoreProgressTone.success]!.scaleAlpha(_kTrackAlpha)),
        ),
      );
    });

    group('theme chain', () {
      const projectFill = CoreColor.token(CoreColors.secondary);
      const toneFill = CoreColor.token(CoreColors.tertiary);
      const theme = ThemeData(
        coreComponentTheme: CoreComponentTheme(
          progress: CoreProgressTheme(
            style: CoreProgressStyle(color: projectFill),
            toneStyles: {
              CoreProgressTone.warning: CoreProgressStyle(color: toneFill),
            },
          ),
        ),
      );

      List<String> fillUnder(
        ComponentTester tester,
        CoreProgressTone tone, {
        CoreProgressStyle? progressStyle,
      }) {
        tester.pumpComponent(
          Theme(
            data: theme,
            child: Progress(
              value: 0.5,
              tone: tone,
              progressStyle: progressStyle,
            ),
          ),
        );
        return _classes(_fill(tester));
      }

      testComponents('project style → toneStyles[tone] → progressStyle', (
        tester,
      ) async {
        expect(
          fillUnder(tester, CoreProgressTone.success),
          contains(_bg(projectFill)),
          reason: 'only the project style reaches success',
        );
        expect(
          fillUnder(tester, CoreProgressTone.warning),
          contains(_bg(toneFill)),
          reason: "the warning row wins over the project's style",
        );
        expect(
          fillUnder(
            tester,
            CoreProgressTone.warning,
            progressStyle: const CoreProgressStyle(
              color: CoreColor.token(CoreColors.info),
            ),
          ),
          contains(_bg(const CoreColor.token(CoreColors.info))),
          reason: 'the instance wins over the tone row',
        );
      });
    });
  });

  group('Progress label cells', () {
    DomComponent byId(ComponentTester tester, String id) =>
        _doms(tester).singleWhere((c) => c.id == id);

    testComponents('without a cell the bar is the whole element', (
      tester,
    ) async {
      pumpWithTheme(tester, const Progress(value: 0.5, id: 'bar'));

      final root = _track(tester);
      expect(root.id, 'bar');
      expect(
        _classes(root),
        containsAll([
          'relative',
          'w-full',
          'overflow-hidden',
          _bg(CoreProgressStyle.defaultBackgroundColor),
        ]),
      );
      expect(root.attributes, isNot(contains('aria-labelledby')));
      expect(root.attributes, isNot(contains('aria-describedby')));
      expect(find.byType(Gap), findsNothing);
      // The bar holds its fill and nothing else.
      expect(
        _doms(tester).where((c) => c.tag == 'div').length,
        2,
        reason: 'the bar grew elements it does not need',
      );
    });

    testComponents('with cells the progressbar is the column around them', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const Progress(
          value: 0.62,
          id: 'plan',
          label: Text('Team plan'),
          valueLabel: Text('31 / 50'),
          caption: Text('AI usage'),
        ),
      );

      final root = _track(tester);
      expect(root.id, 'plan');
      expect(
        _classes(root),
        containsAll(['flex', 'flex-col', 'w-full']),
      );
      expect(
        _classes(root).where((c) => c.startsWith('bg-')),
        isEmpty,
        reason: 'the column took the track colour',
      );
      expect(root.attributes?['aria-valuenow'], '0.62');
      expect(root.attributes?['aria-labelledby'], 'plan-label');
      expect(root.attributes?['aria-describedby'], 'plan-caption');
      expect(byId(tester, 'plan-label'), isNotNull);
      expect(byId(tester, 'plan-caption'), isNotNull);

      // The track sits inside, still the neutral band around the fill.
      final track = _doms(tester).singleWhere(
        (c) =>
            _classes(c).contains(_bg(CoreProgressStyle.defaultBackgroundColor)),
      );
      expect(_inline(track)['height'], isNotNull);
      expect(
        _classes(_indicator(tester)),
        contains(_bg(const CoreColor.token(CoreColors.primary))),
      );
      expect(find.byType(Gap), findsNComponents(2));
    });

    testComponents('each cell carries its own text tier', (tester) async {
      pumpWithTheme(
        tester,
        const Progress(
          value: 0.5,
          id: 'p',
          label: Text('Team plan'),
          valueLabel: Text('62%'),
          caption: Text('AI usage'),
        ),
      );

      final label = byId(tester, 'p-label');
      expect(
        _classes(label),
        containsAll(['text-label-medium', 'text-on-surface', 'flex-1']),
      );
      expect(
        _inline(label),
        isEmpty,
        reason: "the label keeps the role's own weight — nothing rides inline",
      );

      final caption = byId(tester, 'p-caption');
      expect(
        _classes(caption),
        containsAll(['text-body-xs', 'text-on-surface-subtle']),
      );
      expect(_inline(caption), isEmpty);

      final value = _doms(
        tester,
      ).singleWhere((c) => _classes(c).contains('text-on-surface-variant'));
      expect(_classes(value), contains('text-label-medium'));
      expect(
        _inline(value)['font-weight'],
        '${CoreFontWeight.regular}',
        reason: "the regular overlay rides on the role's class",
      );
    });

    testComponents('both spacers default to space8', (tester) async {
      pumpWithTheme(
        tester,
        const Progress(
          value: 0.5,
          label: Text('Team plan'),
          caption: Text('AI usage'),
        ),
      );

      final gaps = find
          .byType(Gap)
          .evaluate()
          .map((e) => (e.component as Gap).gapStyle)
          .toList();
      expect(gaps, [
        CoreProgressStyle.defaultLabelGapStyle,
        CoreProgressStyle.defaultCaptionGapStyle,
      ]);
    });

    testComponents('a lone value label keeps the label cell as a spacer', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const Progress(value: 0.5, id: 'v', valueLabel: Text('62%')),
      );

      final root = _track(tester);
      expect(root.attributes, isNot(contains('aria-labelledby')));
      expect(
        _doms(tester).where((c) => c.id == 'v-label'),
        isEmpty,
        reason: 'an empty cell names nothing',
      );
      final spacer = _doms(tester).singleWhere(
        (c) => _classes(c).contains('flex-1'),
      );
      expect(spacer.children, isEmpty);
      expect(find.byType(Gap), findsOneComponent);
    });

    testComponents('an override reaches the cells and the spacers', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const Progress(
          value: 0.5,
          id: 'o',
          label: Text('Team plan'),
          caption: Text('AI usage'),
          progressStyle: CoreProgressStyle(
            labelStyle: CoreTextStyle(color: _kRaw),
            captionGapStyle: CoreGapStyle(size: CoreSpace.space4),
          ),
        ),
      );

      final label = byId(tester, 'o-label');
      expect(_inline(label)['color'], _kRaw.toValue());
      expect(_inline(label), isNot(contains('font-weight')));
      expect(
        find.byType(Gap).evaluate().map((e) => (e.component as Gap).gapStyle),
        contains(const CoreGapStyle(size: CoreSpace.space4)),
      );
    });

    testComponents('the indeterminate rule still reaches the fill', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const Progress(id: 'busy', label: Text('Uploading')),
      );

      final style = _doms(tester).singleWhere((c) => c.tag == 'style');
      final css = (style.children!.single as RawText).text;
      expect(css, contains('#busy .$_kMarker'));
      expect(_classes(_indicator(tester)), contains(_kMarker));
      expect(_track(tester).attributes, isNot(contains('aria-valuenow')));
    });
  });
}
