// A glass popover panel keeps its backdrop pass while it fades: the engine does
// not wrap such a panel in an opacity that saves a layer above the pass, and
// the surface fades its own terms from the progress instead.
//
// What this holds is the layer tree and the numbers in it. What the compositor
// makes of them — whether the stripes behind a held panel are really blurred —
// is the engine's, and is measured on a device
// (`app/coui_widgetbook/integration_test/popover_fade_probe_test.dart`):
// `flutter_tester` paints the layers and rasterises none of the filters.
//
// The terms a glass material states and what the surface draws at each held
// progress are read from the shared table (`surface_dissolve_vectors.json`),
// the one the Core test holds the arithmetic to.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:coui_flutter/src/components/infra/outlined_container/surface_fade.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

const String _kVectorsPath =
    '../coui_core/test/fixtures/surface_dissolve_vectors.json';

/// The engine's open runs this long, so `pump(500 ms)` holds it at half.
const Duration _kOpen = Duration(milliseconds: 1000);

/// The close curve covers the first two thirds of the duration, so a third of
/// it is half of the way out.
const Duration _kClose = Duration(milliseconds: 1500);

const Duration _kHalfOfOpen = Duration(milliseconds: 500);
const Duration _kHalfOfClose = Duration(milliseconds: 500);
const Duration _kFrame = Duration(milliseconds: 16);

const CoreSurfaceStyleId _glass = CoreSurfaceStyleId.liquidGlass;

/// The material the glass preset states, read from the preset.
final CoreSurfaceToken _material = CoreSurfaceRecipe.presets[_glass]!.surface!;

/// What the preset's pass draws at rest in `flutter_tester`.
///
/// The blur is the preset's plus the correction a surface adds wherever the
/// bend it asked for cannot be drawn (`fallbackBlurAdd`), and
/// `flutter_tester` cannot run the program.
final double _kRestBlur =
    _material.blurRadius! +
    CoreSurfaceRecipe.presets[_glass]!.refraction!.fallbackBlurAdd;
final double _kSaturation = _material.saturation;
final double _kBrightness = _material.backdropBrightness.light;

Map<String, Object?> _vectors() =>
    jsonDecode(File(_kVectorsPath).readAsStringSync()) as Map<String, Object?>;

double _num(Object? value) => (value! as num).toDouble();

/// The panel's content: opaque, so a test that paints it can tell it from the
/// fill.
const Widget _content = SizedBox(
  key: ValueKey('content'),
  width: 120,
  height: 60,
);

/// What the open panel is built from; replaced by a test that needs another.
Widget _popup(BuildContext _) => const Popup(children: [_content]);

/// Mounts an app, opens a panel through the engine and builds its first frame
/// (progress 0).
Future<PopoverEntryHandle<void>> _open(
  WidgetTester tester, {
  CoreSurfaceStyleId style = _glass,
  ThemeData? theme,
  bool highContrast = false,
  WidgetBuilder builder = _popup,
}) async {
  final anchor = GlobalKey();
  await pumpTestApp(
    tester,
    SizedBox(key: anchor, width: 80, height: 32),
    surfaceStyle: style,
    theme: theme,
    highContrast: highContrast,
  );
  final handle = const PopoverOverlayHandler().show<void>(
    context: anchor.currentContext!,
    alignment: Alignment.topLeft,
    anchorAlignment: Alignment.bottomLeft,
    modal: false,
    follow: false,
    showDuration: _kOpen,
    dismissDuration: _kClose,
    builder: builder,
  );
  addTearDown(handle.dismissImmediately);
  await tester.pump();

  return handle;
}

/// Every layer under [root], depth first, [root] included.
Iterable<Layer> _layersUnder(Layer root) sync* {
  yield root;
  if (root is ContainerLayer) {
    for (
      var child = root.firstChild;
      child != null;
      child = child.nextSibling
    ) {
      yield* _layersUnder(child);
    }
  }
}

Iterable<Layer> _allLayers(WidgetTester tester) =>
    _layersUnder(tester.binding.renderViews.first.debugLayer!);

/// The alphas of every layer in the scene that saves a pass for an opacity
/// under full alpha.
List<int> _savingAlphas(WidgetTester tester) => [
  for (final layer in _allLayers(tester))
    if (layer is OpacityLayer && layer.alpha! < 255) layer.alpha!,
];

/// The backdrop filter layers under [within] — the panel by default — in paint
/// order.
List<BackdropFilterLayer> _passLayers(WidgetTester tester, {Finder? within}) =>
    [
      for (final element
          in find
              .descendant(
                of: within ?? find.byType(Popup).first,
                matching: find.byType(BackdropFilter),
              )
              .evaluate())
        (element.renderObject! as RenderBackdropFilter).debugLayer!
            as BackdropFilterLayer,
    ];

