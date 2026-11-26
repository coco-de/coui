// A glass dialog keeps its backdrop pass while it fades: the route does not
// wrap such a panel in an opacity that saves a layer above the pass, and the
// panel's surface fades its own terms from the progress instead.
//
// The mechanism is the one a popover panel is faded by
// (`popover_glass_fade_test.dart` holds its arithmetic against the shared
// table). What is held here is that the dialog route offers it, that the
// dialog's panel takes it, and that nothing the hand-off was not made for
// changes: a panel whose surface draws no pass, a full-screen route and a
// panel that is not the kit's surface are faded as a whole, as they always
// were.
//
// What this holds is the layer tree and the numbers in it. What the compositor
// makes of them — whether the stripes behind a held dialog are really
// blurred — is the engine's, and is measured on a device
// (`app/coui_widgetbook/integration_test/dialog_fade_probe_test.dart`):
// `flutter_tester` paints the layers and rasterises none of the filters.
import 'dart:async';
import 'dart:ui' as ui;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:coui_flutter/src/components/infra/outlined_container/surface_fade.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart' as w;
import 'package:flutter_test/flutter_test.dart';

/// The route runs this long, in both directions, so `pump(500 ms)` holds it at
/// half of its animation.
const Duration _kRoute = Duration(milliseconds: 1000);

const Duration _kHalf = Duration(milliseconds: 500);
const Duration _kFrame = Duration(milliseconds: 16);

const CoreSurfaceStyleId _glass = CoreSurfaceStyleId.liquidGlass;

const w.Key _content = w.ValueKey('content');

/// What the dialog is made of unless a test asks for another: a titled panel
/// with a body that paints nothing, so what a test reads off the layer tree is
/// the surface's own.
w.Widget _dialog(w.BuildContext _) => const Dialog(
  title: Text('Title'),
  content: w.SizedBox(key: _content, width: 120, height: 60),
);

/// Mounts an app, opens a dialog route over it and builds its first frame
/// (progress 0). Returns the app's context, which closes the route.
Future<w.BuildContext> _open(
  WidgetTester tester, {
  CoreSurfaceStyleId style = _glass,
  bool fullScreen = false,
  w.WidgetBuilder builder = _dialog,
}) async {
  late w.BuildContext app;
  await tester.pumpWidget(
    CoUIApp(
      theme: ThemeData.fromCore(CoreThemePresets.light),
      surfaceStyle: style,
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
      fullScreen: fullScreen,
      dialogStyle: const CoreDialogStyle(transitionDuration: _kRoute),
      builder: builder,
    ),
  );
  await tester.pump();

  return app;
}

/// Where the route's animation has to be for the dialog to read [route] of its
/// way in: the dialog's fade runs the route's progress through the enter curve.
double _eased(double route) => CoreEasing.enter.toValue().transform(route);

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

