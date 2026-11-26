/// Platform-independent contract for validator-hint components.
library;

import 'package:coui_core/src/component/contracts/validator_hint/validator_hint_style.dart';
import 'package:coui_core/src/component/contracts/validator_hint/validator_hint_type.dart';

/// Contract for a unified validator-hint component.
///
/// `ValidatorHint` shows a validation message (error / warning /
/// info / success) below a form input, with a leading severity icon.
/// It is the unified replacement for the legacy Flutter and Web
/// `ValidatorHint` — same parameter names, same semantics, full
/// parity.
///
/// Platform-neutral (Epic #1415 option D) — only the widget type `<W>`
/// is generic (`Widget` on Flutter, `Component` on Web).
abstract interface class CoreValidatorHintContract<W> {
  /// The validation message to display.
  W? get message;

  /// The severity type of the validation message.
  ///
  /// Drives the per-type accent colour and default leading icon.
  CoreValidatorHintType get type;

  /// Whether the hint is visible.
  ///
  /// When `false` the component renders nothing (collapses to zero
  /// size).
  bool get visible;

  /// Custom icon shown before the message.
  ///
  /// When `null` a default icon based on [type] is rendered.
  W? get icon;

  /// Per-instance hint chrome / typography style.
  CoreValidatorHintStyle? get validatorHintStyle;
}
