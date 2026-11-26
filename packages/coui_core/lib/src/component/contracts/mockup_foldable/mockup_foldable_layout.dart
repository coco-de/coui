/// Derived geometry for `MockupFoldable` — the one place both platform
/// resolvers size the folding device and its two faces from.
library;

import 'package:coui_core/src/component/contracts/mockup/mockup_device.dart';
import 'package:coui_core/src/component/contracts/mockup/mockup_device_layout.dart';
import 'package:coui_core/src/component/contracts/mockup/mockup_device_rect.dart';
import 'package:coui_core/src/component/contracts/mockup/mockup_device_style.dart';
import 'package:coui_core/src/component/contracts/mockup/mockup_orientation.dart';
import 'package:coui_core/src/component/contracts/mockup_foldable/mockup_fold.dart';
import 'package:coui_core/src/component/contracts/mockup_foldable/mockup_foldable_style.dart';
import 'package:coui_core/src/shape/border_radius.dart';
import 'package:coui_core/src/viewport/core_fold.dart';
import 'package:meta/meta.dart';

/// The status island of one screen, in screen space — origin at the screen's
/// top-left corner, in logical px.
///
/// `column` is the strip at the screen's right edge the island stands in, the
/// whole height of the screen: its width is the room the content keeps clear.
/// `camera`, `clock` and `indicator` are the boxes of the parts that show,
/// top to bottom, each centred across the column; a part that does not show
/// is `null`. `scale` is what the parts were sized by (iOS points → logical
/// px) — the factor the clock's text is drawn at.
typedef CoreMockupFoldableIsland = ({
  CoreMockupDeviceRect column,
  CoreMockupDeviceRect? camera,
  CoreMockupDeviceRect? clock,
  CoreMockupDeviceRect? indicator,
  double scale,
});

/// The sizes of a folding device and of the two `MockupDevice` faces it is
/// made of.
///
/// A `MockupFoldable` draws no body of its own. Open, it is a tablet on its
/// side ([innerDevice], [innerOrientation]); shut, the back of its left half
/// is a phone ([coverDevice]). This class settles the few values the two must
/// agree on — the cover is exactly half the open body wide and as tall — and
/// hands each face the style that makes its `MockupDevice` come out at that
/// size ([innerDeviceStyle], [coverDeviceStyle]). It also places what the
/// device adds to its faces: the status island of each screen ([islandOf]).
///
/// Unscaled, like `CoreMockupDeviceLayout`: the Flutter resolver multiplies
/// by `theme.scaling` and the Web resolver divides into `rem`.
@immutable
class CoreMockupFoldableLayout {
  const CoreMockupFoldableLayout._({
    required this.width,
    required this.height,
    required this.coverWidth,
    required this.thickness,
    required this.perspective,
    required this.innerDeviceStyle,
    required this.coverDeviceStyle,
    required this.innerScreen,
    required this.innerScreenBorderRadius,
    required this.coverScreen,
    required this.coverScreenBorderRadius,
    required this.innerSystemScale,
    required this.coverSystemScale,
    required this.islandWidth,
    required this.islandOffset,
    required this.islandCameraSize,
  });

