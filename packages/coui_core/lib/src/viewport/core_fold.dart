import 'dart:math' as math;

import 'package:coui_core/src/component/contracts/scrollable_client/core_axis.dart';
import 'package:coui_core/src/component/contracts/stacks/core_text_direction.dart';
import 'package:meta/meta.dart';

/// A rectangle in the viewport, measured from its top-left corner in the unit
/// the platform lays out in — Flutter logical pixels, Web CSS pixels.
@immutable
class CoreViewportRect {
  /// Creates a rectangle.
  const CoreViewportRect({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  }) : assert(width >= 0, 'CoreViewportRect width must be non-negative.'),
       assert(height >= 0, 'CoreViewportRect height must be non-negative.');

  /// The left edge.
  final double left;

  /// The top edge.
  final double top;

  /// The horizontal extent.
  final double width;

  /// The vertical extent.
  final double height;

  /// The right edge.
  double get right => left + width;

  /// The bottom edge.
  double get bottom => top + height;

  /// How far the point at [x], [y] is from this rectangle: `0` inside it or on
  /// its edge, otherwise the distance to its nearest edge or corner.
  ///
  /// Measured the way Flutter's `DisplayFeatureSubScreen` measures it — the
  /// straight difference along one axis where the point is level with an
  /// edge, the distance to the corner otherwise — so a tie between two
  /// segments breaks the same way on both platforms.
  double distanceTo(double x, double y) {
    final dx = x < left
        ? left - x
        : x > right
        ? x - right
        : 0.0;
    final dy = y < top
        ? top - y
        : y > bottom
        ? y - bottom
        : 0.0;
    if (dx == 0) return dy;
    if (dy == 0) return dx;

    return math.sqrt(dx * dx + dy * dy);
  }

  @override
  bool operator ==(Object other) =>
      other is CoreViewportRect &&
      other.left == left &&
      other.top == top &&
      other.width == width &&
      other.height == height;

  @override
  int get hashCode => Object.hash(left, top, width, height);

  @override
  String toString() => 'CoreViewportRect($left, $top, $width × $height)';
}

/// How far a fold is folded.
enum CoreFoldState {
  /// Open flat: the screen reads as one surface across the fold.
  flat,

  /// Partly folded, the two sides at an angle — a laptop on a table, or a
  /// book held open.
  halfOpened,

  /// The platform did not say.
  unknown,
}

/// A fold or a hinge that crosses the viewport, as the platform reports it.
@immutable
class CoreFold {
  /// Creates a fold at [bounds].
  const CoreFold({required this.bounds, this.state = CoreFoldState.unknown});

  /// Where it is. A screen that bends reports a line with no width; a hinge
  /// between two screens reports the strip of the viewport it hides.
  final CoreViewportRect bounds;

  /// How far it is folded.
  final CoreFoldState state;

  /// Whether it splits the viewport into segments a panel keeps to one of: it
  /// hides a strip of the viewport, or it is half opened. A screen that bends
  /// and lies flat reads as one surface.
  ///
  /// The rule Flutter's own dialog route applies (`DisplayFeatureSubScreen`),
  /// so a panel the kit places by it opens where a framework route would.
  bool get separates =>
      math.min(bounds.width, bounds.height) > 0 ||
      state == CoreFoldState.halfOpened;

  /// The way it runs: [CoreAxis.horizontal] across the viewport's width,
  /// [CoreAxis.vertical] down its height.
  CoreAxis get axis =>
      bounds.width > bounds.height ? CoreAxis.horizontal : CoreAxis.vertical;

  @override
  bool operator ==(Object other) =>
      other is CoreFold && other.bounds == bounds && other.state == state;

  @override
  int get hashCode => Object.hash(bounds, state);

  @override
  String toString() => 'CoreFold($bounds, $state)';
}

