/// Web implementation of [LiquidMorphRuntime].
///
/// Ticks the morph's clock and writes the silhouette onto the panel as
/// `clip-path` through an owned stylesheet rule. The shape and the interpolation are both Core's, so this
/// file owns the clock and the spelling — never the geometry.
///
/// ## Why the style is written directly rather than rendered
///
/// A morph runs for a few hundred milliseconds at frame rate. Routing that
/// through the component tree would rebuild the panel — and everything
/// inside it — sixty times a second to change one property. The refraction
/// runtime beside this one writes its filter the same way and for the same
/// reason.
///
/// ## Why a clip and not a gooey filter
///
/// The obvious Web way to merge two blobs is a blur-plus-contrast `filter`
/// on a common ancestor, and it was measured: an ancestor filter
/// establishes a new backdrop root, so a glass panel inside it samples the
/// filtered ancestor instead of the page and renders **opaque**. That
/// trades the material for the merge. Carving the shape leaves the backdrop
/// alone, which is also what the Flutter half was measured to do.
library;

import 'dart:js_interop';

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:web/web.dart' as web;

/// How long to wait for the panel element before giving up, in frames.
///
/// Not a design token — a bound on a retry, chosen so a morph that has
/// missed its own window stops asking rather than holding a rAF loop open
/// with nothing to draw.
const int _kMaxWaitFrames = 30;

/// Drives one panel's morph.
class LiquidMorphRuntime {
  /// Creates a runtime bound to the element carrying [elementId].
  LiquidMorphRuntime({required this.elementId});

  /// The id of the panel being carved.
  final String elementId;

  bool _disposed = false;
  double? _startedAtMs;
  web.HTMLStyleElement? _styleHost;
  int? _frameId;
  int _generation = 0;

  /// Starts the morph from [anchor] towards [panel].
  ///
  /// Both bodies are in the panel's own coordinate space, because that is
  /// what `clip-path` resolves against. A screen rectangle would carve the
  /// panel against coordinates it does not live in.
  ///
  /// Calling this a second time restarts the clock rather than stacking a
  /// second loop.
  void start({
    required CoreMorphBlob anchor,
    required CoreMorphBlob panel,
    required CoreMorphSpring spring,
    int resolution = CoreLiquidMorphOutline.defaultResolution,
  }) {
    // An unmeasured body is not a small one. Two zero-sized bodies still
    // make a shape — the smooth union pulls by `k / 4` even where both
    // fields are a single point — so the panel would be carved into a dot
    // rather than left alone.
    if (_isUnmeasured(anchor) || _isUnmeasured(panel)) return;

    if (_frameId != null) web.window.cancelAnimationFrame(_frameId!);
    final generation = ++_generation;
    _startedAtMs = null;
    var waited = 0;
    final settle = spring.settleSeconds();

    void frame(double nowMs) {
      if (_disposed || generation != _generation) return;
      if (web.window.matchMedia('(prefers-reduced-motion: reduce)').matches) {
        _clear();
        return;
      }

      // The element this carves is the clip's own *child*, so on the frame
      // the clip mounts it has not been committed to the document yet.
      // Measured: the panel node appears about 2ms after `start` runs, and
      // the first version resolved the element once, found nothing, and
      // returned — so the morph never ran at all, on any panel, while
      // every other part of the wiring reported success.
      //
      // Waiting is bounded: a morph that has not found its panel within
      // half a second has missed its own window, and looping past that
      // would be a rAF loop with nothing to draw.
      if (web.document.getElementById(elementId) == null) {
        waited++;
        if (waited > _kMaxWaitFrames) return;
        _requestFrame(frame);

        return;
      }

      // The clock starts on the first frame there is something to draw,
      // not on the first frame that ran — otherwise the frames spent
      // waiting would be spent morphing, invisibly.
      _startedAtMs ??= nowMs;
      final seconds = (nowMs - _startedAtMs!) / Duration.millisecondsPerSecond;
      if (seconds >= settle) {
        // Settled: hand the panel back its own shape. Leaving the last
        // frame's clip in place would pin the panel to a silhouette that
        // stops matching it the moment anything resizes.
        _clear();

        return;
      }

      // Written every frame, with no "is anything happening yet" gate: the
      // clip is what holds the panel down to the size it has grown to, so
      // a frame that skips it renders the panel at full size.
      _write(
        morphShapeAt(
          anchor: anchor,
          panel: panel,
          spring: spring,
          seconds: seconds,
        ),
        resolution: resolution,
      );
      _requestFrame(frame);
    }

    _requestFrame(frame);
  }

  /// Stops the morph and removes what it wrote. Idempotent.
  void dispose() {
    _disposed = true;
    if (_frameId != null) web.window.cancelAnimationFrame(_frameId!);
    _frameId = null;
    _clear();
  }

  void _requestFrame(void Function(double) callback) {
    _frameId = web.window.requestAnimationFrame(
      ((double now) {
        _frameId = null;
        callback(now);
      }).toJS,
    );
  }

  void _write(CoreLiquidMorphShape shape, {required int resolution}) {
    final element = web.document.getElementById(elementId);
    if (element == null) return;

    final css = CoreLiquidMorphOutline.of(
      shape,
      resolution: resolution,
    ).toInlineCss();
    // Empty means the walk found no crossing. `clip-path: path("")` clips
    // everything away, so writing it would make a shape that failed to
    // trace look like a panel that vanished.
    if (css.isEmpty) return;

    // Positioning rebuilds the panel's inline style after measurement. An
    // owned rule survives that update, so the clip stays on screen for the
    // entire frame rather than being erased between rAF and paint.
    final host = _styleHost ??= web.HTMLStyleElement()
      ..setAttribute('data-coui-morph', elementId);
    if (!host.isConnected) web.document.head?.append(host);
    host.textContent = '#${web.CSS.escape(elementId)}{clip-path:$css;}';
  }

  void _clear() {
    _styleHost?.remove();
    _styleHost = null;
  }

  static bool _isUnmeasured(CoreMorphBlob blob) =>
      blob.halfWidth <= 0 || blob.halfHeight <= 0;
}
