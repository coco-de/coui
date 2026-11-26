/// Platform-independent contract for unified resizable components.
library;

import 'package:coui_core/src/component/contracts/resizable/resizable_style.dart';

/// Default initial pane size (50% flex ratio).
const _kDefaultInitialSize = 0.5;

/// Data for a single resizable pane.
///
/// Type parameter:
/// - [W] - content widget type (Flutter `Widget`, Web `Component`).
class CoreResizablePaneData<W> {
  /// Creates a [CoreResizablePaneData].
  const CoreResizablePaneData({
    required this.content,
    this.initialSize = _kDefaultInitialSize,
    this.minSize,
    this.maxSize,
  });

  /// Content widget for this pane.
  final W content;

  /// Initial size as a flex ratio (0.0-1.0) of the container.
  ///
  /// Read as intent rather than as the size drawn: `CoreResizableLayout`
  /// normalises the declared ratios across all panes to the whole container
  /// and fits them to [minSize] / [maxSize] before anything renders. So a
  /// list whose ratios do not add up to 1, or one whose ratio sits outside
  /// its own bounds, lays out at the nearest geometry that does — rather
  /// than rendering one fraction while announcing another.
  final double initialSize;

  /// Minimum size as a flex ratio (0.0-1.0) of the container.
  ///
  /// Relaxed proportionally when the panes' minimums cannot fit in the
  /// container together — an unsatisfiable floor cannot be honoured, and
  /// reporting it anyway is what produced dividers whose announced minimum
  /// sat above their announced maximum.
  final double? minSize;

  /// Maximum size as a flex ratio (0.0-1.0) of the container.
  ///
  /// Relaxed proportionally when the panes' maximums cannot fill the
  /// container together, for the same reason [minSize] is.
  final double? maxSize;
}

/// Orientation for resizable panel layout.
enum CoreResizableDirection {
  /// Horizontal split (left/right panes).
  horizontal,

  /// Vertical split (top/bottom panes).
  vertical,
}

/// Contract for a unified resizable component.
///
/// Displays multiple panes with draggable dividers between them.
/// Users can drag dividers to adjust pane sizes.
///
/// Per Epic #1302 chrome / dimensional overrides flow through the
/// single [resizableStyle] slot — see [CoreResizableStyle] for the
/// merge chain.
///
/// Type parameters:
/// - [W] — platform widget type.
abstract interface class CoreResizableContract<W> {
  /// Default for [showDragHandle] — plain thin divider (pointer
  /// platforms). Single source of truth for both Flutter and Web
  /// widgets.
  static const bool defaultShowDragHandle = false;

  /// Default for [optionalDivider] — the divider is always drawn. Single
  /// source of truth for both Flutter and Web widgets.
  static const bool defaultOptionalDivider = false;

  /// Arrow-key resize step, as a fraction of the pane flex-ratio range
  /// (`[0, 1]`) — one arrow press moves a divider by this much of the
  /// container's main axis.
  ///
  /// Reuses `Slider`/`Range`'s ARIA APG "Slider" keyboard-pattern default
  /// (1% of the adjustable range per arrow press, `#3454`) rather than
  /// inventing a new step: a pane's size is already a ratio in that same
  /// `[0, 1]` domain — `deltaRatio = deltaPx / containerSize` in the
  /// pointer-drag handler computes the exact same unit, so this constant
  /// is that ratio's keyboard equivalent, not an arbitrary number. Single
  /// source of truth for both Flutter and Web widgets (mirrors
  /// `CoreDragItemContract.defaultKeyboardDragStep`'s placement).
  static const double defaultKeyboardStepFraction = 0.01;

  /// List of panes to display.
  List<CoreResizablePaneData<W>> get panes;

  /// Split direction.
  CoreResizableDirection get direction;

  /// Called when pane sizes change (drag end or programmatic).
  ///
  /// Receives current flex ratios for each pane.
  void Function(List<double> sizes)? get onResize;

  /// Whether to render a larger, centered grab handle on each divider.
  ///
  /// The thin divider is hard to grab on touch platforms (iOS /
  /// Android). When `true`, the divider hit area is enlarged
  /// ([CoreResizableStyle.handleHitExtent]) and a pill-shaped handle
  /// with drag dots is drawn at the center to invite dragging. Defaults
  /// to [defaultShowDragHandle] (`false`).
  bool get showDragHandle;

  /// Whether the divider stays invisible until it is hovered, focused or
  /// dragged.
  ///
  /// For layouts where a permanent seam is visual noise. The divider still
  /// occupies its hit area while hidden — invisible and ungrabbable are
  /// different things — so pointing at the seam reveals it and dragging
  /// works unchanged. Defaults to [defaultOptionalDivider] (`false`),
  /// which keeps the divider drawn at all times.
  bool get optionalDivider;

  /// Per-instance chrome / dimensional style.
  ///
  /// Resolves through the nested-merge chain:
  ///
  /// ```text
  /// design system default
  ///   → CoreResizableTheme.style
  ///   → parent component slot override
  ///   → widget.resizableStyle
  /// ```
  CoreResizableStyle? get resizableStyle;
}
