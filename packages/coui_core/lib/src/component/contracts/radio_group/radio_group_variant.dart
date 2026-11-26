/// Radio group visual variants.
enum CoreRadioGroupVariant {
  /// Default radio group styling.
  defaultVariant,

  /// A selectable tile per option — the indicator, a title and an optional
  /// description inside one bordered face, and the whole tile is the hit
  /// target.
  ///
  /// For a choice the user weighs against its explanation (a plan, a
  /// delivery speed), where a bare row would leave the explanation outside
  /// the thing being picked. Selection still reads on the indicator's
  /// ring; the tile restates it in its face and border so the chosen
  /// option is visible from across the group.
  card,
}
