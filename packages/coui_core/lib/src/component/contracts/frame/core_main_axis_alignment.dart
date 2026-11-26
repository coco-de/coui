/// Main-axis alignment for `CoreFrameContract` children when
/// `direction` is set (i.e. flex layout is enabled).
///
/// Maps to:
/// - Flutter: `Row.mainAxisAlignment` / `Column.mainAxisAlignment` /
///   `Flex.mainAxisAlignment`.
/// - Web: CSS `justify-content`.
/// - Figma: Auto Layout "Distribution" + axis alignment.
enum CoreMainAxisAlignment {
  /// Pack children to the start of the main axis.
  start,

  /// Pack children to the end of the main axis.
  end,

  /// Pack children around the centre of the main axis.
  center,

  /// Distribute free space evenly *between* children (none on edges).
  spaceBetween,

  /// Distribute free space evenly around each child (half on edges).
  spaceAround,

  /// Distribute free space evenly between children and edges.
  spaceEvenly,
}
