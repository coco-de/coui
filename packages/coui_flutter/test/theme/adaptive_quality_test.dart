// Adaptive quality on the Flutter seat: the tier folded into the theme where a
// recipe becomes a material, the host that feeds the governor the engine's
// raster times, and the surfaces that go without what the tier gives up.
//
// The judgements — when the tier moves, what each tier withholds — are Core's
// and pinned by `adaptive_quality_vectors.json`; this file holds what only the
// seat can: that the `cost` traces of that table, fed as real `FrameTiming`s
// through the engine's callback into a mounted `CoUIApp`, end on the tiers the
// table says and call `onQualityChanged` in its order; that the material a
// surface hands its renderer is what the tier leaves of the style's; that
// reduce transparency, high contrast and the lifecycle outrank the governor;
// and that a step never tweens.
//
// `flutter_tester` cannot run a shader filter, so "the bend is absent" is read
// where the surface decides it — the request it hands its renderer
// (`SurfaceBlur.refraction`) — and the backdrop pass where it is mounted
// (`BackdropFilter`). The pixels are the device probe's
// (`app/coui_widgetbook/integration_test/adaptive_quality_probe_test.dart`).
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

/// A frame's worth of time, enough to take an implicit theme animation past
/// the instant it starts on.
const Duration _kOneFrame = Duration(milliseconds: 16);

const String _kVectorsPath =
    '../coui_core/test/fixtures/adaptive_quality_vectors.json';

Map<String, Object?> _vectors() =>
    jsonDecode(File(_kVectorsPath).readAsStringSync()) as Map<String, Object?>;

List<Map<String, Object?>> _list(Object? value) =>
    (value! as List).cast<Map<String, Object?>>();

CoreQualityTier _tier(Object? name) =>
    CoreQualityTier.values.byName(name! as String);

ThemeData _folded({
  CoreQualityTier quality = CoreQualityTier.full,
  bool reduceTransparency = false,
  bool highContrast = false,
  CoreSurfaceStyleId style = CoreSurfaceStyleId.liquidGlass,
}) => applySurfaceStyle(
  ThemeData.fromCore(CoreThemePresets.light),
  surfaceStyle: style,
  highContrast: highContrast,
  reduceTransparency: reduceTransparency,
  quality: quality,
);

/// The fold for an app that states the frost and the shade (the `ios27`
/// preset, in dark where it states both), at [quality].
ThemeData _foldedWithFrost(CoreQualityTier quality) => applySurfaceStyle(
  ThemeData.fromCore(CoreThemePresets.dark),
  surfaceStyle: CoreSurfaceStyleId.liquidGlass,
  highContrast: false,
  surfaceTuning: CoreSurfaceTuning.ios27,
  quality: quality,
);