  /// Computes the layout of a device [width] wide when open.
  ///
  /// [innerDeviceStyle] and [coverDeviceStyle] are the settled nested styles
  /// (the default with the merge chain laid over it). [thickness],
  /// [perspective] and the three island lengths (iOS points) are settled too
  /// — this function owns no defaults.
  factory CoreMockupFoldableLayout.compute({
    required double width,
    required CoreMockupDeviceStyle innerDeviceStyle,
    required CoreMockupDeviceStyle coverDeviceStyle,
    required double thickness,
    required double perspective,
    required double islandWidth,
    required double islandOffset,
    required double islandCameraSize,
  }) {
    final innerRow = CoreMockupDeviceStyle.defaultsByDevice[innerDevice]!;
    final coverRow = CoreMockupDeviceStyle.defaultsByDevice[coverDevice]!;

    // ─── Open body — a tablet on its side ────────────────
    // The values the cover's size hangs on are read here by the ladder the
    // device's own resolver reads them by, and stated back on the face's
    // style, so a project-wide device theme cannot move one face without the
    // other.
    final innerRail =
        innerDeviceStyle.railWidth ?? CoreMockupDeviceStyle.defaultRailWidth;
    final innerBezel = innerDeviceStyle.bezelWidth ?? innerRow.bezelWidth!;
    final innerRadius = innerDeviceStyle.borderRadius ?? innerRow.borderRadius!;
    final innerAspectA =
        innerDeviceStyle.screenAspectWidth ?? innerRow.screenAspectWidth!;
    final innerAspectB =
        innerDeviceStyle.screenAspectHeight ?? innerRow.screenAspectHeight!;
    // Read long-side-first, as the device reads it: the open body is wide.
    final innerLong = innerAspectA > innerAspectB ? innerAspectA : innerAspectB;
    final innerShort = innerAspectA > innerAspectB
        ? innerAspectB
        : innerAspectA;
    final innerInset = innerRail + innerBezel;
    // The open body is held on its side, so its system lengths are drawn at
    // the landscape scale.
    final innerSystemScale = _atLeastZero(
      innerDeviceStyle.landscapeSystemBarReferenceScale ??
          innerRow.landscapeSystemBarReferenceScale!,
    );
    final innerScreenWidth = _atLeastZero(width - innerInset * 2);
    final innerScreenHeight = innerLong == 0
        ? 0.0
        : innerScreenWidth * innerShort / innerLong;
    final height = innerScreenHeight + innerInset * 2;

    // ─── Cover — the back of the left half ───────────────
    // Half the open body wide and as tall. A `MockupDevice` derives its
    // height from its screen's proportions, so the proportions stated here
    // are the screen box that leaves exactly that body.
    final coverWidth = width / 2;
    final coverRail =
        coverDeviceStyle.railWidth ?? CoreMockupDeviceStyle.defaultRailWidth;
    final coverBezel = coverDeviceStyle.bezelWidth ?? coverRow.bezelWidth!;
    final coverInset = coverRail + coverBezel;
    final coverScreenWidth = _atLeastZero(coverWidth - coverInset * 2);
    final coverScreenHeight = _atLeastZero(height - coverInset * 2);
    // The cover's outer corners are the body's own; the hinge side is cut
    // straight, as the half of a body is.
    final coverRadius =
        coverDeviceStyle.borderRadius ??
        CoreBorderRadius.only(
          topRight: innerRadius.topRight,
          bottomRight: innerRadius.bottomRight,
        );
    final coverSystemScale = _atLeastZero(
      coverDeviceStyle.systemBarReferenceScale ??
          coverRow.systemBarReferenceScale!,
    );

    return CoreMockupFoldableLayout._(
      width: width,
      height: height,
      coverWidth: coverWidth,
      thickness: thickness,
      perspective: perspective,
      innerDeviceStyle: innerDeviceStyle.merge(
        CoreMockupDeviceStyle(
          railWidth: innerRail,
          bezelWidth: innerBezel,
          borderRadius: innerRadius,
          screenAspectWidth: innerLong,
          screenAspectHeight: innerShort,
          landscapeSystemBarReferenceScale: innerSystemScale,
        ),
      ),
      coverDeviceStyle: coverDeviceStyle.merge(
        CoreMockupDeviceStyle(
          railWidth: coverRail,
          bezelWidth: coverBezel,
          borderRadius: coverRadius,
          screenAspectWidth: coverScreenWidth,
          screenAspectHeight: coverScreenHeight,
          systemBarReferenceScale: coverSystemScale,
        ),
      ),
      innerScreen: (
        left: innerInset,
        top: innerInset,
        width: innerScreenWidth,
        height: innerScreenHeight,
      ),
      innerScreenBorderRadius: CoreMockupDeviceLayout.deflateBorderRadius(
        innerRadius,
        innerInset,
      ),
      coverScreen: (
        left: coverInset,
        top: coverInset,
        width: coverScreenWidth,
        height: coverScreenHeight,
      ),
      coverScreenBorderRadius: CoreMockupDeviceLayout.deflateBorderRadius(
        coverRadius,
        coverInset,
      ),
      innerSystemScale: innerSystemScale,
      coverSystemScale: coverSystemScale,
      islandWidth: islandWidth,
      islandOffset: islandOffset,
      islandCameraSize: islandCameraSize,
    );
  }

  /// The device kind the open body is drawn as.
  static const CoreMockupDevice innerDevice = CoreMockupDevice.tablet;

  /// The way the open body is held: on its side, the hinge down its middle.
  static const CoreMockupOrientation innerOrientation =
      CoreMockupOrientation.landscape;

  /// The device kind the cover is drawn as.
  static const CoreMockupDevice coverDevice = CoreMockupDevice.phone;

  /// The way the cover is held: upright.
  static const CoreMockupOrientation coverOrientation =
      CoreMockupOrientation.portrait;

  /// Width of the open body — the `width` the caller supplied. Also the
  /// width of the stage the device folds on.
  final double width;

  /// Height of the open body, and of the cover.
  final double height;

  /// Width of the cover — half of [width].
  final double coverWidth;

  /// How deep each slab is.
  final double thickness;

  /// How far away the device is seen from, in open-body widths.
  final double perspective;

  /// The style the open body's `MockupDevice` is given: the settled nested
  /// style with the values this layout depends on stated on it.
  final CoreMockupDeviceStyle innerDeviceStyle;

