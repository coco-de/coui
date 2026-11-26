/// The fold of a `MockupFoldable` — the angle between its two halves, and
/// everything both platforms draw from that angle.
library;

import 'dart:math' as math;

import 'package:coui_core/src/viewport/core_fold.dart';
import 'package:meta/meta.dart';

/// Which screen of a folding device carries its content.
enum CoreMockupFoldScreen {
  /// The screen inside the fold, spanning both halves.
  inner,

  /// The screen on the back of the half that folds over, seen when the
  /// device is shut.
  cover,
}

/// One flat part of a folded device at one angle.
///
/// `matrix` maps the part's own box — origin at its top-left corner, in the
/// unit the platform lays out in — onto the stage, perspective included. It is
/// sixteen numbers in column-major order, the order both Flutter's `Matrix4`
/// and CSS `matrix3d()` read, so a platform hands it over as it is.
///
/// `visible` is whether the part faces the viewer. The platforms draw the
/// parts in a fixed order and skip the ones that do not, rather than asking
/// each renderer to sort or cull: a renderer that sorts by depth and one that
/// paints in tree order would otherwise disagree.
///
/// `shade` (0 to 1) is how far the part is turned from facing the viewer —
/// the share of the style's shade that lies over it.
typedef CoreMockupFoldPart = ({
  List<double> matrix,
  bool visible,
  double shade,
});

/// The two radii of a rounded corner: how far it reaches across (`x`) and
/// down (`y`).
typedef CoreMockupFoldCorner = ({double x, double y});

/// How a slab's outer edge ends, in the edge's own box.
///
/// A slab's corners are rounded in the plane of its faces, and its edge is
/// the wall between the outlines of its two faces. Where those outlines turn
/// a corner the wall turns with them, out of the flat strip a pose states for
/// the edge. So the strip ends where the outline of the face behind it cuts
/// it: seen nearly face on it is a sliver that stops where the corner begins,
/// and seen edge on it runs the slab's whole height.
///
/// `outlineAtEnd` says which side of the box the device's outline is on: the
/// side the box ends on (`true`) or the one it starts on. `top` and `bottom`
/// are the corners that side is rounded by — `y` as tall as the face's own
/// corner, `x` as wide as that corner is drawn, counted in the widths the
/// strip is drawn across, so it can be many times the box.
///
/// A platform draws the edge as the box widened to the larger of its own
/// width and the two `x`, away from the outline side, with those corners on
/// the outline side — and shows what of that lies inside the box.
typedef CoreMockupFoldEdgeCut = ({
  bool outlineAtEnd,
  CoreMockupFoldCorner top,
  CoreMockupFoldCorner bottom,
});

/// The angle of a folding device and the rules read from it.
///
/// The angle is the one between the two halves, in degrees: [closed] is shut,
/// [flat] is open, the way a hinge sensor reports it. Everything else a
/// `MockupFoldable` shows — which screen is lit, what the app on it is told
/// about the fold, where each half is drawn — is a function of that one
/// number, so a device held at any angle is drawn the same on both platforms
/// and an animation is nothing more than the angle changing.
abstract final class CoreMockupFold {
  /// Shut: the two halves lie on each other and the cover screen faces out.
  static const double closed = 0;

  /// Held open like a book, each half turned a little towards the viewer.
  static const double halfOpen = 144;

  /// Open: the inner screen is one surface.
  static const double flat = 180;

  /// The angle from which the app on the inner screen is told the fold is
  /// flat; below it the fold is half opened and splits the screen in two.
  static const double flatFrom = 150;

  /// The widest angle at which the cover carries the content. Wider than
  /// this the inner screen does.
  static const double coverUntil = 30;

  /// The widest angle at which the cover screen is fully lit; it dims from
  /// here to [coverUntil], where it is off.
  static const double coverLitUntil = 10;

  /// The angle from which the inner screen is fully lit; it brightens from
  /// [coverUntil], where it is off.
  static const double innerLitFrom = 60;

  /// How much of the fold the whole device turns back by, so a device held
  /// part open faces the viewer with both halves instead of one.
  static const double yawFactor = 0.5;

  /// [angle] kept within [closed] and [flat].
  static double clampAngle(double angle) => angle.clamp(closed, flat);

  /// The screen that carries the content at [angle].
  static CoreMockupFoldScreen activeScreen(double angle) =>
      clampAngle(angle) <= coverUntil
      ? CoreMockupFoldScreen.cover
      : CoreMockupFoldScreen.inner;

