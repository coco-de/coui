/// Where a `Divider`'s centred child sits along the divider main axis.
library;

/// Position of a `Divider`'s child slot along the divider main axis.
///
/// The names are logical, not physical — `start` and `end` follow the
/// ambient reading direction, so a `start`-aligned label sits on the
/// right in a right-to-left locale. `left` / `right` would be wrong
/// there, which is why they are absent.
///
/// The two weights below are what both platforms read. Flutter feeds
/// them to the line segments' `Flexible(flex:)`; Web turns a positive
/// weight into a flexible grid track of that many `fr` and a zero weight
/// into a track as long as its content, which is the segment's inset.
/// Either way the segments share what the child leaves by their weights,
/// each holding its own inset inside its share, so the child sits at the
/// same place on both. Keeping the pair here means neither platform owns
/// its own table — a leading/trailing mapping that is swapped can only be
/// swapped in one place, and `center` is the render a bare `Flexible`
/// gives, since it defaults to `flex: 1`.
enum CoreDividerChildAlignment {
  /// Both line segments share the leftover extent equally — the child
  /// sits in the middle. This is the design-system default.
  center(leadingFlex: 1, trailingFlex: 1),

  /// The trailing segment collapses — the child sits at the reading
  /// end edge.
  end(leadingFlex: 1, trailingFlex: 0),

  /// The leading segment collapses — the child sits at the reading
  /// start edge.
  start(leadingFlex: 0, trailingFlex: 1);

  const CoreDividerChildAlignment({
    required this.leadingFlex,
    required this.trailingFlex,
  });

  /// Flex weight handed to the line segment before the child.
  final int leadingFlex;

  /// Flex weight handed to the line segment after the child.
  final int trailingFlex;
}
