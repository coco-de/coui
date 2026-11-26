import 'package:coui_core/src/component/contracts/breakpoint/breakpoint_tier.dart';
import 'package:coui_core/src/component/contracts/responsive_row_column/responsive_row_column_style.dart';

/// Platform-agnostic contract for `ResponsiveRowColumn` — a layout
/// primitive that renders its [children] as a `Row` (horizontal main
/// axis) at or above [switchAt], and as a `Column` (vertical main
/// axis) below it. The cross-platform analogue of
/// `responsive_framework`'s `ResponsiveRowColumn`.
///
/// Direction is derived at render time from the ambient viewport
/// breakpoint tier (via the shared `Breakpoint`/`resolveBreakpoint`
/// accessor from `CoreBreakpointContract`) — it is never a widget
/// parameter of its own.
///
/// Type parameters:
///   - [W] — `Widget` on Flutter, `Component` on Web (child type).
abstract interface class CoreResponsiveRowColumnContract<W> {
  /// Behaviour default for [switchAt] — a BEHAVIOUR value (which axis
  /// the layout renders along at which breakpoint), not chrome, so it
  /// lives here on the Contract rather than on a Style slot. Mirrors
  /// `CoreBreakpointContract.defaultBoundaries`'s placement.
  static const CoreBreakpointTier defaultSwitchAt = .tablet;

  /// The children rendered inside the row/column.
  List<W> get children;

  /// The breakpoint tier at or above which [children] render inside a
  /// `Row` (horizontal); below it, they render inside a `Column`
  /// (vertical). `null` falls back to [defaultSwitchAt].
  CoreBreakpointTier? get switchAt;

  /// Per-instance spacing / alignment style.
  ///
  /// Resolves through the nested-merge chain:
  ///
  /// ```text
  /// design system default
  ///   → CoreResponsiveRowColumnTheme.style
  ///   → widget.responsiveRowColumnStyle
  /// ```
  CoreResponsiveRowColumnStyle? get responsiveRowColumnStyle;
}
