/// Visual variant for unified link components.
library;

/// The tone a `Link` reads in.
///
/// The variant is the colour axis only. Whether the underline is always
/// drawn is the separate `underline` flag on the widget — folding the two
/// into one axis would make "muted with an underline" unsayable.
enum CoreLinkVariant {
  /// The link colour (`CoreColors.link`) — a link that has to be
  /// recognised as one. The default.
  standard,

  /// Secondary text colour (`CoreColors.onSurfaceVariant`) for links in a
  /// supporting position — a footer row, a caption — where a coloured link
  /// would compete with the content it supports.
  muted;

  /// Widget default variant. The Flutter / Web `Link` constructor default
  /// references this value so the two platforms cannot silently diverge.
  static const CoreLinkVariant defaultVariant = standard;
}
