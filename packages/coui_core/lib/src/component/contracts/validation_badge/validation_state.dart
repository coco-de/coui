/// Validation result represented by a `ValidationBadge`.
///
/// - [pending]: pre-input or pre-check (neutral chrome).
/// - [valid]: success (green-tinted chrome).
/// - [invalid]: failure (red-tinted chrome).
enum CoreValidationState {
  /// Pre-input or pre-check state.
  pending,

  /// Validation succeeded.
  valid,

  /// Validation failed.
  invalid;

  /// Widget default state. The `ValidationBadge` / `Validated`
  /// constructor defaults reference this so all consumers share a
  /// single source of truth.
  static const CoreValidationState defaultState = pending;
}
