/// Platform-independent contract for the unified `MockupFoldable`.
library;

import 'package:coui_core/src/component/contracts/mockup_foldable/mockup_fold.dart';
import 'package:coui_core/src/component/contracts/mockup_foldable/mockup_foldable_style.dart';
import 'package:coui_core/src/theme/brightness.dart';

/// Contract for a unified folding-device mockup — a device that folds down
/// its middle, around the caller's screen content.
///
/// Open, the content is on the inner screen, which spans both halves; shut,
/// it is on the cover screen on the back of the half that folds over. How far
/// the device is folded is the one value [foldAngle], and everything drawn —
/// which screen is lit, where each half stands, what the content is told
/// about the fold — follows from it by the rules in [CoreMockupFold], the
/// same on both platforms.
///
/// Both faces are `MockupDevice`s, styled through the nested slots of the
/// single [mockupFoldableStyle]. What the device adds to them is its status
/// island: where a slab phone has a status bar across the top of its screen,
/// this device keeps a column at the screen's right edge — the cover's camera
/// at its top, the clock and the status indicator under it.
/// `[W]` is the platform widget type (`Widget` on Flutter, `Component` on
/// Web).
abstract interface class CoreMockupFoldableContract<W> {
  /// Default for [foldAngle] — open flat.
  static const double defaultFoldAngle = CoreMockupFold.flat;

  /// Default for [showCamera] — the cover has its camera.
  static const bool defaultShowCamera = true;

  /// Default for [showStatus] — both screens show the clock and the status
  /// indicator.
  static const bool defaultShowStatus = true;

  /// Default for [showGestureBar] — no home bar: the content runs to the
  /// screen's bottom edge.
  static const bool defaultShowGestureBar = false;

  /// Content shown on whichever screen is lit: the inner screen while the
  /// device is open, the cover once it is nearly shut. It is laid out in
  /// that screen's simulated safe area — clear of the status island's column
  /// and of the gesture bar, when they show — and keeps its state when the
  /// screen changes.
  ///
  /// On the inner screen it reads the device's fold through `FoldScope`: one
  /// fold down the middle, flat or half opened. While the inner screen is
  /// bent — at any angle short of flat — its two halves stand in different
  /// planes, so the content is shown as a copy: it takes no input and no
  /// focus, and assistive technology does not read it. It is live again on
  /// a flat inner screen and on the cover.
  W get child;

  /// The angle between the two halves, in degrees: [CoreMockupFold.closed]
  /// (0) is shut, [CoreMockupFold.flat] (180) is open, and
  /// [CoreMockupFold.halfOpen] holds it like a book. A value outside that
  /// range is read as the nearer end.
  ///
  /// A change moves the device to the new angle over the style's `duration`;
  /// a zero duration follows the angle at once.
  double get foldAngle;

  /// Width of the open body (semantic layout — stays flat). `null` is
  /// `CoreMockupFoldableStyle.defaultWidth`. The component keeps this width
  /// at every angle; shut, the device stands in its middle.
  double? get width;

  /// Whether the cover's camera renders — the round hole at the top of the
  /// cover's status island. The inner screen has none. Hiding it moves the
  /// clock up into its place.
  bool get showCamera;

  /// Whether the status renders on both screens — the clock and the status
  /// indicator in the column at the screen's right edge. With neither it nor
  /// a camera to show, a screen has no island and its content takes the
  /// column's room too.
  bool get showStatus;

  /// Whether the home gesture bar renders on both screens, with the
  /// safe-area inset it reserves along the bottom.
  bool get showGestureBar;

  /// The brightness both screens render in. `null` follows the theme around
  /// the device. The body, bezel and buttons stay with the page.
  CoreBrightness? get screenBrightness;

  /// Per-instance style.
  ///
  /// Resolves through the nested-merge chain:
  ///
  /// ```text
  /// design system default (CoreMockupFoldableStyle.defaultX)
  ///   → CoreMockupFoldableTheme.style
  ///   → widget.mockupFoldableStyle
  /// ```
  CoreMockupFoldableStyle? get mockupFoldableStyle;
}