void main() {
  group('the fold takes the tier into the material', () {
    final glass = CoreSurfaceRecipe.of(CoreSurfaceStyleId.liquidGlass);

    test('the top tier is the theme as it was, down to the same value', () {
      final plain = applySurfaceStyle(
        ThemeData.fromCore(CoreThemePresets.light),
        surfaceStyle: CoreSurfaceStyleId.liquidGlass,
        highContrast: false,
      );
      expect(_folded(), plain);
      expect(_folded().surfaceQuality, CoreQualityTier.full);
      expect(_folded().surfaceRefraction, glass.refraction);
      expect(_folded().surfaceBlur, glass.surface!.blurRadius);
    });

    test('without the bend only the bend goes', () {
      final full = _folded();
      final theme = _folded(quality: CoreQualityTier.noRefraction);

      expect(theme.surfaceQuality, CoreQualityTier.noRefraction);
      expect(theme.surfaceRefraction, isNull);
      expect(theme.surfaceBlur, full.surfaceBlur);
      expect(theme.surfaceOpacity, full.surfaceOpacity);
      expect(theme.surfaceSaturation, full.surfaceSaturation);
      expect(theme.surfaceBackdropBrightness, full.surfaceBackdropBrightness);
      expect(theme.surfaceSheen, full.surfaceSheen);
      expect(theme.functionalSurface, full.functionalSurface);
      expect(theme.surfaceDrawsOwnEdge, full.surfaceDrawsOwnEdge);
    });

    test('a tier without the backdrop pass takes the frost and the shade with '
        'it; one without only the bend keeps both', () {
      final full = _foldedWithFrost(CoreQualityTier.full);
      expect(full.surfaceFrost, isNotNull, reason: 'the preset states a frost');
      expect(
        full.surfaceBodyShade,
        isNotNull,
        reason: 'and, in dark, a shade',
      );

      // The frost is a pass of its own and the shade reads no coordinates, so
      // withdrawing the bend leaves both.
      final noBend = _foldedWithFrost(CoreQualityTier.noRefraction);
      expect(noBend.surfaceRefraction, isNull);
      expect(noBend.surfaceFrost, full.surfaceFrost);
      expect(noBend.surfaceBodyShade, full.surfaceBodyShade);

      // Both are drawn by the backdrop pass: a tier with no pass has nothing to
      // frost or to shade, whatever the style and the tuning state.
      final solid = _foldedWithFrost(CoreQualityTier.solid);
      expect(solid.surfaceFrost, isNull);
      expect(solid.surfaceBodyShade, isNull);

      // The same answer the reduce-transparency fold gives.
      final reduced = applySurfaceStyle(
        ThemeData.fromCore(CoreThemePresets.dark),
        surfaceStyle: CoreSurfaceStyleId.liquidGlass,
        highContrast: false,
        surfaceTuning: CoreSurfaceTuning.ios27,
        reduceTransparency: true,
      );
      expect(solid.surfaceFrost, reduced.surfaceFrost);
      expect(solid.surfaceBodyShade, reduced.surfaceBodyShade);
    });

    test('solid is the reduce-transparency material, field by field', () {
      final solid = _folded(quality: CoreQualityTier.solid);
      final reduced = _folded(reduceTransparency: true);

      expect(solid.surfaceQuality, CoreQualityTier.solid);
      expect(solid.surfaceRefraction, isNull);
      expect(solid.surfaceBlur, isNull);
      expect(solid.surfaceOpacity, 1);
      expect(solid.surfaceSaturation, CoreSurfaceToken.identitySaturation);
      expect(solid.functionalSurface!.usesTransparency, isFalse);
      expect(
        solid.surfaceSheen,
        glass.surface!.sheen,
        reason: 'the band stays',
      );

      expect(solid.surfaceBlur, reduced.surfaceBlur);
      expect(solid.surfaceOpacity, reduced.surfaceOpacity);
      expect(solid.surfaceSaturation, reduced.surfaceSaturation);
      expect(
        solid.surfaceBackdropBrightness,
        reduced.surfaceBackdropBrightness,
      );
      expect(solid.surfaceSheen, reduced.surfaceSheen);
      expect(solid.functionalSurface, reduced.functionalSurface);
      expect(solid.surfaceRefraction, reduced.surfaceRefraction);
      expect(solid.surfaceDrawsOwnEdge, reduced.surfaceDrawsOwnEdge);
    });

    test('a reduce-transparency preference is the lowest tier whatever tier '
        'was asked for', () {
      for (final asked in CoreQualityTier.values) {
        final theme = _folded(quality: asked, reduceTransparency: true);
        expect(theme.surfaceQuality, CoreQualityTier.solid, reason: '$asked');
        expect(theme.reduceTransparency, isTrue);
        expect(theme.surfaceBlur, isNull);
        expect(theme.surfaceRefraction, isNull);
      }
    });

    test('the table says what every tier leaves of this style', () {
      for (final row in _list(_vectors()['tiers'])) {
        final theme = _folded(quality: _tier(row['tier']));
        expect(
          theme.surfaceRefraction != null,
          row['refraction'],
          reason: '${row['tier']} refraction',
        );
        expect(
          theme.functionalSurface!.usesTransparency,
          row['backdropPass'],
          reason: '${row['tier']} backdrop pass',
        );
      }
    });

    test('a tier never adds an effect the style did not state', () {
      for (final style in [
        CoreSurfaceStyleId.defaultStyle,
        CoreSurfaceStyleId.neoBrutalism,
        CoreSurfaceStyleId.claymorphism,
        CoreSurfaceStyleId.neumorphism,
      ]) {
        for (final tier in CoreQualityTier.values) {
          final theme = _folded(quality: tier, style: style);
          expect(theme.surfaceRefraction, isNull, reason: '$style $tier');
          expect(theme.surfaceBlur, isNull, reason: '$style $tier');
        }
      }
    });

    test('high contrast still removes the bend at the top tier — the tier '
        'does not put it back', () {
      expect(_folded(highContrast: true).surfaceRefraction, isNull);
      expect(
        _folded(
          highContrast: true,
          quality: CoreQualityTier.noRefraction,
        ).surfaceRefraction,
        isNull,
      );
      // The blur survives high contrast, as it did.
      expect(
        _folded(highContrast: true).surfaceBlur,
        glass.surface!.blurRadius,
      );
    });
  });

  group('ThemeData carries the tier by value', () {
    test('a theme at another tier is another theme, and copyWith moves it', () {
      final top = _folded();
      final solid = _folded(quality: CoreQualityTier.solid);
      expect(top == solid, isFalse);
      expect(top.hashCode == solid.hashCode, isFalse);

      final copy = top.copyWith(surfaceQuality: () => CoreQualityTier.solid);
      expect(copy.surfaceQuality, CoreQualityTier.solid);
      expect(top.copyWith().surfaceQuality, CoreQualityTier.full);
    });

    test('the tier alone makes a theme another theme', () {
      // `copyWith` moves nothing but the tier, so a comparison that left it out
      // would call these equal — and a framework that rebuilds on inequality
      // would not rebuild when the only thing that changed is the tier.
      final top = _folded();
      final onlyTier = top.copyWith(
        surfaceQuality: () => CoreQualityTier.solid,
      );

      expect(onlyTier == top, isFalse);
      expect(onlyTier.hashCode == top.hashCode, isFalse);
      expect(
        onlyTier.copyWith(surfaceQuality: () => CoreQualityTier.full) == top,
        isTrue,
      );
    });

    test('a step of the tier is never animated: the new material from the '
        'first frame', () {
      final from = _folded();
      final to = _folded(quality: CoreQualityTier.solid);

      for (final t in [0.0, 0.1, 0.49, 0.5, 1.0]) {
        final mid = ThemeData.lerp(from, to, t);
        expect(mid.surfaceQuality, CoreQualityTier.solid, reason: 't=$t');
        expect(mid.surfaceBlur, to.surfaceBlur, reason: 't=$t blur');
        expect(mid.surfaceOpacity, to.surfaceOpacity, reason: 't=$t opacity');
        expect(mid.surfaceSaturation, to.surfaceSaturation, reason: 't=$t');
        expect(mid.surfaceRefraction, to.surfaceRefraction, reason: 't=$t');
        expect(mid.functionalSurface, to.functionalSurface, reason: 't=$t');
      }
    });

    test('the frost and the shade snap with the rest of the material', () {
      final from = _foldedWithFrost(CoreQualityTier.full);
      final to = _foldedWithFrost(CoreQualityTier.solid);

      for (final t in [0.0, 0.1, 0.49]) {
        final mid = ThemeData.lerp(from, to, t);
        expect(mid.surfaceFrost, isNull, reason: 't=$t frost');
        expect(mid.surfaceBodyShade, isNull, reason: 't=$t shade');
      }
      // And the other way: a tier that gives the pass back brings both back
      // from the first frame, not half-way through the crossfade.
      final back = ThemeData.lerp(to, from, 0);
      expect(back.surfaceFrost, from.surfaceFrost);
      expect(back.surfaceBodyShade, from.surfaceBodyShade);
    });

    test('a step the other way snaps too', () {
      final from = _folded(quality: CoreQualityTier.solid);
      final to = _folded();
      final start = ThemeData.lerp(from, to, 0);
      expect(start.surfaceBlur, to.surfaceBlur);
      expect(start.surfaceRefraction, to.surfaceRefraction);
    });

    test('themes at the same tier still crossfade', () {
      final from = _folded(style: CoreSurfaceStyleId.defaultStyle);
      final to = _folded();
      final mid = ThemeData.lerp(from, to, 0.5);
      // The blur is a scalar and interpolates when no tier is changing.
      expect(mid.surfaceBlur, isNot(to.surfaceBlur));
    });
  });

  group('a local material goes without what the app goes without', () {
    Future<ThemeData> localGlass(
      WidgetTester tester,
      ThemeData app,
    ) async {
      late ThemeData local;
      await tester.pumpWidget(
        Theme(
          data: app,
          child: Builder(
            builder: (context) {
              local = resolveSurfaceTheme(
                context,
                CoreSurfaceStyleId.liquidGlass,
              );

              return const SizedBox();
            },
          ),
        ),
      );

      return local;
    }

    final opaqueApp = _folded(style: CoreSurfaceStyleId.defaultStyle);

    testWidgets('the top tier keeps the local glass whole', (tester) async {
      final local = await localGlass(tester, opaqueApp);
      expect(local.surfaceRefraction, isNotNull);
      expect(local.surfaceBlur, isNotNull);
    });

    testWidgets('an app without the bend gives the local glass no bend', (
      tester,
    ) async {
      final local = await localGlass(
        tester,
        opaqueApp.copyWith(surfaceQuality: () => CoreQualityTier.noRefraction),
      );
      expect(local.surfaceRefraction, isNull);
      expect(local.surfaceBlur, isNotNull, reason: 'blur stays');
    });

    testWidgets('an app that is solid gives the local glass no pass at all', (
      tester,
    ) async {
      final local = await localGlass(
        tester,
        opaqueApp.copyWith(surfaceQuality: () => CoreQualityTier.solid),
      );
      expect(local.surfaceRefraction, isNull);
      expect(local.surfaceBlur, isNull);
      expect(local.surfaceOpacity, 1);
      expect(local.functionalSurface!.usesTransparency, isFalse);
    });

    testWidgets('a reduce-transparency flag alone does the same', (
      tester,
    ) async {
      final local = await localGlass(
        tester,
        opaqueApp.copyWith(reduceTransparency: () => true),
      );
      expect(local.surfaceBlur, isNull);
      expect(local.surfaceRefraction, isNull);
    });
  });

  group("the host feeds the governor the engine's timings", () {
    setUp(() {
      // A native engine: the bend is drawable, so the ladder has all three
      // rungs. `flutter_tester` answers false to the real query.
      SurfaceRefractionProgram.debugIsShaderFilterSupported = () => true;
    });

    tearDown(() {
      SurfaceRefractionProgram.debugIsShaderFilterSupported = () =>
          ui.ImageFilter.isShaderFilterSupported;
      SurfaceRefractionProgram.debugReset();
    });

    final seen = <ThemeData>[];

    Future<AdaptiveQualityHostState> mount(
      WidgetTester tester, {
      CoreAdaptiveQuality? adaptiveQuality,
      bool reduceTransparency = false,
    }) async {
      seen.clear();
      await tester.pumpWidget(
        CoUIApp(
          theme: ThemeData.fromCore(CoreThemePresets.light),
          surfaceStyle: CoreSurfaceStyleId.liquidGlass,
          adaptiveQuality: adaptiveQuality,
          reduceTransparency: reduceTransparency,
          debugShowCheckedModeBanner: false,
          home: Builder(
            builder: (context) {
              seen.add(Theme.of(context));

              return const Center(
                child: Card(child: SizedBox(width: 120, height: 60)),
              );
            },
          ),
        ),
      );

      // The framework's tween draws the theme it started from on the frame it
      // starts on (a tween at 0 is its `begin`), so a re-mounted app shows its
      // new theme one frame later.
      await tester.pump(_kOneFrame);

      return tester.state<AdaptiveQualityHostState>(
        find.byType(AdaptiveQualityHost),
      );
    }

    ui.FrameTiming timing(int costMicros, int atMicros) => ui.FrameTiming(
      vsyncStart: atMicros - costMicros,
      buildStart: atMicros - costMicros,
      buildFinish: atMicros - costMicros,
      rasterStart: atMicros - costMicros,
      rasterFinish: atMicros,
      rasterFinishWallTime: atMicros,
    );

    /// Hands the engine's callback one frame, the way a batch would arrive.
    void report(WidgetTester tester, int costMicros, int atMicros) {
      tester.platformDispatcher.onReportTimings!([
        timing(costMicros, atMicros),
      ]);
    }

    ThemeData theme() => seen.last;

    SurfaceBlur surface(WidgetTester tester) =>
        tester.widget<SurfaceBlur>(find.byType(SurfaceBlur).first);

    testWidgets('an app that states nothing measures nothing and keeps every '
        'surface whole', (tester) async {
      final host = await mount(tester);
      expect(host.governor, isNull);
      expect(theme().surfaceQuality, CoreQualityTier.full);

      var at = 0;
      for (var i = 0; i < 2000; i++) {
        at += 90000;
        report(tester, 90000, at);
      }
      await tester.pump();
      expect(theme().surfaceQuality, CoreQualityTier.full);
      expect(surface(tester).refraction, isNotNull);
      expect(surface(tester).surfaceBlur, isNotNull);
    });

    testWidgets('the rendered surface hands its renderer what each tier '
        'leaves', (tester) async {
      for (final row in _list(_vectors()['tiers'])) {
        final tier = _tier(row['tier']);
        await mount(
          tester,
          adaptiveQuality: CoreAdaptiveQuality(forced: tier),
        );
        final blur = surface(tester);
        expect(blur.refraction != null, row['refraction'], reason: '$tier');
        expect(
          find.byType(BackdropFilter).evaluate().isNotEmpty,
          row['backdropPass'],
          reason: '$tier mounts a backdrop pass',
        );
        expect(blur.surfaceBlur != null, row['backdropPass'], reason: '$tier');
        expect(theme().surfaceQuality, tier);
      }
    });

    testWidgets('a forced tier is held, nothing is measured, and a new one '
        'moves the surfaces', (tester) async {
      var host = await mount(
        tester,
        adaptiveQuality: const CoreAdaptiveQuality(
          forced: CoreQualityTier.noRefraction,
        ),
      );
      expect(host.governor, isNull);
      expect(theme().surfaceQuality, CoreQualityTier.noRefraction);
      expect(surface(tester).refraction, isNull);

      var at = 0;
      for (var i = 0; i < 1000; i++) {
        at += 90000;
        report(tester, 90000, at);
      }
      await tester.pump();
      expect(theme().surfaceQuality, CoreQualityTier.noRefraction);

      host = await mount(
        tester,
        adaptiveQuality: const CoreAdaptiveQuality(
          forced: CoreQualityTier.solid,
        ),
      );
      expect(theme().surfaceQuality, CoreQualityTier.solid);
      expect(find.byType(BackdropFilter), findsNothing);
    });

    testWidgets('an initial tier is on screen from the first frame', (
      tester,
    ) async {
      final host = await mount(
        tester,
        adaptiveQuality: const CoreAdaptiveQuality(
          initialQuality: CoreQualityTier.noRefraction,
        ),
      );
      expect(theme().surfaceQuality, CoreQualityTier.noRefraction);
      expect(seen.first.surfaceQuality, CoreQualityTier.noRefraction);
      expect(host.governor!.phase, CoreQualityPhase.runtime);
      expect(surface(tester).refraction, isNull);
    });

    testWidgets("the tier is judged against the display's refresh rate", (
      tester,
    ) async {
      tester.view.display.refreshRate = 120;
      addTearDown(tester.view.display.resetRefreshRate);
      final host = await mount(
        tester,
        adaptiveQuality: const CoreAdaptiveQuality(),
      );
      expect(host.governor!.budgetMicros, 8333);

      tester.view.display.refreshRate = 60;
      tester.binding.handleMetricsChanged();
      await tester.pump();
      expect(host.governor!.budgetMicros, 16667);
    });

    testWidgets("a target frame rate overrides the display's", (tester) async {
      tester.view.display.refreshRate = 120;
      addTearDown(tester.view.display.resetRefreshRate);
      final host = await mount(
        tester,
        adaptiveQuality: const CoreAdaptiveQuality(targetFrameRate: 60),
      );
      expect(host.governor!.budgetMicros, 16667);
    });

    group('replays the shared cost traces as FrameTimings', () {
      for (final trace in _list(_vectors()['traces'])) {
        if (trace['metric'] != 'cost') continue;

        testWidgets(trace['name']! as String, (tester) async {
          final rungs = [for (final r in trace['rungs']! as List) _tier(r)];
          // A trace whose ladder has no bend rung is an engine that draws
          // none.
          final bends = rungs.contains(CoreQualityTier.noRefraction);
          SurfaceRefractionProgram.debugIsShaderFilterSupported = () => bends;

          final hz = (trace['refreshHz']! as num).toDouble();
          final budget = CoreFrameBudget.microsFor(hz);
          final changes = <CoreQualityChange>[];
          final host = await mount(
            tester,
            adaptiveQuality: CoreAdaptiveQuality(
              initialQuality: trace['initial'] == null
                  ? null
                  : _tier(trace['initial']),
              allowStepUp: trace['allowStepUp'] != false,
              targetFrameRate: hz,
              onQualityChanged: changes.add,
            ),
          );
          final governor = host.governor!;
          expect(governor.rungs, rungs);
          expect(governor.budgetMicros, budget);

          var frame = 0;
          var at = 0;
          final changedAt = <int>[];
          var last = governor.tier;
          final holds = <CoreQualityHold>[];
          for (final step in _list(trace['steps'])) {
            final event = step['event'] as String?;
            if (event != null) {
              switch (event) {
                case 'hold':
                  holds.add(
                    AdaptiveQualityScope.holdMeasurement(
                      tester.element(find.byType(Card)),
                    ),
                  );
                case 'release':
                  holds.removeLast().release();
                case 'reset':
                  tester.binding
                    ..handleAppLifecycleStateChanged(AppLifecycleState.paused)
                    ..handleAppLifecycleStateChanged(AppLifecycleState.resumed);
                default:
                  fail('event $event');
              }
              continue;
            }
            final pattern = (step['pattern'] as List?)?.cast<num>();
            for (var i = 0; i < (step['frames']! as num).toInt(); i++) {
              final ratio = pattern == null
                  ? (step['ratio']! as num).toDouble()
                  : pattern[i % pattern.length].toDouble();
              frame++;
              final cost = (ratio * budget).round();
              at += cost > budget ? cost : budget;
              report(tester, cost, at);
              if (governor.tier != last) {
                changedAt.add(frame);
                last = governor.tier;
              }
            }
          }
          await tester.pump();
          await tester.pump(_kOneFrame);

          final expected = _list(trace['expect']);
          expect(changedAt, [for (final e in expected) e['frame']]);
          expect(
            [for (final c in changes) (c.from.name, c.to.name, c.reason.name)],
            [for (final e in expected) (e['from'], e['to'], e['reason'])],
            reason: 'onQualityChanged, in order, once the change is on screen',
          );
          expect(governor.tier, _tier(trace['final']));
          expect(theme().surfaceQuality, _tier(trace['final']));
          expect(
            AdaptiveQualityScope.of(tester.element(find.byType(Card))),
            _tier(trace['final']),
          );
        });
      }
    });

    testWidgets('a change reaches the rendered surface within a frame, '
        'exactly and not interpolated', (tester) async {
      final host = await mount(
        tester,
        adaptiveQuality: const CoreAdaptiveQuality(),
      );
      expect(surface(tester).refraction, isNotNull);
      final opacity = theme().surfaceOpacity;
      expect(opacity, lessThan(1));

      // Heavy frames to the warm-up's end: full -> solid in one decision.
      var at = 0;
      for (var i = 0; i < 270; i++) {
        at += 40000;
        report(tester, 40000, at);
      }
      expect(host.governor!.tier, CoreQualityTier.solid);

      // The frame the theme animation starts on still draws the theme it
      // started from (a tween at 0 is its `begin`)...
      await tester.pump();
      // ...and the next draws the new one at once — a sixteenth of the way
      // through the animation, where an interpolated opacity would still be
      // translucent and a blur would still be most of its size.
      await tester.pump(_kOneFrame);
      expect(theme().surfaceQuality, CoreQualityTier.solid);
      expect(theme().surfaceOpacity, 1);
      expect(surface(tester).refraction, isNull);
      expect(surface(tester).surfaceBlur, isNull);
      expect(find.byType(BackdropFilter), findsNothing);
    });

    testWidgets('onQualityChanged hears the change with what it was made on', (
      tester,
    ) async {
      final changes = <CoreQualityChange>[];
      await mount(
        tester,
        adaptiveQuality: CoreAdaptiveQuality(onQualityChanged: changes.add),
      );
      var at = 0;
      for (var i = 0; i < 270; i++) {
        at += 25000;
        report(tester, i < 90 ? 1000 : 25000, at);
      }
      expect(changes, isEmpty, reason: 'after the frame, not during it');
      await tester.pump();
      expect(changes, hasLength(1));
      expect(changes.single.reason, CoreQualityReason.warmup);
      expect(changes.single.to, CoreQualityTier.noRefraction);
      expect(changes.single.percentileMillis, 25);
    });

    group('accessibility and the lifecycle outrank the governor', () {
      testWidgets('reduce transparency is the lowest tier, holds the governor '
          'and starts the warm-up over when it ends', (tester) async {
        final host = await mount(
          tester,
          adaptiveQuality: const CoreAdaptiveQuality(),
          reduceTransparency: true,
        );
        expect(theme().surfaceQuality, CoreQualityTier.solid);
        expect(host.governor!.measurementHeld, isTrue);
        expect(find.byType(BackdropFilter), findsNothing);
        expect(
          AdaptiveQualityScope.of(tester.element(find.byType(Card))),
          CoreQualityTier.solid,
        );

        // Cheap frames while held: nothing is judged.
        var at = 0;
        for (var i = 0; i < 600; i++) {
          at += 16667;
          report(tester, 1000, at);
        }
        expect(host.governor!.tier, CoreQualityTier.full);

        // The preference ends: the surfaces return to the governor's tier and
        // the warm-up starts over.
        await tester.pumpWidget(
          CoUIApp(
            theme: ThemeData.fromCore(CoreThemePresets.light),
            surfaceStyle: CoreSurfaceStyleId.liquidGlass,
            adaptiveQuality: const CoreAdaptiveQuality(),
            debugShowCheckedModeBanner: false,
            home: Builder(
              builder: (context) {
                seen.add(Theme.of(context));

                return const Center(
                  child: Card(child: SizedBox(width: 120, height: 60)),
                );
              },
            ),
          ),
        );
        await tester.pump(_kOneFrame);
        expect(theme().surfaceQuality, CoreQualityTier.full);
        expect(host.governor!.phase, CoreQualityPhase.warmup);
        expect(find.byType(BackdropFilter), findsWidgets);
      });

      testWidgets('high contrast keeps the bend off at the top tier', (
        tester,
      ) async {
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(highContrast: true);
        addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
        );
        await mount(tester, adaptiveQuality: const CoreAdaptiveQuality());
        expect(theme().surfaceQuality, CoreQualityTier.full);
        expect(theme().surfaceRefraction, isNull);
        expect(surface(tester).refraction, isNull);
        expect(surface(tester).surfaceBlur, isNotNull);
      });

      testWidgets('returning from the background starts the warm-up over, '
          'keeping the tier', (tester) async {
        final host = await mount(
          tester,
          adaptiveQuality: const CoreAdaptiveQuality(
            initialQuality: CoreQualityTier.noRefraction,
          ),
        );
        expect(host.governor!.phase, CoreQualityPhase.runtime);

        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        expect(host.governor!.phase, CoreQualityPhase.runtime);
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        expect(host.governor!.phase, CoreQualityPhase.warmup);
        expect(host.governor!.tier, CoreQualityTier.noRefraction);
      });

      testWidgets('a resume that was not preceded by a pause does nothing', (
        tester,
      ) async {
        final host = await mount(
          tester,
          adaptiveQuality: const CoreAdaptiveQuality(
            initialQuality: CoreQualityTier.noRefraction,
          ),
        );
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        expect(host.governor!.phase, CoreQualityPhase.runtime);
      });
    });

    group('the governor survives the app rebuilding', () {
      testWidgets('an inline callback is not a change', (tester) async {
        Future<AdaptiveQualityHostState> app(
          void Function(CoreQualityChange) f,
        ) => mount(
          tester,
          adaptiveQuality: CoreAdaptiveQuality(onQualityChanged: f),
        );
        final host = await app((_) {});
        final first = host.governor;
        await app((_) {});
        expect(host.governor, same(first));
      });

      testWidgets('the callback that is called is the latest one', (
        tester,
      ) async {
        final calls = <String>[];
        await mount(
          tester,
          adaptiveQuality: CoreAdaptiveQuality(
            onQualityChanged: (_) => calls.add('old'),
          ),
        );
        await mount(
          tester,
          adaptiveQuality: CoreAdaptiveQuality(
            onQualityChanged: (_) => calls.add('new'),
          ),
        );
        var at = 0;
        for (var i = 0; i < 270; i++) {
          at += 40000;
          report(tester, 40000, at);
        }
        await tester.pump();
        expect(calls, ['new']);
      });

      testWidgets('other terms are another governor', (tester) async {
        final host = await mount(
          tester,
          adaptiveQuality: const CoreAdaptiveQuality(),
        );
        final first = host.governor;
        await mount(
          tester,
          adaptiveQuality: const CoreAdaptiveQuality(allowStepUp: false),
        );
        expect(host.governor, isNot(same(first)));
        expect(host.governor!.allowStepUp, isFalse);
      });

      testWidgets('turning it off leaves a pass-through, and on again '
          'starts one', (tester) async {
        final host = await mount(
          tester,
          adaptiveQuality: const CoreAdaptiveQuality(
            forced: CoreQualityTier.solid,
          ),
        );
        expect(theme().surfaceQuality, CoreQualityTier.solid);
        await mount(tester);
        expect(host.governor, isNull);
        expect(theme().surfaceQuality, CoreQualityTier.full);
        expect(find.byType(BackdropFilter), findsWidgets);
      });
    });

    group('the app can hold the governor off', () {
      testWidgets('frames under a hold are not judged, and the call needs no '
          'guard where nothing runs', (tester) async {
        final host = await mount(
          tester,
          adaptiveQuality: const CoreAdaptiveQuality(),
        );
        final context = tester.element(find.byType(Card));
        final hold = AdaptiveQualityScope.holdMeasurement(context);
        expect(host.governor!.measurementHeld, isTrue);
        var at = 0;
        for (var i = 0; i < 1000; i++) {
          at += 40000;
          report(tester, 40000, at);
        }
        expect(host.governor!.tier, CoreQualityTier.full);
        hold.release();
        expect(hold.released, isTrue);

        await mount(tester);
        final inert = AdaptiveQualityScope.holdMeasurement(
          tester.element(find.byType(Card)),
        );
        expect(inert.released, isTrue);
        inert.release();
      });
    });

    testWidgets('disposing the app stops listening for timings', (
      tester,
    ) async {
      final host = await mount(
        tester,
        adaptiveQuality: const CoreAdaptiveQuality(),
      );
      final governor = host.governor!;
      await tester.pumpWidget(const SizedBox());
      var at = 0;
      for (var i = 0; i < 300; i++) {
        at += 40000;
        report(tester, 40000, at);
      }
      expect(governor.tier, CoreQualityTier.full);
      expect(governor.phase, CoreQualityPhase.warmup);
    });
  });
}
