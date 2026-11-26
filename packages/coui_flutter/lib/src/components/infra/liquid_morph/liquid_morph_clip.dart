/// Carves a child into the silhouette a morph makes at this instant.
///
/// The shape is Core's — this widget owns nothing but the clock and the
/// clip. That division is deliberate: the Web half runs the same Core
/// arithmetic and differs only in how it spells the result, so a
/// disagreement between the two platforms would have to be a disagreement
/// in `coui_core`.
///
/// ## What it does not do
///
/// It does not position anything. The panel is where its own layout put it;
/// this only decides which pixels of it survive. Making the clip also move
/// the panel would put two things in charge of one position, and the
/// overlay position engine is already the one in charge.
///
/// It does not paint the material either. The child keeps its blur, its
/// fill and its edge band — clipping was measured to leave a Flutter
/// backdrop filter intact, which is the reason this design is a clip and
/// not a shader.
library;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/scheduler.dart';

/// Clips [child] to the merged silhouette of [anchor] and [panel].
///
/// Both bodies are in the child's own coordinate space, so a caller hands
/// over the trigger's position *relative to the panel* rather than a screen
/// rectangle — the clip has no way to know where on the screen it ended up,
/// and asking it to would make it depend on the position engine.
///
/// The two bodies are [CoreMorphBlob]s rather than rectangles because that
/// is the vocabulary the shape is built from, and because it is a type both
/// platforms can name. A rectangle would have to be `dart:ui`'s on one side
/// and something else on the other, and the corner radius — which belongs
/// to the body, not to the animation — would travel beside it as a loose
/// number.
class LiquidMorphClip extends StatefulWidget {
  /// Creates a morph clip.
  const LiquidMorphClip({
    required this.anchor,
    required this.panel,
    required this.child,
    super.key,
    this.spring = const CoreMorphSpring(),
    this.resolution = CoreLiquidMorphOutline.defaultResolution,
  });

  /// The body the panel came from — a trigger, in the child's coordinates.
  final CoreMorphBlob anchor;

  /// The body it becomes, in the child's coordinates.
  final CoreMorphBlob panel;

  /// The tempo.
  final CoreMorphSpring spring;

  /// Grid the silhouette is traced on.
  ///
  /// The default was measured at roughly half a millisecond per frame on a
  /// development machine; a device that cannot afford it can trade detail
  /// for time here rather than losing the effect.
  final int resolution;

  /// The panel being carved.
  final Widget child;

  @override
  State<LiquidMorphClip> createState() => _LiquidMorphClipState();
}

class _LiquidMorphClipState extends State<LiquidMorphClip>
    with SingleTickerProviderStateMixin {
  static bool _isUnmeasured(CoreMorphBlob blob) =>
      blob.halfWidth <= 0 || blob.halfHeight <= 0;

  late final Ticker _ticker;
  Duration _elapsed = .zero;
  bool _settled = false;

  @override
  void initState() {
    super.initState();
    // A raw `Ticker` rather than an `AnimationController`, because the
    // curve is not this widget's: the spring is evaluated in closed form
    // from elapsed time, so what is needed here is a clock, and a
    // controller would add a second one with its own duration to keep in
    // step.
    _ticker = createTicker(_handleTick)..start();
  }

  /// The clipper for this frame, or null when nothing should be carved.
  CustomClipper<Path>? _clipperFor(BuildContext context) {
    // Reduced motion is answered by not morphing at all, rather than by
    // morphing quickly. A morph is transition-tier motion, and this kit
    // suppresses that tier to zero — someone who asked for less motion is
    // asking for none, and the panel is simply open.
    if (resolveReducedMotion(context) || _settled) return null;

    // An unmeasured body is not a small one. A caller that has not measured
    // its trigger yet passes zero extents, and two zero-sized bodies still
    // make a shape: the smooth union pulls by `k / 4` even where both
    // fields are a single point, so the panel would be carved into a dot.
    // Refusing here is the difference between "no effect yet" and "the
    // panel disappeared".
    if (_isUnmeasured(widget.anchor) || _isUnmeasured(widget.panel)) {
      return null;
    }

    // No "is anything happening yet" gate. The clip is what holds the panel
    // down to the size it has grown to, so a frame that skips it renders
    // the panel at **full size** — and the one frame where a curve-based
    // gate said "nothing yet" was frame zero, which made every morph open
    // with a flash of its own destination.
    final seconds = _elapsed.inMicroseconds / Duration.microsecondsPerSecond;
    final outline = CoreLiquidMorphOutline.of(
      morphShapeAt(
        anchor: widget.anchor,
        panel: widget.panel,
        spring: widget.spring,
        seconds: seconds,
      ),
      resolution: widget.resolution,
    );
    // An empty outline means the walk found no crossing. Clipping to it
    // would clip the panel away entirely, so a shape that failed to trace
    // renders as a missing panel rather than an unclipped one.
    if (outline.isEmpty) return null;

    return _OutlineClipper(outline);
  }

  void _handleTick(Duration elapsed) {
    if (_settled) return;

    final seconds = elapsed.inMicroseconds / Duration.microsecondsPerSecond;
    // Stop ticking once the spring is done. Left running, this would trace
    // an outline every frame for the rest of the panel's life — for a
    // shape that stopped changing, on a surface that is probably also
    // compositing a blur.
    final done = seconds >= widget.spring.settleSeconds();

    setState(() {
      _elapsed = elapsed;
      _settled = done;
    });

    if (done) _ticker.stop();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Every path out of here returns a `ClipPath`, including the ones that
    // do no clipping at all. Returning a bare `child` instead would change
    // the widget's runtimeType at this slot, `Widget.canUpdate` would fail,
    // and the **whole panel subtree would be rebuilt from scratch** — at
    // settle, most of a second after opening, while someone is already
    // typing into it. Measured: the child's `initState` ran twice. A
    // popover with a text field loses focus; a scrolled list loses its
    // place. It reads as a flaky focus bug, three files from its cause.
    //
    // `clipper: null` with `clipBehavior: Clip.none` is a true
    // pass-through: `RenderClipPath.paint` skips the layer entirely and
    // `hitTest` only narrows when a clipper is set.
    //
    // And the behaviour follows the clipper, because `Clip.none` is not
    // "clip without anti-aliasing" — it is *no clip*: `RenderClipPath.paint`
    // paints the child straight through whenever the behaviour is `none`,
    // whatever clipper it was handed. This shipped with `none` on both
    // branches and every test stayed green, because every test asked
    // whether a clipper was *set* and none read a pixel. Measured on a
    // device: a dock pill in flight was the whole bar, filled. The Web
    // twin carved from day one, which is what made it a divergence.
    final clipper = _clipperFor(context);

    return ClipPath(
      clipper: clipper,
      clipBehavior: clipper == null ? .none : .antiAlias,
      child: widget.child,
    );
  }
}

/// Clips to a Core outline.
///
/// Reclips whenever the outline object changes, which it does every frame
/// while the spring runs and never after it settles.
class _OutlineClipper extends CustomClipper<Path> {
  const _OutlineClipper(this.outline);

  final CoreLiquidMorphOutline outline;

  @override
  Path getClip(Size size) => outline.toValue();

  @override
  bool shouldReclip(covariant _OutlineClipper oldClipper) =>
      !identical(oldClipper.outline, outline);
}