/// The kind of foldable a device is, read from the shape its fold leaves on
/// either side — so it is the same however the device is turned.
enum CoreFoldableKind {
  /// Folds across its length into a smaller square, like a compact — a
  /// Galaxy Z Flip, a Razr. The side of the fold is at least as deep as the
  /// fold is long.
  flip,

  /// Folds down its middle like a book — a Galaxy Z Fold, a Pixel Fold, a
  /// device with two screens and a hinge. Each side is a page, longer along
  /// the fold than it is deep.
  fold,
}

/// How a foldable is being held.
enum CoreFoldPosture {
  /// Open flat.
  flat,

  /// Half open with the fold across the screen: the upper half stands, the
  /// lower half rests on a table.
  tabletop,

  /// Half open with the fold down the screen: two pages side by side.
  book,
}

/// The viewport's folds and what a layout reads from them: the segments a
/// panel keeps to, the kind of device, and how it is held.
///
/// One rule for both platforms. Each feeds it what it measures — Flutter the
/// display features in `MediaQuery`, the Web the browser's viewport segments
/// and its posture media query — and reads the answers back from here, so the
/// same fold gives the same segments, kind and posture on both.
@immutable
class CoreFoldLayout {
  /// Reads [folds] across a viewport of [width] × [height].
  ///
  /// A fold that does not run across the whole viewport — one the window
  /// covers only part of, or something that is not a fold — is not a fold of
  /// this viewport and is left out.
  factory CoreFoldLayout({
    required double width,
    required double height,
    Iterable<CoreFold> folds = const [],
  }) {
    final viewport = CoreViewportRect(
      left: 0,
      top: 0,
      width: width,
      height: height,
    );
    final crossing = [
      for (final fold in folds)
        if (_crosses(fold.bounds, viewport)) fold,
    ];

    return CoreFoldLayout._(
      width: width,
      height: height,
      folds: List.unmodifiable(crossing),
      segments: List.unmodifiable(
        _split(viewport, [
          for (final fold in crossing)
            if (fold.separates) fold.bounds,
        ]),
      ),
    );
  }

  const CoreFoldLayout._({
    required this.width,
    required this.height,
    required this.folds,
    required this.segments,
  });

  /// A viewport nothing has measured: no fold and no segment. What the Web
  /// reads on the server and before the browser has answered.
  static const CoreFoldLayout unmeasured = CoreFoldLayout._(
    width: 0,
    height: 0,
    folds: [],
    segments: [],
  );

  /// The viewport's width.
  final double width;

  /// The viewport's height.
  final double height;

  /// The folds that cross the viewport, in the order the platform reported
  /// them.
  final List<CoreFold> folds;

  /// The viewport split by every fold that separates it ([CoreFold.separates]),
  /// left to right and top to bottom: the whole viewport where nothing
  /// separates it, and nothing where the viewport was not measured.
  final List<CoreViewportRect> segments;

  /// The fold a device with two halves has — the first one; null without a
  /// fold.
  CoreFold? get fold => folds.isEmpty ? null : folds.first;

  /// Whether a fold splits the viewport into more than one segment.
  bool get isSplit => segments.length > 1;

  /// The kind of device, read from [fold]; null without a fold.
  ///
  /// The fold runs along one side of each segment it borders. A side longer
  /// than the segment is deep is a page of a book; a side no longer than it is
  /// deep is half of a compact. Both measures turn with the device, so a
  /// device keeps its kind on its side, and the answer needs no list of
  /// devices.
  CoreFoldableKind? get kind {
    final fold = this.fold;
    if (fold == null) return null;
    final horizontal = fold.axis == CoreAxis.horizontal;
    final along = horizontal ? width : height;

    return along > _depthBeside(fold)
        ? CoreFoldableKind.fold
        : CoreFoldableKind.flip;
  }

  /// How the device is held, read from [fold]; null without a fold, or where
  /// the platform did not say how far it is folded.
  CoreFoldPosture? get posture {
    final fold = this.fold;
    if (fold == null) return null;

    return switch (fold.state) {
      CoreFoldState.flat => CoreFoldPosture.flat,
      CoreFoldState.halfOpened =>
        fold.axis == CoreAxis.horizontal
            ? CoreFoldPosture.tabletop
            : CoreFoldPosture.book,
      CoreFoldState.unknown => null,
    };
  }

