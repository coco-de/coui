/// Platform-agnostic contract for `GridItem`.
///
/// Optional wrapper used inside `ResponsiveGrid` to give a cell
/// multi-column or multi-row span. When wrapped in `GridItem`, the
/// grid reads its `colSpan`/`rowSpan` and allocates the extra cells.
///
/// Type parameters:
///   - `W` — `Widget` on Flutter, `Component` on Web (child type).
library;

/// Contract for the unified `GridItem` span wrapper.
abstract interface class CoreGridItemContract<W> {
  /// The child rendered inside the cell.
  W get child;

  /// How many columns the cell should occupy. `null` means `1`.
  int? get colSpan;

  /// How many rows the cell should occupy. `null` means `1`.
  int? get rowSpan;
}
