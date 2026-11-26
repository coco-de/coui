/// Constraint propagation mode for `Stacks`.
///
/// Mirrors Flutter's `StackFit` semantics so a single contract value
/// produces the same layout intent on Flutter and Web.
enum CoreStackFit {
  /// Children get loose constraints (each child sizes to its own
  /// intrinsic dimensions). Default — equivalent to Flutter's
  /// `StackFit.loose`.
  loose,

  /// Children are forced to fill the parent. Equivalent to
  /// `StackFit.expand`.
  expand,

  /// The parent's constraints flow through to non-positioned children
  /// unchanged. Equivalent to `StackFit.passthrough` — used by infra
  /// wrappers (e.g. `FocusOutline`) that want their child to keep
  /// whatever sizing the surrounding layout provides.
  passthrough,
}
