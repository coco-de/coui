/// Platform-independent contract for unified label components.
///
/// Defines the interface that all Label implementations
/// (Flutter, Web) must satisfy.
library;

import 'package:coui_core/src/component/contracts/label/label_style.dart';

/// Contract for a unified label component.
///
/// Chrome / dimensional / text overrides flow through the single
/// [labelStyle] slot. Behavioural / semantic fields
/// (`text`, `icon`, `isRequired`, `disabled`, `semanticLabel`)
/// stay flat. `htmlFor` is deprecated — see its own doc comment.
///
/// Type parameters:
/// - [W] — platform widget type (Flutter `Widget`, Web `Component`).
///
/// Implementations should render a static text label suitable for
/// form fields, with an optional leading icon and required-indicator.
abstract interface class CoreLabelContract<W> {
  /// Label text content.
  String get text;

  /// Optional leading icon widget (Flutter `Widget` / Web `Component`).
  W? get icon;

  /// Whether to show the required indicator (`*`).
  bool get isRequired;

  /// Whether the label is in disabled state — applies muted color and
  /// reduced opacity.
  bool get disabled;

  /// Accessible label override (a11y). Maps to Flutter `Semantics(label:)`
  /// and Web `aria-label` attribute.
  String? get semanticLabel;

  /// Optional id of the form control this label is associated with.
  ///
  /// Does not wire a label↔control association on either platform —
  /// Web emits it as a `for` attribute on a `<span>`, which HTML only
  /// recognizes on `<label>`/`<output>`, and Flutter maps it to a test
  /// identifier that carries no accessibility meaning. Use `FormField`
  /// instead, which links the label and control on both platforms.
  @Deprecated(
    'Label does not wire htmlFor to a control on either platform — use '
    'FormField, which links label and control (since 0.146)',
  )
  String? get htmlFor;

  /// Per-instance chrome / dimensional / text style.
  ///
  /// Resolves through the nested-merge chain:
  ///
  /// ```text
  /// design system default
  ///   → CoreLabelTheme.style
  ///   → parent component slot override
  ///   → widget.labelStyle
  /// ```
  CoreLabelStyle? get labelStyle;
}