  /// The style the cover's `MockupDevice` is given: the settled nested style
  /// with the cover's size, corners and camera stated on it.
  final CoreMockupDeviceStyle coverDeviceStyle;

  /// The inner screen's box, measured from the open body's top-left corner.
  final CoreMockupDeviceRect innerScreen;

  /// The inner screen's corners.
  final CoreBorderRadius innerScreenBorderRadius;

  /// The cover screen's box, measured from the cover's top-left corner.
  final CoreMockupDeviceRect coverScreen;

  /// The cover screen's corners.
  final CoreBorderRadius coverScreenBorderRadius;

  /// The scale the open body draws its system lengths at (iOS points →
  /// logical px), and its screen's island with them.
  final double innerSystemScale;

  /// The scale the cover draws its system lengths at, and its screen's island
  /// with them.
  final double coverSystemScale;

  /// Width of the island's column (iOS points).
  final double islandWidth;

  /// Distance from a screen's top edge to its island's first part (iOS
  /// points).
  final double islandOffset;

  /// Diameter of the cover's camera (iOS points).
  final double islandCameraSize;

  /// Where the hinge runs, measured from the open body's left edge.
  double get hingeX => width / 2;

  /// The status island of [screen], or `null` when nothing of it shows
  /// there — then the content has the whole width of that screen.
  ///
  /// The cover's island starts with its camera when [showCamera]; the inner
  /// screen has no camera. Under it, when [showStatus], come the clock and
  /// the status indicator. Every part is centred across the column and laid
  /// top to bottom from the island's offset.
  CoreMockupFoldableIsland? islandOf(
    CoreMockupFoldScreen screen, {
    required bool showCamera,
    required bool showStatus,
  }) {
    final onCover = screen == CoreMockupFoldScreen.cover;
    final hasCamera = onCover && showCamera;
    if (!hasCamera && !showStatus) return null;

    final box = onCover ? coverScreen : innerScreen;
    final scale = onCover ? coverSystemScale : innerSystemScale;
    final columnWidth = _atMost(islandWidth * scale, box.width);
    final columnLeft = box.width - columnWidth;

    CoreMockupDeviceRect centred(double top, double width, double height) => (
      left: columnLeft + (columnWidth - width) / 2,
      top: top,
      width: width,
      height: height,
    );

    var top = islandOffset * scale;
    CoreMockupDeviceRect? camera;
    if (hasCamera) {
      final size = islandCameraSize * scale;
      camera = centred(top, size, size);
      top += size + CoreMockupFoldableStyle.islandCameraGap * scale;
    }
    CoreMockupDeviceRect? clock;
    CoreMockupDeviceRect? indicator;
    if (showStatus) {
      final clockHeight = CoreMockupFoldableStyle.islandClockHeight * scale;
      // The clock's line runs the column's whole width: its words are
      // centred in it, however wide they come out.
      clock = (
        left: columnLeft,
        top: top,
        width: columnWidth,
        height: clockHeight,
      );
      top += clockHeight + CoreMockupFoldableStyle.islandClockGap * scale;
      final size = CoreMockupFoldableStyle.islandIndicatorSize * scale;
      indicator = centred(top, size, size);
    }

    return (
      column: (
        left: columnLeft,
        top: 0,
        width: columnWidth,
        height: box.height,
      ),
      camera: camera,
      clock: clock,
      indicator: indicator,
      scale: scale,
    );
  }

  /// What the app on the device's screen reads from `FoldScope` at [angle]:
  /// on the inner screen, one fold down its middle, flat or half opened; on
  /// the cover, a screen with no fold.
  CoreFoldLayout foldLayoutAt(double angle) {
    if (CoreMockupFold.activeScreen(angle) == CoreMockupFoldScreen.cover) {
      return CoreFoldLayout(
        width: coverScreen.width,
        height: coverScreen.height,
      );
    }

    return CoreFoldLayout(
      width: innerScreen.width,
      height: innerScreen.height,
      folds: [
        CoreFold(
          bounds: CoreViewportRect(
            left: innerScreen.width / 2,
            top: 0,
            width: 0,
            height: innerScreen.height,
          ),
          state: CoreMockupFold.foldState(angle),
        ),
      ],
    );
  }

  /// Where every part is drawn at [angle], with every length multiplied by
  /// [scale] — the factor the platform draws this layout at.
  CoreMockupFoldPose poseAt(double angle, {double scale = 1}) =>
      CoreMockupFoldPose.compute(
        angle: angle,
        width: width * scale,
        height: height * scale,
        thickness: thickness * scale,
        perspective: perspective,
      );
}

double _atLeastZero(double value) => value < 0 ? 0 : value;

double _atMost(double value, double limit) => value > limit ? limit : value;