/// Every opacity layer above [layer], nearest first.
List<OpacityLayer> _opacitiesAbove(Layer layer) => [
  for (var parent = layer.parent; parent != null; parent = parent.parent)
    if (parent is OpacityLayer) parent,
];

/// The alphas of the opacity layers above the backdrop passes under [within]
/// that save a layer — the ones an opacity at less than full alpha makes.
List<int> _savingAlphasAbovePasses(WidgetTester tester, {Finder? within}) => [
  for (final pass in _passLayers(tester, within: within))
    for (final opacity in _opacitiesAbove(pass))
      if (opacity.alpha! < 255) opacity.alpha!,
];

/// The engine's own fade: the nearest `RenderAnimatedOpacity` above [of].
RenderAnimatedOpacity _engineFade(WidgetTester tester, {Finder? of}) {
  RenderAnimatedOpacity? found;
  tester.element(of ?? find.byType(Popup).first).visitAncestorElements((
    element,
  ) {
    final render = element is RenderObjectElement ? element.renderObject : null;
    if (render is RenderAnimatedOpacity) {
      found = render;

      return false;
    }

    return true;
  });

  return found!;
}

/// The surface's own fade boxes.
List<RenderSurfaceFadeBox> _fadeBoxes(WidgetTester tester) => [
  for (final element in find.byType(SurfaceFadeBox).evaluate())
    element.renderObject! as RenderSurfaceFadeBox,
];

/// The labels of the semantics nodes the app exposes, read off the node tree.
///
/// Not `find.bySemanticsLabel`: a hidden subtree's render objects keep the node
/// they last had, so that finder goes on finding a label the tree no longer
/// carries.
List<String> _semanticLabels(WidgetTester tester) {
  final labels = <String>[];
  void walk(SemanticsNode node) {
    labels.add(node.getSemanticsData().label);
    node.visitChildren((child) {
      walk(child);

      return true;
    });
  }

  walk(
    tester.binding.renderViews.first.owner!.semanticsOwner!.rootSemanticsNode!,
  );

  return labels;
}

/// The filter the material pass states at [blur], [saturation] and
/// [brightness] — built the way the surface builds it.
ui.ImageFilter _passFilter(
  double blur,
  double saturation,
  double brightness,
) => ui.ImageFilter.compose(
  outer: ColorFilter.matrix(
    backdropColorMatrix(saturation: saturation, brightness: brightness),
  ),
  inner: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
);

ui.ImageFilter _frostFilter(double sigma, double opacity) =>
    ui.ImageFilter.compose(
      outer: ColorFilter.matrix(surfaceFrostColorMatrix(opacity)),
      inner: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
    );

/// The numbers an `ImageFilter` is made of, read from its description — the
/// filter keeps no accessor of its own, and its equality is exact, which a
/// product of two doubles is not.
List<double> _numbers(ui.ImageFilter filter) => [
  for (final match in RegExp(r'-?\d+(?:\.\d+)?(?:e-?\d+)?').allMatches(
    filter.toString(),
  ))
    double.parse(match.group(0)!),
];

/// Matches a filter made of the same operations with the same numbers, to a
/// few ulps.
Matcher _sameFilter(ui.ImageFilter expected) => predicate<ui.ImageFilter?>(
  (actual) {
    if (actual == null) return false;
    final got = _numbers(actual);
    final want = _numbers(expected);
    if (got.length != want.length) return false;
    for (var i = 0; i < got.length; i++) {
      if ((got[i] - want[i]).abs() > 1e-9) return false;
    }

    // The operations, with the numbers taken out.
    String shape(ui.ImageFilter f) =>
        f.toString().replaceAll(RegExp(r'-?\d+(?:\.\d+)?(?:e-?\d+)?'), '#');

    return shape(actual) == shape(expected);
  },
  'the filter $expected',
);

