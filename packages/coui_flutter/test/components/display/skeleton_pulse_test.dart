// The alpha Flutter's Skeleton paints at each end of its pulse — read off the
// painted decoration and compared against the vector table coui_core owns,
// the same numbers the Web test compares its `--pulse-from` / `--pulse-to`
// against.
//
// The pulse opacity is multiplied into the fill's own alpha. Writing it over
// the fill instead is what made a transparent fill pulse as black here while
// Web and the Figma canvas stayed clear.
import 'dart:convert';
import 'dart:io';

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

const String kSkeletonPulseVectorsPath =
    '../coui_core/test/fixtures/skeleton_pulse_vectors.json';

/// The tokens the vector table names — `CoreColors` has no lookup by name.
const Map<String, CoreColorToken> _kTokens = {'primary': CoreColors.primary};

const double _kTolerance = 1e-9;

/// Flutter's `Cubic` solves its x to 0.001; the alpha it paints is within
/// that of the table's exact evaluation.
const double _kCurveTolerance = 2e-3;

/// One pulse is sampled this often, over two full cycles.
const Duration _kSampleStep = Duration(milliseconds: 50);
const int _kSamples = 80;

const double _kWidth = 200;
const double _kHeight = 20;

/// The colour the skeleton block is painting this frame.
Color _painted(WidgetTester tester) {
  final box = tester.widget<Container>(
    find.descendant(
      of: find.byType(Skeleton),
      matching: find.byType(Container),
    ),
  );

  return (box.decoration! as BoxDecoration).color!;
}

CoreColor? _fill(Map<String, Object?>? spec) {
  if (spec == null) return null;
  final argb = spec['argb'] as String?;
  if (argb != null) return CoreColor(int.parse(argb));

  return CoreColor.token(
    _kTokens[spec['token']]!,
    opacity: (spec['opacity']! as num).toDouble(),
  );
}

