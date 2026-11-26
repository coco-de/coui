/// The carousel used to declare eleven of these on Flutter and none on Web,
// which is the failure mode that looks finished from the authoring side: the
// field exists, `copyWith` carries it, nothing throws, and the screen never
// changes. What these tests read back is that each one reaches the CSS the
// browser actually paints — the axis, the slide extent, the alignment slack,
// the easing, the gap, and the two transition modes — plus the auto-play
// switches that only show up in when the next advance fires.
library;

import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

/// Slide count used by every resolver case.
const _kSlides = 3;

/// Slide positions a three-slide carousel renders without a clone buffer.
const _kPositions = [0, 1, 2];

/// Half a slide of progress — the frame where two slides share the viewport.
const _kHalfSlide = 0.5;

/// Progress half a slide past the last one — the wrap-around frame.
const _kWrapSlide = 2.5;

/// Slide extent used by the partial-width cases.
const _kHalfExtent = CoreCarouselSizeConstraint.fractional(0.5);

/// Absolute slide extent (160 logical px = 10rem at the default root size).
const _kFixedExtent = CoreCarouselSizeConstraint.fixed(160);

/// Auto-play interval long enough that only the *first* advance can fire
/// inside a test — so what is asserted is when auto-play starts, not how
/// fast it repeats.
const _kLongInterval = Duration(minutes: 1);

late ResolvedCarousel _seen;

class _Capture extends StatelessComponent {
  const _Capture({
    this.alignment = CoreCarouselAlignment.center,
    this.animate = true,
    this.curve = CoreEasing.easeInOut,
    this.direction = CoreAxis.horizontal,
    this.gap = 0,
    this.mode = CoreCarouselTransitionMode.sliding,
    this.progress = 0,
    this.sizeConstraint = const CoreCarouselSizeConstraint.fractional(1),
    this.slidePositions = _kPositions,
    this.speed = CoreCarouselStyle.defaultTransitionSpeed,
  });

  final CoreCarouselAlignment alignment;
  final bool animate;
  final CoreCubicBezier curve;
  final CoreAxis direction;
  final double gap;
  final CoreCarouselTransitionMode mode;
  final double progress;
  final CoreCarouselSizeConstraint sizeConstraint;
  final List<int> slidePositions;
  final Duration speed;

  @override
  Component build(BuildContext context) {
    _seen = resolveCarousel(
      variant: CoreCarouselVariant.defaultVariant,
      context,
      alignment: alignment,
      animate: animate,
      curve: curve,
      direction: direction,
      gap: gap,
      itemCount: _kSlides,
      mode: mode,
      progress: progress,
      sizeConstraint: sizeConstraint,
      slidePositions: slidePositions,
      speed: speed,
      wrap: true,
    );

    return const Component.text('x');
  }
}

Future<ResolvedCarousel> _resolve(
  ComponentTester tester,
  _Capture capture,
) async {
  pumpWithTheme(tester, capture);
  await tester.pump();

  return _seen;
}

Map<String, String> _props(WebElementChrome chrome) =>
    chrome.inlineStyles?.properties ?? const {};

/// Every rendered slide's text, in DOM order.
List<String> _slideTexts(ComponentTester tester) => find
    .byType(Text)
    .evaluate()
    .map((e) => (e.component as Text).data)
    .toList();

/// Pumps a carousel and returns every index its `onIndexChanged` reported,
/// in order — empty when auto-play left it where it started.
Future<List<int>> _reportedIndices(
  ComponentTester tester,
  Carousel Function(void Function(int) report) build,
) async {
  final reported = <int>[];
  pumpWithTheme(tester, build(reported.add));
  await tester.pump();
  await Future<void>.delayed(.zero);

  return reported;
}