void main() {
  group('a glass panel at half of its open', () {
    testWidgets('has no layer above its backdrop pass that saves a pass', (
      tester,
    ) async {
      await _open(tester);
      await tester.pump(_kHalfOfOpen);

      expect(_passLayers(tester), hasLength(1));
      expect(
        _savingAlphasAbovePasses(tester),
        isEmpty,
        reason:
            'an opacity under 255 above a backdrop filter saves a layer the '
            'filter then reads nothing of',
      );
    });

    testWidgets('is faded once: by the surface, not also by the engine', (
      tester,
    ) async {
      await _open(tester);
      await tester.pump(_kHalfOfOpen);

      // The engine paints at full alpha, which the framework emits as an
      // offset — the layer the panel at rest has always been drawn through.
      expect(_engineFade(tester).opacity.value, 1);
      expect(
        _savingAlphas(tester),
        [128],
        reason:
            'exactly one layer fades the panel, at half — the surface puts it '
            'over its fill and content, beside its pass',
      );
    });

    testWidgets('fades the content in a layer beside the pass, not over it', (
      tester,
    ) async {
      await _open(tester);
      await tester.pump(_kHalfOfOpen);

      final pass = _passLayers(tester).single;
      final fading = _allLayers(
        tester,
      ).whereType<OpacityLayer>().where((layer) => layer.alpha == 128).single;
      // Neither contains the other: the opacity is over what the pass sits
      // under, not over the pass.
      expect(_opacitiesAbove(pass), isNot(contains(fading)));
      for (final inner in _layersUnder(fading)) {
        expect(inner, isNot(isA<BackdropFilterLayer>()));
      }
    });

    testWidgets('draws the material at half of what it states', (tester) async {
      await _open(tester);
      await tester.pump(_kHalfOfOpen);

      expect(
        _passLayers(tester).single.filter,
        _sameFilter(
          _passFilter(
            _kRestBlur * 0.5,
            1 + (_kSaturation - 1) * 0.5,
            1 + (_kBrightness - 1) * 0.5,
          ),
        ),
      );
      expect(_fadeBoxes(tester).single.progress, closeTo(0.5, 1e-9));
      expect(_fadeBoxes(tester).single.debugAlpha, 128);
    });

    testWidgets('and the frost lays down half of its share', (tester) async {
      await _open(
        tester,
        theme: const ThemeData().copyWith(
          surfaceFrost: () => const CoreSurfaceFrost(sigma: 14, opacity: 0.8),
        ),
      );
      await tester.pump(_kHalfOfOpen);

      final passes = _passLayers(tester);
      expect(passes, hasLength(2), reason: 'the cloud and the material');
      expect(passes.first.filter, _sameFilter(_frostFilter(14, 0.4)));
      expect(_savingAlphasAbovePasses(tester), isEmpty);
    });

    testWidgets('is faded by the progress at every held level, the same way', (
      tester,
    ) async {
      await _open(tester);
      var elapsed = Duration.zero;
      for (final level in [0.25, 0.5, 0.75]) {
        final next = Duration(milliseconds: (level * 1000).round());
        await tester.pump(next - elapsed);
        elapsed = next;

        expect(
          _savingAlphasAbovePasses(tester),
          isEmpty,
          reason: 'level $level',
        );
        expect(
          _fadeBoxes(tester).single.progress,
          closeTo(level, 1e-9),
          reason: 'level $level',
        );
        expect(
          _passLayers(tester).single.filter,
          _sameFilter(
            _passFilter(
              _kRestBlur * level,
              1 + (_kSaturation - 1) * level,
              1 + (_kBrightness - 1) * level,
            ),
          ),
          reason: 'level $level',
        );
      }
    });
  });

  group('a glass panel at rest', () {
    testWidgets('keeps its pass at the stated material, with nothing saved '
        'above or beside it', (tester) async {
      await _open(tester);
      await tester.pump(_kOpen);
      await tester.pump(_kFrame);

      expect(_engineFade(tester).opacity.value, 1);
      expect(_savingAlphas(tester), isEmpty);
      expect(
        _passLayers(tester).single.filter,
        _sameFilter(_passFilter(_kRestBlur, _kSaturation, _kBrightness)),
      );
    });

    testWidgets('paints the content straight through, with no layer of its '
        'own', (tester) async {
      await _open(tester);
      await tester.pump(_kOpen);
      await tester.pump(_kFrame);

      final box = _fadeBoxes(tester).single;
      expect(box.progress, 1);
      expect(box.isRepaintBoundary, isFalse);
      expect(box.alwaysNeedsCompositing, isFalse);
    });

    testWidgets('builds the same material a surface outside the engine does', (
      tester,
    ) async {
      await pumpTestApp(
        tester,
        const Popup(children: [_content]),
        surfaceStyle: _glass,
      );
      final outside =
          find
                  .descendant(
                    of: find.byType(Popup),
                    matching: find.byType(BackdropFilter),
                  )
                  .evaluate()
                  .single
                  .widget
              as BackdropFilter;
      // Outside any engine nothing is mounted for the fade.
      expect(find.byType(SurfaceFadeBox), findsNothing);
      expect(find.byType(SurfaceFadeAdopter), findsNothing);

      await tester.pumpWidget(const SizedBox());
      await _open(tester);
      await tester.pump(_kOpen);
      await tester.pump(_kFrame);
      final inside =
          find
                  .descendant(
                    of: find.byType(Popup),
                    matching: find.byType(BackdropFilter),
                  )
                  .evaluate()
                  .single
                  .widget
              as BackdropFilter;

      // The very filter, not an equal one: nothing downstream rebuilds a
      // filter for a value that did not move.
      expect(inside.filter, outside.filter);
    });
  });

  group('a glass panel at nothing', () {
    testWidgets('paints nothing: no pass, no fill, no content, no semantics', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _open(
        tester,
        builder: (_) => Popup(
          children: [Semantics(label: 'panel content', child: _content)],
        ),
      );

      // The first frame is the panel at nothing.
      expect(_engineFade(tester).opacity.value, 0);
      expect(find.byType(BackdropFilter), findsNothing);
      final box = _fadeBoxes(tester).single;
      expect(box.debugAlpha, 0);
      expect(box.isRepaintBoundary, isFalse);
      expect(_semanticLabels(tester), isNot(contains('panel content')));

      await tester.pump(_kHalfOfOpen);
      expect(_semanticLabels(tester), contains('panel content'));
      semantics.dispose();
    });
  });

  group('a glass panel closing', () {
    testWidgets('is held the same way going out', (tester) async {
      final handle = await _open(tester);
      await tester.pump(_kOpen);
      await tester.pump(_kFrame);

      handle.close();
      await tester.pump();
      await tester.pump(_kHalfOfClose);

      expect(_engineFade(tester).opacity.value, 1);
      expect(_savingAlphasAbovePasses(tester), isEmpty);
      final progress = _fadeBoxes(tester).single.progress;
      expect(progress, closeTo(0.5, 0.02));
      expect(
        _passLayers(tester).single.filter,
        _sameFilter(
          _passFilter(
            _kRestBlur * progress,
            1 + (_kSaturation - 1) * progress,
            1 + (_kBrightness - 1) * progress,
          ),
        ),
      );
    });

    testWidgets('gives its pass up with the fill, with no step in between', (
      tester,
    ) async {
      final handle = await _open(tester);
      await tester.pump(_kOpen);
      await tester.pump(_kFrame);

      handle.close();
      await tester.pump();
      // Walk the whole close in 20 ms frames: the blur falls with the fill and
      // never moves by more than a frame's share of it, and the frame the fill
      // is gone in is the frame the pass is.
      double? previous;
      var sawNothing = false;
      for (var elapsed = 0; elapsed < 1500; elapsed += 20) {
        await tester.pump(const Duration(milliseconds: 20));
        if (find.byType(Popup).evaluate().isEmpty) break;
        final passes = _passLayers(tester);
        final blur = passes.isEmpty ? 0.0 : _numbers(passes.last.filter!).first;
        if (previous != null) {
          expect(
            (blur - previous).abs(),
            lessThan(_kRestBlur * 0.2),
            reason: 'the blur between two frames, at $elapsed ms',
          );
        }
        previous = blur;
        if (_fadeBoxes(tester).single.debugAlpha == 0) {
          sawNothing = true;
          expect(passes, isEmpty, reason: 'a pass with no panel left to blur');
        }
      }
      expect(sawNothing, isTrue, reason: 'the close reached nothing');
    });
  });

  group('a panel whose surface draws no backdrop pass', () {
    testWidgets('is faded as a whole by the engine', (
      tester,
    ) async {
      await _open(tester, style: CoreSurfaceStyleId.defaultStyle);
      await tester.pump(_kHalfOfOpen);

      expect(_engineFade(tester).opacity.value, closeTo(0.5, 1e-9));
      expect(find.byType(BackdropFilter), findsNothing);
      expect(find.byType(SurfaceFadeBox), findsNothing);
      expect(_savingAlphas(tester), [128]);
    });

    testWidgets('under reduced transparency, a glass style is faded by the '
        'engine', (tester) async {
      await _open(tester, theme: const ThemeData(reduceTransparency: true));
      await tester.pump(_kHalfOfOpen);

      expect(find.byType(BackdropFilter), findsNothing);
      expect(_engineFade(tester).opacity.value, closeTo(0.5, 1e-9));
      expect(find.byType(SurfaceFadeBox), findsNothing);
    });

    testWidgets('at the solid quality tier, a glass style is faded by the '
        'engine', (tester) async {
      final solid = applySurfaceStyle(
        ThemeData.fromCore(CoreThemePresets.light),
        surfaceStyle: _glass,
        highContrast: false,
        quality: CoreQualityTier.solid,
      );
      await _open(tester, style: CoreSurfaceStyleId.defaultStyle, theme: solid);
      await tester.pump(_kHalfOfOpen);

      expect(find.byType(BackdropFilter), findsNothing);
      expect(_engineFade(tester).opacity.value, closeTo(0.5, 1e-9));
      expect(find.byType(SurfaceFadeBox), findsNothing);
    });

    testWidgets("a panel that is not the kit's surface is faded as a whole", (
      tester,
    ) async {
      await _open(
        tester,
        builder: (_) => const ColoredBox(
          key: ValueKey('plain'),
          color: Color(0xFF123456),
          child: SizedBox(width: 50, height: 50),
        ),
      );
      await tester.pump(_kHalfOfOpen);

      expect(
        _engineFade(
          tester,
          of: find.byKey(const ValueKey('plain')),
        ).opacity.value,
        0.5,
      );
    });
  });

  group('a glass panel under high contrast', () {
    testWidgets('keeps its blur pass, so its surface fades it', (tester) async {
      // High contrast takes the bend, the frost and the shade from the glass
      // and keeps its translucent fill and its blur. What the panel is faded
      // by follows what the surface draws — a rule written for high contrast
      // here would be a second answer about a pass the surface already
      // answered.
      await _open(tester, highContrast: true);
      await tester.pump(_kHalfOfOpen);

      expect(find.byType(BackdropFilter), findsOneWidget);
      expect(_engineFade(tester).opacity.value, 1);
      expect(_savingAlphasAbovePasses(tester), isEmpty);
      expect(_savingAlphas(tester), [128]);
    });
  });

  group('the claim', () {
    testWidgets('is made by the surface that draws the pass and released with '
        'it', (tester) async {
      final handle = await _open(tester);
      await tester.pump(_kHalfOfOpen);
      expect(_engineFade(tester).opacity.value, 1);

      handle.dismissImmediately();
      await tester.pump();
      expect(find.byType(Popup), findsNothing);
    });

    testWidgets('goes back to the engine when the surface stops drawing a '
        'pass', (tester) async {
      final reduce = ValueNotifier(false);
      addTearDown(reduce.dispose);
      final anchor = GlobalKey();
      await tester.pumpWidget(
        ValueListenableBuilder<bool>(
          valueListenable: reduce,
          builder: (_, reduced, _) => buildTestApp(
            SizedBox(key: anchor, width: 80, height: 32),
            surfaceStyle: _glass,
            theme: ThemeData(reduceTransparency: reduced),
          ),
        ),
      );
      final handle = const PopoverOverlayHandler().show<void>(
        context: anchor.currentContext!,
        alignment: Alignment.topLeft,
        anchorAlignment: Alignment.bottomLeft,
        modal: false,
        follow: false,
        showDuration: _kOpen,
        dismissDuration: _kClose,
        builder: _popup,
      );
      addTearDown(handle.dismissImmediately);
      await tester.pump();
      await tester.pump(_kHalfOfOpen);
      expect(_engineFade(tester).opacity.value, 1);
      expect(find.byType(BackdropFilter), findsOneWidget);

      // The app asks for less transparency while the panel is open: the
      // surface has no pass to draw, so the panel is the engine's to fade.
      reduce.value = true;
      await tester.pump();
      expect(find.byType(BackdropFilter), findsNothing);
      expect(_engineFade(tester).opacity.value, closeTo(0.5, 0.02));
      expect(find.byType(SurfaceFadeBox), findsNothing);
      expect(_savingAlphas(tester), hasLength(1));
    });

    testWidgets('is not made again by a glass surface inside the panel', (
      tester,
    ) async {
      await _open(
        tester,
        builder: (_) => const Popup(
          children: [
            Popup(children: [_content]),
            Popup(children: [SizedBox(width: 20, height: 20)]),
          ],
        ),
      );
      await tester.pump(_kHalfOfOpen);

      // One surface fades the panel, once; the two inside it are in its
      // content, not beside it.
      expect(find.byType(SurfaceFadeAdopter), findsOneWidget);
      expect(_fadeBoxes(tester), hasLength(1));
      expect(_savingAlphas(tester), [128]);
    });

    testWidgets('is not made by a surface under one that declined it', (
      tester,
    ) async {
      // An opaque panel (the default style) holding a glass one: the outer
      // surface decides for the panel, and it declines, so the engine fades
      // the whole of it and the inner surface is not offered the fade.
      await _open(
        tester,
        style: CoreSurfaceStyleId.defaultStyle,
        builder: (_) => const Popup(
          children: [
            Popup(
              popupStyle: CorePopupStyle(surfaceStyle: .liquidGlass),
              children: [_content],
            ),
          ],
        ),
      );
      await tester.pump(_kHalfOfOpen);

      expect(_engineFade(tester).opacity.value, closeTo(0.5, 1e-9));
      expect(find.byType(SurfaceFadeBox), findsNothing);
      expect(_savingAlphas(tester), [128]);
    });
  });

  group('the cast a glass panel throws', () {
    testWidgets('fades with the panel and keeps its shape', (tester) async {
      await _open(tester);
      await tester.pump(const Duration(milliseconds: 250));

      final cast = tester
          .widget<InjectedCast>(find.byType(InjectedCast))
          .shadows;
      final atRest = resolvePopup(tester.element(find.byType(Popup))).boxShadow;
      expect(cast, isNotEmpty);
      expect(cast.length, atRest.length);
      for (var i = 0; i < cast.length; i++) {
        expect(cast[i].blurRadius, atRest[i].blurRadius);
        expect(cast[i].offset, atRest[i].offset);
        expect(cast[i].spreadRadius, atRest[i].spreadRadius);
        expect(cast[i].color.a, closeTo(atRest[i].color.a * 0.25, 1e-3));
      }
    });

    testWidgets('is the list the resolver states at rest', (tester) async {
      await _open(tester);
      await tester.pump(_kOpen);
      await tester.pump(_kFrame);

      final cast = tester
          .widget<InjectedCast>(find.byType(InjectedCast))
          .shadows;
      final atRest = resolvePopup(tester.element(find.byType(Popup))).boxShadow;
      expect(cast, atRest);
    });
  });

  group('the shadows a surface fades', () {
    test('are the same list when there is nothing to fade', () {
      const shadows = [BoxShadow(color: Color(0x80000000), blurRadius: 4)];
      expect(identical(fadeShadows(shadows, null), shadows), isTrue);
      expect(identical(fadeShadows(shadows, 1), shadows), isTrue);
      const none = <BoxShadow>[];
      expect(identical(fadeShadows(none, 0.5), none), isTrue);
    });

    test('keep every term but the alpha', () {
      const shadow = BoxShadow(
        color: Color(0x80000000),
        offset: Offset(2, 3),
        blurRadius: 4,
        spreadRadius: 1,
      );
      final faded = fadeShadows(const [shadow], 0.5).single;
      expect(faded.offset, shadow.offset);
      expect(faded.blurRadius, shadow.blurRadius);
      expect(faded.spreadRadius, shadow.spreadRadius);
      expect(faded.color.a, closeTo(shadow.color.a * 0.5, 1e-9));
    });
  });

  group('the fade box', () {
    testWidgets('saves a layer only between nothing and full', (tester) async {
      final progress = ValueNotifier<double>(1);
      addTearDown(progress.dispose);
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ValueListenableBuilder<double>(
            valueListenable: progress,
            builder: (_, value, _) => SurfaceFadeBox(
              progress: value,
              child: const SizedBox(width: 10, height: 10),
            ),
          ),
        ),
      );
      RenderSurfaceFadeBox box() => tester.renderObject<RenderSurfaceFadeBox>(
        find.byType(SurfaceFadeBox),
      );

      expect(box().isRepaintBoundary, isFalse, reason: 'full');
      progress.value = 0.5;
      await tester.pump();
      expect(box().isRepaintBoundary, isTrue, reason: 'half');
      expect(_savingAlphas(tester), [128]);
      progress.value = 0;
      await tester.pump();
      expect(box().isRepaintBoundary, isFalse, reason: 'nothing');
      expect(_allLayers(tester).whereType<OpacityLayer>(), isEmpty);
      progress.value = 1;
      await tester.pump();
      expect(box().isRepaintBoundary, isFalse, reason: 'full again');
      expect(_allLayers(tester).whereType<OpacityLayer>(), isEmpty);
    });

    testWidgets('leaves its child out of the semantics at nothing', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final progress = ValueNotifier<double>(1);
      addTearDown(progress.dispose);
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ValueListenableBuilder<double>(
            valueListenable: progress,
            builder: (_, value, _) => SurfaceFadeBox(
              progress: value,
              child: Semantics(
                label: 'content',
                child: const SizedBox(width: 10, height: 10),
              ),
            ),
          ),
        ),
      );
      expect(_semanticLabels(tester), contains('content'));
      progress.value = 0;
      await tester.pump();
      expect(_semanticLabels(tester), isNot(contains('content')));
      // A thousandth is under one level of 255: still nothing painted, and
      // still nothing to read.
      progress.value = 0.001;
      await tester.pump();
      expect(_semanticLabels(tester), isNot(contains('content')));
      progress.value = 0.5;
      await tester.pump();
      expect(_semanticLabels(tester), contains('content'));
      semantics.dispose();
    });
  });

  group('another kit surface as the panel', () {
    testWidgets('an outlined container takes the fade over like a popup', (
      tester,
    ) async {
      const panel = Key('container');
      await _open(
        tester,
        builder: (_) => const OutlinedContainer(
          key: panel,
          role: .functional,
          child: SizedBox(width: 120, height: 60),
        ),
      );
      await tester.pump(_kHalfOfOpen);

      final within = find.byKey(panel);
      expect(_passLayers(tester, within: within), hasLength(1));
      expect(_savingAlphasAbovePasses(tester, within: within), isEmpty);
      expect(_engineFade(tester, of: within).opacity.value, 1);
      expect(_fadeBoxes(tester).single.progress, closeTo(0.5, 1e-9));
      expect(_savingAlphas(tester), [128]);
    });

    testWidgets('a tooltip bubble takes the fade over like a popup', (
      tester,
    ) async {
      const bubble = Key('tip');
      await pumpTestApp(
        tester,
        const Tooltip(
          waitDuration: Duration.zero,
          tooltipChild: Text('tip', key: bubble),
          child: Text('trigger'),
        ),
        surfaceStyle: _glass,
      );
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(tester.getCenter(find.text('trigger')));
      await tester.pump();
      // Part of the way into the open: past the wait, short of the settle.
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump(const Duration(milliseconds: 40));

      expect(find.byKey(bubble), findsOneWidget);
      final progress = _fadeBoxes(tester).single.progress;
      expect(progress, inExclusiveRange(0, 1));
      final within = find.ancestor(
        of: find.byKey(bubble),
        matching: find.byType(SurfaceBlur),
      );
      expect(_passLayers(tester, within: within), isNotEmpty);
      expect(_savingAlphasAbovePasses(tester, within: within), isEmpty);
      expect(_engineFade(tester, of: find.byKey(bubble)).opacity.value, 1);

      await tester.pump(const Duration(seconds: 1));
      expect(_fadeBoxes(tester).single.progress, 1);
      await mouse.moveTo(const Offset(2, 2));
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('a dropdown menu panel takes the fade over like a popup', (
      tester,
    ) async {
      await pumpTestApp(
        tester,
        DropdownMenu(
          trigger: const Text('Open'),
          items: [CoreMenuItem.action('Profile', onPressed: () {})],
        ),
        surfaceStyle: _glass,
      );
      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));

      final within = find
          .ancestor(of: find.text('Profile'), matching: find.byType(Popup))
          .first;
      final progress = _fadeBoxes(tester).first.progress;
      expect(progress, inExclusiveRange(0, 1));
      expect(_passLayers(tester, within: within), isNotEmpty);
      expect(_savingAlphasAbovePasses(tester, within: within), isEmpty);
      expect(_engineFade(tester, of: find.text('Profile')).opacity.value, 1);
    });
  });

  group('the limits of the hand-off', () {
    testWidgets("a root that is not the kit's surface is left unfaded", (
      tester,
    ) async {
      const root = Key('root');
      await _open(
        tester,
        builder: (_) => const ColoredBox(
          key: root,
          color: Color(0xFF123456),
          child: Popup(children: [_content]),
        ),
      );
      await tester.pump(_kHalfOfOpen);

      // The surface inside is the first the host offers the fade to, so it
      // takes it over and the host stops applying its own — and the box
      // around it, which no surface owns, is faded by no one.
      expect(_engineFade(tester, of: find.byKey(root)).opacity.value, 1);
      expect(
        find.descendant(
          of: find.byKey(root),
          matching: find.byType(SurfaceFadeBox),
        ),
        findsOneWidget,
      );
      expect(_savingAlphas(tester), [128]);
    });

    testWidgets('siblings that disagree: the one with no pass is not faded', (
      tester,
    ) async {
      await _open(
        tester,
        builder: (_) => const Column(
          mainAxisSize: .min,
          children: [
            Popup(children: [_content]),
            Popup(
              popupStyle: CorePopupStyle(surfaceStyle: .defaultStyle),
              children: [SizedBox(key: Key('opaque'), width: 40, height: 20)],
            ),
          ],
        ),
      );
      await tester.pump(_kHalfOfOpen);

      // Both are offered the fade; the glass one claims it, the opaque one
      // declines — and nothing is left to fade the opaque one.
      expect(find.byType(SurfaceFadeAdopter), findsNWidgets(2));
      expect(
        _engineFade(tester, of: find.byKey(const Key('opaque'))).opacity.value,
        1,
      );
      expect(
        find.descendant(
          of: find.ancestor(
            of: find.byKey(const Key('opaque')),
            matching: find.byType(Popup),
          ),
          matching: find.byType(SurfaceFadeBox),
        ),
        findsNothing,
      );
    });
  });

  group('the edge light a surface draws', () {
    // Read back through one real-async hop: rasterising and the readback are
    // engine futures that never complete under the binding's fake clock.
    Future<(ByteData, int)> paint(
      WidgetTester tester,
      SurfaceSheenPainter painter,
      Size size,
    ) async {
      final result = await tester.runAsync(() async {
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder)
          ..drawRect(
            Offset.zero & size,
            Paint()..color = const Color(0xFF000000),
          );
        painter.paint(canvas, size);
        final image = await recorder.endRecording().toImage(
          size.width.round(),
          size.height.round(),
        );
        final bytes = (await image.toByteData())!;
        image.dispose();

        return (bytes, size.width.round());
      });

      return result!;
    }

    int red((ByteData, int) image, int x, int y) =>
        image.$1.getUint8(((y * image.$2) + x) * 4);

    SurfaceSheenPainter painter(double opacity) => SurfaceSheenPainter(
      radius: BorderRadius.circular(30),
      width: 6,
      lightColor: const Color(0xFFFFFFFF),
      darkColor: const Color(0xFFFFFFFF),
      fade: 0.18,
      rimWidth: 2,
      rimColor: const Color(0xFFFFFFFF),
      rimProfile: const CoreSurfaceEdgeBevel(
        thickness: 2,
        lightAngle: -45,
        lightIntensity: 0.8,
        rimWidth: 2,
        rimIntensity: 1,
      ),
      opacity: opacity,
    );

    testWidgets('keeps its share of its alpha, band and rim alike', (
      tester,
    ) async {
      const size = Size(160, 60);
      final rest = await paint(tester, painter(1), size);
      final half = await paint(tester, painter(0.5), size);
      final gone = await paint(tester, painter(0), size);

      // The band's lit run, mid-edge; and the rim on the corner that faces
      // the light, one pixel inside its stroke.
      const inset = 29.0;
      final corner = (30 - (inset * 0.7071)).round();
      for (final (name, x, y) in [
        ('band', 80, 2),
        ('rim', corner, corner),
      ]) {
        final full = red(rest, x, y);
        expect(full, greaterThan(150), reason: '$name at rest is drawn');
        expect(
          red(half, x, y),
          closeTo(full * 0.5, 4),
          reason: '$name at half keeps half of its alpha',
        );
        expect(red(gone, x, y), 0, reason: '$name at nothing paints nothing');
      }
    });

    test('compares by the opacity too', () {
      expect(painter(1).shouldRepaint(painter(0.5)), isTrue);
      expect(painter(0.5).shouldRepaint(painter(0.5)), isFalse);
    });
  });

  group('the table', () {
    testWidgets('states what the surface draws at each held progress', (
      tester,
    ) async {
      final cases =
          ((_vectors()['material']! as Map<String, Object?>)['cases']!
                  as List<Object?>)
              .cast<Map<String, Object?>>();
      for (final row in cases) {
        final progress = _num(row['progress']);
        final reason = 'progress $progress';
        await tester.pumpWidget(const SizedBox());
        await pumpTestApp(
          tester,
          SurfaceBlur(
            surfaceBlur: 4,
            surfaceSaturation: 1.6,
            surfaceBackdropBrightness: 0.92,
            fadeProgress: progress,
            child: const SizedBox(width: 40, height: 40),
          ),
          theme: const ThemeData().copyWith(
            surfaceFrost: () => const CoreSurfaceFrost(sigma: 14, opacity: 0.8),
          ),
        );

        if (progress == 0) {
          expect(find.byType(BackdropFilter), findsNothing, reason: reason);
          continue;
        }
        final passes = find
            .byType(BackdropFilter)
            .evaluate()
            .map((e) => e.widget as BackdropFilter)
            .toList();
        expect(passes, hasLength(2), reason: reason);
        expect(
          passes.first.filter,
          _sameFilter(_frostFilter(14, _num(row['frostOpacity']))),
          reason: 'frost at $reason',
        );
        expect(
          passes.last.filter,
          _sameFilter(
            _passFilter(
              _num(row['blur']),
              _num(row['saturation']),
              _num(row['brightness']),
            ),
          ),
          reason: 'material at $reason',
        );
      }
    });
  });
}
