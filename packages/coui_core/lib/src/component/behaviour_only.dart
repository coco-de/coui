/// Marks an enum member a widget composes with for its BEHAVIOUR, not one a
/// designer chooses for its look.
///
/// `CoreButtonVariant.fixed` is the case this exists for: a pressable
/// `CardImage` wraps itself in a `Button` to get press, focus and the
/// accessibility role, and `fixed` is the variant that paints nothing so the
/// card's own chrome shows through. It is a real member — the widget needs
/// it — but it is not a design choice, and offering it on the Figma canvas
/// beside `primary` and `outline` presents a mechanism as an option.
///
/// The Figma axis reader leaves a member carrying this annotation off the
/// canvas the same way it leaves a `@Deprecated` one off: the member stays
/// in the enum, the style table still carries its row, and nothing about
/// the running app changes. Only the set of poses the canvas draws does.
///
/// Distinct from `@Deprecated` on purpose. Deprecated means "going away";
/// this means "staying, and not yours to pick". The two are read by the
/// same gate but say different things to the next person reading the enum.
class BehaviourOnly {
  /// Const so it can sit in an annotation.
  const BehaviourOnly();
}

/// See [BehaviourOnly].
const behaviourOnly = BehaviourOnly();
