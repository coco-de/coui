import 'dart:ui' as ui;

import 'package:coui_core/coui_core.dart';
import 'package:coui_flutter/src/components/infra/outlined_container/surface_backdrop_pass.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Float indices the refraction program's uniforms are written at.
///
/// `setFloat` addresses uniforms by index in declaration order, a `vec2`
/// counting as two. The engine owns 0 and 1 (`uSize`). Nothing checks the
/// mapping at runtime — a pair swapped compiles, runs, and bends by an
/// index it read as a radius — so `surface_refraction_parity_test.dart`
/// pins these against the shader's declarations.
const int kSurfaceRefractionBezelIndex = 2;
const int kSurfaceRefractionRadiusIndex = 3;
const int kSurfaceRefractionStrengthIndex = 4;
const int kSurfaceRefractionIndexIndex = 5;
const int kSurfaceRefractionDispersionIndex = 6;
const int kSurfaceRefractionOriginIndex = 7;
const int kSurfaceRefractionExtentIndex = 9;
const int kSurfaceRefractionLensIndex = 11;

/// `uRefractionModel`: the law the rim is bent by, as
/// [surfaceRefractionModelUniform] spells it.
const int kSurfaceRefractionModelIndex = 12;

/// `uBodyShade`: how much of itself a white pixel loses, as
/// `CoreSurfaceBodyShade.strength` states it. Zero draws nothing.
const int kSurfaceBodyShadeIndex = 13;

/// The number the fragment program reads a [CoreRefractionModel] as.
///
/// An exhaustive switch rather than `index`: a member added to the enum is
/// a compile error here until the shader has a branch for it, instead of a
/// value the program quietly reads as the default.
double surfaceRefractionModelUniform(CoreRefractionModel model) =>
    switch (model) {
      CoreRefractionModel.snell => 0,
      CoreRefractionModel.paraxial => 1,
    };

/// The surface's rectangle in the pixels the refraction program measures
/// in: [transform] takes the surface's local space to the root, and the
/// root's logical pixels become the backdrop texture's at [devicePixelRatio].
///
/// Kept as a function rather than a line inside the layer because it is the
/// one piece of this file a widget test can reach — the layer only runs
/// where the scene is actually built.
Rect surfaceRectInBackdropPixels({
  required Matrix4 transform,
  required Size size,
  required double devicePixelRatio,
}) {
  final root = MatrixUtils.transformRect(transform, Offset.zero & size);

  return Rect.fromLTWH(
    root.left * devicePixelRatio,
    root.top * devicePixelRatio,
    root.width * devicePixelRatio,
    root.height * devicePixelRatio,
  );
}

/// The material pass with the bend on top — a backdrop filter whose
/// refraction program is told, every frame, where the surface is.
///
/// ## Why the surface has to say where it is
///
/// An `ImageFilter.shader` program does not run in the surface's
/// coordinates. `uSize` and `FlutterFragCoord()` describe the backdrop
/// snapshot the filter reads — the whole render target, the window on
/// screen — and nothing tells the program which part of that is the
/// surface. Measured on Impeller (`refraction_sampling_probe_test.dart` and
/// its siblings): composed or bare, clipped or not, under an `Opacity` or
/// not, the program saw the capture's size and the capture's pixels.
///
/// The shipped shader used to take those for the surface's rectangle and so
/// bent the *window's* rim. A panel at the screen's edge showed the window's
/// band through its own edge and looked right; a panel anywhere else did not
/// bend at all — measured, zero dispersed pixels inside its band. The Web
/// renderer bakes its displacement map per element and never had the
/// problem, which is what made it a divergence rather than a look.
///
/// ## Why at scene-build time, not at paint
///
/// The rectangle is the surface's transform to the root, and that changes
/// without the surface repainting — an ancestor scrolls, a route slides —
/// so a value captured at paint would be stale on exactly the frames people
/// watch. The layer below recomputes it each time the scene is built and
/// writes the program's uniforms then, the same moment the compositor reads
/// them. That costs one `getTransformTo` per surface per frame and a fresh
/// uniform buffer; the empty child costs nothing to re-add.
///
/// ## What it assumes
///
/// That the backdrop the filter reads is the root render view at the device
/// pixel ratio. That holds while no layer above the surface saves a pass that
/// starts anywhere but the root's origin, and it is checked every time the
/// scene is built (see [backdropReadsRootPass]): a surface inside a frosted
/// container, a fade under a clip or a layer blur is handed the coordinates
/// of that pass, which would put the band where the surface is not. There the
/// surface keeps the rest of its material and does not bend, the same answer
/// it gives wherever the engine cannot run the program.
///
/// A capture that rasterises a subtree with `toImage` makes that subtree the
/// root, so a probe that captures must place its boundary at the root's
/// origin for the two to agree.
class SurfaceBackdrop extends SingleChildRenderObjectWidget {
  const SurfaceBackdrop({
    required this.material,
    required this.program,
    required this.cornerRadius,
    required this.devicePixelRatio,
    required super.child,
    super.key,
    this.refraction,
    this.bodyShade = 0,
  }) : assert(
         refraction != null || bodyShade > 0,
         'A program with nothing to bend and nothing to shade is a pass the '
         'plain backdrop filter already draws.',
       );

