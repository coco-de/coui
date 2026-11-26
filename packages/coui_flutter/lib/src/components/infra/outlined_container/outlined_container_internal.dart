import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:coui_flutter/coui_flutter.dart';
import 'package:coui_flutter/src/components/infra/outlined_container/surface_fade.dart';
import 'package:coui_flutter/src/components/infra/outlined_container/web_surface_backdrop.dart';

// === Outlined Container Component Constants ===

/// Default gap between dashes — sourced from [CoreDashedBorder].
const double _kDefaultDashedGap = CoreDashedBorder.dashGap;

/// Default thickness of dashes — sourced from [CoreDashedBorder].
const double _kDefaultDashedThickness = CoreDashedBorder.strokeWidth;

/// Default width of dashes — sourced from [CoreDashedBorder].
const double _kDefaultDashedWidth = CoreDashedBorder.dashLength;

/// How many surfaces a widget already sits inside.
///
/// Flowed down the tree rather than passed by callers, because nesting
/// is a property of the tree and not of either component: a card is
/// right to be a surface, and so is the card it sits in. Only the pair
/// is wrong, and only something that can see the pair can say so. On the
/// Web that something is the cascade; here it is this.
///
/// Components never read it. A resolver does, and hands the depth to
/// `ThemeData.surfaceFor` alongside the role its component declared —
/// the same shape the role axis already has, where the component states
/// an identity and the axis turns it into a material.
class SurfaceDepth extends InheritedWidget {
  /// Marks [child] as sitting inside [depth] surfaces.
  const SurfaceDepth({required this.depth, required super.child, super.key});

  /// The number of surfaces above this point in the tree.
  final int depth;

  /// The depth at [context], or zero where no surface is above it.
  static int of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SurfaceDepth>()?.depth ?? 0;

  @override
  bool updateShouldNotify(SurfaceDepth oldWidget) => depth != oldWidget.depth;
}

/// The frost a surface at [context] lays under its material, or null for
/// none.
///
/// **The one place a surface is let off the frost.** The cloud is the most
/// expensive term of the material — one extra backdrop pass per surface that
/// draws it, on top of the pass the surface already runs — and the cheapest
/// to lose: without it the surface keeps its blur, chroma lift, dimming,
/// shade and bend, and reads as the same glass with less of a cloud in it.
/// A rule that sheds it under load (a frame budget, a count of surfaces on
/// screen, a thermal state) belongs here and returns null, and nothing else
/// in the render path has to know.
///
/// Today the answer is the theme's: the style seat has already dropped it
/// for high contrast and reduced transparency, so this is null there, and
/// null where no theme is above the surface at all.
CoreSurfaceFrost? resolveSurfaceFrost(BuildContext context) =>
    Theme.maybeOf(context)?.surfaceFrost;

/// The blur a surface that asked for [blur] draws, or null for none.
///
/// What the asked-for blur becomes once the engine's answer about the bend is
/// in: where [refraction] was asked for and cannot be drawn, the blur goes up
/// by the request's `fallbackBlurAdd`, so a surface that loses its bend is not
/// flatter than the one that kept it. The correction lands only where the bend
/// is *impossible*, never while the program is still arriving — applying it
/// during the load would make the blur step down the moment the shader landed,
/// a visible jump on exactly the platforms that support the feature, caused by
/// the code meant to help the ones that do not.
///
/// Null is no pass: a blur that is absent, or that comes to nothing, is not a
/// pass to mount.
double? surfaceDrawnBlur({
  required double? blur,
  required CoreSurfaceRefraction? refraction,
}) {
  if (blur == null) return null;
  final drawn =
      refraction == null ||
          ImageFilter.isShaderFilterSupported ||
          webSurfaceRefractionSupported
      ? blur
      : blur + refraction.fallbackBlurAdd;

  return drawn > 0 ? drawn : null;
}