  /// The index in [segments] a panel anchored at [x], [y] opens in: the
  /// segment that holds the point, otherwise the nearest, the first of those
  /// equally near. Null where the viewport was not measured.
  int? segmentIndexAt(double x, double y) {
    if (segments.isEmpty) return null;
    var closest = 0;
    var closestDistance = segments.first.distanceTo(x, y);
    for (var index = 1; index < segments.length; index++) {
      final distance = segments[index].distanceTo(x, y);
      if (distance < closestDistance) {
        closest = index;
        closestDistance = distance;
      }
    }

    return closest;
  }

  /// Where a panel that nothing anchors opens: the segment at the top of the
  /// reading start — the top left of a left-to-right page, the top right of a
  /// right-to-left one. Null where the viewport was not measured.
  ///
  /// The point Flutter's dialog route falls back to when it is given none.
  int? startSegmentIndex(CoreTextDirection direction) =>
      segmentIndexAt(direction == CoreTextDirection.rtl ? width : 0, 0);

  /// The index in [segments] a panel placed at an alignment of the viewport
  /// opens in — a drawer docked to an edge, a stack of toasts in a corner.
  /// [x] and [y] are the alignment, each from `-1` (the left, the top)
  /// through `0` (the middle) to `1` (the right, the bottom). Null where the
  /// viewport was not measured.
  ///
  /// It is the segment that holds that point of the viewport. A point on a
  /// fold — a panel centred across it — belongs to no segment, or to the two
  /// that meet there, and opens in the nearest: of those equally near, the
  /// upper one, then the one at the reading start. That is the side a panel
  /// that nothing anchors opens on ([startSegmentIndex]), so a sheet centred
  /// on a fold and a dialog share a side.
  ///
  /// [within] is the box the panel is placed in, in the viewport's
  /// coordinates, where that is not the viewport itself — a layer that
  /// covers part of it. The point is then that alignment of the box: a
  /// layer that stops short of one edge has its middle off the viewport's,
  /// and a panel centred in it lies in the segment its own middle is in.
  int? segmentIndexAligned(
    double x,
    double y,
    CoreTextDirection direction, {
    CoreViewportRect? within,
  }) {
    if (segments.isEmpty) return null;
    final pointX = (within?.left ?? 0) + (x + 1) / 2 * (within?.width ?? width);
    final pointY =
        (within?.top ?? 0) + (y + 1) / 2 * (within?.height ?? height);
    var closest = 0;
    var closestDistance = segments.first.distanceTo(pointX, pointY);
    for (var index = 1; index < segments.length; index++) {
      final distance = segments[index].distanceTo(pointX, pointY);
      final nearer = distance < closestDistance - _tieTolerance;
      final asNear = (distance - closestDistance).abs() <= _tieTolerance;
      if (nearer ||
          (asNear &&
              _opensBefore(segments[index], segments[closest], direction))) {
        closest = index;
        closestDistance = distance;
      }
    }

    return closest;
  }

  /// How much nearer one segment must be than another to count as nearer.
  /// Two segments beside a fold are equally far from its middle only up to
  /// the rounding of the halves the platform reports.
  static const double _tieTolerance = 1e-6;

  /// Whether [segment] is where a panel opens before [other]: the upper of
  /// the two, or at the same height the one at the reading start.
  static bool _opensBefore(
    CoreViewportRect segment,
    CoreViewportRect other,
    CoreTextDirection direction,
  ) {
    if (segment.top != other.top) return segment.top < other.top;

    return direction == CoreTextDirection.rtl
        ? segment.left > other.left
        : segment.left < other.left;
  }

