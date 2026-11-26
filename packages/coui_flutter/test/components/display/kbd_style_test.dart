import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

/// A theme whose content surface is translucent — the case where a shadow
/// painted behind the key box would show through the fill.
ThemeData _glassTheme() => ThemeData.fromCore(
  CoreThemeData(
    colorScheme: CouiColorPresets.source.light(),
    brightness: CoreBrightness.light,
    designSystem: DesignSystem.coui,
    defaultSurface: const CoreSurfaceToken(
      type: SurfaceType.glass,
      opacity: CoreSurfaceOpacity.same(0.6),
      blurRadius: 24,
    ),
  ),
);

/// The resolved light theme every test starts from. `const ThemeData()` keeps
/// colour tokens unresolved, which a surface style cannot bend.
final _light = ThemeData.fromCore(CoreThemePresets.light);

/// A key that states the xs stack itself — the default casts nothing, so a
/// test of how a stated stack is bent and painted names it.
const _kXs = CoreKbdStyle(keyShadow: CoreShadow.xs);

/// A key whose edge cannot be seen: a transparent border colour (the
/// default, stated).
const _kHidden = CoreKbdStyle(keyBorderColor: CoreColor.transparent);

/// A key that states a visible edge — the default has none, so a test of how
/// a drawn edge is sized, floored or scaled names one.
const _kEdged = CoreKbdStyle(
  keyBorderColor: CoreColor.token(CoreColors.outlineSubtle),
);

/// A hard, offset stack — nothing like [CoreShadow.xs], so a test that
/// reads it back cannot be satisfied by an xs stack.
const _kHard = <CoreShadowLayer>[
  (
    offsetX: 3,
    offsetY: 3,
    blurRadius: 0,
    spreadRadius: 0,
    opacity: 1,
    inset: false,
  ),
];

Future<ResolvedKbd> _resolve(
  WidgetTester tester, {
  ThemeData? theme,
  CoreSurfaceStyleId surfaceStyle = .defaultId,
  CoreKbdStyle? kbdStyle,
}) async {
  ResolvedKbd? resolved;
  // Unmount first: `buildTestApp` puts the child in an `Overlay` whose
  // initial entries are honoured on the first mount only.
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpWidget(
    buildTestApp(
      Builder(
        builder: (context) {
          resolved = resolveKbd(context, kbdStyle: kbdStyle);
          return const SizedBox.shrink();
        },
      ),
      theme: theme ?? _light,
      surfaceStyle: surfaceStyle,
    ),
  );

  return resolved!;
}

Future<void> _pump(
  WidgetTester tester,
  Widget kbd, {
  ThemeData? theme,
  CoreSurfaceStyleId surfaceStyle = .defaultId,
}) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpWidget(
    buildTestApp(kbd, theme: theme ?? _light, surfaceStyle: surfaceStyle),
  );
}

List<InjectedCast> _casts(WidgetTester tester) =>
    tester.widgetList<InjectedCast>(find.byType(InjectedCast)).toList();

/// The decorations of the boxes sitting directly inside each cast.
Iterable<BoxDecoration> _keyDecorations(WidgetTester tester) => tester
    .widgetList<Container>(
      find.descendant(
        of: find.byType(InjectedCast),
        matching: find.byType(Container),
      ),
    )
    .map((c) => c.decoration)
    .whereType<BoxDecoration>();

