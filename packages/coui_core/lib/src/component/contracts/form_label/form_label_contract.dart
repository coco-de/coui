/// Platform-independent contract for form-label components.
library;

import 'package:coui_core/src/component/contracts/form_label/form_label_style.dart';
import 'package:coui_core/src/size/component_size.dart';

/// Contract for a unified form-label component.
///
/// `FormLabel` renders descriptive text for a form input, with an
/// optional required indicator (`*`) appended after the label. It is
/// the unified replacement for the legacy Flutter `FormLabel` and Web
/// `FormLabel` — same parameter names, same semantics, full parity.
///
/// Platform-neutral (Epic #1415 option D) — only the widget type `<W>`
/// is generic (`Widget` on Flutter, `Component` on Web).
abstract interface class CoreFormLabelContract<W> {
  /// The main label content, typically a text node.
  W? get label;

  /// Whether the labelled field is required.
  ///
  /// When `true` the [requiredIndicator] is shown after the label.
  bool get isRequired;

  /// Custom widget shown after the label when [isRequired] is `true`.
  ///
  /// When `null` a default error-coloured asterisk (`*`) is rendered.
  W? get requiredIndicator;

  /// Size tier — selects the label typography rung from
  /// [CoreFormLabelStyle.defaultsBySize]. A caller composing `FormLabel`
  /// beside a sized field (e.g. `TextField`) passes that field's own
  /// size through here so the label's type scales with it.
  CoreComponentSize get size;

  /// Whether the labelled field is enabled.
  ///
  /// `false` dims both the label and the required indicator to
  /// [CoreFormLabelStyle.defaultDisabledColor] — a semantic (build-time)
  /// property, not a runtime interaction state.
  bool get enabled;

  /// Per-instance label chrome / typography style.
  CoreFormLabelStyle? get formLabelStyle;
}