  /// How deep the viewport is on either side of [fold], up to the next fold
  /// that runs the same way or the edge — the deeper side.
  double _depthBeside(CoreFold fold) {
    final horizontal = fold.axis == CoreAxis.horizontal;
    final start = horizontal ? fold.bounds.top : fold.bounds.left;
    final end = horizontal ? fold.bounds.bottom : fold.bounds.right;
    var before = 0.0;
    var after = horizontal ? height : width;
    for (final other in folds) {
      if (identical(other, fold) || other.axis != fold.axis) continue;
      final otherStart = horizontal ? other.bounds.top : other.bounds.left;
      final otherEnd = horizontal ? other.bounds.bottom : other.bounds.right;
      if (otherEnd <= start) before = math.max(before, otherEnd);
      if (otherStart >= end) after = math.min(after, otherStart);
    }

    return math.max(start - before, after - end);
  }

  /// Whether [bounds] runs across the whole of [viewport], one way or the
  /// other, and lies inside it the other way.
  static bool _crosses(CoreViewportRect bounds, CoreViewportRect viewport) {
    final acrossHeight =
        bounds.top <= viewport.top &&
        bounds.bottom >= viewport.bottom &&
        bounds.left >= viewport.left &&
        bounds.right <= viewport.right;
    final acrossWidth =
        bounds.left <= viewport.left &&
        bounds.right >= viewport.right &&
        bounds.top >= viewport.top &&
        bounds.bottom <= viewport.bottom;

    return acrossHeight || acrossWidth;
  }

  /// [viewport] divided along every rectangle in [avoid] that runs across a
  /// part of it — Flutter's `DisplayFeatureSubScreen.subScreensInBounds`,
  /// with one difference: a part is divided only by a rectangle that lies
  /// within it. Flutter divides a part by any rectangle as tall (or as wide)
  /// as the part, so with two folds running the same way its first part
  /// reaches past the first fold to the second. With one fold the two agree.
  static List<CoreViewportRect> _split(
    CoreViewportRect viewport,
    List<CoreViewportRect> avoid,
  ) {
    var parts = [viewport];
    for (final bounds in avoid) {
      final next = <CoreViewportRect>[];
      for (final part in parts) {
        final runsDown = part.top >= bounds.top && part.bottom <= bounds.bottom;
        final runsAcross =
            part.left >= bounds.left && part.right <= bounds.right;
        if (runsDown && bounds.left < part.right && bounds.right > part.left) {
          if (part.left < bounds.left) {
            next.add(
              CoreViewportRect(
                left: part.left,
                top: part.top,
                width: bounds.left - part.left,
                height: part.height,
              ),
            );
          }
          if (part.right > bounds.right) {
            next.add(
              CoreViewportRect(
                left: bounds.right,
                top: part.top,
                width: part.right - bounds.right,
                height: part.height,
              ),
            );
          }
        } else if (runsAcross &&
            bounds.top < part.bottom &&
            bounds.bottom > part.top) {
          if (part.top < bounds.top) {
            next.add(
              CoreViewportRect(
                left: part.left,
                top: part.top,
                width: part.width,
                height: bounds.top - part.top,
              ),
            );
          }
          if (part.bottom > bounds.bottom) {
            next.add(
              CoreViewportRect(
                left: part.left,
                top: bounds.bottom,
                width: part.width,
                height: part.bottom - bounds.bottom,
              ),
            );
          }
        } else {
          next.add(part);
        }
      }
      parts = next;
    }

    return parts;
  }

  @override
  bool operator ==(Object other) {
    if (other is! CoreFoldLayout ||
        other.width != width ||
        other.height != height ||
        other.folds.length != folds.length) {
      return false;
    }
    for (var index = 0; index < folds.length; index++) {
      if (other.folds[index] != folds[index]) return false;
    }

    return true;
  }

  @override
  int get hashCode => Object.hash(width, height, Object.hashAll(folds));

  @override
  String toString() =>
      'CoreFoldLayout($width × $height, folds: $folds, segments: $segments)';
}