  /// The blur, with the chroma lift composed over it when there is one.
  final ui.ImageFilter material;

  /// The compiled refraction program.
  final ui.FragmentProgram program;

  /// The bend the surface asked for, or null for a surface that only shades.
  final CoreSurfaceRefraction? refraction;

  /// How much of itself a white pixel loses under this surface, 0 to 1
  /// (`CoreSurfaceBodyShade.strength`), or zero for no shade.
  ///
  /// The same program draws it, so a surface that bends and shades pays for
  /// one pass, and one that shades alone mounts the program with every
  /// geometric uniform at zero. Unlike the bend it needs no coordinates, so
  /// it is drawn in whatever pass the layers above hand the program — see
  /// [RenderSurfaceBackdrop].
  final double bodyShade;

  /// The surface's corner, in logical pixels.
  final double cornerRadius;

  /// Logical-to-device scale of the root the backdrop is read from.
  final double devicePixelRatio;

  @override
  RenderSurfaceBackdrop createRenderObject(BuildContext context) =>
      RenderSurfaceBackdrop(
        material: material,
        program: program,
        refraction: refraction,
        bodyShade: bodyShade,
        cornerRadius: cornerRadius,
        devicePixelRatio: devicePixelRatio,
      );

  @override
  void updateRenderObject(
    BuildContext context,
    RenderSurfaceBackdrop renderObject,
  ) {
    renderObject
      ..material = material
      ..program = program
      ..refraction = refraction
      ..bodyShade = bodyShade
      ..cornerRadius = cornerRadius
      ..devicePixelRatio = devicePixelRatio;
  }
}

/// Paints like `RenderBackdropFilter`, through a layer that resolves the
/// filter when the scene is built rather than when this object paints.
class RenderSurfaceBackdrop extends RenderProxyBox {
  RenderSurfaceBackdrop({
    required ui.ImageFilter material,
    required ui.FragmentProgram program,
    required CoreSurfaceRefraction? refraction,
    required double bodyShade,
    required double cornerRadius,
    required double devicePixelRatio,
  }) : _material = material,
       _program = program,
       _refraction = refraction,
       _bodyShade = bodyShade,
       _cornerRadius = cornerRadius,
       _devicePixelRatio = devicePixelRatio;

  ui.ImageFilter _material;
  set material(ui.ImageFilter value) {
    if (identical(_material, value) || _material == value) return;
    _material = value;
    markNeedsPaint();
  }

  ui.FragmentProgram _program;
  set program(ui.FragmentProgram value) {
    if (identical(_program, value)) return;
    _program = value;
    _shader?.dispose();
    _shader = null;
    markNeedsPaint();
  }

  CoreSurfaceRefraction? _refraction;
  set refraction(CoreSurfaceRefraction? value) {
    if (_refraction == value) return;
    _refraction = value;
    markNeedsPaint();
  }

  double _bodyShade;

  /// How much of itself a white pixel loses under this surface, 0 to 1.
  double get bodyShade => _bodyShade;
  set bodyShade(double value) {
    if (_bodyShade == value) return;
    _bodyShade = value;
    markNeedsPaint();
  }

  double _cornerRadius;
  set cornerRadius(double value) {
    if (_cornerRadius == value) return;
    _cornerRadius = value;
    markNeedsPaint();
  }

  double _devicePixelRatio;
  set devicePixelRatio(double value) {
    if (_devicePixelRatio == value) return;
    _devicePixelRatio = value;
    markNeedsPaint();
  }

  /// One shader for the life of the program; its uniforms are rewritten
  /// per scene. A new shader per frame would allocate for nothing.
  ui.FragmentShader? _shader;

  /// The rectangle the last scene build resolved for this surface, in the
  /// backdrop texture's pixels — what the compositor was told, not what the
  /// last paint saw.
  ///
  /// Null until a scene has been built. Recorded in debug and test builds
  /// only, so a widget test can hold that the rectangle follows a move that
  /// never repainted this surface (see `surface_backdrop_layout_move_test`).
  @visibleForTesting
  Rect? get debugResolvedRect => _debugResolvedRect;
  Rect? _debugResolvedRect;

  /// How many times a scene build has resolved this surface's filter.
  ///
  /// One per scene while the layer is re-added every time; a layer the
  /// compositor retained would not count.
  @visibleForTesting
  int get debugResolveCount => _debugResolveCount;
  int _debugResolveCount = 0;

  @override
  _SurfaceBackdropLayer? get layer => super.layer as _SurfaceBackdropLayer?;

