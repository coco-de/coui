import 'dart:ui' as ui;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

/// The band as actually rasterised, as a comparable list of pixels.
///
/// Recorded through a real `Canvas` rather than inspected as fields,
/// because the question these tests exist to answer is whether the value
/// moved pixels — a painter can hold the right numbers and draw with the
/// wrong ones. Synchronous `toImage` is safe here only because these are
/// plain `test` cases: inside `testWidgets` the fake-async zone never
/// completes that future and the case dies on a ten-minute timeout that
/// reads like a functional failure rather than a harness one.
Future<List<int>> _paint(SurfaceSheenPainter painter) async {
  const size = ui.Size(40, 40);
  final recorder = ui.PictureRecorder();
  painter.paint(Canvas(recorder), size);

  final image = recorder.endRecording().toImageSync(
    size.width.toInt(),
    size.height.toInt(),
  );
  final bytes = await image.toByteData();
  image.dispose();

  return bytes!.buffer.asUint8List().toList();
}

/// WCAG relative-luminance contrast between two opaque colours.
///
/// Both arguments must already be composited — the formula has no notion
/// of alpha, so handing it a translucent colour silently measures the
/// colour it would be at full strength.
double _contrastRatio(Color a, Color b) {
  final first = a.computeLuminance();
  final second = b.computeLuminance();
  final lighter = first > second ? first : second;
  final darker = first > second ? second : first;

  return (lighter + 0.05) / (darker + 0.05);
}

Future<ThemeData> _themeUnder(
  WidgetTester tester,
  CoreSurfaceStyleId style,
) async {
  late ThemeData seen;
  await tester.pumpWidget(
    CoUIApp(
      theme: ThemeData.fromCore(CoreThemePresets.light),
      surfaceStyle: style,
      home: Builder(
        builder: (context) {
          seen = Theme.of(context);
          return const SizedBox.shrink();
        },
      ),
    ),
  );

  return seen;
}