  /// What the app on the inner screen is told about the fold at [angle].
  static CoreFoldState foldState(double angle) => clampAngle(angle) >= flatFrom
      ? CoreFoldState.flat
      : CoreFoldState.halfOpened;

  /// Whether the inner screen lies in one plane at [angle]. Only then can a
  /// platform draw its content live; at any other angle the two halves are
  /// drawn apart, each from a copy.
  static bool innerIsFlat(double angle) => clampAngle(angle) >= flat;

  /// How lit the inner screen is at [angle], 0 (off) to 1.
  static double innerScreenLight(double angle) =>
      _smoothStep(coverUntil, innerLitFrom, clampAngle(angle));

  /// How lit the cover screen is at [angle], 0 (off) to 1.
  static double coverScreenLight(double angle) =>
      1 - _smoothStep(coverLitUntil, coverUntil, clampAngle(angle));

  static double _smoothStep(double from, double to, double value) {
    final t = ((value - from) / (to - from)).clamp(0.0, 1.0);

    return t * t * (3 - 2 * t);
  }
}

/// Where every part of a folding device is drawn at one angle.
///
/// The device is two slabs joined down the middle. The right one stays; the
/// left one turns about the hinge towards the viewer and comes to rest on the
/// right one, its back — which carries the cover screen — facing out. The
/// whole device turns back by a share of that ([CoreMockupFold.yawFactor]) so
/// a device held part open shows both halves, steps back as its halves come
/// forward so it does not swell, and is kept in the middle of the stage.
///
/// Parts, in the order a platform draws them: [innerRight], [edgeRight],
/// [innerLeft], [edgeLeft], [cover]. That order is right at every angle,
/// because the only parts that ever overlap are the cover and what lies
/// under it.
@immutable
class CoreMockupFoldPose {
  const CoreMockupFoldPose._({
    required this.width,
    required this.height,
    required this.thickness,
    required this.angle,
    required this.turn,
    required this.yaw,
    required this.depth,
    required this.slide,
    required this.distance,
    required this.activeScreen,
    required this.isFlat,
    required this.innerRight,
    required this.innerLeft,
    required this.cover,
    required this.edgeLeft,
    required this.edgeRight,
    required this.innerScreenDim,
    required this.coverScreenDim,
  });

  /// The pose at [angle] of a device [width] × [height] when open, whose
  /// slabs are [thickness] deep, seen from [perspective] widths away.
  ///
  /// Lengths are in the unit the platform lays out in; the result is in the
  /// same unit.
  factory CoreMockupFoldPose.compute({
    required double angle,
    required double width,
    required double height,
    required double thickness,
    required double perspective,
  }) {
    final clamped = CoreMockupFold.clampAngle(angle);
    final hingeX = width / 2;
    final coverWidth = width / 2;
    // How far the left slab has turned from open, how far the whole device
    // turns back, and so how far the left slab stands from facing the
    // viewer.
    final turn = (CoreMockupFold.flat - clamped) * math.pi / 180;
    final yaw = -CoreMockupFold.yawFactor * math.sin(turn);
    final leftTilt = turn + yaw;
    // A half turned towards the viewer comes nearer and is drawn larger.
    // Stepping the device back by two thirds of how far its outer edges
    // come forward keeps a part-open device narrower than an open one, as
    // it is in the hand.
    final depth = -width / 6 * (math.sin(leftTilt) + math.sin(-yaw));

    final distance = math.max<double>(perspective * width, 1);
    final camera = _perspective(width / 2, height / 2, distance);
    final placed = _multiply(
      camera,
      _multiply(_translation(0, 0, depth), _turnAbout(hingeX, yaw)),
    );
    final placedFold = _multiply(placed, _turnAbout(hingeX, turn));
    final coverPlane = _coverPlane(hingeX, thickness);
    final leftEdgePlane = _leftEdgePlane(thickness);
    final rightEdgePlane = _rightEdgePlane(width);

    // ─── Keep what is drawn in the middle of the stage ───
    // Shut, the device is half as wide and lies on the right half. The
    // leftmost and rightmost points it reaches — the hinge, each slab's
    // outer edge front and back, both ends of the cover — are found where
    // they land, and the picture is slid so they straddle the middle.
    final reach = [
      project(placed, hingeX, 0).x,
      project(placed, width, 0).x,
      project(_multiply(placed, rightEdgePlane), thickness, 0).x,
      project(placedFold, 0, 0).x,
      project(_multiply(placedFold, leftEdgePlane), 0, 0).x,
      project(_multiply(placedFold, coverPlane), 0, 0).x,
      project(_multiply(placedFold, coverPlane), coverWidth, 0).x,
    ];
    final slide =
        width / 2 - (reach.reduce(math.min) + reach.reduce(math.max)) / 2;
    final group = _multiply(_translation(slide, 0, 0), placed);
    final folded = _multiply(_translation(slide, 0, 0), placedFold);

    final innerRightMatrix = group;
    final innerLeftMatrix = folded;
    final coverMatrix = _multiply(folded, coverPlane);
    final edgeLeftMatrix = _multiply(folded, leftEdgePlane);
    final edgeRightMatrix = _multiply(group, rightEdgePlane);

    return CoreMockupFoldPose._(
      width: width,
      height: height,
      thickness: thickness,
      angle: clamped,
      turn: turn,
      yaw: yaw,
      depth: depth,
      slide: slide,
      distance: distance,
      activeScreen: CoreMockupFold.activeScreen(clamped),
      isFlat: CoreMockupFold.innerIsFlat(clamped),
      innerRight: (
        matrix: innerRightMatrix,
        visible: _facesViewer(innerRightMatrix, width, height),
        shade: _shadeOf(yaw),
      ),
      innerLeft: (
        matrix: innerLeftMatrix,
        visible: _facesViewer(innerLeftMatrix, width, height),
        shade: _shadeOf(leftTilt),
      ),
      cover: (
        matrix: coverMatrix,
        visible: _facesViewer(coverMatrix, coverWidth, height),
        shade: _shadeOf(math.pi - leftTilt),
      ),
      edgeLeft: (
        matrix: edgeLeftMatrix,
        visible: _facesViewer(edgeLeftMatrix, thickness, height),
        shade: 0,
      ),
      edgeRight: (
        matrix: edgeRightMatrix,
        visible: _facesViewer(edgeRightMatrix, thickness, height),
        shade: 0,
      ),
      innerScreenDim: 1 - CoreMockupFold.innerScreenLight(clamped),
      coverScreenDim: 1 - CoreMockupFold.coverScreenLight(clamped),
    );
  }

