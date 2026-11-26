/// Platform-independent contract for validation-wrapper components.
library;

import 'package:coui_core/src/component/contracts/validated/validated_style.dart';
import 'package:coui_core/src/component/contracts/validation_badge/validation_state.dart';

/// Contract for a unified validation-wrapper component.
///
/// `Validated` wraps a form field and visually indicates its
/// validation state through a coloured ring around the field, plus an
/// optional message rendered below it. It is the unified presentational
/// replacement for the legacy Web `Validated` and the visual layer of
/// the legacy Flutter `Validated<T>` — same parameter names, same
/// semantics, full parity.
///
/// Platform-neutral (Epic #1415 option D) — only the widget type `<W>`
/// is generic (`Widget` on Flutter, `Component` on Web).
abstract interface class CoreValidatedContract<W> {
  /// The current validation state.
  ///
  /// Drives the per-state ring colour and whether the message is
  /// shown.
  CoreValidationState get state;

  /// Validation message rendered below the wrapped child.
  ///
  /// Only shown when [state] is not [CoreValidationState.pending].
  W? get message;

  /// The form field wrapped by this validation indicator.
  W? get child;

  /// Per-instance validation chrome / dimensional style.
  CoreValidatedStyle? get validatedStyle;
}
