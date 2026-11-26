/// Shadow elevation level for `CoreOutlinedContainerContract`.
///
/// Maps to:
/// - Flutter: a `BoxShadow` list with M3-style offset/blur/spread
///   computed from the level (none → empty list).
/// - Web: Tailwind `shadow-{none|sm|md|lg}` utility class.
///
/// Mirrors `CoreCardElevation` semantically; kept as a separate enum so
/// OutlinedContainer can evolve independently from Card defaults.
enum CoreOutlinedContainerElevation {
  /// No shadow.
  none,

  /// Subtle shadow for slight depth (Tailwind `shadow-sm`).
  soft,

  /// Medium shadow for moderate depth (Tailwind `shadow-md`).
  medium,

  /// Strong shadow for prominent depth (Tailwind `shadow-lg`).
  strong,
}