/// Whether a surface that asked for [blur] and [refraction] draws a backdrop
/// pass.
///
/// **The one answer.** The surface mounts its pass by it and a surface that
/// offers to fade itself (`SurfaceFadeAdopter`) claims a panel's fade by it, so
/// the two cannot come apart: a surface that claimed the fade for a pass it did
/// not draw would leave its panel unfaded, and one that drew a pass without
/// claiming would lose it to the opacity above. It is read from the same
/// numbers the surface's own resolver settled — which is where the style
/// axis, the quality ladder, reduced transparency, high contrast and a forced
/// palette have already had their say.
bool surfaceDrawsBackdropPass({
  required double? blur,
  required CoreSurfaceRefraction? refraction,
}) => surfaceDrawnBlur(blur: blur, refraction: refraction) != null;

/// The material a translucent surface is made of — one backdrop pass
/// plus the light that runs along its edge.
///
/// The blur, the chroma lift and the edge band arrive together because
/// they are one statement about a material rather than three effects
/// that happen to be near each other. Splitting them would let a surface
/// saturate without a backdrop to saturate, which is not glass; it is
/// just a stronger colour.
class SurfaceBlur extends StatefulWidget {
  /// Draws [child] on the material the other arguments state.
  const SurfaceBlur({
    required this.child,
    this.borderRadius,
    super.key,
    this.surfaceBlur,
    this.surfaceSaturation,
    this.surfaceBackdropBrightness,
    this.surfaceSheen,
    this.refraction,
    this.fadeProgress,
  });

  /// What the surface is made over: the fill, the border and the content.
  final Widget child;

  /// The backdrop blur sigma, in logical pixels, or null for no pass.
  final double? surfaceBlur;

  /// Chroma lift for the backdrop, or null/`1.0` for none.
  final double? surfaceSaturation;

  /// Dimming for the backdrop, or null/`1.0` for none.
  ///
  /// Rides the same pass as [surfaceSaturation]; the two multiply out
  /// into one colour matrix rather than composing two filters.
  final double? surfaceBackdropBrightness;

  /// Light running along the surface's edge, or null for none.
  ///
  /// Paint-ready: the resolver has already scaled the width and resolved
  /// the colours, so this widget selects and renders rather than deciding.
  final ResolvedSurfaceSheen? surfaceSheen;

  /// Edge bending the caller asked for, or null for none.
  ///
  /// A request, not a guarantee — see [CoreSurfaceRefraction]. Where the
  /// engine cannot draw it the surface keeps the rest of its material and
  /// simply does not bend anything.
  final CoreSurfaceRefraction? refraction;

  /// How far in view this surface is while a panel it draws is fading, 0 to 1,
  /// or null for a surface that is not fading.
  ///
  /// Handed down by `SurfaceFadeAdopter` when a surface that draws a backdrop
  /// pass has taken the panel's fade over, and nowhere else: a surface whose
  /// panel is faded by an opacity above it must not be given one, or the panel
  /// would fade twice.
  ///
  /// What it moves is the part of the surface an opacity cannot fade. The
  /// pass keeps its place and every term it states goes from nothing to its
  /// stated value with `CoreSurfaceDissolve.share` of the progress — the blur,
  /// the frost, the chroma lift, the dimming, the body shade and the bend — so
  /// the glass dissolves into the page instead of turning off in one frame.
  /// What the pass sits under moves by the progress itself: the child (fill,
  /// border, content) fades with an opacity that does not contain the pass,
  /// and the edge light fades with it.
  ///
  /// At 1 the surface is drawn as it is without it, the same filters and the
  /// same layers; at 0 it paints nothing.
  final double? fadeProgress;

  /// The shape the pass and the edge light are bounded to.
  final BorderRadiusGeometry? borderRadius;

  @override
  State<SurfaceBlur> createState() => _SurfaceBlurState();
}

class _SurfaceBlurState extends State<SurfaceBlur> {
  final GlobalKey _mainContainerKey = GlobalKey();

  /// The compiled program, once it has arrived.
  ///
  /// Null covers three states that render identically and deliberately so:
  /// not asked for, still loading, and failed to load. A surface mid-load
  /// that dropped its blur would flash, and one whose asset failed would
  /// look broken rather than plain.
  FragmentProgram? _refractionProgram;

  /// Guards against asking twice, including after a failure. A retry loop
  /// on a missing asset would run every rebuild and never succeed.
  bool _refractionRequested = false;

