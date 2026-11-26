/// Visual variant for toast notification components.
library;

/// The visual style variant for a toast notification.
///
/// Determines the color scheme and visual treatment of the toast.
enum CoreToastVariant {
  /// Something worked — a green check.
  ///
  /// Not the variant a reader reaches for as "the plain one": this one
  /// carries a success check, and the plain toast is [neutral], which is
  /// what [defaultVariant] points at.
  success,

  /// Destructive toast variant for error/warning messages.
  destructive,

  /// A toast that reports nothing — news, not an outcome.
  ///
  /// The one variant with no leading glyph. [success] and [destructive]
  /// each say how something turned out and carry a glyph that says which;
  /// this one has nothing to report, so the absence IS the distinction.
  ///
  /// This member is new in #4505. Its `BREAKING CHANGE:` footer was one
  /// of five squashed into a single commit and dropped by the release
  /// tooling (only the first footer is read). The restatement in #4616
  /// was itself squash-merged with four sibling footers and lost the
  /// same way (`ea3efc985`) — this is the second restatement, on its
  /// own commit. An exhaustive `switch` over this enum needs a new arm;
  /// [success]/[destructive] fill and foreground tokens changed too
  /// (both render modes).
  ///
  /// That absence is why [defaultVariant] points here. A caller who names
  /// no variant has asserted no outcome, and a glyph-less toast is what
  /// asserting nothing looks like.
  ///
  /// The three differ in that glyph and nothing else — background,
  /// foreground and border are the same raised-surface pair in all
  /// three, so this is not a quieter toast, it is the same toast with
  /// nothing claimed on it.
  neutral;

  /// Widget default variant. Flutter / Web `Toast` constructors
  /// reference this value so the two platforms cannot silently
  /// diverge on the default.
  ///
  /// Moved off [success] and onto [neutral]. A bare `Toast('Saved')` used
  /// to draw a green check — asserting an outcome its caller never stated.
  /// The variant with no glyph is what "no particular news" looks like,
  /// and that is what a caller who named no variant means.
  static const CoreToastVariant defaultVariant = neutral;
}
