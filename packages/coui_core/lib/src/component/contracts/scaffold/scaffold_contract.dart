/// Platform-independent contract for scaffold components.
///
/// Defines the interface that all scaffold implementations (Flutter,
/// Web) must satisfy.
library;

import 'package:coui_core/src/component/contracts/scaffold/scaffold_style.dart';
import 'package:coui_core/src/component/contracts/scaffold/scaffold_variant.dart';
import 'package:coui_core/src/spacing/edge_insets.dart';

/// Contract for a scaffold component.
///
/// `Scaffold` provides the fundamental screen-layout structure —
/// stacked header sections, a main content area and stacked footer
/// sections — plus an optional sidebar, optional floating action button
/// and an optional loading-progress indicator.
///
/// The behaviour / semantic fields (`headers` / `footers` / `child` /
/// `sidebar` / `variant` / `floatingActionButton` /
/// `floatingActionButtonLocation` / `floatingHeader` / `floatingFooter`
/// / `loadingProgress` / `loadingProgressIndeterminate`) stay flat on
/// the widget — they change the *content* or *behaviour* of the layout,
/// not its visual chrome. All chrome / dimensional overrides flow
/// through [scaffoldStyle].
///
/// `W` is the platform widget type (`Widget` on Flutter, `Component` on
/// Web).
abstract interface class CoreScaffoldContract<W> {
  /// Existing screens retain their horizontal application bar.
  static const defaultAdaptiveAppBarActions = false;

  /// Move the first direct AppBar's movable controls to a reserved side strip.
  /// Opt-in: existing scaffolds retain their layout. Horizontal-only BarAction
  /// controls remain beside the title. A hinge alone is not a control strip.
  bool get adaptiveAppBarActions;

  /// Explicit system control insets, in physical logical pixels. Null reads
  /// MediaQuery.viewPadding on Flutter and CSS safe-area-inset-* on Web.
  /// Useful for embedded device previews and server-rendered layouts.
  CoreEdgeInsets? get appBarControlInsets;

  /// One platform-neutral eligibility rule. A conventional landscape phone
  /// with symmetric insets or a top notch retains its horizontal app bar.
  static bool hasAppBarControlRail({
    required CoreEdgeInsets insets,
    required double controlWidth,
    required double outerInset,
  }) =>
      insets.top == 0 &&
      (insets.left > 0) != (insets.right > 0) &&
      insets.left + insets.right >= controlWidth + outerInset;

  /// The header sections, stacked top-to-bottom above the body.
  List<W> get headers;

  /// The footer sections, stacked top-to-bottom below the body.
  List<W> get footers;

  /// The main content area of the scaffold.
  W get child;

  /// An optional sidebar rendered alongside the body.
  W? get sidebar;

  /// An optional button floating above the body content.
  W? get floatingActionButton;

  /// Where the [floatingActionButton] is positioned.
  CoreScaffoldFabLocation get floatingActionButtonLocation;

  /// Whether the header floats above the body without taking layout
  /// space.
  bool get floatingHeader;

  /// Whether the footer floats above the body without taking layout
  /// space.
  bool get floatingFooter;

  /// The loading progress value (`0.0`–`1.0`), or `null` for no
  /// indicator.
  double? get loadingProgress;

  /// Whether the loading indicator runs in indeterminate mode.
  bool get loadingProgressIndeterminate;

  /// The visual variant of the scaffold.
  CoreScaffoldVariant get variant;

  /// Per-instance scaffold chrome / dimensional style.
  CoreScaffoldStyle? get scaffoldStyle;
}