  @override
  bool get alwaysNeedsCompositing => child != null;

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child == null) {
      layer = null;

      return;
    }
    assert(needsCompositing);
    final backdrop = layer ??= _SurfaceBackdropLayer();
    backdrop.resolve = _resolveFilter;
    context.pushLayer(backdrop, super.paint, offset);
  }

  /// The composed filter for the surface's current rectangle: the bend,
  /// outer, over the material pass. Bending first and blurring after would
  /// smear the displacement back out and cost a pass to achieve less.
  ///
  /// Where the engine cannot run the program the material goes out alone.
  /// The surface that mounts this already checked, so on a device that is
  /// not the branch taken for want of an engine; it is what lets the widget
  /// exist at all under `flutter_tester`, whose `ImageFilter.shader` is an
  /// unconditional throw.
  ///
  /// The bend goes out as well where the layers above this one hand the
  /// program another pass's coordinates, because the rectangle below would be
  /// measured in the wrong ones — and the shade does not, because it measures
  /// nothing. A surface that only shades keeps the shade there; one that
  /// bends and shades keeps the shade and loses the bend; one that only bends
  /// has the material alone.
  ui.ImageFilter _resolveFilter() {
    // Before the capability gate so a headless test, where the gate always
    // answers no, still sees the rectangle a device would have been given.
    final rect = surfaceRectInBackdropPixels(
      transform: getTransformTo(null),
      size: size,
      devicePixelRatio: _devicePixelRatio,
    );
    assert(() {
      _debugResolvedRect = rect;
      _debugResolveCount++;

      return true;
    }(), 'debug-only record for tests');
    if (!ui.ImageFilter.isShaderFilterSupported) return _material;
    // The bend needs the root's coordinates and the shade needs none, so a
    // surface whose pass the layers above have moved keeps its shade and
    // loses only the bend.
    final bend = _readsRootPass() ? _refraction : null;
    if (bend == null && _bodyShade <= 0) return _material;

    final shader = _shader ??= _program.fragmentShader();
    // Every uniform is written on every scene: the shader outlives the
    // scene, and a bend that was on a frame ago must not stay on because
    // this frame has none.
    shader
      ..setFloat(kSurfaceRefractionBezelIndex, bend?.bezel ?? 0)
      ..setFloat(
        kSurfaceRefractionRadiusIndex,
        _cornerRadius * _devicePixelRatio,
      )
      ..setFloat(kSurfaceRefractionStrengthIndex, bend?.strength ?? 0)
      ..setFloat(kSurfaceRefractionIndexIndex, bend?.refractiveIndex ?? 1)
      ..setFloat(kSurfaceRefractionDispersionIndex, bend?.dispersion ?? 0)
      ..setFloat(kSurfaceRefractionOriginIndex, rect.left)
      ..setFloat(kSurfaceRefractionOriginIndex + 1, rect.top)
      ..setFloat(kSurfaceRefractionExtentIndex, rect.width)
      ..setFloat(kSurfaceRefractionExtentIndex + 1, rect.height)
      ..setFloat(kSurfaceRefractionLensIndex, bend?.lens ?? 0)
      ..setFloat(
        kSurfaceRefractionModelIndex,
        bend == null ? 0 : surfaceRefractionModelUniform(bend.model),
      )
      ..setFloat(kSurfaceBodyShadeIndex, _bodyShade);

    return ui.ImageFilter.compose(
      outer: ui.ImageFilter.shader(shader),
      inner: _material,
    );
  }

  /// Whether the layers above this surface leave the filter reading the
  /// root's pixels. Asked at scene-build time, when the surface's layer is
  /// attached; before its first paint there is nothing above it to ask.
  bool _readsRootPass() {
    final backdrop = layer;

    return backdrop == null || backdropReadsRootPass(backdrop);
  }

  /// [_readsRootPass], for a test: the scene-time resolve only runs where a
  /// scene is built, and the program only runs on Impeller, so the decision
  /// is the part a widget test can read.
  @visibleForTesting
  bool get debugReadsRootPass => _readsRootPass();

  @override
  void dispose() {
    _shader?.dispose();
    _shader = null;
    super.dispose();
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        DiagnosticsProperty<CoreSurfaceRefraction>('refraction', _refraction),
      )
      ..add(DoubleProperty('bodyShade', _bodyShade))
      ..add(DoubleProperty('cornerRadius', _cornerRadius))
      ..add(DoubleProperty('devicePixelRatio', _devicePixelRatio));
  }
}

/// A backdrop filter layer whose filter is decided when the scene is built.
///
/// `alwaysNeedsAddToScene` keeps it out of the retained-layer cache, so
/// every frame that reaches the compositor asks [resolve] again — which is
/// what lets the surface's rectangle follow a scroll it never repainted for.
///
/// The resolved filter is pushed directly rather than stored through the
/// `filter` setter: that setter marks the layer as needing a scene update,
/// and the framework asserts a layer that always needs one never asks.
class _SurfaceBackdropLayer extends BackdropFilterLayer {
  ui.ImageFilter Function()? resolve;

  @override
  bool get alwaysNeedsAddToScene => true;

  @override
  void addToScene(ui.SceneBuilder builder) {
    final resolved = resolve?.call() ?? filter;
    assert(resolved != null, 'nothing to filter with');
    engineLayer = builder.pushBackdropFilter(
      resolved!,
      blendMode: blendMode,
      oldLayer: engineLayer as ui.BackdropFilterEngineLayer?,
    );
    addChildrenToScene(builder);
    builder.pop();
  }
}