  /// Width of the open body the pose is of.
  final double width;

  /// Height of the open body the pose is of.
  final double height;

  /// How deep each slab of the device the pose is of is.
  final double thickness;

  /// The angle this pose is of, within [CoreMockupFold.closed] and
  /// [CoreMockupFold.flat].
  final double angle;

  /// How far the left slab has turned about the hinge from open, in
  /// radians: 0 open, π shut.
  ///
  /// [turn], [yaw], [depth], [slide] and [distance] are the steps every
  /// part's matrix is built from, stated apart for a platform that has to
  /// write the same steps in its own units — the Web composes them as CSS
  /// transform functions in `rem`, so the pose follows the root font size.
  /// From the stage inwards a part is placed by: slide across by [slide];
  /// the camera, [distance] away and looking at the middle of the open body;
  /// step back by [depth]; turn the whole device by [yaw] about the hinge;
  /// for a part of the left slab, turn by [turn] about the hinge; then the
  /// part's own plane.
  final double turn;

  /// How far the whole device is turned back about the hinge, in radians.
  final double yaw;

  /// How far the device is moved towards the viewer — negative, so it steps
  /// back as its halves come forward.
  final double depth;

  /// How far the finished picture is slid across the stage to keep what is
  /// drawn in its middle.
  final double slide;

  /// How far the camera stands from the screen's plane.
  final double distance;

  /// The screen that carries the content.
  final CoreMockupFoldScreen activeScreen;

  /// Whether the inner screen lies in one plane, so its content can be drawn
  /// live rather than from a copy per half.
  final bool isFlat;

  /// The right half of the open body. Its box is the whole open body; the
  /// platform shows the part right of the hinge.
  final CoreMockupFoldPart innerRight;

  /// The left half of the open body. Its box is the whole open body; the
  /// platform shows the part left of the hinge.
  final CoreMockupFoldPart innerLeft;

  /// The back of the left slab, which carries the cover screen. Its box is
  /// half the open body wide and as tall, with the hinge on its left.
  final CoreMockupFoldPart cover;

  /// The outer edge of the left slab. Its box is the slab's thickness wide
  /// and as tall as the body.
  final CoreMockupFoldPart edgeLeft;

  /// The outer edge of the right slab. Its box is the slab's thickness wide
  /// and as tall as the body.
  final CoreMockupFoldPart edgeRight;

  /// How far the inner screen is dimmed towards off, 0 (lit) to 1 (off).
  final double innerScreenDim;

  /// How far the cover screen is dimmed towards off, 0 (lit) to 1 (off).
  final double coverScreenDim;

