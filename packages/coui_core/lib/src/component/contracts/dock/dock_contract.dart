/// Platform-independent contract for a unified bottom dock navigation.
library;

import 'package:coui_core/src/component/contracts/dock/core_dock_size.dart';
import 'package:coui_core/src/component/contracts/dock/dock_style.dart';

/// Data object for a single `Dock` item.
///
/// Used as a platform-neutral payload (the actual widget/component is built
/// inside the `Dock` implementation on each platform). Keeps the API
/// identical across Flutter and Web — only the [W] widget type differs.
class CoreDockItemData<W> {
  /// Creates a [CoreDockItemData].
  const CoreDockItemData({
    required this.icon,
    this.label,
    this.isActive = false,
    this.onPressed,
  });

  /// Icon widget/component rendered at the top of the item.
  final W icon;

  /// Optional text label rendered below [icon]. Hidden automatically on
  /// `CoreDockSize.xs` / `sm` to match legacy visual behaviour.
  final String? label;

  /// Whether this item is currently selected. Active items use
  /// `colorScheme.primary` for both icon and label, plus a heavier font
  /// weight on the label.
  final bool isActive;

  /// Tap/click callback. When null the item is inert but still renders.
  final void Function()? onPressed;
}

/// Contract for a unified bottom dock navigation bar.
///
/// Type parameters:
/// - [W] — platform widget type (`Widget` on Flutter, `Component` on Web).
abstract interface class CoreDockContract<W> {
  /// Items rendered inside the dock from leading (start) to trailing (end).
  List<CoreDockItemData<W>> get items;

  /// Size preset that drives the dock bar's minimum height and default icon
  /// size. The bar grows past that height when its items need more room
  /// (see `CoreDockStyle.height`).
  ///
  /// When null, falls back to `CoreDockSize.md`. `size` is a
  /// widget-only semantic identifier — the theme cannot override it.
  CoreDockSize? get size;

  /// Accessible label announced by screen readers for the whole dock
  /// (navigation landmark).
  String? get semanticLabel;

  /// Per-instance composite chrome / slot style.
  ///
  /// All chrome (background / border colours, active / inactive item
  /// colours, nested label / icon styles) lives inside this slot.
  /// Resolves through the nested-merge chain:
  ///
  /// ```text
  /// design system default (CoreDockStyle.defaultX)
  ///   → CoreDockTheme.style
  ///   → parent component slot override
  ///   → widget.dockStyle
  /// ```
  CoreDockStyle? get dockStyle;
}
