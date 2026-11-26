import 'dart:math' as math;

import 'package:flutter/rendering.dart';

/// Whether the backdrop a refraction program reads is the root's.
///
/// ## Why the surface has to ask
///
/// The program measures the surface's rectangle against the root (see
/// `SurfaceBackdrop`) and subtracts it from `FlutterFragCoord()`, which is
/// only the same space while the filter reads the root's pixels. A layer
/// above the surface that saves a pass of its own hands the filter that pass
/// instead: `uSize` is the pass's size and `FlutterFragCoord()` is relative to
/// the pass's origin. Measured on Impeller (Metal) with a program that reads
/// both back as colour (`refraction_enclosing_pass_probe_test.dart`), the
/// band lands displaced by that origin: a picture of a band in the wrong
/// place, drawn with full confidence, not a missing one. A surface inside a
/// frosted container, a fade under a clip or a layer blur can all get it.
///
/// ## Which layers do it
///
/// What follows is what the probe measured, written as the rule it supports.
///
/// * A layer that saves a pass sized by the clip in effect where it paints
///   (opacity, a shader mask, a colour filter, a backdrop filter, a clip that
///   saves a layer) hands the filter a pass that starts where that clip
///   starts. With no clip above it that is the root's origin and nothing
///   moves; under a clip that starts elsewhere — a viewport, a card, a
///   frosted panel — the pass starts there. The pass is the clip, not the
///   layer's own box: a backdrop filter that sits inside its clip still gets
///   the clip's origin.
/// * An image filter's pass is the size of what it holds, which is not known
///   from here, so no origin can be stated for it.
/// * Clips between the opener and the surface do not move the opener's pass,
///   which is why an opacity above a scroll view's clip is harmless where
///   the same opacity inside it is not.
///
/// ## What the answer is used for
///
/// Where the pass does not start at the root's origin the surface keeps the
/// rest of its material and does not bend, which is what the kit does
/// wherever the engine cannot run the program. Stating the origin and
/// subtracting it would keep the bend, but that needs the pass's size to be
/// checked against the engine's, and for an image filter it cannot be known.
///
/// A surface with none of these above it pays one walk up its parents, which
/// allocates nothing; only a surface that has an opener above it goes on to
/// place the clips, which allocates a short list.
bool backdropReadsRootPass(Layer layer) {
  ContainerLayer? nearest;
  for (var above = layer.parent; above != null; above = above.parent) {
    switch (_passOf(above)) {
      case .contentSized:
        return false;
      case .clipped:
        nearest ??= above;
      case .none:
        break;
    }
  }
  if (nearest == null) {
    return true;
  }

  return _clipsStartAtRoot(nearest);
}

/// How a layer decides the pass it saves.
enum _Pass {
  /// Saves no pass of its own.
  none,

  /// Saves a pass the size of the clip in effect where it paints.
  clipped,

  /// Saves a pass the size of what it holds.
  contentSized,
}

_Pass _passOf(Layer layer) => switch (layer) {
  ImageFilterLayer() => .contentSized,
  OpacityLayer() ||
  ShaderMaskLayer() ||
  ColorFilterLayer() ||
  BackdropFilterLayer() => .clipped,
  _ when _clipBehaviorOf(layer) == Clip.antiAliasWithSaveLayer => .clipped,
  _ => .none,
};

/// What a clip layer does at its edge, or null for a layer that is not one.
Clip? _clipBehaviorOf(Layer layer) => switch (layer) {
  ClipRectLayer(:final clipBehavior) => clipBehavior,
  ClipRRectLayer(:final clipBehavior) => clipBehavior,
  ClipPathLayer(:final clipBehavior) => clipBehavior,
  ClipRSuperellipseLayer(:final clipBehavior) => clipBehavior,
  _ => null,
};

/// A clip that starts less than one device pixel from the root's origin
/// starts at it: a pass is allocated in whole pixels, rounded out.
const double _kRootOriginTolerance = 1;

/// Whether every clip above and including [opener] starts at the root's
/// origin, so that the pass it saves does.
///
/// The origin of an intersection of rectangles is the larger of their lefts
/// and the larger of their tops, so the clips need no intersecting: only the
/// two maxima, against the root's zero. Each clip is moved into the root's
/// space by the transforms of the layers above it, root first, which is the
/// order `Layer.applyTransform` composes them in. The root layer carries the
/// device pixel ratio, so the space is the device's.
bool _clipsStartAtRoot(ContainerLayer opener) {
  final chain = <ContainerLayer>[];
  for (ContainerLayer? at = opener; at != null; at = at.parent) {
    chain.add(at);
  }
  final toRoot = Matrix4.identity();
  var left = 0.0;
  var top = 0.0;
  for (var i = chain.length - 1; i >= 0; i--) {
    final at = chain[i];
    // A clip layer is never made with `Clip.none`; a layer that is not one
    // has no clip to describe.
    final bounds = _clipBehaviorOf(at) == null ? null : at.describeClipBounds();
    if (bounds != null) {
      final inRoot = MatrixUtils.transformRect(toRoot, bounds);
      left = math.max(left, inRoot.left);
      top = math.max(top, inRoot.top);
    }
    if (i > 0) {
      at.applyTransform(chain[i - 1], toRoot);
    }
  }

  return left < _kRootOriginTolerance && top < _kRootOriginTolerance;
}
