/// Carves a panel into the silhouette a morph makes at this instant.
///
/// The shape and the interpolation are Core's — this component owns nothing
/// but the lifecycle. That division is deliberate: the Flutter half runs the
/// same Core arithmetic and differs only in how it spells the result, so a
/// disagreement between the two platforms would have to be a disagreement in
/// `coui_core`.
///
/// ## Why it names its target instead of wrapping it
///
/// The Flutter twin wraps its child, because clipping there is a render
/// node. Here it is a style property on an element that already exists, and
/// that element is usually the positioned panel itself — wrapping it would
/// put a static box between the panel and whatever positions it, which
/// changes the layout of every overlay to add an effect that changes none of
/// it. So this renders [child] unchanged, adds no element, and finds its
/// target by id, the same way surface refraction does.
///
/// The capability is symmetric; only the handle differs, in the direction
/// each framework already points.
library;

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/components/infra/liquid_morph/liquid_morph_dom.dart';
import 'package:jaspr/jaspr.dart';

/// Runs a morph on the element carrying [elementId].
///
/// [anchor] and [panel] are both in that element's own coordinate space,
/// because that is what `clip-path` resolves against. A screen rectangle
/// would carve the panel against coordinates it does not live in.
class LiquidMorphClip extends StatefulComponent {
  /// Creates a morph clip.
  const LiquidMorphClip({
    required this.elementId,
    required this.anchor,
    required this.panel,
    required this.child,
    super.key,
    this.spring = const CoreMorphSpring(),
    this.resolution = CoreLiquidMorphOutline.defaultResolution,
  });

  /// The id of the element being carved.
  final String elementId;

  /// The body the panel came from — a trigger, in the panel's coordinates.
  final CoreMorphBlob anchor;

  /// The body it becomes, in the panel's coordinates.
  final CoreMorphBlob panel;

  /// The tempo.
  final CoreMorphSpring spring;

  /// Grid the silhouette is traced on.
  final int resolution;

  /// The subtree containing the element being carved. Rendered unchanged.
  final Component child;

  @override
  State<LiquidMorphClip> createState() => _LiquidMorphClipState();
}

class _LiquidMorphClipState extends State<LiquidMorphClip> {
  LiquidMorphRuntime? _runtime;

  @override
  void initState() {
    super.initState();
    _start();
  }

  /// Starts only on the client.
  ///
  /// The server emits the panel already open: a morph is a transition
  /// between two states and the server only ever renders the second one.
  /// Markup carrying a mid-flight clip would ship a half-drawn panel as the
  /// first thing a user sees.
  void _start() {
    if (!kIsWeb) return;

    (_runtime ??= LiquidMorphRuntime(elementId: component.elementId)).start(
      anchor: component.anchor,
      panel: component.panel,
      spring: component.spring,
      resolution: component.resolution,
    );
  }

  @override
  void didUpdateComponent(LiquidMorphClip oldComponent) {
    super.didUpdateComponent(oldComponent);
    // Restart only when the flight itself changed. Re-running on every
    // rebuild would reset the clock mid-morph, and the panel would keep
    // leaving its trigger without ever arriving.
    if (oldComponent.anchor == component.anchor &&
        oldComponent.panel == component.panel &&
        oldComponent.spring == component.spring) {
      return;
    }

    _runtime?.dispose();
    _runtime = null;
    _start();
  }

  @override
  void dispose() {
    _runtime?.dispose();
    _runtime = null;
    super.dispose();
  }

  @override
  Component build(BuildContext context) => component.child;
}