  // Not `initState`: whether the program is wanted depends on the theme (a
  // surface that bends nothing still mounts it to draw the body shade), and a
  // theme cannot be read before `initState` completes. `didChangeDependencies`
  // runs right after it and before the first build, so a surface whose
  // program has already landed still gets it on the frame it mounts.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadRefractionIfPossible();
  }

  @override
  void didUpdateWidget(SurfaceBlur oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadRefractionIfPossible();
  }

  /// Asks for the program only where the engine can actually run it.
  ///
  /// `isShaderFilterSupported` is the runtime query, not a platform check:
  /// it reports whether Impeller is on, and an embedder can turn that off
  /// on a platform that usually has it. On Flutter Web it is a literal
  /// `false`, which is why this path never reaches `ImageFilter.shader`
  /// there — that SDK defines the constructor as an unconditional throw.
  ///
  /// Wanted for the bend, and for the body shade the theme states: the shade
  /// is drawn by the same program, with the bend's uniforms at zero.
  void _loadRefractionIfPossible() {
    final wantsProgram =
        widget.refraction != null ||
        Theme.maybeOf(context)?.surfaceBodyShade != null;
    if (_refractionRequested || !wantsProgram) return;
    if (!ImageFilter.isShaderFilterSupported) return;

    _refractionRequested = true;
    // Synchronous where the app root's warm-up has already landed the
    // program: this surface then bends on the frame it mounts rather than
    // the one after. Assigned directly because both callers run before
    // the build that reads it.
    final ready = SurfaceRefractionProgram.loaded;
    if (ready != null) {
      _refractionProgram = ready;

      return;
    }
    unawaited(_loadRefraction());
  }

  /// The material filter last built, and the numbers it was built from.
  late ImageFilter _cachedMaterial;
  (double, double?, double?)? _cachedMaterialKey;

  /// Blur alone, or blur with the chroma lift composed over it.
  ///
  /// Identity on both scalars takes the plain-blur branch rather than
  /// composing an identity matrix: the composed filter is a second
  /// render pass, and every surface in the default style would pay for
  /// it to achieve nothing. Either one alone being non-identity is
  /// enough to need the matrix.
  ImageFilter _backdropFilter(
    double blur,
    double? surfaceSaturation,
    double? surfaceBackdropBrightness,
  ) {
    final key = (blur, surfaceSaturation, surfaceBackdropBrightness);
    if (_cachedMaterialKey == key) return _cachedMaterial;
    _cachedMaterialKey = key;
    return _cachedMaterial = _createBackdropFilter(
      blur,
      surfaceSaturation,
      surfaceBackdropBrightness,
    );
  }

  ImageFilter _createBackdropFilter(
    double blur,
    double? surfaceSaturation,
    double? surfaceBackdropBrightness,
  ) {
    final blurFilter = ImageFilter.blur(sigmaX: blur, sigmaY: blur);
    final saturation = surfaceSaturation ?? CoreSurfaceToken.identitySaturation;
    final brightness =
        surfaceBackdropBrightness ?? CoreSurfaceToken.identityBrightness;

    if (saturation == CoreSurfaceToken.identitySaturation &&
        brightness == CoreSurfaceToken.identityBrightness) {
      return blurFilter;
    }

    return ImageFilter.compose(
      outer: ColorFilter.matrix(
        backdropColorMatrix(saturation: saturation, brightness: brightness),
      ),
      inner: blurFilter,
    );
  }

  /// The frost's filter: a Gaussian of the cloud's sigma whose result keeps
  /// only [CoreSurfaceFrost.opacity] of its alpha.
  ///
  /// A backdrop pass composites its filtered result over the backdrop it
  /// read, so a cloud at that alpha lands as `opacity · cloud +
  /// (1 − opacity) · backdrop` — `CoreSurfaceFrost.mix`, with no shader.
  /// Kept with the numbers it was built from, so a rebuild with the same frost
  /// hands the compositor the same filter.
  ({double sigma, double opacity, ImageFilter filter})? _frostCache;

  ImageFilter _frostFilter(CoreSurfaceFrost frost) {
    final cached = _frostCache;
    if (cached != null &&
        cached.sigma == frost.sigma &&
        cached.opacity == frost.opacity) {
      return cached.filter;
    }
    final filter = ImageFilter.compose(
      outer: ColorFilter.matrix(surfaceFrostColorMatrix(frost.opacity)),
      inner: ImageFilter.blur(sigmaX: frost.sigma, sigmaY: frost.sigma),
    );
    _frostCache = (
      sigma: frost.sigma,
      opacity: frost.opacity,
      filter: filter,
    );

    return filter;
  }

  /// The backdrop pass [terms] state: the material, with the cloud under it
  /// when the theme states a frost.
  ///
  /// The cloud is a pass of its own, drawn first and in the same clip, so the
  /// material's pass reads the mix it left behind — the order the Web list
  /// states (the cloud's filter first, then blur, chroma lift, dimming).
  /// Siblings, not ancestors: a layer above the material that saved a pass
  /// would hand the program another pass's coordinates (see
  /// [SurfaceBackdrop]), and two backdrop filters side by side do not.
  Widget _backdropPass(CoreSurfaceBackdropPass terms, BorderRadius radius) {
    final material = _materialPass(terms, radius);
    final frost = terms.frost;
    if (frost == null) return material;

    return Stacks(
      fit: .expand,
      children: [
        BackdropFilter(filter: _frostFilter(frost), child: const SizedBox()),
        material,
      ],
    );
  }

  /// The material's own pass for [terms]: the material alone, or the
  /// material with the bend and the shade on top.
  ///
  /// The bending case is its own render object because the program has to
  /// be told where the surface is, every frame, in the backdrop's pixels —
  /// see [SurfaceBackdrop]. The plain case stays the framework's own
  /// `BackdropFilter`, which is also the branch every surface takes where
  /// the engine cannot run the program.
  Widget _materialPass(CoreSurfaceBackdropPass terms, BorderRadius radius) {
    final refraction = terms.refraction;
    final bodyShade = terms.bodyShade;
    final material = _backdropFilter(
      terms.blur,
      terms.saturation,
      terms.brightness,
    );
    if (refraction != null && webSurfaceRefractionSupported) {
      return WebSurfaceBackdrop(
        refraction: refraction,
        borderRadius: radius,
        blur: terms.blur,
        saturation: terms.saturation ?? 1,
        brightness: terms.brightness ?? 1,
        background: BackdropFilter(
          filter: material,
          child: const SizedBox.expand(),
        ),
        child: const SizedBox.expand(),
      );
    }
    final program = _refractionProgram;
    if (program == null || (refraction == null && bodyShade <= 0)) {
      /// Had to add SizedBox, otherwise it won't blur.
      return BackdropFilter(filter: material, child: const SizedBox());
    }

    return SurfaceBackdrop(
      material: material,
      program: program,
      refraction: refraction,
      bodyShade: bodyShade,
      // The shape's own corner, so the band follows a rounded pane's
      // corners rather than its bounding box — which is what the Web map
      // has always done.
      cornerRadius: radius.topLeft.x,
      devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
      child: const SizedBox(),
    );
  }

  /// The shared load — one asset request for the process, however many
  /// surfaces ask. A failed load answers null, and the holder remembers it
  /// so this is not retried on every rebuild.
  Future<void> _loadRefraction() async {
    final program = await SurfaceRefractionProgram.warmUp();
    if (!mounted || program == null) return;

    setState(() => _refractionProgram = program);
  }

  /// The backdrop pass as it is drawn while the surface is [fadeProgress] of
  /// the way in view, or at rest where it is null.
  ///
  /// Every term the pass states goes from nothing to its stated value with
  /// the share of the progress `CoreSurfaceDissolve` gives it — see there for
  /// which terms follow what — and a term at rest is the very value the
  /// surface states, so a surface at rest hands the compositor the filters it
  /// states. Below the progress at which the fill itself is no longer painted
  /// (one level of alpha) there is no pass: a blur of the page under a panel
  /// that is not there would be a smudge with nothing to explain it.
  Widget _passAt(
    BuildContext context,
    double blur,
    BorderRadius radius,
    double? fadeProgress,
  ) {
    final progress = fadeProgress ?? 1;
    if (Color.getAlphaFromOpacity(progress) == 0) {
      return const SizedBox.shrink();
    }

    // The pass the surface states, then that pass at this progress: the one
    // statement of which term follows which scale is Core's.
    return _backdropPass(
      CoreSurfaceBackdropPass(
        blur: blur,
        saturation: widget.surfaceSaturation,
        brightness: widget.surfaceBackdropBrightness,
        frost: resolveSurfaceFrost(context),
        refraction: widget.refraction,
        bodyShade: Theme.maybeOf(context)?.surfaceBodyShade?.strength ?? 0,
      ).dissolvedAt(progress),
      radius,
    );
  }

  @override
  Widget build(BuildContext context) {
    final fadeProgress = widget.fadeProgress;
    final blur = widget.surfaceBlur;
    final sheen = widget.surfaceSheen;
    // Everything below this point is inside one more surface than
    // everything above it. Published unconditionally — even when this
    // instance draws no blur — because depth counts surfaces, not
    // backdrop passes, and a surface that dropped its pass because it
    // was already nested is still a surface its own children sit in.
    final depth = SurfaceDepth.of(context) + 1;
    final radius = widget.borderRadius?.optionallyResolve(context) ?? .zero;

    final drawnBlur = surfaceDrawnBlur(
      blur: blur,
      refraction: widget.refraction,
    );

    // What sits over the pass — fill, border, content — fades with the
    // progress itself, under an opacity that does not contain the pass: a
    // backdrop filter inside a saved layer would read nothing. A surface that
    // is not fading builds the child without a wrapper.
    final main = KeyedSubtree(key: _mainContainerKey, child: widget.child);
    final content = fadeProgress == null
        ? main
        : SurfaceFadeBox(progress: fadeProgress, child: main);

    var result = drawnBlur == null
        ? content
        : Stacks(
            fit: .passthrough,
            children: [
              Position.fill(
                child: ClipRRect(
                  borderRadius: radius,
                  child: _passAt(context, drawnBlur, radius, fadeProgress),
                ),
              ),
              content,
            ],
          );

    // Painted last so it lands on top of the surface, mirroring the Web
    // twin's `::after`. No gate on whether the surface throws a shadow —
    // `resolveSurfaceRim` has one because an inset rim needs a shadow
    // stack to sit in, and copying it here would make the band vanish on
    // exactly the flat glass panels this axis exists for.
    if (sheen != null) {
      // The wall goes on before the band, so the band's runs stay the
      // outermost thing on the edge — the same order the Web twin gets by
      // declaring `box-shadow` after the run layers on one element.
      //
      // `InsetShadow` rather than a fifth gradient in the painter: Flutter
      // has no inset box shadow and the cut-out that fakes one already
      // lives there, shared. Re-deriving it here is how a surface comes to
      // draw a slightly different wall from its neighbour.
      result = InsetShadow(
        shadows: fadeShadows(sheen.bevel, fadeProgress),
        radius: radius,
        child: result,
      );
      // No `ExcludeSemantics`: the painter adds no node of its own (it has
      // no `semanticsBuilder`), and wrapping it would hide `result` — the
      // surface's content — from assistive tech under every style that
      // states a sheen.
      result = CustomPaint(
        foregroundPainter: SurfaceSheenPainter(
          radius: radius,
          width: sheen.width,
          lightColor: sheen.lightColor,
          darkColor: sheen.darkColor,
          fade: sheen.fade,
          rimWidth: sheen.rimWidth,
          rimColor: sheen.rimColor,
          rimProfile: sheen.rimProfile,
          opacity: fadeProgress ?? 1,
        ),
        child: result,
      );
    }

    return SurfaceDepth(depth: depth, child: result);
  }
}