void main() {
  final doc =
      jsonDecode(File(kSkeletonPulseVectorsPath).readAsStringSync())
          as Map<String, Object?>;
  final cases = (doc['cases']! as List).cast<Map<String, Object?>>();

  test('the vector table is not empty', () {
    expect(cases, isNotEmpty);
  });

  final timelines =
      ((doc['timelines']! as Map<String, Object?>)['cases']! as List)
          .cast<Map<String, Object?>>();

  // Where the pulse is at each point of its period — the same table Web's
  // emitted period, curve and keyframes are held to. Both cases run on the
  // default pulse ends — rest `defaultFromOpacity`, peak `defaultToOpacity`,
  // the ones the first vector case states.
  group('the pulse follows the shared timeline', () {
    const rest = CoreSkeletonStyle.defaultFromOpacity;
    const peak = CoreSkeletonStyle.defaultToOpacity;

    for (final c in timelines) {
      testWidgets('${c['name']}', (tester) async {
        final period = Duration(milliseconds: c['periodMs']! as int);
        final l = (c['curve']! as List).cast<num>();
        final curve = (
          x1: l[0].toDouble(),
          y1: l[1].toDouble(),
          x2: l[2].toDouble(),
          y2: l[3].toDouble(),
        );
        // The default case runs on the defaults, so it pins them too.
        final style = c['name'] == 'default'
            ? null
            : CoreSkeletonStyle(duration: period, curve: curve);
        await tester.pumpWidget(
          buildTestApp(
            Skeleton(width: _kWidth, height: _kHeight, skeletonStyle: style),
          ),
        );

        var elapsed = Duration.zero;
        for (final s in (c['samples']! as List).cast<Map<String, Object?>>()) {
          final t = (s['t']! as num).toDouble();
          final at = period * t;
          await tester.pump(at - elapsed);
          elapsed = at;
          final progress = (s['progress']! as num).toDouble();
          expect(
            _painted(tester).a,
            closeTo(rest + (peak - rest) * progress, _kCurveTolerance),
            reason: 't $t',
          );
        }
      });
    }
  });

  // A display-tier loop reduced motion stops: the placeholder holds
  // its resting end, keeps announcing, and pulses again once the setting is
  // turned off.
  group('reduced motion holds the resting end', () {
    testWidgets('no pulse, resting fill, announcement kept', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const Skeleton(width: _kWidth, height: _kHeight),
          disableAnimations: true,
        ),
      );

      for (var i = 0; i <= _kSamples; i++) {
        expect(
          _painted(tester).a,
          CoreSkeletonStyle.defaultFromOpacity,
          reason: 'sample $i',
        );
        await tester.pump(_kSampleStep);
      }
      expect(
        find.bySemanticsLabel(
          CoUILocalizations.of(
            tester.element(find.byType(Skeleton)),
          ).loadingLabel,
        ),
        findsOneWidget,
      );
    });

    testWidgets('pulses again when the setting is turned off', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const Skeleton(width: _kWidth, height: _kHeight),
          disableAnimations: true,
        ),
      );
      await tester.pump(CoreSkeletonStyle.defaultDuration);
      expect(_painted(tester).a, CoreSkeletonStyle.defaultFromOpacity);

      await tester.pumpWidget(
        buildTestApp(const Skeleton(width: _kWidth, height: _kHeight)),
      );
      await tester.pump(CoreSkeletonStyle.defaultDuration ~/ 2);
      expect(
        _painted(tester).a,
        closeTo(CoreSkeletonStyle.defaultToOpacity, _kCurveTolerance),
        reason: 'the peak, half a period after the pulse restarts',
      );
    });
  });

  group('pulse ends match the shared vectors', () {
    for (final c in cases) {
      testWidgets('${c['name']}: rest ${c['restAlpha']}, '
          'peak ${c['peakAlpha']}', (tester) async {
        await tester.pumpWidget(
          buildTestApp(
            Skeleton(
              width: _kWidth,
              height: _kHeight,
              skeletonStyle: CoreSkeletonStyle(
                backgroundColor: _fill(c['fill'] as Map<String, Object?>?),
                fromOpacity: (c['fromOpacity']! as num).toDouble(),
                toOpacity: (c['toOpacity']! as num).toDouble(),
              ),
            ),
          ),
        );

        // The controller starts at the resting end and reaches the peak
        // half a period later — one period is the full pulse.
        expect(
          _painted(tester).a,
          closeTo((c['restAlpha']! as num).toDouble(), _kTolerance),
          reason: 'resting end',
        );
        await tester.pump(CoreSkeletonStyle.defaultDuration ~/ 2);
        expect(
          _painted(tester).a,
          closeTo((c['peakAlpha']! as num).toDouble(), _kTolerance),
          reason: 'peak',
        );
      });
    }
  });

  testWidgets('a transparent fill stays transparent through the whole pulse', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildTestApp(
        const Skeleton(width: _kWidth, height: _kHeight).transparent,
      ),
    );

    for (var i = 0; i <= _kSamples; i++) {
      expect(_painted(tester).a, 0, reason: 'sample $i');
      await tester.pump(_kSampleStep);
    }
  });

  testWidgets('the pulse keeps tracking a dark scheme', (tester) async {
    // The ends are scaled before the scheme resolves them. Scaling an
    // already-resolved token rebuilds it unresolved, and the conversion
    // then falls back to the light palette — this pins the order.
    final dark = CoreThemePresets.darkColorScheme.surfaceContainerHighest.argb;
    final light =
        CoreThemePresets.lightColorScheme.surfaceContainerHighest.argb;
    expect(dark, isNot(light), reason: 'the two schemes must differ to tell');

    await tester.pumpWidget(
      buildTestApp(
        const Skeleton(width: _kWidth, height: _kHeight),
        theme: ThemeData(colorScheme: CoreThemePresets.darkColorScheme),
      ),
    );

    final painted = _painted(tester);
    expect(
      painted.withValues(alpha: 1).toARGB32(),
      Color(dark).withValues(alpha: 1).toARGB32(),
    );
    expect(painted.a, CoreSkeletonStyle.defaultFromOpacity);
  });

  group('re-resolving the same style leaves the animation alone', () {
    // `Curve` has no value equality, so a guard comparing the resolved
    // curve objects reads "changed" on every rebuild — the pulse is re-driven
    // each time a parent rebuilds, and nothing visible says so.
    //
    // The style changes from inside the tree: `buildTestApp` mounts its child
    // once in an overlay entry, so pumping a new widget there never reaches
    // the Skeleton's `didUpdateWidget`.
    Animation<double> animationOf(WidgetTester tester) =>
        tester
                .widget<AnimatedBuilder>(
                  find.descendant(
                    of: find.byType(Skeleton),
                    matching: find.byType(AnimatedBuilder),
                  ),
                )
                .animation
            as Animation<double>;

    Future<ValueNotifier<CoreSkeletonStyle?>> pumpWithStyle(
      WidgetTester tester,
      CoreSkeletonStyle? initial,
    ) async {
      final style = ValueNotifier<CoreSkeletonStyle?>(initial);
      addTearDown(style.dispose);
      await tester.pumpWidget(
        buildTestApp(
          ValueListenableBuilder<CoreSkeletonStyle?>(
            valueListenable: style,
            builder: (context, value, _) => Skeleton(
              width: _kWidth,
              height: _kHeight,
              skeletonStyle: value,
            ),
          ),
        ),
      );

      return style;
    }

    testWidgets('a style that resolves to the same curve keeps the animation', (
      tester,
    ) async {
      final style = await pumpWithStyle(tester, null);
      final before = animationOf(tester);

      // A new style object and a new Skeleton, spelling out the default.
      style.value = const CoreSkeletonStyle(
        curve: CoreSkeletonStyle.defaultCurve,
      );
      await tester.pump();

      expect(identical(animationOf(tester), before), isTrue);
    });

    testWidgets('a different curve does re-drive it', (tester) async {
      final style = await pumpWithStyle(tester, null);
      final before = animationOf(tester);

      style.value = const CoreSkeletonStyle(curve: CoreEasing.enter);
      await tester.pump();

      expect(identical(animationOf(tester), before), isFalse);
    });
  });
}
