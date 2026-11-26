/// Banner-specific visual variants.
///
/// Each variant maps to a distinct visual style in both Flutter and Web.
/// Flutter maps to theme-based decoration, Web maps to Tailwind CSS classes.
///
/// This is the "what kind of message" axis. How loudly the banner says it
/// is the separate `CoreBannerEmphasis` axis — the two are deliberately
/// not folded into one enum, because a folded axis makes every
/// tone × loudness pair a hand-authored entry instead of a lookup.
///
/// The `CoreBannerEmphasis` axis itself, and the resulting nested-Map
/// shape of `defaultsByVariant` (see `banner_style.dart`), landed in
/// #4505 alongside the `neutral` rename below but were squashed into the
/// same commit whose breaking-change footer never reached the release
/// notes — restated in a follow-up commit's footer.
enum CoreBannerVariant {
  /// Neutral banner — no tone, the surface's own colours.
  ///
  /// Named `neutral` rather than `default` because `default` is a Dart
  /// keyword and cannot be an identifier at all. `neutral` is also what
  /// six other CoUI enums already call their no-tone member, so this is
  /// the repo's existing spelling rather than a new one.
  neutral,

  /// Informational banner (blue theme).
  info,

  /// Success banner (green theme).
  success,

  /// Warning banner (yellow/orange theme).
  warning,

  /// Destructive/error banner (red theme).
  destructive;

  /// Widget default variant — the Flutter / Web `Banner` constructors
  /// reference this so the default cannot silently diverge.
  ///
  /// This is [neutral], matching the Figma component set's own default.
  /// It previously pointed at [info], so a `Banner(...)` written without
  /// an explicit `variant:` used to render blue and now renders neutral.
  /// Call sites that meant the informational tone must now say so.
  static const CoreBannerVariant defaultVariant = neutral;
}