void main() {
  group('a surface treatment reaches the theme', () {
    testWidgets('glass sets translucency and blur', (tester) async {
      // Both roles carry it: floating surfaces (popovers, sheets) and the
      // page's cards are the same glass under this style.
      final theme = await _themeUnder(tester, CoreSurfaceStyleId.liquidGlass);
      final functional = theme.functionalSurface;

      expect(functional, isNotNull);
      expect(functional!.opacity.isOpaque, isFalse);
      expect(functional.blurRadius, isNotNull);
      expect(functional.blurRadius, greaterThan(0));

      // Two-sided: the content role — the flat theme fields — draws the
      // same material. A preset that quietly made cards opaque again would
      // fail here rather than on a screenshot.
      expect(theme.surfaceOpacity, functional.opacityIn(theme));
      expect(theme.surfaceBlur, functional.blurRadius);
    });

    testWidgets('a style that states no treatment leaves both unset', (
      tester,
    ) async {
      final theme = await _themeUnder(tester, CoreSurfaceStyleId.neoBrutalism);

      expect(theme.surfaceOpacity, isNull);
      expect(theme.surfaceBlur, isNull);
    });

    testWidgets('glass sets the chroma lift and the edge band', (tester) async {
      // The half that makes it read as glass rather than as fog, on both
      // roles — the content role is the same material.
      final theme = await _themeUnder(tester, CoreSurfaceStyleId.liquidGlass);
      final functional = theme.functionalSurface;

      expect(functional, isNotNull);
      expect(
        functional!.saturation,
        greaterThan(CoreSurfaceToken.identitySaturation),
      );
      expect(functional.sheen, isNotNull);

      // Two-sided: the content role lifts the same chroma and wears the
      // same band.
      expect(theme.surfaceSaturation, functional.saturation);
      expect(theme.surfaceSheen, functional.sheen);
    });

    testWidgets('a style with no material states neither', (tester) async {
      final theme = await _themeUnder(tester, CoreSurfaceStyleId.neoBrutalism);

      expect(theme.surfaceSaturation, isNull);
      expect(theme.surfaceSheen, isNull);
    });

    testWidgets('the other seat agrees with the style seat', (tester) async {
      // Two ways in: `surfaceStyle:` and a `defaultSurface` token on the
      // core theme. Wiring only the first leaves an app that sets the
      // token blurring without saturating — same recipe, different glass,
      // and nothing says which one is wrong.
      const recipeId = CoreSurfaceStyleId.liquidGlass;
      final viaStyle = await _themeUnder(tester, recipeId);
      final token = CoreSurfaceRecipe.of(recipeId).surface;

      final viaToken = ThemeData.fromCore(
        CoreThemePresets.light.copyWith(defaultSurface: token),
      );

      expect(viaToken.surfaceSaturation, viaStyle.surfaceSaturation);
      expect(viaToken.surfaceSheen, viaStyle.surfaceSheen);

      // The functional role is the one that actually varies with glass —
      // `defaultSurface:` has no lever for it, so this only pins that
      // `surfaceStyle:` still sets a real (non-identity) value there. The
      // content-role check above is otherwise comparing two identity
      // values and would not catch a broken `surfaceStyle:` path.
      expect(viaStyle.functionalSurface, isNotNull);
      expect(
        viaStyle.functionalSurface!.saturation,
        greaterThan(CoreSurfaceToken.identitySaturation),
      );
    });
  });

  group('the material survives the value-equality gate', () {
    test('two themes differing only in saturation are not equal', () {
      // A field left out of `==` makes the axis compute correctly and
      // change nothing on screen, because the framework never rebuilds.
      // That failure leaves no trace in a screenshot.
      const a = ThemeData(surfaceSaturation: 1);
      const b = ThemeData(surfaceSaturation: 1.3);

      expect(a, isNot(b));
      expect(a.hashCode, isNot(b.hashCode));
    });

    test('and neither are two differing only in the band', () {
      const sheen = CoreSurfaceEdgeSheen(
        width: 1,
        lightColor: CoreColor.token(CoreColors.surfaceHighlight),
        darkColor: CoreColor.token(CoreColors.scrim),
      );
      const a = ThemeData();
      const b = ThemeData(surfaceSheen: sheen);

      expect(a, isNot(b));
      expect(a.hashCode, isNot(b.hashCode));
    });

    test('the band compares by value, not by identity', () {
      // Two equal bands built separately must compare equal, or every
      // rebuild looks like a change and the theme animates forever.
      const one = CoreSurfaceEdgeSheen(
        width: 1,
        lightColor: CoreColor.token(CoreColors.surfaceHighlight),
        darkColor: CoreColor.token(CoreColors.scrim),
      );
      const other = CoreSurfaceEdgeSheen(
        width: 1,
        lightColor: CoreColor.token(CoreColors.surfaceHighlight),
        darkColor: CoreColor.token(CoreColors.scrim),
      );

      expect(one, other);
      expect(one.hashCode, other.hashCode);
    });
  });

  group('the band keeps its sense across modes', () {
    /// Below this a run is not subtle, it is absent. Colours pinned to one
    /// end of the scale land at 1.02 and 1.13 against the surface that
    /// shares their end, which is what this floor exists to catch.
    const runVisibilityMinimum = 1.2;

    for (final mode in const ['light', 'dark']) {
      test('in $mode, each run is visible against the surface it lies on', () {
        // The band is drawn *on* the surface, so what decides whether it
        // reads is the run composited over that surface — not the token
        // it came from, which is opaque and always looks like plenty.
        final core = mode == 'dark'
            ? CoreThemePresets.dark
            : CoreThemePresets.light;
        final scheme = ThemeData.fromCore(core).colorScheme;
        final sheen = CoreSurfaceRecipe.of(
          CoreSurfaceStyleId.liquidGlass,
        ).functionalSurface!.sheen!;
        final surface = scheme
            .resolve(const CoreColor.token(CoreColors.surface))
            .toValue();

        for (final run in [sheen.lightColor, sheen.darkColor]) {
          final seen = Color.alphaBlend(scheme.resolve(run).toValue(), surface);

          expect(
            _contrastRatio(seen, surface),
            greaterThanOrEqualTo(runVisibilityMinimum),
            reason: 'a run that cannot be seen is half the treatment',
          );
        }
      });

      test('in $mode, the vertical run is the heavier of the two', () {
        // What makes this a band rather than an outline. Both runs step
        // away from the surface; the assertion is that they step by
        // different amounts, and that the *same* one leads in both modes —
        // otherwise the band's character changes with the theme.
        final core = mode == 'dark'
            ? CoreThemePresets.dark
            : CoreThemePresets.light;
        final scheme = ThemeData.fromCore(core).colorScheme;
        final sheen = CoreSurfaceRecipe.of(
          CoreSurfaceStyleId.liquidGlass,
        ).functionalSurface!.sheen!;
        final surface = scheme
            .resolve(const CoreColor.token(CoreColors.surface))
            .toValue();

        double distance(CoreColor run) => _contrastRatio(
          Color.alphaBlend(scheme.resolve(run).toValue(), surface),
          surface,
        );

        expect(
          distance(sheen.darkColor),
          greaterThan(distance(sheen.lightColor)),
          reason: 'equal weights read as a uniform outline',
        );
      });
    }

    test('resolving the band throws on neither mode', () {
      // A band drawn in a slot no palette fills would throw here: the
      // reader has no derived fallback, so the app dies at the first
      // glass surface rather than merely looking wrong.
      final sheen = CoreSurfaceRecipe.of(
        CoreSurfaceStyleId.liquidGlass,
      ).functionalSurface!.sheen!;

      for (final preset in [CoreThemePresets.light, CoreThemePresets.dark]) {
        final scheme = ThemeData.fromCore(preset).colorScheme;

        expect(
          () => scheme.resolve(sheen.lightColor).toValue(),
          returnsNormally,
        );
        expect(
          () => scheme.resolve(sheen.darkColor).toValue(),
          returnsNormally,
        );
      }
    });
  });

  group('it reaches the shared surface primitive', () {
    testWidgets('the primitive picks up the theme treatment', (tester) async {
      // Until now only one component read the theme's material, while the
      // Web resolver had always read it — so a theme-wide treatment reached
      // one platform. This is the parity check. `role: .functional`
      // because that is the role liquidGlass actually treats now — the
      // primitive's default role (content) draws flat under this style.
      late ResolvedOutlinedContainer resolved;

      await tester.pumpWidget(
        CoUIApp(
          theme: ThemeData.fromCore(CoreThemePresets.light),
          surfaceStyle: CoreSurfaceStyleId.liquidGlass,
          home: Builder(
            builder: (context) {
              resolved = resolveOutlinedContainer(
                context,
                role: CoreSurfaceRole.functional,
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(resolved.surfaceBlur, isNotNull);
      expect(resolved.surfaceBlur, greaterThan(0));
    });

    testWidgets('an explicit style slot still wins over the theme', (
      tester,
    ) async {
      late ResolvedOutlinedContainer resolved;

      await tester.pumpWidget(
        CoUIApp(
          theme: ThemeData.fromCore(CoreThemePresets.light),
          surfaceStyle: CoreSurfaceStyleId.liquidGlass,
          home: Builder(
            builder: (context) {
              resolved = resolveOutlinedContainer(
                context,
                containerStyle: const CoreOutlinedContainerStyle(
                  surfaceBlur: 0,
                ),
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(resolved.surfaceBlur, 0);
    });
  });

  group('and it reaches the pixels', () {
    testWidgets('the backdrop composes the chroma lift onto the blur', (
      tester,
    ) async {
      // The layer the guard cannot see. `check_axis_field_consumed.sh`
      // reports `saturation` as read because an unrelated
      // `accent.saturation` (an HSVColor property) carries the same name
      // — so the wiring can be deleted with CI still green, and only a
      // filter read back off the tree says otherwise.
      await tester.pumpWidget(
        CoUIApp(
          theme: ThemeData.fromCore(CoreThemePresets.light),
          surfaceStyle: CoreSurfaceStyleId.liquidGlass,
          home: const OutlinedContainer(
            role: CoreSurfaceRole.functional,
            child: SizedBox(width: 40, height: 40),
          ),
        ),
      );

      final filters = tester
          .widgetList<BackdropFilter>(find.byType(BackdropFilter))
          .map((w) => w.filter.toString())
          .toList();

      expect(filters, isNotEmpty, reason: 'the surface must blur at all');
      expect(
        filters.any((f) => f.contains('ColorFilter.matrix')),
        isTrue,
        reason: 'a plain blur means the chroma lift was dropped',
      );
    });

    testWidgets('a style with no material composes nothing', (tester) async {
      await tester.pumpWidget(
        CoUIApp(
          theme: ThemeData.fromCore(CoreThemePresets.light),
          surfaceStyle: CoreSurfaceStyleId.neoBrutalism,
          home: const OutlinedContainer(child: SizedBox(width: 40, height: 40)),
        ),
      );

      final filters = tester
          .widgetList<BackdropFilter>(find.byType(BackdropFilter))
          .map((w) => w.filter.toString());

      expect(filters.any((f) => f.contains('ColorFilter.matrix')), isFalse);
    });

    testWidgets('the band is attached to the surface', (tester) async {
      await tester.pumpWidget(
        CoUIApp(
          theme: ThemeData.fromCore(CoreThemePresets.light),
          surfaceStyle: CoreSurfaceStyleId.liquidGlass,
          home: const OutlinedContainer(
            role: CoreSurfaceRole.functional,
            child: SizedBox(width: 40, height: 40),
          ),
        ),
      );

      expect(
        tester
            .widgetList<CustomPaint>(find.byType(CustomPaint))
            .any((w) => w.foregroundPainter is SurfaceSheenPainter),
        isTrue,
      );
    });

    testWidgets('the edge wall is drawn, on a surface that casts nothing', (
      tester,
    ) async {
      // The load-bearing half. `highlightRim` uses the same mechanism and
      // would have been the obvious home for this, but its resolver
      // returns nothing when the component authored no shadow — and a
      // plain `OutlinedContainer` authors none. Routed that way the wall
      // would appear on dialogs and vanish on cards.
      //
      // So this asserts both things at once: that the wall is drawn, and
      // that the surface under it really is one with no shadow stack.
      await tester.pumpWidget(
        CoUIApp(
          theme: ThemeData.fromCore(CoreThemePresets.light),
          surfaceStyle: CoreSurfaceStyleId.liquidGlass,
          home: const OutlinedContainer(
            role: CoreSurfaceRole.functional,
            child: SizedBox(width: 40, height: 40),
          ),
        ),
      );

      final decorations = tester
          .widgetList<DecoratedBox>(find.byType(DecoratedBox))
          .map((w) => w.decoration)
          .whereType<BoxDecoration>();
      expect(
        decorations.every((d) => (d.boxShadow ?? const []).isEmpty),
        isTrue,
        reason:
            'the premise is gone — this surface now casts, so a rim '
            'would have reached it and the test proves nothing',
      );

      final walls = tester
          .widgetList<InsetShadow>(find.byType(InsetShadow))
          .where((w) => w.shadows.isNotEmpty)
          .toList();

      expect(walls, isNotEmpty, reason: 'the wall never reached the surface');
      expect(
        walls.first.shadows.every((s) => s.color.a > 0),
        isTrue,
        reason: 'a fully transparent wall draws nothing',
      );
    });

    testWidgets('a style with no wall draws none', (tester) async {
      // Otherwise "the wall is drawn" could be satisfied by a widget that
      // is always in the tree with layers that are always non-empty.
      await tester.pumpWidget(
        CoUIApp(
          theme: ThemeData.fromCore(CoreThemePresets.light),
          surfaceStyle: CoreSurfaceStyleId.neoBrutalism,
          home: const OutlinedContainer(child: SizedBox(width: 40, height: 40)),
        ),
      );

      expect(
        tester
            .widgetList<InsetShadow>(find.byType(InsetShadow))
            .any((w) => w.shadows.isNotEmpty),
        isFalse,
      );
    });

    test('the band width reaches its geometry', () async {
      // Width and fade are the two fields the name-grep guard is blind
      // to — `width` collides with unrelated fields on three other Core
      // types, `fade` with two more. Reading the drawn result back is
      // the only thing that fails when the wiring is cut.
      const base = SurfaceSheenPainter(
        radius: BorderRadius.zero,
        width: 1,
        lightColor: Color(0xFFFFFFFF),
        darkColor: Color(0xFF000000),
        fade: 0.18,
      );
      const wider = SurfaceSheenPainter(
        radius: BorderRadius.zero,
        width: 4,
        lightColor: Color(0xFFFFFFFF),
        darkColor: Color(0xFF000000),
        fade: 0.18,
      );

      expect(base.shouldRepaint(wider), isTrue);
      expect(await _paint(base), isNot(await _paint(wider)));
    });

    test('and so does its fade', () async {
      const base = SurfaceSheenPainter(
        radius: BorderRadius.zero,
        width: 2,
        lightColor: Color(0xFFFFFFFF),
        darkColor: Color(0xFF000000),
        fade: 0.05,
      );
      const softer = SurfaceSheenPainter(
        radius: BorderRadius.zero,
        width: 2,
        lightColor: Color(0xFFFFFFFF),
        darkColor: Color(0xFF000000),
        fade: 0.45,
      );

      expect(base.shouldRepaint(softer), isTrue);
      expect(await _paint(base), isNot(await _paint(softer)));
    });

    test('an out-of-range fade is clamped, not asserted', () {
      // A theme is data and data arrives from places an assertion cannot
      // reach. Both platforms clamp through `effectiveFade` so they
      // cannot disagree about what an out-of-range theme means.
      const sheen = CoreSurfaceEdgeSheen(
        width: 1,
        lightColor: CoreColor.token(CoreColors.surfaceHighlight),
        darkColor: CoreColor.token(CoreColors.scrim),
        fade: 0.9,
      );

      expect(sheen.effectiveFade, 0.5);
    });
  });

  group('the material reaches every surface that claims to be one', () {
    // Reach is read back per surface rather than listed anywhere. A list
    // goes stale the moment a component is added and nothing fails, and
    // `check_axis_field_consumed.sh` cannot help — it greps field names, so
    // it sees the axis is read *somewhere* and never which surface reads it.

    Future<T> underGlass<T>(
      WidgetTester tester,
      T Function(BuildContext context) resolve,
    ) async {
      late T out;
      await tester.pumpWidget(
        CoUIApp(
          theme: ThemeData.fromCore(CoreThemePresets.light),
          surfaceStyle: CoreSurfaceStyleId.liquidGlass,
          home: Builder(
            builder: (context) {
              out = resolve(context);

              return const SizedBox.shrink();
            },
          ),
        ),
      );

      return out;
    }

    testWidgets('the popup panel resolves a material', (tester) async {
      final resolved = await underGlass(tester, resolvePopup);

      expect(resolved.surfaceBlur, isNotNull);
      expect(resolved.surfaceBlur, greaterThan(0));
      expect(resolved.surfaceSheen, isNotNull);
    });

    testWidgets('and the panel is actually wrapped in it', (tester) async {
      // The resolver reading the axis is half of reach; a widget that never
      // wraps the surface would still pass the test above.
      await tester.pumpWidget(
        CoUIApp(
          theme: ThemeData.fromCore(CoreThemePresets.light),
          surfaceStyle: CoreSurfaceStyleId.liquidGlass,
          home: const Popup(children: [SizedBox(width: 40, height: 20)]),
        ),
      );

      expect(
        find.descendant(
          of: find.byType(Popup),
          matching: find.byType(SurfaceBlur),
        ),
        findsOneWidget,
      );
    });

    testWidgets('and the panel it wraps actually bends', (tester) async {
      // Frost without bend is a blurred panel, not glass — and the bend
      // is the term the material is named for. It shipped reaching
      // exactly one surface: `OutlinedContainer` passed it and the other
      // thirteen did not, so a card bent and the context menu that
      // opened over it did not.
      //
      // Read off the wrapper rather than off the painted filter on
      // purpose: the displacement runs through `ImageFilter.shader`,
      // which the test engine reports as unsupported, so the shader is
      // absent from the filter for a reason that has nothing to do with
      // whether the request arrived. The request is the thing this
      // component owes.
      await tester.pumpWidget(
        CoUIApp(
          theme: ThemeData.fromCore(CoreThemePresets.light),
          surfaceStyle: CoreSurfaceStyleId.liquidGlass,
          home: const Popup(children: [SizedBox(width: 40, height: 20)]),
        ),
      );

      final blur = tester.widget<SurfaceBlur>(
        find.descendant(
          of: find.byType(Popup),
          matching: find.byType(SurfaceBlur),
        ),
      );

      expect(
        blur.refraction,
        isNotNull,
        reason: 'the panel frosts but never bends',
      );
      expect(
        blur.refraction,
        CoreSurfaceRecipe.of(.liquidGlass).refraction,
        reason: 'it bends by something other than what the style states',
      );
    });

    testWidgets('a style that states no bend asks for none', (tester) async {
      await tester.pumpWidget(
        CoUIApp(
          theme: ThemeData.fromCore(CoreThemePresets.light),
          surfaceStyle: CoreSurfaceStyleId.neoBrutalism,
          home: const Popup(children: [SizedBox(width: 40, height: 20)]),
        ),
      );

      for (final w in tester.widgetList<SurfaceBlur>(
        find.byType(SurfaceBlur),
      )) {
        expect(w.refraction, isNull);
      }
    });

    testWidgets('a panel that states no fill gets none of it', (tester) async {
      // The nested-submenu shape: a `Popup` whose style states a transparent
      // background so it reads as a group inside its parent's panel. Giving
      // that one a material stacks a backdrop pass inside the one already
      // running and squares a band around an indented group.
      final resolved = await underGlass(
        tester,
        (context) => resolvePopup(
          context,
          popupStyle: const CorePopupStyle(
            backgroundColor: CoreColor.transparent,
          ),
        ),
      );

      expect(resolved.surfaceBlur, isNull);
      expect(resolved.surfaceSheen, isNull);
    });

    testWidgets('the scaffold header resolves a material', (tester) async {
      final resolved = await underGlass(
        tester,
        (context) => resolveScaffold(
          context,
          variant: CoreScaffoldVariant.defaultVariant,
        ),
      );

      expect(resolved.surfaceBlur, isNotNull);
      expect(resolved.surfaceBlur, greaterThan(0));
      expect(resolved.surfaceSheen, isNotNull);
    });

    testWidgets('and the header is actually wrapped in it', (tester) async {
      // The header fixture is deliberately plain. A `Card` here would pass
      // this test with the header wiring deleted, because `Card` composes
      // `OutlinedContainer`, which wraps a `SurfaceBlur` of its own —
      // `findsOneWidget` is load-bearing for the same reason.
      await tester.pumpWidget(
        CoUIApp(
          theme: ThemeData.fromCore(CoreThemePresets.light),
          surfaceStyle: CoreSurfaceStyleId.liquidGlass,
          home: const Scaffold(
            headers: [SizedBox(height: 40)],
            child: SizedBox.shrink(),
          ),
        ),
      );

      expect(
        find.descendant(
          of: find.byType(Scaffold),
          matching: find.byType(SurfaceBlur),
        ),
        findsOneWidget,
      );
    });

    testWidgets('the default style wraps nothing', (tester) async {
      // Without this the two tests above would pass on a widget that always
      // wraps, which would put a backdrop pass under every app that never
      // asked for one.
      await tester.pumpWidget(
        CoUIApp(
          theme: ThemeData.fromCore(CoreThemePresets.light),
          home: const Scaffold(
            headers: [SizedBox(height: 40)],
            child: SizedBox.shrink(),
          ),
        ),
      );

      expect(find.byType(SurfaceBlur), findsNothing);
    });
  });

  group('an app can tune the material it turned on', () {
    testWidgets('the values it states reach the theme', (tester) async {
      // The preset is the default answer, not the only one. Without this an
      // app's only route to a different glass is a fork. Tuning follows
      // the material to every role made of it — under liquidGlass that is
      // both, so a tuned frost reaches the cards and the popovers alike.
      late ThemeData seen;
      await tester.pumpWidget(
        CoUIApp(
          theme: ThemeData.fromCore(CoreThemePresets.light),
          surfaceStyle: CoreSurfaceStyleId.liquidGlass,
          // 0.7, which matches neither mode of the shipped fill (0.5 / 0.6):
          // a fixture equal to one of them would pass on a tuning that
          // never applied.
          surfaceTuning: const CoreSurfaceTuning(
            surfaceOpacity: 0.7,
            surfaceBlur: 32,
            surfaceSaturation: 1.6,
          ),
          home: Builder(
            builder: (context) {
              seen = Theme.of(context);

              return const SizedBox.shrink();
            },
          ),
        ),
      );

      final functional = seen.functionalSurface;
      expect(functional, isNotNull);
      expect(functional!.opacity, const CoreSurfaceOpacity.same(0.7));
      expect(functional.blurRadius, 32);
      expect(functional.saturation, 1.6);

      // Two-sided: the content role is the same glass, so the flat fields
      // move with it. A fold that followed one role would leave a card at
      // the preset's frost beside a retuned popover.
      expect(seen.surfaceOpacity, 0.7);
      expect(seen.surfaceBlur, 32);
    });

    testWidgets('and reach the surface that paints them', (tester) async {
      // Theme reach and paint reach are different questions — a value can
      // sit on `ThemeData` and never be read by the resolver that draws.
      late ResolvedOutlinedContainer resolved;
      await tester.pumpWidget(
        CoUIApp(
          theme: ThemeData.fromCore(CoreThemePresets.light),
          surfaceStyle: CoreSurfaceStyleId.liquidGlass,
          surfaceTuning: const CoreSurfaceTuning(surfaceBlur: 32),
          home: Builder(
            builder: (context) {
              resolved = resolveOutlinedContainer(
                context,
                role: CoreSurfaceRole.functional,
              );

              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(resolved.surfaceBlur, 32);
    });

    testWidgets('an untuned app is left exactly as it was', (tester) async {
      final tuned = await _themeUnder(tester, CoreSurfaceStyleId.liquidGlass);
      final recipe = CoreSurfaceRecipe.of(CoreSurfaceStyleId.liquidGlass);
      final preset = recipe.surface!;
      final presetFunctional = recipe.functionalSurface!;

      expect(
        tuned.surfaceOpacity,
        preset.opacity.resolve(CoreBrightness.light),
      );
      expect(tuned.surfaceBlur, preset.blurRadius);
      expect(tuned.surfaceSaturation, preset.saturation);
      expect(tuned.surfaceSheen, preset.sheen);

      // The content-role fields above are all identity for this preset
      // (flat), so they alone would pass under a broken untuned path too.
      // The functional role is where the preset actually differs from
      // identity, so pin it too.
      expect(tuned.functionalSurface, isNotNull);
      expect(tuned.functionalSurface!.opacity, presetFunctional.opacity);
      expect(tuned.functionalSurface!.blurRadius, presetFunctional.blurRadius);
      expect(
        tuned.functionalSurface!.saturation,
        presetFunctional.saturation,
      );
    });
  });

  group('the band is the boundary, so the stroke steps aside', () {
    // `role: .functional` throughout this group — the band, and the
    // suppression it triggers, is a functional-role treatment under
    // liquidGlass now; the container's default role (content) draws flat
    // and suppresses nothing (#4424).
    Future<ResolvedOutlinedContainer> resolveUnderGlass(
      WidgetTester tester, {
      bool highContrast = false,
    }) async {
      late ResolvedOutlinedContainer resolved;
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(highContrast: highContrast),
          child: CoUIApp(
            theme: ThemeData.fromCore(CoreThemePresets.light),
            surfaceStyle: CoreSurfaceStyleId.liquidGlass,
            home: Builder(
              builder: (context) {
                resolved = resolveOutlinedContainer(
                  context,
                  role: CoreSurfaceRole.functional,
                );
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      return resolved;
    }

    testWidgets('the stroke goes transparent and keeps its box', (
      tester,
    ) async {
      final resolved = await resolveUnderGlass(tester);

      expect(resolved.surfaceSheen, isNotNull, reason: 'band is present');
      expect(resolved.borderColor.a, 0, reason: 'and the stroke is not');
      // Load-bearing, and the tripwire for anyone who "simplifies" the
      // suppression to a zero width. Flutter collapses a transparent
      // border's width, so reading the *suppressed* colour instead of the
      // authored one would turn a paint change into 1px per side — while
      // Web, which only overrides the colour, kept its box. Nothing else
      // in either suite measures that 2px.
      expect(
        resolved.borderWidth,
        greaterThan(0),
        reason: 'the box is what high contrast hands back',
      );
    });

    testWidgets('and high contrast hands the stroke back', (tester) async {
      final resolved = await resolveUnderGlass(tester, highContrast: true);

      // Flutter has no forced-colours mode, so this gate is the mirror of
      // the Web rule that restores the edge under `forced-colors` and
      // `prefers-contrast`. Same guarantee, each platform's own signal.
      expect(resolved.borderColor.a, greaterThan(0));
      expect(resolved.surfaceBlur, greaterThan(0), reason: 'material stays');
    });

    testWidgets('and it reaches Popup, not just the container', (
      tester,
    ) async {
      // The gap this closes was real: the suppression lived inside
      // `resolveOutlinedContainer`, and `Popup` resolves its own stroke —
      // so the panel behind every popover and menu kept a border the card
      // beside it had lost. Two surfaces, one material, two answers.
      late ResolvedPopup resolved;
      await tester.pumpWidget(
        CoUIApp(
          theme: ThemeData.fromCore(CoreThemePresets.light),
          surfaceStyle: CoreSurfaceStyleId.liquidGlass,
          home: Builder(
            builder: (context) {
              resolved = resolvePopup(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(resolved.borderColor.a, 0);
    });

    test('the style declares the boundary it actually has', () {
      final recipe = CoreSurfaceRecipe.of(CoreSurfaceStyleId.liquidGlass);

      // The band is a gradient, which forced colours erases — so the
      // contract may not claim a stroke, and owes the fallback instead.
      // The functional role is the one that draws the band under this
      // preset now; content draws flat and claims no edge of its own.
      expect(recipe.functionalSurface?.drawsOwnEdge, isTrue);
      expect(
        recipe.a11y.boundaryMechanism,
        CoreSurfaceBoundaryMechanism.shadow,
      );
      expect(recipe.a11y.forcedColorsBoundary, isNotNull);
    });
  });

  group('the focus ring stays readable next to the band', () {
    // G1 re-judged because this unit changed its premise. The ring sits
    // just outside the surface edge; the band now sits just inside it, on
    // the same radius. If the two read as one thing, the preset has a
    // focus indicator that looks like part of the frame.
    //
    // Measured at 3:1 — WCAG 1.4.11 non-text contrast, the same floor
    // `tool/check_contrast.dart` holds component boundaries to. Values with
    // CoUI's fixed palette (`CouiColorPresets.source`):
    //
    //            ring↔horizontal   ring↔vertical
    //   light         8.54              7.59
    //   dark         13.01             11.05
    //
    // The ring is `primary/800` in light and `neutral/100` in dark, so it
    // stands far from both runs. A run dark enough to approach it
    // would no longer be a subtle band, which is why this stays a floor
    // to hold rather than the constraint that picks the band's colours —
    // that is the runs' own visibility, judged in the group above.
    const nonTextMinimum = 3.0;

    for (final mode in const ['light', 'dark']) {
      test('in $mode, both runs stay clear of the ring', () {
        final core = mode == 'dark'
            ? CoreThemePresets.dark
            : CoreThemePresets.light;
        final scheme = ThemeData.fromCore(core).colorScheme;
        final sheen = CoreSurfaceRecipe.of(
          CoreSurfaceStyleId.liquidGlass,
        ).functionalSurface!.sheen!;

        final ring = scheme
            .resolve(CoreFocusOutlineStyle.defaultBorderColor)
            .toValue();
        // The runs are translucent, so compare what is actually seen —
        // each composited over the surface it lies on. Comparing the raw
        // token would flatter the lit run, which is pure white before it
        // is laid down at 30%.
        final surface = scheme
            .resolve(const CoreColor.token(CoreColors.surface))
            .toValue();

        for (final run in [sheen.lightColor, sheen.darkColor]) {
          final seen = Color.alphaBlend(scheme.resolve(run).toValue(), surface);

          expect(
            _contrastRatio(ring, seen),
            greaterThanOrEqualTo(nonTextMinimum),
            reason: 'the ring must not read as part of the band',
          );
        }
      });
    }
  });

  group('the styles that flatten or soften', () {
    testWidgets('neumorphism puts component surfaces on the page colour', (
      tester,
    ) async {
      // Its whole look: the only thing separating a control from the page is
      // the shadow. The a11y contract carries what that costs.
      final theme = await _themeUnder(tester, CoreSurfaceStyleId.neumorphism);

      expect(theme.colorScheme.surfaceContainer, theme.colorScheme.surface);
      expect(
        theme.colorScheme.surfaceContainerHighest,
        isNot(theme.colorScheme.surface),
        reason: 'something must still differentiate',
      );
    });

    testWidgets('claymorphism states only a softer cast', (tester) async {
      // Pastel accents were measured to drop the worst accent pair under
      // 4.5:1 at every setting, so this style deliberately makes no colour
      // statement at all.
      final theme = await _themeUnder(tester, CoreSurfaceStyleId.claymorphism);
      final authored = ThemeData.fromCore(CoreThemePresets.light);

      expect(theme.colorScheme.primary, authored.colorScheme.primary);
      expect(
        CoreSurfaceRecipe.of(
          CoreSurfaceStyleId.claymorphism,
        ).geometry.shadowBlurScale,
        greaterThan(1),
      );
    });
  });

  group('the backdrop dims as well as amplifies', () {
    test('the matrix scales the colour rows and leaves alpha alone', () {
      // Brightness is `diag(b, b, b, 1)` multiplied on the left of the
      // saturation matrix, which is exactly "scale the three colour rows
      // by b". Alpha is untouched: dimming a backdrop must not make it
      // more transparent, and a matrix that scaled row four would do
      // precisely that.
      final plain = backdropColorMatrix(saturation: 1.6, brightness: 1);
      final dim = backdropColorMatrix(saturation: 1.6, brightness: 0.25);

      for (var i = 0; i < 15; i++) {
        expect(dim[i], closeTo(plain[i] * 0.25, 1e-12), reason: 'index $i');
      }
      expect(dim.sublist(15), plain.sublist(15));
    });

    test('identity on both scalars is the identity matrix', () {
      expect(
        backdropColorMatrix(saturation: 1, brightness: 1),
        <double>[
          1, 0, 0, 0, 0, //
          0, 1, 0, 0, 0, //
          0, 0, 1, 0, 0, //
          0, 0, 0, 1, 0, //
        ],
      );
    });

    test('the dimming lands after the lift, not before', () {
      // The two do not commute — the saturation matrix has cross terms,
      // so scaling before it feeds different values into those terms
      // than scaling after. This pins the order the Web's
      // `saturate(s) brightness(b)` list produces, which is the only
      // reason the two platforms show the same pixels.
      const s = 1.6;
      const b = 0.25;
      final after = backdropColorMatrix(saturation: s, brightness: b);

      // Brightness-first would be `saturate(dim(x))`: the luminance
      // weights would act on already-scaled channels, which for a linear
      // scale happens to give the same product — so the distinguishing
      // term is the diagonal, where `(inv + s) * b` differs from
      // `inv + s * b`.
      const lumR = 0.213;
      const invR = lumR * (1 - s);
      expect(after[0], closeTo((invR + s) * b, 1e-12));
      expect(after[0], isNot(closeTo(invR + s * b, 1e-12)));
    });

    testWidgets('and the surface actually draws with it', (tester) async {
      // The read-back the guard cannot do. `check_axis_field_consumed.sh`
      // proves something *reads* the field; only the matrix pulled off
      // the rendered tree proves the read reached the paint.
      //
      // One pump per case, deliberately. An earlier version of this test
      // pumped twice inside one body and compared the two filters — and
      // passed a dimmed surface while reporting the undimmed matrix,
      // because the second pump handed the same `const` child back and
      // the subtree was never rebuilt. A differential that cannot tell
      // "unchanged" from "not recomputed" is not a differential.
      await tester.pumpWidget(
        CoUIApp(
          theme: ThemeData.fromCore(CoreThemePresets.light).copyWith(
            surfaceBlur: () => 12,
            surfaceSaturation: () => 1.6,
            surfaceBackdropBrightness: () => 0.25,
          ),
          home: const OutlinedContainer(child: SizedBox(width: 40, height: 40)),
        ),
      );

      final painted = tester
          .widget<BackdropFilter>(find.byType(BackdropFilter).first)
          .filter
          .toString();

      // Derived, not pinned: the claim is that the surface paints the
      // matrix this pair produces, not that the pair produces some
      // particular number.
      final expected = backdropColorMatrix(saturation: 1.6, brightness: 0.25);
      final undimmed = backdropColorMatrix(saturation: 1.6, brightness: 1);

      expect(painted, contains('${expected.first}'));
      expect(
        painted,
        isNot(contains('${undimmed.first}')),
        reason:
            'the surface painted the undimmed matrix — the term was '
            'computed and dropped somewhere between theme and paint',
      );
    });

    testWidgets('a surface that dims nothing pays for no extra pass', (
      tester,
    ) async {
      // Identity has to take the plain-blur branch. Composing an identity
      // matrix is a second render pass on every surface in the default
      // style, spent to multiply by one.
      await tester.pumpWidget(
        CoUIApp(
          theme: ThemeData.fromCore(CoreThemePresets.light).copyWith(
            surfaceBlur: () => 12,
            surfaceBackdropBrightness: () => 1,
          ),
          home: const OutlinedContainer(child: SizedBox(width: 40, height: 40)),
        ),
      );

      final filters = tester
          .widgetList<BackdropFilter>(find.byType(BackdropFilter))
          .map((w) => w.filter.toString());

      expect(filters.any((f) => f.contains('ColorFilter.matrix')), isFalse);
    });

    testWidgets('the recipe value reaches the theme seat', (tester) async {
      // The seat resolves the authored pair for the mode it is building
      // for, so what lands on the theme is a number and the comparison
      // has to say which half it expects.
      final seen = await _themeUnder(tester, CoreSurfaceStyleId.liquidGlass);

      expect(
        seen.surfaceBackdropBrightness,
        CoreSurfaceRecipe.of(
          .liquidGlass,
        ).surface!.backdropBrightness.resolve(seen.coreBrightness),
      );
    });

    test('and it is the half that belongs to the mode', () {
      // The property the pair exists for. A brightness that resolved the
      // same in both modes would satisfy every other assertion in this
      // file — the field would be read, the fold would run, the filter
      // would be emitted — and the material would still be wrong on one
      // side of the palette.
      //
      // Asserted on the fold rather than through a pumped app: `CoUIApp`
      // cross-fades between themes, so pumping a second one and reading it
      // on the next frame reads a theme still interpolating from the
      // first. The fold is the seat under test and it is pure.
      final stated = CoreSurfaceRecipe.of(
        .liquidGlass,
      ).surfaceFor(.functional)!.backdropBrightness;

      final themes = {
        CoreBrightness.light: applySurfaceStyle(
          ThemeData.fromCore(CoreThemePresets.light),
          surfaceStyle: CoreSurfaceStyleId.liquidGlass,
          highContrast: false,
        ),
        CoreBrightness.dark: applySurfaceStyle(
          ThemeData.fromCore(CoreThemePresets.dark),
          surfaceStyle: CoreSurfaceStyleId.liquidGlass,
          highContrast: false,
        ),
      };

      for (final entry in themes.entries) {
        final theme = entry.value;

        expect(theme.coreBrightness, entry.key);
        expect(
          theme.surfaceFor(.functional)!.backdropBrightnessIn(theme),
          stated.resolve(entry.key),
          reason:
              '${entry.key.name} took the other half — the seat is not '
              'resolving by mode, and the material is wrong on every screen '
              'in that mode while every structural check stays green',
        );
        // The content material is what every card, command and
        // description-card draws. It is the same glass, so it resolves to
        // the same half of the pair in each mode — a content role that
        // took identity or the other mode's half would move every card
        // while this file's functional checks stayed green.
        expect(
          theme.surfaceFor(.content)!.backdropBrightnessIn(theme),
          stated.resolve(entry.key),
        );
      }
    });

    test('and the two modes reach the painter as different matrices', () {
      // One level below the theme: the matrix is what Flutter actually
      // composes into the backdrop pass, and it is pure, so the claim can
      // be checked directly rather than inferred from the field it was
      // built from.
      final stated = CoreSurfaceRecipe.of(
        .liquidGlass,
      ).surfaceFor(.functional)!;
      final saturation = stated.saturation;

      expect(
        backdropColorMatrix(
          saturation: saturation,
          brightness: stated.backdropBrightness.light,
        ),
        isNot(
          backdropColorMatrix(
            saturation: saturation,
            brightness: stated.backdropBrightness.dark,
          ),
        ),
      );
    });

    testWidgets('a style with no material states no dimming', (tester) async {
      late ThemeData seen;

      await tester.pumpWidget(
        CoUIApp(
          theme: ThemeData.fromCore(CoreThemePresets.light),
          surfaceStyle: CoreSurfaceStyleId.neoBrutalism,
          home: Builder(
            builder: (context) {
              seen = Theme.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(seen.surfaceBackdropBrightness, isNull);
    });

    test('two themes differing only in the dimming are not equal', () {
      const a = ThemeData(surfaceBackdropBrightness: 1);
      const b = ThemeData(surfaceBackdropBrightness: 0.25);

      expect(a, isNot(b));
      expect(a.hashCode, isNot(b.hashCode));
    });
  });

  group('a floating surface draws the role material', () {
    testWidgets('the two roles resolve differently under glass', (
      tester,
    ) async {
      late ThemeData seen;
      await tester.pumpWidget(
        CoUIApp(
          theme: ThemeData.fromCore(CoreThemePresets.light),
          surfaceStyle: CoreSurfaceStyleId.liquidGlass,
          home: Builder(
            builder: (context) {
              seen = Theme.of(context);

              return const SizedBox.shrink();
            },
          ),
        ),
      );

      final content = seen.surfaceFor(CoreSurfaceRole.content);
      final functional = seen.surfaceFor(CoreSurfaceRole.functional);

      expect(content, isNotNull);
      expect(functional, isNotNull);
      expect(
        functional,
        isNot(content),
        reason: 'the role reached the theme and then stopped mattering',
      );
    });

    testWidgets('a style with one material gives it to both', (tester) async {
      late ThemeData seen;
      await tester.pumpWidget(
        CoUIApp(
          theme: ThemeData.fromCore(CoreThemePresets.light),
          surfaceStyle: CoreSurfaceStyleId.neoBrutalism,
          home: Builder(
            builder: (context) {
              seen = Theme.of(context);

              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(
        seen.surfaceFor(CoreSurfaceRole.functional),
        seen.surfaceFor(CoreSurfaceRole.content),
        reason: 'the role axis is not free for a style that does not use it',
      );
    });

    testWidgets('a flat override still reaches the material', (tester) async {
      // The regression this shape was rewritten to prevent. `surfaceOpacity`
      // and its siblings are public, and `copyWith(surfaceOpacity: …)` is
      // how a caller retunes one term without restating the rest. An
      // earlier draft stored a content token beside the flat fields, and
      // that twin went stale against exactly this call — a navigation bar
      // stayed opaque under a theme that had asked for 70%, and the only
      // thing that said so was a test reading the painted fill.
      late ThemeData seen;
      await tester.pumpWidget(
        CoUIApp(
          theme: ThemeData.fromCore(
            CoreThemePresets.light,
          ).copyWith(surfaceOpacity: () => 0.7),
          home: Builder(
            builder: (context) {
              seen = Theme.of(context);

              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(
        seen.surfaceFor(CoreSurfaceRole.content)?.opacity,
        const CoreSurfaceOpacity.same(0.7),
      );
      expect(
        seen.surfaceFor(CoreSurfaceRole.functional)?.opacity,
        const CoreSurfaceOpacity.same(0.7),
      );
    });

    testWidgets('high contrast hands the floating edge back too', (
      tester,
    ) async {
      // The flat field is gated on high contrast; the role token has to
      // carry the same answer. Ungated, the same theme would report
      // `surfaceDrawsOwnEdge == false` and
      // `surfaceFor(.functional)!.drawsOwnEdge == true` — nothing reads
      // the second today, which is precisely the shape a latent trap has
      // before someone builds on it.
      late ThemeData seen;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(highContrast: true),
          child: CoUIApp(
            theme: ThemeData.fromCore(CoreThemePresets.light),
            surfaceStyle: CoreSurfaceStyleId.liquidGlass,
            home: Builder(
              builder: (context) {
                seen = Theme.of(context);

                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      expect(seen.surfaceDrawsOwnEdge, isFalse);
      expect(
        seen.surfaceFor(CoreSurfaceRole.functional)?.drawsOwnEdge,
        isFalse,
        reason: 'the floating token kept an edge claim the theme withdrew',
      );
    });

    testWidgets('and a floating panel actually paints it', (tester) async {
      // The acceptance criterion, read off the tree: the role has to reach
      // paint, not just the theme. `Popup` declares itself functional, so
      // the fill it paints is the floating material's. The shipped style
      // states the same alpha for both roles, so the negative control runs
      // on a recipe that states two — that is where "drew the wrong role"
      // is visible at all.
      await tester.pumpWidget(
        CoUIApp(
          theme: ThemeData.fromCore(CoreThemePresets.light),
          surfaceStyle: CoreSurfaceStyleId.liquidGlass,
          home: const Popup(children: [SizedBox(width: 40, height: 20)]),
        ),
      );

      late ResolvedPopup resolved;
      await tester.pumpWidget(
        CoUIApp(
          theme: ThemeData.fromCore(CoreThemePresets.light),
          surfaceStyle: CoreSurfaceStyleId.liquidGlass,
          home: Builder(
            builder: (context) {
              resolved = resolvePopup(context);

              return const SizedBox.shrink();
            },
          ),
        ),
      );

      final recipe = CoreSurfaceRecipe.of(.liquidGlass);

      // Read off the painted fill rather than an intermediate: the
      // resolver folds the material's alpha into the colour, so this is
      // the value that reaches the screen.
      expect(
        resolved.backgroundColor.a,
        closeTo(
          recipe.surfaceFor(.functional)!.opacity.resolve(CoreBrightness.light),
          0.01,
        ),
        reason: 'the panel did not paint the floating material',
      );
      // The negative control needs two materials to tell apart. Read the
      // popup again under a theme whose content role is opaque and whose
      // floating role is still the glass; the panel must paint the
      // floating alpha, not the content's 1.0.
      late ResolvedPopup split;
      await tester.pumpWidget(
        CoUIApp(
          theme: ThemeData.fromCore(CoreThemePresets.light),
          surfaceStyle: CoreSurfaceStyleId.liquidGlass,
          home: Builder(
            builder: (context) {
              return Theme(
                data: Theme.of(context).copyWith(
                  surfaceOpacity: () => 1.0,
                  surfaceBlur: () => null,
                ),
                child: Builder(
                  builder: (context) {
                    split = resolvePopup(context);

                    return const SizedBox.shrink();
                  },
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        split.backgroundColor.a,
        closeTo(
          recipe.surfaceFor(.functional)!.opacity.resolve(CoreBrightness.light),
          0.01,
        ),
        reason: 'the panel drew the content material, not the floating one',
      );
    });
  });

  group('glass does not stack on glass here either', () {
    testWidgets('a nested surface runs one backdrop pass, not two', (
      tester,
    ) async {
      // The divergence this group exists for, measured before the fix:
      // the Web suppressed the inner pass and Flutter did not, so a
      // nested glass surface drew two σ-16 filters here and one there.
      // Variances add, so the composed result was σ≈22.6 against σ-16 —
      // the same code, two screens.
      await tester.pumpWidget(
        CoUIApp(
          theme: ThemeData.fromCore(CoreThemePresets.light),
          surfaceStyle: CoreSurfaceStyleId.liquidGlass,
          home: const OutlinedContainer(
            role: CoreSurfaceRole.functional,
            child: OutlinedContainer(
              role: CoreSurfaceRole.functional,
              child: SizedBox(width: 40, height: 40),
            ),
          ),
        ),
      );

      expect(
        tester.widgetList<BackdropFilter>(find.byType(BackdropFilter)),
        hasLength(1),
        reason: 'the inner surface ran a second pass over a blurred backdrop',
      );
    });

    testWidgets('an unnested surface still draws its own', (tester) async {
      // The half that keeps the assertion above from passing on a build
      // that lost the material altogether.
      await tester.pumpWidget(
        CoUIApp(
          theme: ThemeData.fromCore(CoreThemePresets.light),
          surfaceStyle: CoreSurfaceStyleId.liquidGlass,
          home: const OutlinedContainer(
            role: CoreSurfaceRole.functional,
            child: SizedBox(width: 40, height: 40),
          ),
        ),
      );

      expect(
        tester.widgetList<BackdropFilter>(find.byType(BackdropFilter)),
        hasLength(1),
      );
    });

    testWidgets('the depth a surface sees counts its surface ancestors', (
      tester,
    ) async {
      // Components never read this. A resolver does, and only to hand it
      // to the axis beside the role its component declared.
      final seen = <int>[];
      await tester.pumpWidget(
        CoUIApp(
          theme: ThemeData.fromCore(CoreThemePresets.light),
          surfaceStyle: CoreSurfaceStyleId.liquidGlass,
          home: Builder(
            builder: (outer) {
              seen.add(SurfaceDepth.of(outer));

              return OutlinedContainer(
                role: CoreSurfaceRole.functional,
                child: Builder(
                  builder: (inner) {
                    seen.add(SurfaceDepth.of(inner));

                    return const SizedBox(width: 40, height: 40);
                  },
                ),
              );
            },
          ),
        ),
      );

      expect(seen, [0, 1]);
    });

    testWidgets('and both platforms thin at the same depth', (tester) async {
      // Parity read off the theme rather than asserted in prose: the
      // material Flutter resolves at each depth is the one the recipe
      // states, which is the same object the Web sheet is emitted from.
      late ThemeData seen;
      await tester.pumpWidget(
        CoUIApp(
          theme: ThemeData.fromCore(CoreThemePresets.light),
          surfaceStyle: CoreSurfaceStyleId.liquidGlass,
          home: Builder(
            builder: (context) {
              seen = Theme.of(context);

              return const SizedBox.shrink();
            },
          ),
        ),
      );

      final recipe = CoreSurfaceRecipe.of(.liquidGlass);
      for (final role in CoreSurfaceRole.values) {
        for (final depth in [0, 1, 2, 5]) {
          expect(
            seen.surfaceFor(role, depth: depth)?.blurRadius,
            recipe.surfaceFor(role, depth: depth)?.blurRadius,
            reason: '${role.name} at depth $depth differs from the recipe',
          );
        }
      }
    });
  });
}
