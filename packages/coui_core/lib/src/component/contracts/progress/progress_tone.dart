/// What a linear `Progress` bar's fill colour means.
library;

/// What a `Progress` bar's fill colour means.
///
/// The fill is the part of the bar that says how far along the work is, so
/// its colour is the one place a bar can say what kind of progress it is —
/// a quota running out, an upload that failed. The track is not part of
/// the axis: every tone runs over the same neutral track
/// (`CoreProgressStyle.defaultBackgroundColor`), so a success bar and a
/// primary bar differ only in the fill.
///
/// The member names are the ones `Alert` and `Badge` use for the same
/// meanings, so a status reads with the same word on every component that
/// shows one. Each tone's fill lives in one row of
/// `CoreProgressStyle.defaultsByTone`.
///
/// `RadialProgress` has no tone axis.
enum CoreProgressTone {
  /// The brand accent — ordinary progress. The default.
  primary,

  /// Done, healthy, within budget.
  success,

  /// Needs attention soon — a quota close to its limit.
  warning,

  /// Failed, blocked, over the limit.
  destructive;

  /// Widget default tone — the Flutter / Web `Progress` constructors
  /// reference this so the default cannot silently diverge.
  static const CoreProgressTone defaultTone = primary;
}