/// Paints [CoreSurfaceEdgeSheen] — bright horizontal runs, shaded
/// vertical ones, each fading out toward the corners where the two meet.
///
/// Drawn as four gradient strips inset to the border radius rather than
/// as a stroked rounded rect, because a single stroke cannot hold two
/// colours and a per-run fade at once.
/// Public for the same reason [DashedPainter] is: a painter is the only
/// place this axis becomes pixels, and a test that cannot reach it can
/// only assert that the value was carried, never that it was drawn.
class SurfaceSheenPainter extends CustomPainter {
  /// Paints the edge light a surface states, inside [radius].
  const SurfaceSheenPainter({
    required this.radius,
    required this.width,
    required this.lightColor,
    required this.darkColor,
    required this.fade,
    this.rimWidth = 0,
    this.rimColor = const Color(0x00000000),
    this.rimProfile,
    this.opacity = 1,
  });

  /// The shape the light is clipped to.
  final BorderRadius radius;

  /// How wide each edge strip is.
  final double width;

  /// The colour of the horizontal runs, the lit edges.
  final Color lightColor;

  /// The colour of the vertical runs, the shaded sides.
  final Color darkColor;

  /// Where along a run it reaches full strength, as a fraction of its length.
  final double fade;

  /// How much of its own alpha the edge light keeps, 0 to 1 — the progress of
  /// the surface it edges while that surface is fading, so the light leaves
  /// with the fill it lights instead of outlasting it.
  ///
  /// A scale on what is drawn and not a colour: the rim's own opacity is the
  /// lobe's, per point, and replaces the colour's alpha, so a colour that
  /// carried the fade would not reach it.
  final double opacity;

