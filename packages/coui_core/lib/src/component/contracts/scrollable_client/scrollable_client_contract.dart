/// Platform-independent contract for a 2D scrollable viewport.
library;

import 'package:coui_core/src/component/contracts/scrollable_client/core_axis.dart';
import 'package:coui_core/src/component/contracts/scrollable_client/core_diagonal_drag_behavior.dart';
import 'package:coui_core/src/component/contracts/scrollable_client/core_hit_test_behavior.dart';
import 'package:coui_core/src/component/contracts/scrollable_client/core_keyboard_dismiss_behavior.dart';
import 'package:coui_core/src/component/contracts/scrollable_client/core_scrollable_details.dart';
import 'package:coui_core/src/component/contracts/semantics/core_semantic_role.dart';

/// Builder invoked by a ScrollableClient on every scroll frame.
///
/// - [context]: platform build context.
/// - [offset]: current (x, y) scroll position in pixels.
/// - [viewportSize]: width/height of the visible area in pixels.
/// - [child]: the optional static child passed to the ScrollableClient
///   (forwarded verbatim so implementations can avoid rebuilding it).
typedef CoreScrollableBuilder<W, Off, Sz> =
    W Function(
      Object context,
      Off offset,
      Sz viewportSize,
      W? child,
    );

/// Contract for a 2D scrollable viewport component.
///
/// Type parameters:
/// - [W] — platform widget type (`Widget` on Flutter, `Component` on Web).
/// - [Off] — offset type (`Offset` on Flutter, a simple `({double dx, double
///   dy})` record on Web).
/// - [Sz] — size type (`Size` on Flutter, `({double width, double height})`
///   record on Web).
/// - [Clp] — clip behaviour type (`Clip` on Flutter, `CoreClip` on Web).
///
/// Implementations must expose a [builder] that the viewport calls on every
/// frame with the current scroll [Off] / [Sz], plus a static [child] that is
/// forwarded into the builder unchanged (to avoid rebuilding subtrees that
/// don't depend on the scroll state).
abstract interface class CoreScrollableClientContract<W, Off, Sz, Clp> {
  /// Default diagonal drag behaviour when the widget parameter is null.
  /// Single source shared by the Flutter and Web resolvers so the two
  /// stay in parity.
  static const CoreDiagonalDragBehavior defaultDiagonalDragBehavior = .none;

  /// Default overscroll flag when the widget parameter is null.
  static const bool defaultOverscroll = false;

  /// Default hit-test behaviour when the widget parameter is null.
  static const CoreHitTestBehavior defaultHitTestBehavior = .opaque;

  /// Default keyboard-dismiss behaviour when the widget parameter is null.
  static const CoreKeyboardDismissBehavior defaultKeyboardDismissBehavior =
      .manual;

  /// Default scrollbar visibility when the widget parameter is null.
  static const bool defaultShowScrollbar = true;

  /// What the viewport announces itself to be.
  ///
  /// A drag-scroll surface is a grouping, not a landmark: this component
  /// is a primitive that other components (a table, a canvas) scroll
  /// their own content inside, so one landmark per instance would fill a
  /// screen reader's landmark list with entries that name nothing the
  /// user was looking for.
  static const CoreSemanticRole semanticRole = .group;

  /// How far one arrow-key press scrolls, in logical pixels.
  ///
  /// Matches the line increment Flutter's own `ScrollAction` uses for a
  /// hardware keyboard, so a `ScrollableClient` moves by the same amount
  /// as every other scroll view on that platform — and, because both
  /// platforms read this constant, by the same amount as its Web twin.
  static const double keyboardLineStep = 50;

  /// What fraction of the viewport one `PageUp` / `PageDown` scrolls.
  ///
  /// Also Flutter's own figure for `ScrollIncrementType.page`. Less than
  /// a full viewport on purpose — the overlap is what lets a reader keep
  /// their place across a page jump.
  static const double keyboardPageStepFraction = 0.8;

  /// Static child forwarded into [builder] on every scroll frame.
  W? get child;

  /// Called on every scroll update to build the current view.
  CoreScrollableBuilder<W, Off, Sz> get builder;

  /// Primary scroll axis (used when only one axis drives the layout).
  CoreAxis get mainAxis;

  /// Per-axis details for the vertical axis (direction + initial offset).
  CoreScrollableDetails get verticalDetails;

  /// Per-axis details for the horizontal axis (direction + initial offset).
  CoreScrollableDetails get horizontalDetails;

  /// How diagonal drags are resolved. [CoreDiagonalDragBehavior.free] lets
  /// both axes scroll simultaneously; other values restrict to the dominant
  /// axis.
  CoreDiagonalDragBehavior? get diagonalDragBehavior;

  /// Whether overscroll past the content edges is permitted.
  bool? get overscroll;

  /// How the viewport clips content that overflows its bounds.
  Clp? get clipBehavior;

  /// How the viewport responds to pointer events. See [CoreHitTestBehavior].
  CoreHitTestBehavior? get hitTestBehavior;

  /// Whether and when scrolling dismisses the soft keyboard / focused
  /// element. See [CoreKeyboardDismissBehavior].
  CoreKeyboardDismissBehavior? get keyboardDismissBehavior;

  /// Whether the design-system scrollbar is rendered. Defaults to `true` —
  /// when `false` both the Flutter `RawScrollbar` and the Web
  /// `::-webkit-scrollbar` skin are suppressed and the viewport scrolls
  /// without a visible thumb.
  bool? get showScrollbar;

  /// The accessible name announced for the viewport.
  ///
  /// Nullable rather than defaulted because a compile-time constant
  /// default cannot see the active locale — the displayed value is
  /// resolved at render time as `semanticLabel ?? localizations
  /// .scrollableClientLabel`, which is the only shape that reacts to a
  /// locale switch (`cross-platform/localization.md`).
  String? get semanticLabel;
}
