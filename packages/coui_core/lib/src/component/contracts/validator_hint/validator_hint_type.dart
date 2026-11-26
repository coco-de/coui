/// Validation-message severity for `ValidatorHint`.
library;

import 'package:coui_core/src/component/contracts/semantics/core_semantic_role.dart';

/// The type of validation message a `ValidatorHint` displays.
///
/// Mirrors the legacy Flutter `ValidatorHintType` enum 1:1 — same
/// members, same order.
enum CoreValidatorHintType {
  /// An error message indicating validation failure.
  error,

  /// A warning message for a potential issue.
  warning,

  /// An informational message.
  info,

  /// A success message indicating validation passed.
  success,

  /// A message with no severity — a rule not yet met, a hint that is
  /// simply stated.
  ///
  /// The other four all *report* something: this failed, this needs
  /// attention, here is something to know, this passed. A password
  /// checklist on a form nobody has typed into yet reports nothing —
  /// every rule is merely pending. Drawn in one of the four, that empty
  /// state reads as the system announcing something before the user has
  /// acted; the closest fit, [info], paints two unmet rules blue.
  ///
  /// Named for what it *is* rather than for `pending` — what it says is
  /// "no severity", and the checklist's not-yet is one use of that
  /// rather than the whole of it. A hint stating a fixed rule ("8
  /// characters or more") is the same colour and never becomes anything
  /// else.
  neutral;

  /// Widget default type. The Flutter / Web `ValidatorHint`
  /// constructor default references this so both platforms share a
  /// single source of truth.
  static const CoreValidatorHintType defaultType = error;

  /// How urgently a hint of this type interrupts a screen reader.
  ///
  /// A validation message usually appears *after* the user acted —
  /// submitting, or leaving a field — and without a live region nothing
  /// announces it: the field is still focused, the reader has nothing new
  /// to read, and the only person who learns the value was rejected is
  /// the one who can see it (WCAG 3.3.1).
  ///
  /// Tone decides urgency, the same way it does for `Alert`: an [error]
  /// is assertive (`alert` cuts off the current sentence), the other
  /// reported tones are polite (`status` waits its turn). [neutral]
  /// reports nothing — a checklist rule not yet met is page content, and
  /// a live region on it would announce every pending rule at load.
  ///
  /// One mapping read by both platforms so they cannot disagree: Web
  /// emits it as `role`, Flutter's semantics seat turns `alert` /
  /// `status` into a live region.
  CoreSemanticRole? toSemanticRole() => switch (this) {
    error => CoreSemanticRole.alert,
    warning || info || success => CoreSemanticRole.status,
    neutral => null,
  };
}
