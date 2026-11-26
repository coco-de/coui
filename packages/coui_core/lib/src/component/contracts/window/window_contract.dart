import 'package:coui_core/src/component/contracts/window/core_window_constraints.dart';
import 'package:coui_core/src/component/contracts/window/core_window_controller.dart';
import 'package:coui_core/src/component/contracts/window/core_window_rect.dart';
import 'package:coui_core/src/component/contracts/window/window_style.dart';
import 'package:coui_core/src/spacing/spacing.dart';

/// Cross-platform contract for the unified `Window` component.
///
/// Type parameter:
/// - [W]: Widget (Flutter) or Component (Web).
///
/// All rectangle/constraints/controller types live in `coui_core` so the
/// contract is platform-neutral; each platform adopts them via a thin
/// wrapper where needed.
abstract interface class CoreWindowContract<W> {
  /// Pointer travel (logical/CSS px) a title-bar drag on a maximized or
  /// snapped window must cover before the window restores to its
  /// floating bounds. A plain (slightly shaky) click stays a click —
  /// without this gate every grab attempt on a snapped window popped it
  /// back to floating size. Shared by both platforms' drag handlers.
  static const double defaultSnapRestoreSlop = 18;

  /// The FULL-maximize relative rect (the window flush with every
  /// desktop edge). Behaviour decisions key on this — "is this a full
  /// maximize, or a partial snap layout?" gates the corner-radius drop
  /// and the drag-restore semantics on both platforms, so the sentinel
  /// lives here instead of being re-spelled inline at every compare
  /// site.
  static const CoreWindowRect fullMaximizeRect = CoreWindowRect.fromLTWH(
    0,
    0,
    1,
    1,
  );

  /// Default thickness of each of the 8 resize hit regions, in
  /// logical/CSS px (pre-scaling). Shared by both platforms' `Window`
  /// constructors so the same grab area answers on each.
  static const double defaultResizeThickness = CoreSpace.space8;

  /// Title slot (typically a `Text` widget/component).
  W? get title;

  /// Action slot rendered next to the minimize/maximize/close controls.
  /// `null` uses the platform default window action row.
  W? get actions;

  /// Window body content.
  W? get content;

  /// Optional external state controller. When provided, the window adopts
  /// its state and propagates user-driven changes back through the
  /// controller.
  CoreWindowController? get controller;

  /// Initial logical-pixel bounds (ignored when [controller] is set).
  CoreWindowRect? get bounds;

  /// Initial maximized rectangle (relative 0..1) or null for floating.
  CoreWindowRect? get maximized;

  /// Whether the window starts minimized.
  bool? get minimized;

  /// Whether the window starts pinned to the always-on-top layer.
  bool? get alwaysOnTop;

  /// Whether drag-to-edge snapping is enabled.
  bool? get enableSnapping;

  /// Whether the window is resizable via edge/corner handles.
  bool? get resizable;

  /// Thickness of each of the 8 resize hit regions, in logical/CSS px
  /// (pre-scaling). Only consulted while [resizable].
  ///
  /// A hit region is invisible on both platforms — nothing is painted at
  /// this value — so it lives on the widget plane
  /// (`core/style-contract.md`: Style slots carry visual chrome only)
  /// rather than in `CoreWindowStyle`. Flutter still folds
  /// `theme.scaling` into it in the resolver, since density scaling is
  /// an EMIT step and widgets do not scale
  /// (`resolver/scaling-and-gap.md`); Web uses CSS px 1:1.
  double? get resizeThickness;

  /// Whether the title bar supports drag-to-move.
  bool? get draggable;

  /// Whether the close control is active.
  bool? get closable;

  /// Whether the maximize control is active.
  bool? get maximizable;

  /// Whether the minimize control is active.
  bool? get minimizable;

  /// Size constraints enforced during resize.
  CoreWindowConstraints? get constraints;

  /// Per-instance chrome / dimensional style bundle
  /// (`titleBarHeight`).
  ///
  /// Resolved through the nested-merge chain:
  ///
  /// ```text
  /// design system default
  ///   → CoreWindowTheme.style
  ///   → parent component slot override
  ///   → widget.windowStyle
  /// ```
  CoreWindowStyle? get windowStyle;
}

/// Contract for the multi-window container (`WindowNavigator`).
///
/// Type parameter:
/// - [W]: Widget (Flutter) or Component (Web). Each platform's concrete
///   navigator narrows [initialWindows] to its own `Window` type via a
///   covariant override (`Window` implements [CoreWindowContract]).
abstract interface class CoreWindowNavigatorContract<W> {
  /// Initial list of windows rendered by the navigator.
  ///
  /// Typed against [CoreWindowContract] so the contract stays
  /// platform-neutral; each platform narrows this to `List<Window>`
  /// covariantly.
  List<CoreWindowContract<W>> get initialWindows;

  /// Background content rendered behind the floating windows.
  W? get child;

  /// Whether to render the top snap bar (preset pane layouts).
  bool get showTopSnapBar;
}