  /// The crest's stroke width; zero draws no rim.
  final double rimWidth;

  /// The rim's colour at full strength.
  final Color rimColor;

  /// The lobe the rim's opacity follows — see [CoreSurfaceEdgeBevel.rimSweep].
  final CoreSurfaceEdgeBevel? rimProfile;

  /// Stop 0 of the sweep sits at the top: Flutter measures sweep angles
  /// clockwise from the positive x axis, Core clockwise from the top.
  static const double _kSweepStart = -math.pi / 2;
  static const double _kSweepEnd = 3 * math.pi / 2;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final bounds = Offset.zero & size;
    canvas
      ..save()
      ..clipRRect(radius.toRRect(bounds));

    if (width > 0) _paintBand(canvas, size);
    _paintRim(canvas, bounds);

    canvas.restore();
  }

  /// The crest: a stroke just inside the contour whose opacity follows
  /// the Core lobe around the shape.
  ///
  /// A sweep gradient about the centre, with the stops Core sampled along
  /// the contour. The Web twin hands the same stops to a `conic-gradient`;
  /// neither platform decides where the peak lands.
  void _paintRim(Canvas canvas, Rect bounds) {
    final profile = rimProfile;
    if (rimWidth <= 0 || profile == null) return;

    final stops = profile.rimSweep(
      width: bounds.width,
      height: bounds.height,
      // One radius, as the Web runtime reads one. The refraction map makes
      // the same simplification; a shape with four different corners is
      // not one this material has been drawn on.
      radius: radius.topLeft.x,
    );
    if (stops.isEmpty) return;

    final shader = SweepGradient(
      startAngle: _kSweepStart,
      endAngle: _kSweepEnd,
      colors: [
        for (final s in stops) rimColor.withValues(alpha: s.alpha * opacity),
      ],
      stops: [for (final s in stops) s.angle / 360],
    ).createShader(bounds);
    canvas.drawRRect(
      radius.toRRect(bounds).deflate(rimWidth / 2),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = rimWidth
        ..shader = shader,
    );
  }

  void _paintBand(Canvas canvas, Size size) {
    // Horizontal runs read as the lit edges, vertical ones as the shaded
    // sides — that disagreement is the whole signature of the treatment,
    // and it is why an inset shadow (uniform by construction) cannot
    // stand in for it.
    final light = _scaled(lightColor);
    final dark = _scaled(darkColor);
    _paintRun(canvas, Rect.fromLTWH(0, 0, size.width, width), light, true);
    _paintRun(
      canvas,
      Rect.fromLTWH(0, size.height - width, size.width, width),
      light,
      true,
    );
    _paintRun(canvas, Rect.fromLTWH(0, 0, width, size.height), dark, false);
    _paintRun(
      canvas,
      Rect.fromLTWH(size.width - width, 0, width, size.height),
      dark,
      false,
    );
  }

  /// [color] at the alpha the surface's fade leaves it — itself at rest.
  Color _scaled(Color color) =>
      opacity >= 1 ? color : color.withValues(alpha: color.a * opacity);

  @override
  bool shouldRepaint(covariant SurfaceSheenPainter oldDelegate) {
    return oldDelegate.radius != radius ||
        oldDelegate.width != width ||
        oldDelegate.lightColor != lightColor ||
        oldDelegate.darkColor != darkColor ||
        oldDelegate.fade != fade ||
        oldDelegate.rimWidth != rimWidth ||
        oldDelegate.rimColor != rimColor ||
        oldDelegate.rimProfile != rimProfile ||
        oldDelegate.opacity != opacity;
  }

  /// One edge strip, fading in from each end.
  ///
  /// The two stops are placed at [fade] and its mirror, so a run reaches
  /// full strength only across its middle. `effectiveFade` has already
  /// clamped the value at or below 0.5; at exactly 0.5 the two stops
  /// meet and the run peaks at a single point, which is the strongest
  /// fade the shape can express rather than a degenerate case.
  void _paintRun(Canvas canvas, Rect rect, Color color, bool horizontal) {
    final transparent = color.withValues(alpha: 0);
    final gradient = LinearGradient(
      begin: horizontal ? Alignment.centerLeft : Alignment.topCenter,
      end: horizontal ? Alignment.centerRight : Alignment.bottomCenter,
      colors: [transparent, color, color, transparent],
      stops: [0, fade, 1 - fade, 1],
    );

    canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));
  }
}

