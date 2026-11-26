/// Platform-independent contract for dialog components.
library;

import 'package:coui_core/src/component/contracts/dialog/dialog_style.dart';

/// Contract for a dialog/alert dialog component.
///
/// Per Epic #1302, every chrome / dimensional / surface effect
/// override flows through the single [dialogStyle] field — see
/// [CoreDialogStyle] for the merge chain. Behaviour fields
/// (open / onClose / actions list) stay flat on the contract.
///
/// Type parameters:
/// - [W] — platform widget type (Flutter `Widget`, Web `Component`).
abstract interface class CoreDialogContract<W> {
  /// Dialog title widget.
  W? get title;

  /// Dialog content widget.
  W? get content;

  /// Leading widget (e.g., icon before title).
  W? get leading;

  /// Trailing widget (e.g., close button).
  W? get trailing;

  /// Action buttons (e.g., Cancel, Confirm). To use a specific
  /// button variant, inject the widget directly here (Epic #1302
  /// 원칙 8 — asChild pattern).
  List<W>? get actions;

  /// Whether the dialog is open/visible.
  bool get open;

  /// Called when the dialog is closed.
  void Function()? get onClose;

  /// Per-instance dialog style covering panel chrome + dimensional
  /// + surface effects + nested title / content / actionButton
  /// styles.
  ///
  /// Resolves through the nested-merge chain:
  ///
  /// ```text
  /// design system default
  ///   → CoreDialogTheme.style
  ///   → parent component slot override
  ///   → widget.dialogStyle
  /// ```
  ///
  /// Named [dialogStyle] (not `style`) so the Web base class
  /// `UiComponent.style: List<Styling>?` still works without
  /// colliding.
  CoreDialogStyle? get dialogStyle;
}
