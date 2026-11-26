/// Whether an empty region is empty because nothing is there yet, or
/// because something failed.
library;

/// The reason an `EmptyState` is showing.
///
/// Separate from the density variant because the two are orthogonal: a
/// compact panel can be empty for either reason, and folding them into
/// one enum would make "compact" and "failed" mutually exclusive.
///
/// The distinction is not decoration. "No orders yet" and "Could not
/// load orders" look the same on screen unless something says otherwise,
/// and to a screen reader they are identical — both are just text in a
/// box. One of them is a failure the user should hear about.
enum CoreEmptyStateTone {
  /// Nothing is here yet. Ordinary content: the list is empty, the
  /// search matched nothing, the folder is new.
  neutral,

  /// Something failed and that is why there is nothing to show.
  failure,

  /// Something finished and that is why there is nothing left to show —
  /// a completed task, an all-clear result.
  success;

  /// Widget default. Flutter / Web `EmptyState` constructors reference
  /// this value so the two cannot drift.
  static const CoreEmptyStateTone defaultTone = neutral;
}
