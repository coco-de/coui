import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Whether a panel's surface fades itself, or is faded as a whole by whatever
/// mounted it.
///
/// ## The defect this hand-off exists for
///
/// An opacity that is less than full saves the layer it wraps. A backdrop
/// filter inside a saved layer reads only what was painted into that layer —
/// nothing — so a glass surface under such an opacity loses its blur, its
/// chroma lift and its bend in the first frame of a fade and goes on as a
/// plain translucent plate while the page behind it turns sharp.
///
/// Measured on Impeller (Metal), a glass panel that is faded by an opacity and
/// held at half its progress keeps three quarters of the page's stripe
/// contrast in its middle — the veil, no blur — where the same panel at rest
/// keeps under one percent.
///
/// The opacity cannot be taken off the panel as a whole and left at that: a
/// panel that does not draw a backdrop pass (an opaque style, the `solid`
/// quality tier, reduced transparency, high contrast) needs the opacity, and
/// the panel's content is as likely as not to be a surface that is not ours.
/// So the surface is asked: it takes the fade over, or it does not.
///
/// ## How the hand-off goes
///
/// A host that fades a panel — the popover engine, and the dialog route, both
/// through [SurfaceFadeHost] — mounts a [SurfaceFadeScope] above it, carrying
/// the progress and a [SurfaceFadeClaims]. The panel's surface — the first one
/// under the scope, which is the one that draws the panel — wraps what it draws
/// in a [SurfaceFadeAdopter]:
///
/// * a surface that **draws a backdrop pass** claims the fade. The host stops
///   applying the opacity (it paints the panel at full alpha, which the
///   framework emits as an offset and not as a saved layer), and the surface
///   fades its own terms from the progress: the fill and the content with an
///   opacity that does not contain the pass, and the pass itself by scaling
///   what it states (`CoreSurfaceDissolve`). The host cannot apply both, and
///   the surface cannot apply either unless it holds the claim, so a panel is
///   never faded twice.
/// * a surface that **draws no pass** claims nothing. The host keeps fading
///   the whole panel by its opacity.
///
/// Either way the adopter hides the scope from everything below it. A surface
/// nested in the panel — a glass button in a menu, a card in a popover — is
/// inside the surface that decided, and a second claim from it would take the
/// fade away from a panel whose outer surface had asked to keep it.
///
/// A claim is made while the surface is built, before the frame the panel first
/// paints in, and released when the surface goes, so there is no frame in which
/// the host has let go of an opacity nobody has taken up.
class SurfaceFadeScope extends InheritedWidget {
  /// A host's statement that the panel below is fading at [progress], and that
  /// the surface that draws it may take the fade over through [claims].
  const SurfaceFadeScope({
    required this.progress,
    required SurfaceFadeClaims this.claims,
    required super.child,
    super.key,
  });

  /// What a surface publishes below itself once it has decided: nothing below
  /// it is offered the fade.
  const SurfaceFadeScope.consumed({required super.child, super.key})
    : progress = 1,
      claims = null;

  /// How far the panel is in view, 0 to 1: 0 is gone and 1 is at rest.
  final double progress;

  /// Where a surface that draws a backdrop pass says so, or null in the scope a
  /// surface has already decided under.
  final SurfaceFadeClaims? claims;

  /// The scope a surface under [context] may be offered the fade through, or
  /// null where no host is fading the panel or a surface above has decided.
  ///
  /// Asking registers a dependency, so a surface that asks is rebuilt as the
  /// progress moves; one that does not ask never hears of it.
  static SurfaceFadeScope? maybeOf(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<SurfaceFadeScope>();

    return scope?.claims == null ? null : scope;
  }

  @override
  bool updateShouldNotify(SurfaceFadeScope oldWidget) =>
      progress != oldWidget.progress || !identical(claims, oldWidget.claims);
}

/// The surfaces that have taken a panel's fade over, counted, so the host that
/// would otherwise fade the panel can tell whether it still has to.
///
/// A [ChangeNotifier] because the host's answer is read by a render object that
/// has to repaint when it changes, and that change arrives while the surface is
/// being built — where setting state on the host's widgets is an error and
/// telling a render object is not.
class SurfaceFadeClaims extends ChangeNotifier {
  int _count = 0;
  bool _disposed = false;

  /// Whether a surface has taken the fade over.
  bool get isClaimed => _count > 0;

  /// Takes the fade over on behalf of a surface that draws a backdrop pass.
  void claim() {
    if (_disposed) return;
    _count++;
    if (_count == 1) notifyListeners();
  }

