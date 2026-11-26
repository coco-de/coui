/// Shadow elevation level for `CoreFrameContract`.
library;

import 'package:coui_core/src/component/contracts/outlined_container/core_outlined_container_elevation.dart';

/// Shadow elevation level for `CoreFrameContract`.
///
/// Provides a discrete preset that maps cleanly across both
/// platforms; for fully arbitrary shadows callers can pass a
/// platform-typed `boxShadow` value instead, which takes precedence
/// over the elevation preset.
///
/// Maps to:
/// - Flutter: a `BoxShadow` list with M3-style offset/blur/spread
///   computed from the level (none → empty list).
/// - Web: Tailwind `shadow-{none|sm|md|lg}` utility class.
/// - Figma: roughly equivalent to the depth presets used in Figma's
///   Effects panel.
///
/// Replaces `CoreOutlinedContainerElevation` once `OutlinedContainer`
/// is absorbed into `Frame` — the level set is identical so
/// migration is a 1:1 rename.
enum CoreFrameElevation {
  /// No shadow.
  none,

  /// Subtle shadow for slight depth (Tailwind `shadow-sm`).
  soft,

  /// Medium shadow for moderate depth (Tailwind `shadow-md`).
  medium,

  /// Strong shadow for prominent depth (Tailwind `shadow-lg`).
  strong;

  /// Maps this frame elevation to the matching
  /// [CoreOutlinedContainerElevation]. Both enums share the same four
  /// levels — keeping the conversion next to the source enum means any
  /// future entry added here surfaces a compile error on the switch
  /// instead of silently drifting from the outlined-container
  /// counterpart, and lets the Flutter `resolveFrame` reuse the single
  /// canonical `resolveOutlinedContainerBoxShadow` elevation → shadow
  /// mapping (Epic #1603 C4 — shadow geometry stays single-sourced).
  CoreOutlinedContainerElevation toOutlinedContainerElevation() {
    return switch (this) {
      .none => .none,
      .soft => .soft,
      .medium => .medium,
      .strong => .strong,
    };
  }
}