/// What a dashed line is drawn with: the colour and the dash geometry.
class DashedLineProperties {
  /// Creates the properties of a dashed line.
  const DashedLineProperties({
    required this.color,
    required this.gap,
    required this.thickness,
    required this.width,
  });

  /// The properties between [a] and [b] at [t].
  factory DashedLineProperties.lerp(
    DashedLineProperties a,
    DashedLineProperties b,
    double t,
  ) {
    return DashedLineProperties(
      color: Color.lerp(a.color, b.color, t)!,
      gap: lerpDouble(a.gap, b.gap, t)!,
      thickness: lerpDouble(a.thickness, b.thickness, t)!,
      width: lerpDouble(a.width, b.width, t)!,
    );
  }

  /// The length of one dash.
  final double width;

  /// The space between two dashes.
  final double gap;

  /// The stroke width of a dash.
  final double thickness;

  /// The colour of the dashes.
  final Color color;
}

/// What a dashed container is drawn with: the shape, the colour and the dash
/// geometry.
class DashedContainerProperties {
  /// Creates the properties of a dashed container.
  const DashedContainerProperties({
    required this.borderRadius,
    required this.color,
    required this.gap,
    required this.thickness,
    required this.width,
  });

  /// The properties between [a] and [b] at [t], the corners resolved against
  /// [context].
  factory DashedContainerProperties.lerp(
    BuildContext context,
    DashedContainerProperties a,
    DashedContainerProperties b,
    double t,
  ) {
    return DashedContainerProperties(
      borderRadius: BorderRadius.lerp(
        a.borderRadius.optionallyResolve(context),
        b.borderRadius.optionallyResolve(context),
        t,
      )!,
      color: Color.lerp(a.color, b.color, t)!,
      gap: lerpDouble(a.gap, b.gap, t)!,
      thickness: lerpDouble(a.thickness, b.thickness, t)!,
      width: lerpDouble(a.width, b.width, t)!,
    );
  }