  /// Gives the fade back, when the surface that claimed it goes or stops
  /// drawing a pass.
  void release() {
    if (_disposed) return;
    assert(_count > 0, 'a release with nothing claimed');
    _count--;
    if (_count == 0) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

/// Wraps a surface's drawing so that it takes a panel's fade over when it can.
///
/// Mounted by a surface that finds a [SurfaceFadeScope] above it — see there
/// for the hand-off — and only then: a surface with no scope above it builds
/// what it always built, with no wrapper at all.
///
/// [builder] is handed the progress when this surface holds the claim, and
/// null when it does not, in which case the host is fading the panel and the
/// surface draws itself at rest. Everything [builder] returns is built under
/// a scope that offers the fade to nothing.
class SurfaceFadeAdopter extends StatefulWidget {
  /// Creates the adopter for a surface under [scope].
  const SurfaceFadeAdopter({
    required this.scope,
    required this.drawsPass,
    required this.builder,
    super.key,
  });

  /// The scope the surface was offered the fade through.
  final SurfaceFadeScope scope;

  /// Whether the surface draws a backdrop pass — the one thing that cannot be
  /// faded by an opacity above it, and so the one thing that takes the fade
  /// over. Decided by `surfaceDrawsBackdropPass`, the answer the surface's own
  /// pass is mounted by.
  final bool drawsPass;

  /// Builds the surface at the progress it is handed, or at rest where that is
  /// null.
  final Widget Function(double? progress) builder;

  @override
  State<SurfaceFadeAdopter> createState() => _SurfaceFadeAdopterState();
}

class _SurfaceFadeAdopterState extends State<SurfaceFadeAdopter> {
  SurfaceFadeClaims? _claimed;

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(SurfaceFadeAdopter oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  @override
  void dispose() {
    _claimed?.release();
    _claimed = null;
    super.dispose();
  }

  /// Holds a claim exactly while the surface draws a pass under a scope that
  /// can be claimed.
  void _sync() {
    final wanted = widget.drawsPass ? widget.scope.claims : null;
    if (identical(wanted, _claimed)) return;
    _claimed?.release();
    _claimed = wanted;
    wanted?.claim();
  }

  @override
  Widget build(BuildContext context) => SurfaceFadeScope.consumed(
    child: widget.builder(_claimed == null ? null : widget.scope.progress),
  );
}

/// Fades a panel: as a whole, or — where its surface asks to — by the
/// surface's own terms.
///
/// The host is whatever brings a panel into view and out of it: the popover
/// engine for a popover, a menu, a select, a hover card and a tooltip, and the
/// dialog route for a dialog.
///
/// An opacity that is less than full saves the layer it wraps, and a backdrop
/// filter inside a saved layer reads nothing: a glass panel under it loses its
/// blur, its chroma lift and its bend in the first frame of the open and of
/// the close, and goes on as a plain translucent plate while the page behind
/// it turns sharp. So the panel's surface is asked first. One that draws a
/// backdrop pass takes the fade over (see [SurfaceFadeScope]): this stops
/// applying the opacity, and the surface fades what it is made of, the pass
/// dissolving into the page with the fill instead of switching off. Everything
/// else — an opaque style, the `solid` quality tier, reduced transparency, a
/// panel whose surface is not the kit's — is faded by the opacity.
///
/// The opacity is the framework's own `FadeTransition`, in every case. What a
/// claim changes is the number it is given, not the widget: it stays at full
/// alpha, which the framework emits as an offset rather than a saved layer (the
/// panel at rest is drawn through it too), so no opacity above the surface
/// isolates anything. It goes to nothing while the progress is nothing, so a
/// panel that has faded out is not painted and is not read out, whichever of
/// the two fades it.
///
/// The host listens to [animation] itself, so the progress it publishes moves
/// with every frame of an animation that nothing else rebuilds the panel for —
/// a route's. The panel is handed through as [child], so only the widgets that
/// asked for the progress are rebuilt by it, and the panel's own tree keeps
/// one shape for the whole of the transition.
class SurfaceFadeHost extends StatefulWidget {
  /// Hosts [child] as a panel that is [animation] of the way in view.
  const SurfaceFadeHost({
    required this.animation,
    required this.child,
    super.key,
  });

  /// How far in view the panel is, 0 to 1: 0 is gone and 1 is at rest.
  final Animation<double> animation;

  /// The panel.
  final Widget child;

  @override
  State<SurfaceFadeHost> createState() => _SurfaceFadeHostState();
}

class _SurfaceFadeHostState extends State<SurfaceFadeHost> {
  final SurfaceFadeClaims _claims = SurfaceFadeClaims();
  late _PanelFadeOpacity _opacity;

  @override
  void initState() {
    super.initState();
    _opacity = _PanelFadeOpacity(widget.animation, _claims);
  }

  @override
  void didUpdateWidget(SurfaceFadeHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.animation, widget.animation)) {
      _opacity = _PanelFadeOpacity(widget.animation, _claims);
    }
  }

  @override
  void dispose() {
    _claims.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.animation,
    child: widget.child,
    builder: (context, child) => SurfaceFadeScope(
      progress: widget.animation.value.clamp(0.0, 1.0),
      claims: _claims,
      child: FadeTransition(opacity: _opacity, child: child),
    ),
  );
}

/// The opacity a host applies to a panel: the animation, until a surface takes
/// the fade over, and from then on full — or nothing, while the animation is.
///
/// An [Animation] so that the claim, which is made while the surface is built
/// and so cannot rebuild any widget above it, reaches the render object that
/// paints the opacity through the listener that render object already has.
class _PanelFadeOpacity extends Animation<double> {
  const _PanelFadeOpacity(this.parent, this.claims);