/// The backdrop filter layers under the dialog's surface, in paint order.
List<BackdropFilterLayer> _passLayers(WidgetTester tester) => [
  for (final element
      in find
          .descendant(
            of: find.byType(SurfaceBlur),
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

/// The alphas of the opacity layers above the backdrop passes that save a
/// layer — the ones an opacity at less than full alpha makes.
List<int> _savingAlphasAbovePasses(WidgetTester tester) => [
  for (final pass in _passLayers(tester))
    for (final opacity in _opacitiesAbove(pass))
      if (opacity.alpha! < 255) opacity.alpha!,
];

/// The route's own fade: the nearest `RenderAnimatedOpacity` above the panel.
RenderAnimatedOpacity _routeFade(WidgetTester tester) {
  RenderAnimatedOpacity? found;
  tester.element(find.byType(Dialog)).visitAncestorElements((element) {
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

/// What the dialog's pass states at rest in `flutter_tester`: the material the
/// panel resolved, with the blur a surface draws where the bend it asked for
/// cannot be drawn — `flutter_tester` cannot run the program.
({double blur, double saturation, double brightness}) _restMaterial(
  WidgetTester tester,
) {
  final context = tester.element(find.byType(SurfaceBlur));
  final resolved = resolveDialog(context);
  final blur = surfaceDrawnBlur(
    blur: resolved.surfaceBlur,
    refraction: Theme.of(context).surfaceRefraction,
  );
  expect(blur, isNotNull, reason: 'a glass dialog draws a backdrop pass');

  return (
    blur: blur!,
    saturation: resolved.surfaceSaturation ?? 1,
    brightness: resolved.surfaceBackdropBrightness ?? 1,
  );
}

/// The filter the pass states [material] at [progress] of the way in — the
/// arithmetic is Core's.
ui.ImageFilter _passAt(
  ({double blur, double saturation, double brightness}) material,
  double progress,
) {
  final blur = CoreSurfaceDissolve.scaled(material.blur, progress);

  return ui.ImageFilter.compose(
    outer: ColorFilter.matrix(
      backdropColorMatrix(
        saturation: CoreSurfaceDissolve.towardIdentity(
          material.saturation,
          progress,
        ),
        brightness: CoreSurfaceDissolve.towardIdentity(
          material.brightness,
          progress,
        ),
      ),
    ),
    inner: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
  );
}

/// The numbers an `ImageFilter` is made of, read from its description — the
/// filter keeps no accessor of its own, and its equality is exact, which a
/// product of two doubles is not.
List<double> _numbers(ui.ImageFilter filter) => [
  for (final match in RegExp(
    r'-?\d+(?:\.\d+)?(?:e-?\d+)?',
  ).allMatches(filter.toString()))
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
  group('a glass dialog at half of its open', () {
    testWidgets('has no layer above its backdrop pass that saves a pass', (
      tester,
    ) async {
      await _open(tester);
      await tester.pump(_kHalf);

      expect(_passLayers(tester), hasLength(1));
      expect(
        _savingAlphasAbovePasses(tester),
        isEmpty,
        reason:
            'an opacity under 255 above a backdrop filter saves a layer the '
            'filter then reads nothing of',
      );
    });

    testWidgets('is faded once: by the surface, not also by the route', (
      tester,
    ) async {
      await _open(tester);
      await tester.pump(_kHalf);

      // The route paints at full alpha, which the framework emits as an
      // offset — the layer the panel at rest has always been drawn through.
      expect(_routeFade(tester).opacity.value, 1);
      expect(
        _savingAlphas(tester),
        [ui.Color.getAlphaFromOpacity(_eased(0.5))],
        reason:
            'exactly one layer fades the panel, at the progress the route '
            'states — the surface puts it over its fill and content, beside '
            'its pass',
      );
    });

    testWidgets('fades the content in a layer beside the pass, not over it', (
      tester,
    ) async {
      await _open(tester);
      await tester.pump(_kHalf);

      final pass = _passLayers(tester).single;
      final alpha = ui.Color.getAlphaFromOpacity(_eased(0.5));
      final fading = _allLayers(
        tester,
      ).whereType<OpacityLayer>().where((layer) => layer.alpha == alpha).single;
      // Neither contains the other: the opacity is over what the pass sits
      // under, not over the pass.
      expect(_opacitiesAbove(pass), isNot(contains(fading)));
      for (final inner in _layersUnder(fading)) {
        expect(inner, isNot(isA<BackdropFilterLayer>()));
      }
    });

    testWidgets('draws the material at the share of what it states', (
      tester,
    ) async {
      await _open(tester);
      await tester.pump(_kHalf);

      final progress = _eased(0.5);
      expect(_fadeBoxes(tester).single.progress, closeTo(progress, 1e-9));
      expect(
        _passLayers(tester).single.filter,
        _sameFilter(_passAt(_restMaterial(tester), progress)),
      );
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

        final progress = _eased(level);
        expect(
          _savingAlphasAbovePasses(tester),
          isEmpty,
          reason: 'level $level',
        );
        expect(
          _fadeBoxes(tester).single.progress,
          closeTo(progress, 1e-9),
          reason: 'level $level',
        );
        expect(
          _passLayers(tester).single.filter,
          _sameFilter(_passAt(_restMaterial(tester), progress)),
          reason: 'level $level',
        );
      }
    });
  });

  group('a glass dialog at rest', () {
    testWidgets('keeps its pass at the stated material, with nothing saved '
        'above or beside it', (tester) async {
      await _open(tester);
      await tester.pump(_kRoute);
      await tester.pump(_kFrame);

      expect(_routeFade(tester).opacity.value, 1);
      expect(_savingAlphas(tester), isEmpty);
      expect(
        _passLayers(tester).single.filter,
        _sameFilter(_passAt(_restMaterial(tester), 1)),
      );
    });

    testWidgets('paints the content straight through, with no layer of its '
        'own', (tester) async {
      await _open(tester);
      await tester.pump(_kRoute);
      await tester.pump(_kFrame);

      final box = _fadeBoxes(tester).single;
      expect(box.progress, 1);
      expect(box.isRepaintBoundary, isFalse);
      expect(box.alwaysNeedsCompositing, isFalse);
    });
  });

  group('a glass dialog at nothing', () {
    testWidgets('paints nothing: no pass, no fill, no content', (tester) async {
      await _open(tester);

      // The first frame is the panel at nothing.
      expect(_routeFade(tester).opacity.value, 0);
      expect(find.byType(BackdropFilter), findsNothing);
      final box = _fadeBoxes(tester).single;
      expect(box.debugAlpha, 0);
      expect(box.isRepaintBoundary, isFalse);
    });
  });

  group('a glass dialog closing', () {
    testWidgets('is held the same way going out', (tester) async {
      final app = await _open(tester);
      await tester.pump(_kRoute);
      await tester.pump(_kFrame);

      w.Navigator.of(app).pop();
      await tester.pump();
      await tester.pump(_kHalf);

      final progress = _eased(0.5);
      expect(_routeFade(tester).opacity.value, 1);
      expect(_savingAlphasAbovePasses(tester), isEmpty);
      expect(_fadeBoxes(tester).single.progress, closeTo(progress, 1e-6));
      expect(
        _passLayers(tester).single.filter,
        _sameFilter(_passAt(_restMaterial(tester), progress)),
      );
    });

    testWidgets('gives its pass up with the fill, with no step in between', (
      tester,
    ) async {
      final app = await _open(tester);
      await tester.pump(_kRoute);
      await tester.pump(_kFrame);

      w.Navigator.of(app).pop();
      await tester.pump();
      // Walk the close: every frame the pass is there exactly while the fill
      // is, and the progress it is held at only goes down.
      var previous = double.infinity;
      var walked = 0;
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 40));
        final boxes = _fadeBoxes(tester);
        if (boxes.isEmpty) break;
        walked++;
        final progress = boxes.single.progress;
        expect(progress, lessThanOrEqualTo(previous));
        previous = progress;
        final passes = _passLayers(tester);
        if (ui.Color.getAlphaFromOpacity(progress) == 0) {
          expect(passes, isEmpty, reason: 'nothing is painted at nothing');
        } else {
          expect(passes, hasLength(1), reason: 'at progress $progress');
          expect(
            _savingAlphasAbovePasses(tester),
            isEmpty,
            reason: 'at progress $progress',
          );
        }
      }
      // A walk that found nothing to read is not a walk.
      expect(walked, greaterThan(10), reason: 'the close was walked');
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
    });
  });

  group('a dialog whose surface draws no backdrop pass', () {
    testWidgets('is faded as a whole by the route', (tester) async {
      await _open(tester, style: CoreSurfaceStyleId.defaultStyle);
      await tester.pump(_kHalf);

      final progress = _eased(0.5);
      expect(find.byType(BackdropFilter), findsNothing);
      expect(
        _routeFade(tester).opacity.value,
        closeTo(progress, 1e-9),
        reason: 'no surface claimed the fade, so the route keeps it',
      );
      expect(
        _savingAlphas(tester),
        contains(ui.Color.getAlphaFromOpacity(progress)),
      );
      expect(find.byType(SurfaceFadeBox), findsNothing);
    });
  });

  group('what the hand-off is not made for', () {
    testWidgets('a full-screen route is faded as a whole', (tester) async {
      await _open(tester, fullScreen: true);
      await tester.pump(_kHalf);

      // No scope is offered, so nothing mounts a wrapper for it.
      expect(find.byType(SurfaceFadeAdopter), findsNothing);
      expect(find.byType(SurfaceFadeHost), findsNothing);
      expect(
        _routeFade(tester).opacity.value,
        closeTo(_eased(0.5), 1e-9),
        reason: 'the page the caller put in the route fades with the route',
      );
    });

    testWidgets("a panel that is not the kit's surface is faded as a whole", (
      tester,
    ) async {
      await _open(
        tester,
        builder: (_) => const w.SizedBox(key: _content, width: 120, height: 60),
      );
      await tester.pump(_kHalf);

      expect(find.byType(SurfaceFadeAdopter), findsNothing);
      expect(find.byType(SurfaceFadeBox), findsNothing);
      final render = tester.renderObject(find.byKey(_content));
      RenderAnimatedOpacity? fade;
      for (var node = render.parent; node != null; node = node.parent) {
        if (node is RenderAnimatedOpacity) {
          fade = node;
          break;
        }
      }
      expect(fade, isNotNull);
      expect(fade!.opacity.value, closeTo(_eased(0.5), 1e-9));
    });
  });

  group('the state inside the dialog', () {
    testWidgets('a focused field keeps its state and its focus from the first '
        'frame to rest', (tester) async {
      final controller = w.TextEditingController();
      final focusNode = w.FocusNode();
      addTearDown(controller.dispose);
      addTearDown(focusNode.dispose);
      await _open(
        tester,
        builder: (_) => Dialog(
          title: const Text('Title'),
          content: w.EditableText(
            controller: controller,
            focusNode: focusNode,
            autofocus: true,
            style: const w.TextStyle(),
            cursorColor: const w.Color(0xFF000000),
            backgroundCursorColor: const w.Color(0xFF000000),
          ),
        ),
      );

      // The field is built on the first frame, at nothing — it has to be the
      // same field on every frame after, not one rebuilt when the fade ends.
      final first = tester.state<w.EditableTextState>(
        find.byType(w.EditableText),
      );
      for (final step in [_kFrame, _kHalf, _kHalf, _kFrame]) {
        await tester.pump(step);
        expect(
          tester.state<w.EditableTextState>(find.byType(w.EditableText)),
          same(first),
          reason: 'the field was rebuilt',
        );
      }
      expect(focusNode.hasFocus, isTrue);
    });
  });

  group('the host', () {
    testWidgets('is gone with the dialog, taking its claim with it', (
      tester,
    ) async {
      final app = await _open(tester);
      await tester.pump(_kRoute);
      expect(find.byType(SurfaceFadeHost), findsOneWidget);

      w.Navigator.of(app).pop();
      await tester.pumpAndSettle();

      expect(find.byType(SurfaceFadeHost), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('the cast', () {
    testWidgets('of a translucent panel is painted outside the box', (
      tester,
    ) async {
      // Flutter's `BoxDecoration.boxShadow` fills a shape behind the box and
      // lets the fill paint over it; CSS paints an outer shadow outside the
      // border box only. Under an opaque fill the two look the same. The
      // glass panel's fill is translucent, and a cast in its decoration
      // showed through the panel — on Flutter only.
      await _open(tester);
      await tester.pump(_kRoute);

      expect(
        _panelFill(tester).a,
        lessThan(1),
        reason: "the premise: the glass panel's fill is translucent",
      );
      expect(_casts(tester), hasLength(1));
      expect(_casts(tester).single.shadows, isNotEmpty);
      expect(
        _decorationsWithCast(tester),
        isEmpty,
        reason:
            'two casts would stack, and the one in the decoration is the '
            'kind that shows through the fill',
      );
    });

    testWidgets('of an opaque panel stays in its decoration', (tester) async {
      // Nothing can show through an opaque fill, so the tree is the one it
      // always was: no wrapper nobody asked for.
      await _open(tester, style: CoreSurfaceStyleId.defaultStyle);
      await tester.pump(_kRoute);

      expect(_panelFill(tester).a, 1);
      expect(_casts(tester), isEmpty);
      expect(_decorationsWithCast(tester), hasLength(1));
    });

    testWidgets('fades with the panel by the progress', (tester) async {
      // Outside the box, the cast is also outside the opacity the fill and
      // the content fade under, so it is faded by the progress itself.
      await _open(tester);
      await tester.pump(_kHalf);
      final progress = _eased(0.5);
      final held = [
        for (final shadow in _casts(tester).single.shadows) shadow.color.a,
      ];

      await tester.pump(_kRoute);
      final rest = [
        for (final shadow in _casts(tester).single.shadows) shadow.color.a,
      ];

      expect(rest, isNotEmpty);
      expect(held, hasLength(rest.length));
      for (var i = 0; i < rest.length; i++) {
        expect(held[i], closeTo(rest[i] * progress, 1e-6), reason: 'layer $i');
      }
    });
  });
}

/// The panel's fill, read off the decoration that paints it.
Color _panelFill(WidgetTester tester) => _decorationsUnderDialog(
  tester,
).firstWhere((decoration) => decoration.color != null).color!;

/// The casts painted outside a box under the dialog.
List<InjectedCast> _casts(WidgetTester tester) => tester
    .widgetList<InjectedCast>(
      find.descendant(
        of: find.byType(Dialog),
        matching: find.byType(InjectedCast),
      ),
    )
    .toList();

/// The decorations under the dialog that state a box shadow — the kind that
/// fills a shape behind the box.
List<BoxDecoration> _decorationsWithCast(WidgetTester tester) => [
  for (final decoration in _decorationsUnderDialog(tester))
    if ((decoration.boxShadow ?? const <BoxShadow>[]).isNotEmpty) decoration,
];

List<BoxDecoration> _decorationsUnderDialog(WidgetTester tester) => tester
    .widgetList<w.DecoratedBox>(
      find.descendant(
        of: find.byType(Dialog),
        matching: find.byType(w.DecoratedBox),
      ),
    )
    .map((box) => box.decoration)
    .whereType<BoxDecoration>()
    .toList();