  /// The length of one dash.
  final double width;

  /// The space between two dashes.
  final double gap;

  /// The stroke width of a dash.
  final double thickness;

  /// The colour of the dashes.
  final Color color;

  /// The corners the dashes follow.
  final BorderRadiusGeometry borderRadius;
}

/// Draws a dashed border around [child].
class DashedContainer extends StatelessWidget {
  /// Draws [child] inside a dashed border.
  const DashedContainer({
    required this.child,
    this.borderRadius,
    this.color,
    this.gap,
    super.key,
    this.strokeWidth,
    this.thickness,
  });

  /// The length of one dash, or null for [CoreDashedBorder.dashLength] at the
  /// theme's scale.
  final double? strokeWidth;

  /// The space between two dashes, or null for [CoreDashedBorder.dashGap] at
  /// the theme's scale.
  final double? gap;

  /// The stroke width of a dash, or null for [CoreDashedBorder.strokeWidth]
  /// at the theme's scale.
  final double? thickness;

  /// The colour of the dashes, or null for the theme's outline.
  final Color? color;

  /// What the border surrounds.
  final Widget child;

  /// The corners the dashes follow, or null for the container's own radius.
  final BorderRadiusGeometry? borderRadius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedValueBuilder(
      value: DashedContainerProperties(
        borderRadius: borderRadius ?? .circular(CoreRadius.radius16),
        color: color ?? theme.colorScheme.outline.toValue(),
        gap: gap ?? (theme.scaling * _kDefaultDashedGap),
        thickness: thickness ?? (theme.scaling * _kDefaultDashedThickness),
        width: strokeWidth ?? (theme.scaling * _kDefaultDashedWidth),
      ),
      duration: kDefaultDuration,
      lerp: (a, b, t) {
        return DashedContainerProperties.lerp(context, a, b, t);
      },
      builder: (context, value, child) {
        return CustomPaint(
          painter: DashedPainter(
            borderRadius: value.borderRadius.optionallyResolve(context),
            color: value.color,
            gap: value.gap,
            thickness: value.thickness,
            width: value.width,
          ),
          child: child,
        );
      },
      child: child,
    );
  }
}