  /// How the right slab's outer edge ends ([edgeRight]'s box).
  ///
  /// The right slab only ever shows its inner face, so the device's outline
  /// is the other side of its edge — where the box ends, at the slab's back.
  /// [top] and [bottom] are the open body's right corners, in the unit the
  /// pose was computed in.
  CoreMockupFoldEdgeCut rightEdgeCut({
    required CoreMockupFoldCorner top,
    required CoreMockupFoldCorner bottom,
  }) => (
    outlineAtEnd: true,
    top: _outlineCorner(
      top,
      edge: edgeRight,
      face: innerRight,
      faceEdge: width,
      inward: -1,
      y: 0,
    ),
    bottom: _outlineCorner(
      bottom,
      edge: edgeRight,
      face: innerRight,
      faceEdge: width,
      inward: -1,
      y: height,
    ),
  );

  /// How the left slab's outer edge ends ([edgeLeft]'s box).
  ///
  /// The left slab shows its cover or its inner face, and the device's
  /// outline is the face it does not show: the inner one, where the box ends,
  /// while the cover faces the viewer, and the cover, where the box starts,
  /// otherwise. [innerTop] and [innerBottom] are the open body's left
  /// corners, [coverTop] and [coverBottom] the cover's corners away from the
  /// hinge, in the unit the pose was computed in.
  CoreMockupFoldEdgeCut leftEdgeCut({
    required CoreMockupFoldCorner innerTop,
    required CoreMockupFoldCorner innerBottom,
    required CoreMockupFoldCorner coverTop,
    required CoreMockupFoldCorner coverBottom,
  }) => (
    outlineAtEnd: cover.visible,
    top: _outlineCorner(
      cover.visible ? innerTop : coverTop,
      edge: edgeLeft,
      face: innerLeft,
      faceEdge: 0,
      inward: 1,
      y: 0,
    ),
    bottom: _outlineCorner(
      cover.visible ? innerBottom : coverBottom,
      edge: edgeLeft,
      face: innerLeft,
      faceEdge: 0,
      inward: 1,
      y: height,
    ),
  );

  /// One end of the outline side of an edge, in the edge's own box: the far
  /// face's own [corner], as tall as it is and as wide as it is drawn across
  /// the [face] (from [faceEdge], turning [inward]), counted in the widths
  /// the strip is drawn across the [edge]. Both are measured on the stage at
  /// [y].
  CoreMockupFoldCorner _outlineCorner(
    CoreMockupFoldCorner corner, {
    required CoreMockupFoldPart edge,
    required CoreMockupFoldPart face,
    required double faceEdge,
    required double inward,
    required double y,
  }) {
    const square = (x: 0.0, y: 0.0);
    if (corner.x == 0 || corner.y == 0) return square;

    final across = _span(edge.matrix, 0, thickness, y);
    // Drawn no wider than nothing, the edge has no outline to cut.
    if (across <= 0) return square;
    final around = _span(
      face.matrix,
      faceEdge,
      faceEdge + inward * corner.x,
      y,
    );

    return (x: around / across * thickness, y: corner.y);
  }

  /// How long the run from [from] to [to] along a part's box, at [y], is
  /// drawn on the stage under [matrix].
  static double _span(List<double> matrix, double from, double to, double y) {
    final a = project(matrix, from, y);
    final b = project(matrix, to, y);
    final dx = b.x - a.x;
    final dy = b.y - a.y;

    return math.sqrt(dx * dx + dy * dy);
  }