  final Animation<double> parent;
  final SurfaceFadeClaims claims;

  @override
  double get value {
    final progress = parent.value;
    if (!claims.isClaimed) return progress;

    return progress > 0 ? 1 : 0;
  }

  @override
  AnimationStatus get status => parent.status;

  @override
  void addListener(VoidCallback listener) {
    parent.addListener(listener);
    claims.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    parent.removeListener(listener);
    claims.removeListener(listener);
  }

  @override
  void addStatusListener(AnimationStatusListener listener) =>
      parent.addStatusListener(listener);

  @override
  void removeStatusListener(AnimationStatusListener listener) =>
      parent.removeStatusListener(listener);
}

/// [shadows] as they are drawn while their surface is [progress] of the way in
/// or out of view: each layer's alpha is scaled by the progress and nothing
/// else about it moves.
///
/// What an opacity over the whole surface does to a shadow, for a shadow that
/// is painted outside the part of the surface that fades — the cast a glass
/// panel throws, which sits behind the panel and cannot be inside its opacity.
///
/// Returns [shadows] itself when there is nothing to fade (no progress, or a
/// progress of 1), so a surface at rest hands its painter the list it always
/// did.
List<BoxShadow> fadeShadows(List<BoxShadow> shadows, double? progress) {
  if (progress == null || progress >= 1 || shadows.isEmpty) return shadows;

  return [
    for (final shadow in shadows)
      BoxShadow(
        color: shadow.color.withValues(alpha: shadow.color.a * progress),
        offset: shadow.offset,
        blurRadius: shadow.blurRadius,
        spreadRadius: shadow.spreadRadius,
        blurStyle: shadow.blurStyle,
      ),
  ];
}

/// Paints [child] at [progress] of its own alpha — an opacity that keeps no
/// layer where it has nothing to do.
///
/// The framework's own opacities keep a layer for every alpha above zero,
/// including full alpha, where the layer is emitted as an offset and costs a
/// repaint boundary for nothing. A surface at rest is the common case and has
/// to draw exactly what it states, so this paints the child straight through
/// at 1, paints nothing at 0, and saves a layer only between.
///
/// The surface puts this around what it draws *over* its backdrop pass —
/// fill, border, content — and never around the pass: a backdrop filter inside
/// the layer this saves would read nothing.
class SurfaceFadeBox extends SingleChildRenderObjectWidget {
  /// Creates a fade at [progress].
  const SurfaceFadeBox({required this.progress, super.child, super.key});

  /// How much of its own alpha the child keeps, 0 to 1.
  final double progress;

  @override
  RenderSurfaceFadeBox createRenderObject(BuildContext context) =>
      RenderSurfaceFadeBox(progress: progress);

  @override
  void updateRenderObject(
    BuildContext context,
    RenderSurfaceFadeBox renderObject,
  ) {
    renderObject.progress = progress;
  }
}

/// The render object behind [SurfaceFadeBox].
class RenderSurfaceFadeBox extends RenderProxyBox {
  /// Creates a fade at [progress].
  RenderSurfaceFadeBox({double progress = 1, RenderBox? child})
    : _progress = progress.clamp(0.0, 1.0),
      _alpha = ui.Color.getAlphaFromOpacity(progress),
      super(child);

  double _progress;
  int _alpha;

  /// How much of its own alpha the child keeps, 0 to 1.
  double get progress => _progress;
  set progress(double value) {
    final next = value.clamp(0.0, 1.0);
    if (next == _progress) return;
    final neededCompositing = alwaysNeedsCompositing;
    final wasVisible = _alpha != 0;
    _progress = next;
    _alpha = ui.Color.getAlphaFromOpacity(next);
    if (neededCompositing != alwaysNeedsCompositing) {
      markNeedsCompositingBitsUpdate();
    }
    markNeedsCompositedLayerUpdate();
    if (wasVisible != (_alpha != 0)) markNeedsSemanticsUpdate();
  }

  /// The alpha the child is painted at, 0 to 255 — what the layer carries
  /// between the two ends, and what a test reads without a layer to read it
  /// from.
  @visibleForTesting
  int get debugAlpha => _alpha;

  /// A layer is needed only while the child is partly there. At either end the
  /// child is painted straight through or not at all.
  @override
  bool get alwaysNeedsCompositing =>
      child != null && _alpha > 0 && _alpha < 255;

  @override
  bool get isRepaintBoundary => alwaysNeedsCompositing;

  @override
  OffsetLayer updateCompositedLayer({
    required covariant OpacityLayer? oldLayer,
  }) {
    return (oldLayer ?? OpacityLayer())..alpha = _alpha;
  }

  @override
  bool paintsChild(RenderBox child) {
    assert(child.parent == this, 'asked about a box that is not a child');

    return _alpha > 0;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child == null || _alpha == 0) return;
    super.paint(context, offset);
  }

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    if (child != null && _alpha != 0) visitor(child!);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty('progress', _progress));
  }
}