/// Paints a dashed horizontal line along the top of its box.
class DashedLinePainter extends CustomPainter {
  /// Paints dashes of [width] [gap] apart, [thickness] thick, in [color].
  const DashedLinePainter({
    required this.color,
    required this.gap,
    required this.thickness,
    required this.width,
  });

  /// The length of one dash.
  final double width;

  /// The space between two dashes.
  final double gap;

  /// The stroke width of a dash.
  final double thickness;

  /// The colour of the dashes.
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0);
    final pathMetrics = path.computeMetrics();
    final draw = Path();
    for (final pathMetric in pathMetrics) {
      for (var i = 0.0; i < pathMetric.length; i += gap + width) {
        final start = i;
        var end = i + width;
        if (end > pathMetric.length) {
          end = pathMetric.length;
        }
        draw.addPath(pathMetric.extractPath(start, end), .zero);
      }
    }
    canvas.drawPath(
      draw,
      Paint()
        ..color = color
        ..strokeWidth = thickness
        ..style = .stroke,
    );
  }

  @override
  bool shouldRepaint(covariant DashedLinePainter oldDelegate) {
    return oldDelegate.width != width ||
        oldDelegate.gap != gap ||
        oldDelegate.thickness != thickness ||
        oldDelegate.color != color;
  }
}

/// Paints a dashed border around its box, following [borderRadius].
class DashedPainter extends CustomPainter {
  /// Paints dashes of [width] [gap] apart, [thickness] thick, in [color].
  const DashedPainter({
    required this.color,
    required this.gap,
    required this.thickness,
    required this.width,
    this.borderRadius,
  });

  /// The length of one dash.
  final double width;

  /// The space between two dashes.
  final double gap;

  /// The stroke width of a dash.
  final double thickness;

  /// The colour of the dashes.
  final Color color;

  /// The corners the dashes follow, or null for square ones.
  final BorderRadius? borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    if (borderRadius != null && borderRadius != .zero) {
      path.addRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(0, 0, size.width, size.height),
          topLeft: borderRadius!.topLeft,
          topRight: borderRadius!.topRight,
          bottomRight: borderRadius!.bottomRight,
          bottomLeft: borderRadius!.bottomLeft,
        ),
      );
    } else {
      path.addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    }

    final pathMetrics = path.computeMetrics();
    final draw = Path();
    for (final pathMetric in pathMetrics) {
      for (var i = 0.0; i < pathMetric.length; i += gap + width) {
        final start = i;
        var end = i + width;
        if (end > pathMetric.length) {
          end = pathMetric.length;
        }
        draw.addPath(pathMetric.extractPath(start, end), .zero);
      }
    }
    canvas.drawPath(
      draw,
      Paint()
        ..color = color
        ..strokeWidth = thickness
        ..style = .stroke,
    );
  }

  @override
  bool shouldRepaint(covariant DashedPainter oldDelegate) {
    return oldDelegate.width != width ||
        oldDelegate.gap != gap ||
        oldDelegate.thickness != thickness ||
        oldDelegate.color != color ||
        oldDelegate.borderRadius != borderRadius;
  }
}