void main() {
  group('Kbd key cap — resolved defaults', () {
    testWidgets('a stated edge is a hairline, not a one-pixel line', (
      tester,
    ) async {
      final resolved = await _resolve(tester, kbdStyle: _kEdged);

      expect(resolved.keyBorderWidth, CoreStrokeWidth.stroke0_5);
    });

    testWidgets('a key states the subtle hairline edge by default', (
      tester,
    ) async {
      final resolved = await _resolve(tester);

      expect(resolved.keyBorderColor.a, greaterThan(0));
      expect(resolved.keyBorderWidth, CoreStrokeWidth.stroke0_5);
    });

    testWidgets('the fill is the page face and the edge is outlineSubtle', (
      tester,
    ) async {
      late Color surface;
      late Color outlineSubtle;
      late Color highest;
      ResolvedKbd? resolved;

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(
        buildTestApp(
          Builder(
            builder: (context) {
              final scheme = Theme.of(context).colorScheme;
              Color of(CoreColorToken token) =>
                  scheme.resolve(CoreColor.token(token)).toValue();
              surface = of(CoreColors.surface);
              outlineSubtle = of(CoreColors.outlineSubtle);
              highest = of(CoreColors.surfaceContainerHighest);
              resolved = resolveKbd(context);
              return const SizedBox.shrink();
            },
          ),
          theme: _light,
        ),
      );

      expect(resolved!.keyBackgroundColor, surface);
      expect(resolved!.keyBorderColor, outlineSubtle);
      // The negative control: the former container fill must not be what
      // matched, or the expectation above proves nothing.
      expect(resolved!.keyBackgroundColor, isNot(highest));
    });

    testWidgets('a key casts nothing unless a style states a stack', (
      tester,
    ) async {
      final resolved = await _resolve(tester);

      expect(resolved.keyShadow, isEmpty);
      expect(resolved.keyRim, isEmpty);
    });

    testWidgets('padding is 2 down and 6 across; the floor is 18', (
      tester,
    ) async {
      final resolved = await _resolve(tester);

      expect(
        resolved.keyPadding,
        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      );
      expect(resolved.keyMinSize, CoreSize.size18);
    });

    testWidgets('a stated xs shadow is thrown straight down', (
      tester,
    ) async {
      final resolved = await _resolve(tester, kbdStyle: _kXs);

      expect(resolved.keyShadow, hasLength(CoreShadow.xs.length));
      for (final (i, layer) in resolved.keyShadow.indexed) {
        expect(layer.offset.dx, 0);
        expect(layer.offset.dy, CoreShadow.xs[i].offsetY);
      }
      // The Flutter conversion clamps a sub-pixel σ to 0, so not every
      // layer of a small stack is soft — but the stack as a whole is.
      expect(
        resolved.keyShadow.any((layer) => layer.blurRadius > 0),
        isTrue,
        reason: 'unbent: a hard stack is what a preset turns this into',
      );
    });

    testWidgets('a stated shadow replaces the default whole', (tester) async {
      final resolved = await _resolve(
        tester,
        kbdStyle: const CoreKbdStyle(keyShadow: _kHard),
      );

      expect(resolved.keyShadow, hasLength(1));
      expect(resolved.keyShadow.single.offset, const Offset(3, 3));
    });

    testWidgets('an empty stack states no shadow', (tester) async {
      final resolved = await _resolve(
        tester,
        kbdStyle: const CoreKbdStyle(keyShadow: CoreShadow.none),
      );

      expect(resolved.keyShadow, isEmpty);
    });
  });

  group('Kbd key cap — what the preset does to it', () {
    testWidgets('a style contributes no cast to a key that states none', (
      tester,
    ) async {
      // The key states its own shadow, so a style bends that stack and never
      // adds its injected cast to a key that has none — nor a rim.
      for (final style in [
        CoreSurfaceStyleId.neoBrutalism,
        CoreSurfaceStyleId.claymorphism,
      ]) {
        final resolved = await _resolve(tester, surfaceStyle: style);
        expect(resolved.keyShadow, isEmpty, reason: '$style cast');
        expect(resolved.keyRim, isEmpty, reason: '$style rim');
      }
    });

    testWidgets('a style with a cast bends the xs stack, not replaces it', (
      tester,
    ) async {
      final resolved = await _resolve(
        tester,
        surfaceStyle: .neoBrutalism,
        kbdStyle: _kXs,
      );

      // The same count as the authored stack: a substituted injected cast
      // would be its own length, and one stacked on top would add to it.
      expect(resolved.keyShadow, hasLength(CoreShadow.xs.length));
      for (final (i, bent) in resolved.keyShadow.indexed) {
        final authored = CoreShadow.xs[i];
        expect(bent.blurRadius, 0, reason: 'the bend hard-edges every layer');
        expect(bent.offset.dx, authored.offsetX + CoreStrokeWidth.stroke4);
        expect(bent.offset.dy, authored.offsetY + CoreStrokeWidth.stroke4);
      }
    });

    testWidgets('the stroke floor lifts a drawn hairline', (tester) async {
      late ThemeData theme;
      ResolvedKbd? resolved;

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(
        buildTestApp(
          Builder(
            builder: (context) {
              theme = Theme.of(context);
              resolved = resolveKbd(context, kbdStyle: _kEdged);
              return const SizedBox.shrink();
            },
          ),
          theme: _light,
          surfaceStyle: .neoBrutalism,
        ),
      );

      final floored = theme.geometry.stroke(CoreStrokeWidth.stroke0_5);
      expect(floored, greaterThan(CoreStrokeWidth.stroke0_5));
      expect(resolved!.keyBorderWidth, floored);
    });

    testWidgets('a style lifts the default hairline edge to its floor', (
      tester,
    ) async {
      // The default edge is drawn, so a preset whose floor is above the
      // hairline lifts it like any other stroke.
      final resolved = await _resolve(tester, surfaceStyle: .neoBrutalism);

      expect(resolved.keyBorderWidth, greaterThan(CoreStrokeWidth.stroke0_5));
    });
  });

  group('Kbd key cap — size', () {
    testWidgets('a drawn border sits inside the layout — a key is 20 tall', (
      tester,
    ) async {
      // padding 2 + 2, one line of the labelXs label, and the hairline on
      // both edges (0.5 + 0.5). The label line is 11 × 1.4 = 15.4, which the
      // test engine lays out at 15 — so the key measures 20 here. A
      // `DecoratedBox` would paint the border inside the child's extent and
      // leave this at 19; the `Container` adds it, which is what the CSS
      // border-box does.
      await _pump(tester, const Kbd(keys: ['Ctrl'], kbdStyle: _kEdged));

      final line = tester.getSize(find.text('Ctrl')).height;
      final key = tester.getSize(find.byType(InjectedCast).first).height;
      expect(key, 2 + line + 2 + 0.5 + 0.5);
      expect(key, 20);
    });

    testWidgets('the default key draws its hairline — it is 20 tall', (
      tester,
    ) async {
      // The default border is the visible hairline, so it takes layout like
      // a stated one: padding 2 + the label line + 2 + 0.5 + 0.5 — 20 in the
      // test engine, whose line is 15. Rendered from the defaults.
      await _pump(tester, const Kbd(keys: ['Ctrl']));

      final line = tester.getSize(find.text('Ctrl')).height;
      final key = tester.getSize(find.byType(InjectedCast).first).height;
      expect(key, 2 + line + 2 + 0.5 + 0.5);
      expect(key, 20);
    });

    testWidgets('a transparent border stated takes no room either', (
      tester,
    ) async {
      await _pump(tester, const Kbd(keys: ['Ctrl'], kbdStyle: _kHidden));

      final line = tester.getSize(find.text('Ctrl')).height;
      final key = tester.getSize(find.byType(InjectedCast).first).height;
      expect(key, 2 + line + 2);
    });

    testWidgets('the fold reaches a width the app states, and a floor', (
      tester,
    ) async {
      // A stated width does not bring a hidden edge back, and neither does a
      // style's stroke floor — 0 is not a drawn stroke, so nothing lifts it.
      final stated = await _resolve(
        tester,
        kbdStyle: const CoreKbdStyle(
          keyBorderColor: CoreColor.transparent,
          keyBorderWidth: CoreStrokeWidth.stroke2,
        ),
      );
      expect(stated.keyBorderWidth, 0);

      final floored = await _resolve(
        tester,
        surfaceStyle: .neoBrutalism,
        kbdStyle: const CoreKbdStyle(
          keyBorderColor: CoreColor.transparent,
          keyBorderWidth: CoreStrokeWidth.stroke2,
        ),
      );
      expect(floored.keyBorderWidth, 0);
    });

    testWidgets('a token edge at opacity 0 folds, at partial opacity draws', (
      tester,
    ) async {
      // The Web twin reads the same answer off the opacity modifier of the
      // token, so a hidden token edge is one box on both platforms.
      final hidden = await _resolve(
        tester,
        kbdStyle: const CoreKbdStyle(
          keyBorderColor: CoreColor.token(CoreColors.outline, opacity: 0),
        ),
      );
      expect(hidden.keyBorderWidth, 0);

      final faint = await _resolve(
        tester,
        kbdStyle: const CoreKbdStyle(
          keyBorderColor: CoreColor.token(CoreColors.outline, opacity: 0.4),
        ),
      );
      expect(faint.keyBorderWidth, CoreStrokeWidth.stroke0_5);
    });

    testWidgets('a visible colour restored on the edge draws its width', (
      tester,
    ) async {
      final resolved = await _resolve(
        tester,
        kbdStyle: const CoreKbdStyle(
          keyBorderColor: CoreColor.token(CoreColors.outline),
        ),
      );

      expect(resolved.keyBorderWidth, CoreStrokeWidth.stroke0_5);
    });

    testWidgets('a material that draws its own edge keeps the key box', (
      tester,
    ) async {
      // The fold reads the colour the key AUTHORED, not the one a material
      // left after suppressing it: a suppressed stroke is a paint change, and
      // reading it would turn it into a layout change on this platform alone.
      final resolved = await _resolve(
        tester,
        surfaceStyle: .liquidGlass,
        kbdStyle: _kEdged,
      );

      expect(
        resolved.keyBorderColor.a,
        0,
        reason: 'the premise: this material draws the edge itself',
      );
      expect(resolved.keyBorderWidth, greaterThan(0));
    });
  });

  group('Kbd key cap — the phone scale', () {
    testWidgets('the hairline and the shadow are not multiplied', (
      tester,
    ) async {
      final phone = const AdaptiveScaling(1.25).scale(_light);
      const stated = CoreKbdStyle(
        keyBorderColor: CoreColor.token(CoreColors.outlineSubtle),
        keyShadow: CoreShadow.xs,
      );
      final base = await _resolve(tester, kbdStyle: stated);
      final scaled = await _resolve(tester, theme: phone, kbdStyle: stated);

      // Size follows the scale; the hairline and the cast do not.
      expect(scaled.keyMinSize, closeTo(base.keyMinSize * 1.25, 0.0001));
      expect(scaled.keyBorderWidth, base.keyBorderWidth);
      expect(base.keyBorderWidth, greaterThan(0));
      expect(base.keyShadow, isNotEmpty);
      expect(scaled.keyShadow, base.keyShadow);
    });
  });

  group('Kbd key cap — where the shadow is painted', () {
    testWidgets('one cast per key, none on the row that holds them', (
      tester,
    ) async {
      await _pump(tester, const Kbd(keys: ['Ctrl', 'C'], kbdStyle: _kXs));

      final casts = _casts(tester);
      expect(casts, hasLength(2));
      for (final cast in casts) {
        expect(cast.shadows, hasLength(CoreShadow.xs.length));
      }
    });

    testWidgets('a key that states none paints no cast', (tester) async {
      await _pump(tester, const Kbd(keys: ['Ctrl', 'C']));

      for (final cast in _casts(tester)) {
        expect(cast.shadows, isEmpty);
      }
    });

    testWidgets('a single widget key has its own cast', (tester) async {
      await _pump(tester, const Kbd.icon(keyContent: Text('⏎')));

      expect(_casts(tester), hasLength(1));
    });

    testWidgets('the box carries no shadow of its own', (tester) async {
      // A shadow in the decoration is drawn behind the fill, so a
      // translucent fill would show it through — on this platform only.
      await _pump(tester, const Kbd(keys: ['Ctrl', 'C'], kbdStyle: _kXs));

      final decorations = _keyDecorations(tester).toList();
      expect(decorations, hasLength(2));
      for (final decoration in decorations) {
        expect(decoration.boxShadow ?? const <BoxShadow>[], isEmpty);
      }
    });

    testWidgets('the cast is knocked out of the key under a glass fill', (
      tester,
    ) async {
      final theme = _glassTheme();
      final resolved = await _resolve(tester, theme: theme);
      expect(
        resolved.keyBackgroundColor.a,
        lessThan(1.0),
        reason: 'the premise: this fill lets a shadow behind it show through',
      );

      await _pump(
        tester,
        const Kbd(keys: ['Ctrl'], kbdStyle: _kXs),
        theme: theme,
      );

      expect(_casts(tester).single.shadows, isNotEmpty);
      for (final decoration in _keyDecorations(tester)) {
        expect(decoration.boxShadow ?? const <BoxShadow>[], isEmpty);
      }
    });

    testWidgets('the rim is drawn over the box, not behind it', (tester) async {
      // Claymorphism states an inset highlight. `BoxDecoration` paints
      // shadows behind the fill, so a rim handed to it never shows: it has
      // to be drawn by `InsetShadow`, over the box.
      await _pump(
        tester,
        const Kbd(keys: ['Ctrl', 'C'], kbdStyle: _kXs),
        surfaceStyle: .claymorphism,
      );

      final insets = tester
          .widgetList<InsetShadow>(find.byType(InsetShadow))
          .toList();
      expect(insets, hasLength(2), reason: 'one rim per key');
      for (final inset in insets) {
        expect(inset.shadows, isNotEmpty);
      }
      for (final decoration in _keyDecorations(tester)) {
        expect(decoration.boxShadow ?? const <BoxShadow>[], isEmpty);
      }
    });

    testWidgets('a style that states no rim draws none', (tester) async {
      await _pump(tester, const Kbd(keys: ['Ctrl']));

      for (final inset in tester.widgetList<InsetShadow>(
        find.byType(InsetShadow),
      )) {
        expect(inset.shadows, isEmpty);
      }
    });

    testWidgets('a key that casts no shadow gets no rim either', (
      tester,
    ) async {
      // A rim decorates a raised surface; it does not raise a flat one.
      await _pump(
        tester,
        const Kbd(
          keys: ['Ctrl'],
          kbdStyle: CoreKbdStyle(keyShadow: CoreShadow.none),
        ),
        surfaceStyle: .claymorphism,
      );

      for (final inset in tester.widgetList<InsetShadow>(
        find.byType(InsetShadow),
      )) {
        expect(inset.shadows, isEmpty);
      }
    });

    testWidgets('an empty stack paints no cast', (tester) async {
      await _pump(
        tester,
        const Kbd(
          keys: ['Ctrl'],
          kbdStyle: CoreKbdStyle(keyShadow: CoreShadow.none),
        ),
      );

      for (final cast in _casts(tester)) {
        expect(cast.shadows, isEmpty);
      }
    });
  });
}