void main() {
  for (final index in _kPositions) {
    testComponents('finite carousel indicator retains index $index', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        Carousel(
          items: const [Text('first'), Text('second'), Text('third')],
          currentIndex: index,
          wrap: false,
          showNavigation: false,
        ),
      );
      await tester.pump();
      final indicator =
          find.byType(DotIndicator).evaluate().single.component as DotIndicator;
      expect(indicator.index, index);
    });
  }

  group('direction picks the axis slides travel along', () {
    testComponents('horizontal translates X on a flex row', (tester) async {
      final resolved = await _resolve(tester, const _Capture());

      expect(resolved.track.className, contains('flex-row'));
      expect(_props(resolved.track)['transform'], startsWith('translateX('));
    });

    testComponents('vertical translates Y on a flex column', (tester) async {
      final resolved = await _resolve(
        tester,
        const _Capture(direction: .vertical),
      );

      expect(resolved.track.className, contains('flex-col'));
      expect(_props(resolved.track)['transform'], startsWith('translateY('));
      // A percentage slide extent needs a definite basis to resolve
      // against, which stacked auto-height slides cannot provide.
      expect(_props(resolved.track)['height'], '100%');
    });

    testComponents('and the slide extent follows the axis', (tester) async {
      final horizontal = await _resolve(tester, const _Capture());
      expect(_props(horizontal.slides.first).keys, contains('min-width'));

      final vertical = await _resolve(
        tester,
        const _Capture(direction: .vertical),
      );
      expect(_props(vertical.slides.first).keys, contains('min-height'));
    });
  });

  group('sizeConstraint sets how far one slide extends', () {
    testComponents('fractional emits a viewport percentage', (tester) async {
      final resolved = await _resolve(
        tester,
        const _Capture(sizeConstraint: _kHalfExtent),
      );

      expect(_props(resolved.slides.first)['min-width'], '50.0%');
    });

    testComponents('fixed emits an absolute rem length', (tester) async {
      final resolved = await _resolve(
        tester,
        const _Capture(sizeConstraint: _kFixedExtent),
      );

      expect(_props(resolved.slides.first)['min-width'], '10.0rem');
    });

    testComponents('and a full-width slide travels one viewport', (
      tester,
    ) async {
      // Progress 1 with a full-viewport slide must land exactly one
      // viewport away — the baseline the fractional case below deviates
      // from, so a wrong extent shows up as a wrong translate.
      final resolved = await _resolve(tester, const _Capture(progress: 1));

      expect(_props(resolved.track)['transform'], 'translateX(-100.0%)');
    });

    testComponents('a half-width slide travels half a viewport', (
      tester,
    ) async {
      final resolved = await _resolve(
        tester,
        const _Capture(
          alignment: .start,
          progress: 1,
          sizeConstraint: _kHalfExtent,
        ),
      );

      expect(_props(resolved.track)['transform'], 'translateX(-50.0%)');
    });
  });

  group('alignment distributes the leftover viewport extent', () {
    testComponents('start leaves no slack before the slide', (tester) async {
      final resolved = await _resolve(
        tester,
        const _Capture(alignment: .start, sizeConstraint: _kHalfExtent),
      );

      expect(_props(resolved.track)['transform'], 'translateX(0.0%)');
    });

    testComponents('center splits it in half', (tester) async {
      final resolved = await _resolve(
        tester,
        const _Capture(sizeConstraint: _kHalfExtent),
      );

      expect(_props(resolved.track)['transform'], 'translateX(25.0%)');
    });

    testComponents('end puts all of it before the slide', (tester) async {
      final resolved = await _resolve(
        tester,
        const _Capture(alignment: .end, sizeConstraint: _kHalfExtent),
      );

      expect(_props(resolved.track)['transform'], 'translateX(50.0%)');
    });

    testComponents('and a full-width slide has none to distribute', (
      tester,
    ) async {
      // The alignment axis is only observable when a slide is smaller than
      // the viewport; asserting that keeps the default case honest.
      final start = await _resolve(
        tester,
        const _Capture(alignment: .start),
      );
      final end = await _resolve(tester, const _Capture(alignment: .end));

      expect(_props(start.track)['transform'], _props(end.track)['transform']);
    });
  });

  group('curve and speed drive the CSS transition', () {
    testComponents('the easing token lands as a cubic-bezier', (tester) async {
      final resolved = await _resolve(
        tester,
        const _Capture(curve: CoreEasing.easeOutBack),
      );

      expect(
        _props(resolved.track)['transition'],
        contains('cubic-bezier(0.175, 0.885, 0.32, 1.275)'),
      );
    });

    testComponents('a different curve emits different control points', (
      tester,
    ) async {
      final linear = await _resolve(
        tester,
        const _Capture(curve: CoreEasing.linear),
      );
      final easeInOut = await _resolve(tester, const _Capture());

      expect(
        _props(linear.track)['transition'],
        isNot(_props(easeInOut.track)['transition']),
      );
    });

    testComponents('speed lands as the transition duration', (tester) async {
      final resolved = await _resolve(
        tester,
        const _Capture(speed: Duration(milliseconds: CoreDuration.ms500)),
      );

      expect(_props(resolved.track)['transition'], contains('500ms'));
    });

    testComponents('a drag frame suppresses the transition entirely', (
      tester,
    ) async {
      // Animating during a drag makes the track lag the finger.
      final resolved = await _resolve(tester, const _Capture(animate: false));

      expect(_props(resolved.track)['transition'], 'none');
    });
  });

  group('transition carries both the mode and the gap', () {
    testComponents('a sliding gap spaces the flex line', (tester) async {
      final resolved = await _resolve(tester, const _Capture(gap: 16));

      // The spacing variable a density re-points — the translate below
      // counts the same variable, so the two move together, and the Flutter
      // twin's layout moves its gap by the same rung.
      expect(_props(resolved.track)['gap'], 'var(--coui-space-16)');
    });

    testComponents('no gap emits no gap rule', (tester) async {
      final resolved = await _resolve(tester, const _Capture());

      expect(_props(resolved.track).keys, isNot(contains('gap')));
    });

    testComponents('a gap also shifts how far the track travels', (
      tester,
    ) async {
      // Slide n sits at n * (extent + gap), so a gap the transform ignores
      // would leave every slide progressively off-centre.
      final resolved = await _resolve(
        tester,
        const _Capture(gap: 16, progress: 1),
      );

      expect(
        _props(resolved.track)['transform'],
        contains('- 1.0 * var(--coui-space-16)'),
      );
    });

    testComponents('the slides keep their stops when a density re-points the '
        'gap', (tester) async {
      // Evaluates what the browser does with the emitted CSS: the line's
      // `gap` and the translate's gap term both read `--coui-space-16`, which
      // each density's stylesheet rule sets to that density's rung. Slide `n`
      // sits at `n * (extent + gap)` in the line, so the active slide lands
      // on the alignment slack — `(viewport - extent) / 2` — whatever the gap.
      const viewport = 400.0;
      const extent = 160.0;
      final term = RegExp(
        r'^translateX\(calc\((-?[\d.]+)% ([+-]) ([\d.]+)rem'
        r'(?: ([+-]) ([\d.]+) \* var\(--coui-space-(\d+)\))?\)\)$',
      );

      for (final progress in const [1.0, 2.0]) {
        final resolved = await _resolve(
          tester,
          _Capture(
            gap: CoreSpace.space16,
            progress: progress,
            sizeConstraint: _kFixedExtent,
          ),
        );
        final transform = _props(resolved.track)['transform']!;
        final match = term.firstMatch(transform);
        expect(match, isNotNull, reason: transform);
        expect(_props(resolved.track)['gap'], 'var(--coui-space-16)');

        for (final density in CoreDensity.values) {
          final gap = density.space(double.parse(match!.group(6)!));
          final rem =
              double.parse(match.group(3)!) * (match.group(2) == '-' ? -1 : 1);
          final gaps =
              double.parse(match.group(5)!) * (match.group(4) == '-' ? -1 : 1);
          final translate =
              viewport * double.parse(match.group(1)!) / 100 +
              rem * 16 +
              gaps * gap;
          final activeLeft = translate + progress * (extent + gap);
          expect(
            activeLeft,
            closeTo((viewport - extent) / 2, 1e-9),
            reason: '${density.name} at $progress: $transform',
          );
        }
      }
    });

    testComponents('fading stacks the slides instead of translating', (
      tester,
    ) async {
      final resolved = await _resolve(tester, const _Capture(mode: .fading));

      expect(resolved.track.className, isNot(contains('flex')));
      expect(_props(resolved.track).keys, isNot(contains('transform')));
      expect(_props(resolved.slides.first)['position'], 'absolute');
    });

    testComponents('and cross-fades them with opacity', (tester) async {
      final resolved = await _resolve(tester, const _Capture(mode: .fading));
      final slides = resolved.slides.map(_props).toList();

      expect(slides[0]['opacity'], '1.0');
      expect(slides[1]['opacity'], '0.0');
      expect(slides[0]['transition'], startsWith('opacity '));
    });

    testComponents('a half-way progress shows two slides at once', (
      tester,
    ) async {
      final resolved = await _resolve(
        tester,
        const _Capture(mode: .fading, progress: _kHalfSlide),
      );
      final slides = resolved.slides.map(_props).toList();

      expect(slides[0]['opacity'], '0.5');
      expect(slides[1]['opacity'], '0.5');
    });

    testComponents('and the last slide fades into the first when wrapping', (
      tester,
    ) async {
      // Measured the long way around, the distance from progress 2.5 to
      // slide 0 is 2.5 — both ends would sit fully transparent and the
      // wrap would read as a blank frame.
      final resolved = await _resolve(
        tester,
        const _Capture(mode: .fading, progress: _kWrapSlide),
      );
      final slides = resolved.slides.map(_props).toList();

      expect(slides[2]['opacity'], '0.5');
      expect(slides[0]['opacity'], '0.5');
    });
  });

  group('an empty carousel still resolves', () {
    testComponents('with no slides to measure the track from', (tester) async {
      // The track transform is measured from the first rendered slide, and
      // an empty carousel has none — reading it unguarded threw `Bad state:
      // No element` before a single slide had been supplied.
      final resolved = await _resolve(
        tester,
        const _Capture(slidePositions: []),
      );

      expect(resolved.slides, isEmpty);
      expect(_props(resolved.track)['transform'], 'translateX(0.0%)');
    });

    testComponents('and renders nothing for it', (tester) async {
      pumpWithTheme(tester, const Carousel());
      await tester.pump();

      expect(_slideTexts(tester), isEmpty);
    });
  });

  group('content comes from either items or itemBuilder', () {
    testComponents('itemBuilder builds the slides lazily', (tester) async {
      pumpWithTheme(
        tester,
        Carousel(
          itemBuilder: (context, index) => Text('slide $index'),
          itemCount: _kSlides,
          showIndicators: false,
          showNavigation: false,
          wrap: false,
        ),
      );
      await tester.pump();

      expect(_slideTexts(tester), ['slide 0', 'slide 1', 'slide 2']);
    });

    testComponents('reverse flips which content lands on which slot', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const Carousel(
          items: [Text('a'), Text('b'), Text('c')],
          showIndicators: false,
          showNavigation: false,
          wrap: false,
          reverse: true,
        ),
      );
      await tester.pump();

      // Position 1 reads content -1, which wraps to the last item.
      expect(_slideTexts(tester), ['a', 'c', 'b']);
    });
  });

  group('auto-play switches decide when and where it advances', () {
    testComponents('waitOnStart holds the first advance back', (tester) async {
      final reported = await _reportedIndices(
        tester,
        (report) => Carousel(
          items: const [Text('a'), Text('b'), Text('c')],
          duration: _kLongInterval,
          autoPlay: true,
          onIndexChanged: report,
          waitOnStart: true,
        ),
      );

      expect(reported, isEmpty);
    });

    testComponents('without it the carousel advances on mount', (tester) async {
      final reported = await _reportedIndices(
        tester,
        (report) => Carousel(
          items: const [Text('a'), Text('b'), Text('c')],
          duration: _kLongInterval,
          autoPlay: true,
          onIndexChanged: report,
        ),
      );

      expect(reported.first, 1);
    });

    testComponents('autoplayReverse advances backwards instead', (
      tester,
    ) async {
      final reported = await _reportedIndices(
        tester,
        (report) => Carousel(
          items: const [Text('a'), Text('b'), Text('c')],
          transition: const CoreCarouselTransition.fading(),
          duration: _kLongInterval,
          autoPlay: true,
          onIndexChanged: report,
          autoplayReverse: true,
        ),
      );

      expect(reported.first, _kSlides - 1);
    });

    // The gate itself, all four combinations. This side used to require the
    // flag and ignore a lone `duration`, while the Flutter twin did the
    // opposite — so the same code auto-played on exactly one platform. The
    // flag is now nullable and derives from the interval when unset, which
    // makes both prior behaviours agree; a derivation is precisely the thing
    // that drifts unsigned, so each corner is pinned.
    testComponents('the flag alone turns it on', (tester) async {
      final reported = await _reportedIndices(
        tester,
        (report) => Carousel(
          items: const [Text('a'), Text('b'), Text('c')],
          autoPlay: true,
          onIndexChanged: report,
        ),
      );

      expect(reported.first, 1);
    });

    testComponents('the flag alone turns it off', (tester) async {
      final reported = await _reportedIndices(
        tester,
        (report) => Carousel(
          items: const [Text('a'), Text('b'), Text('c')],
          autoPlay: false,
          duration: Duration.zero,
          onIndexChanged: report,
        ),
      );

      expect(reported, isEmpty);
    });

    testComponents('an interval with no flag still auto-plays', (tester) async {
      // Previously ignored here: this side gated on the flag alone, so a
      // caller who only stated an interval got a still carousel on Web and a
      // moving one on Flutter.
      final reported = await _reportedIndices(
        tester,
        (report) => Carousel(
          items: const [Text('a'), Text('b'), Text('c')],
          duration: Duration.zero,
          onIndexChanged: report,
        ),
      );

      expect(reported.first, 1);
    });

    testComponents('neither one stays still', (tester) async {
      final reported = await _reportedIndices(
        tester,
        (report) => Carousel(
          items: const [Text('a'), Text('b'), Text('c')],
          onIndexChanged: report,
        ),
      );

      expect(reported, isEmpty);
    });

    testComponents('durationBuilder overrides the flat interval', (
      tester,
    ) async {
      // A per-index builder that answers for the current slide must be
      // consulted at all — the flat `duration` here is a minute, so an
      // ignored builder is an advance that never lands.
      final asked = <int>[];
      final reported = await _reportedIndices(
        tester,
        (report) => Carousel(
          items: const [Text('a'), Text('b'), Text('c')],
          duration: _kLongInterval,
          autoPlay: true,
          onIndexChanged: report,
          durationBuilder: (index) {
            asked.add(index);

            return Duration.zero;
          },
          waitOnStart: true,
        ),
      );

      expect(asked, isNotEmpty);
      expect(reported.first, 1);
    });
  });
}
