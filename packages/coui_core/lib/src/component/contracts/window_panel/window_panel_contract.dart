import 'package:coui_core/src/component/callback_types.dart';
import 'package:coui_core/src/component/contracts/window_panel/core_title_bar_drag.dart';
import 'package:coui_core/src/component/contracts/window_panel/window_panel_style.dart';

/// Platform-independent contract for `WindowPanel`.
///
/// A window panel renders a title bar + content area with optional
/// minimize / maximize / close controls. The contract mirrors the legacy
/// Flutter `WindowPanel` and its Web counterpart so they can share call
/// sites and themes.
///
/// Type parameters:
/// - [W] — platform widget type (`Widget` on Flutter, `Component` on Web).
abstract interface class CoreWindowPanelContract<W> {
  /// Title bar content. Typically a `Text` / `Component.text(...)`. May be
  /// null for a chrome-only window frame.
  W? get title;

  /// Main content area below the title bar.
  W? get child;

  /// Custom actions rendered between the title and the default control
  /// buttons (e.g. refresh / pin buttons).
  W? get actions;

  /// Whether the close button is rendered. Defaults to `true`.
  bool get closable;

  /// Whether the minimize button is rendered. Defaults to `false`.
  bool get minimizable;

  /// Whether the maximize button is rendered. Defaults to `false`.
  bool get maximizable;

  /// Callback invoked when the close button is clicked.
  CoreVoidCallback? get onClose;

  /// Callback invoked when the minimize button is clicked.
  CoreVoidCallback? get onMinimize;

  /// Callback invoked when the maximize button is clicked.
  CoreVoidCallback? get onMaximize;

  /// Hides the content area (keeps the title bar visible). Defaults to
  /// `false`.
  bool get isMinimized;

  /// Invoked when a drag gesture starts on the title bar. Used by
  /// `Window` to move the window; panels not hosted inside a window
  /// manager can ignore this.
  CoreTitleBarDragStartCallback? get onTitleBarDragStart;

  /// Invoked on every drag update while the title bar is being dragged.
  CoreTitleBarDragUpdateCallback? get onTitleBarDragUpdate;

  /// Invoked when the drag ends (normal release).
  CoreTitleBarDragEndCallback? get onTitleBarDragEnd;

  /// Invoked when the drag is cancelled (pointer lost / platform
  /// interruption). Implementations may treat this identically to
  /// [onTitleBarDragEnd].
  CoreTitleBarDragEndCallback? get onTitleBarDragCancel;

  /// Invoked when the user double-clicks the title bar. Used by
  /// `Window` to toggle maximized state.
  CoreVoidCallback? get onTitleBarDoubleTap;

  /// Per-instance chrome style bundle — the outer frame radius and the
  /// title bar background colour.
  ///
  /// Resolves through the nested-merge chain:
  ///
  /// ```text
  /// design system default
  ///   → CoreWindowPanelTheme.style
  ///   → parent component slot override
  ///   → widget.windowPanelStyle
  /// ```
  CoreWindowPanelStyle? get windowPanelStyle;
}
