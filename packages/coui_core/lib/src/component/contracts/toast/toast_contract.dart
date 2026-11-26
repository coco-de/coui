/// Cross-platform contract for unified toast notification components.
library;

import 'package:coui_core/src/component/contracts/toast/toast_style.dart';
import 'package:coui_core/src/component/contracts/toast/toast_variant.dart';

/// Contract for a unified toast notification component.
///
/// Per Epic #1302, every chrome / dimensional override flows through
/// the single [toastStyle] field — see [CoreToastStyle] for the
/// merge chain. Behaviour fields stay flat on the contract.
///
/// Type parameters:
/// - [W] — Widget type (Flutter `Widget`, Web `Component`).
///
/// The dismiss callback is a parameterless `void Function()` — Flutter
/// `VoidCallback` and Web `CoreVoidCallback` are both structural
/// aliases of it, so no separate callback type parameter is needed
/// (Phase 6f: contract keeps only the widget type `<W>` generic).
abstract interface class CoreToastContract<W> {
  /// The primary text message displayed inside the toast.
  String get message;

  /// Optional secondary description below the message.
  String? get description;

  /// The visual variant of the toast.
  CoreToastVariant get variant;

  /// Whether the toast draws its leading glyph together with the gap after
  /// it.
  ///
  /// `false` starts the message and description at the panel's inset: a
  /// notice that reads by its words alone. The variant still picks the
  /// glyph when this is on — `neutral` has none to draw either way — and
  /// the action and the dismiss button stay where they were. Defaults to
  /// [defaultShowIcon].
  bool get showIcon;

  /// Default for [showIcon] — the variant's glyph is drawn. Both widgets
  /// take their default from here, so the two cannot drift apart.
  static const bool defaultShowIcon = true;

  /// Callback invoked when the toast dismiss button is pressed.
  /// When non-null, a close button is rendered.
  void Function()? get onDismiss;

  /// Optional action widget displayed alongside the content.
  W? get action;

  /// Per-instance toast style covering panel chrome + dimensional
  /// overrides plus nested message / description / action button
  /// styles.
  ///
  /// Resolves through the nested-merge chain:
  ///
  /// ```text
  /// design system default for variant
  ///   → CoreToastTheme.style
  ///   → CoreToastTheme.variantStyles[variant]
  ///   → parent component slot override
  ///   → widget.toastStyle
  /// ```
  ///
  /// Named [toastStyle] (not `style`) so the Web base class
  /// `UiComponent.style: List<Styling>?` still works without
  /// colliding.
  CoreToastStyle? get toastStyle;
}