  /// Where the point at [x], [y] of a part's box lands on the stage under
  /// [matrix].
  static ({double x, double y}) project(
    List<double> matrix,
    double x,
    double y,
  ) {
    final w = matrix[3] * x + matrix[7] * y + matrix[15];

    return (
      x: (matrix[0] * x + matrix[4] * y + matrix[12]) / w,
      y: (matrix[1] * x + matrix[5] * y + matrix[13]) / w,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreMockupFoldPose &&
          other.width == width &&
          other.height == height &&
          other.thickness == thickness &&
          other.angle == angle &&
          _listEquals(other.innerRight.matrix, innerRight.matrix) &&
          _listEquals(other.innerLeft.matrix, innerLeft.matrix) &&
          _listEquals(other.cover.matrix, cover.matrix) &&
          _listEquals(other.edgeLeft.matrix, edgeLeft.matrix) &&
          _listEquals(other.edgeRight.matrix, edgeRight.matrix);

  @override
  int get hashCode => Object.hash(
    width,
    height,
    thickness,
    angle,
    Object.hashAll(innerRight.matrix),
    Object.hashAll(innerLeft.matrix),
    Object.hashAll(cover.matrix),
    Object.hashAll(edgeLeft.matrix),
    Object.hashAll(edgeRight.matrix),
  );
}

bool _listEquals(List<double> a, List<double> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }

  return true;
}

/// The share of the shade over a part turned [tilt] radians from facing the
/// viewer: none face on, all of it edge on.
double _shadeOf(double tilt) {
  final s = math.sin(tilt);

  return (s * s).clamp(0.0, 1.0);
}

/// Whether a box [width] × [height] under [matrix] shows its front: its
/// corners still run clockwise on the stage, and it has not turned edge on.
bool _facesViewer(List<double> matrix, double width, double height) {
  final origin = CoreMockupFoldPose.project(matrix, 0, 0);
  final across = CoreMockupFoldPose.project(matrix, width, 0);
  final down = CoreMockupFoldPose.project(matrix, 0, height);
  final area =
      (across.x - origin.x) * (down.y - origin.y) -
      (across.y - origin.y) * (down.x - origin.x);

  // A part less than a thousandth of its own area across is edge on.
  return area > width * height * _kEdgeOnShare;
}

const double _kEdgeOnShare = 0.001;

// ─── 4 × 4 matrices, column-major ─────────────────────────────
// Element (row, column) is at `column * 4 + row`. The stage's x runs right,
// y down and z towards the viewer.

List<double> _matrix(
  double m00,
  double m01,
  double m02,
  double m03,
  double m10,
  double m11,
  double m12,
  double m13,
  double m20,
  double m21,
  double m22,
  double m23,
  double m30,
  double m31,
  double m32,
  double m33,
) => List<double>.unmodifiable([
  // Written above by rows; stored by columns.
  m00, m10, m20, m30,
  m01, m11, m21, m31,
  m02, m12, m22, m32,
  m03, m13, m23, m33,
]);

List<double> _multiply(List<double> a, List<double> b) {
  final out = List<double>.filled(16, 0);
  for (var column = 0; column < 4; column++) {
    for (var row = 0; row < 4; row++) {
      var sum = 0.0;
      for (var k = 0; k < 4; k++) {
        sum += a[k * 4 + row] * b[column * 4 + k];
      }
      out[column * 4 + row] = sum;
    }
  }

  return List<double>.unmodifiable(out);
}

List<double> _translation(double x, double y, double z) =>
    _matrix(1, 0, 0, x, 0, 1, 0, y, 0, 0, 1, z, 0, 0, 0, 1);

/// A turn of [radians] about the vertical line through [hingeX] on the
/// screen's plane. A positive turn brings what is left of the line towards
/// the viewer and sends what is right of it away.
List<double> _turnAbout(double hingeX, double radians) {
  final c = math.cos(radians);
  final s = math.sin(radians);

  return _matrix(
    c,
    0,
    s,
    hingeX - hingeX * c, //
    0,
    1,
    0,
    0,
    -s,
    0,
    c,
    hingeX * s,
    0,
    0,
    0,
    1,
  );
}

/// A camera [distance] in front of the screen's plane, looking at
/// ([centerX], [centerY]): what is nearer is drawn larger about that point.
List<double> _perspective(double centerX, double centerY, double distance) =>
    _matrix(
      1,
      0,
      -centerX / distance,
      0, //
      0,
      1,
      -centerY / distance,
      0,
      0,
      0,
      1,
      0,
      0,
      0,
      -1 / distance,
      1,
    );

/// The back of the left slab in the open body's frame: [thickness] behind
/// the screen, and turned over so that it reads the right way round once the
/// slab has folded onto the right half.
List<double> _coverPlane(double hingeX, double thickness) => _matrix(
  -1,
  0,
  0,
  hingeX, //
  0,
  1,
  0,
  0,
  0,
  0,
  -1,
  -thickness,
  0,
  0,
  0,
  1,
);

/// The left slab's outer edge in the open body's frame: at the body's left
/// edge, running from its back to its screen.
List<double> _leftEdgePlane(double thickness) => _matrix(
  0,
  0,
  -1,
  0, //
  0,
  1,
  0,
  0,
  1,
  0,
  0,
  -thickness,
  0,
  0,
  0,
  1,
);

/// The right slab's outer edge in the open body's frame: at the body's right
/// edge, running from its screen to its back.
List<double> _rightEdgePlane(double width) => _matrix(
  0,
  0,
  1,
  width, //
  0,
  1,
  0,
  0,
  -1,
  0,
  0,
  0,
  0,
  0,
  0,
  1,
);
