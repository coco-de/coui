/// How a `Steps` lays its steps out.
///
/// Two shapes for one model (`CoreStepData` + `CoreStepStatus`): the
/// numbered circles joined by connectors that walk a user through a
/// process, and a flat list of status rows that reports where each step of
/// a run stands.
enum CoreStepsVariant {
  /// Numbered indicator circles joined by connectors, each step's title
  /// and description beside it. Vertical or horizontal (`vertical`). The
  /// default.
  numbered,

  /// One `StepItem` row per step — a status glyph, the title on one line,
  /// an optional trailing note at the end — stacked with no connector and
  /// no number.
  ///
  /// Always vertical: a row's trailing note pins to the end of the row, so
  /// the rows need the full width. `vertical` is ignored. Each item's
  /// description is not drawn — a list row has one line.
  list;

  /// Widget default variant — the Flutter / Web `Steps` constructors
  /// reference this so the default cannot silently diverge.
  static const CoreStepsVariant defaultVariant = numbered;
}
