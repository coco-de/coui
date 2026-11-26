/// Platform-independent line type for `CodeDiff`.
library;

/// `CodeDiff` 라인 종류.
enum CoreCodeDiffLineType {
  /// Added line (a `successContainer` band with an `onSuccessContainer`
  /// `+ ` prefix).
  added,

  /// Removed line (an `errorContainer` band with an `onErrorContainer`
  /// `- ` prefix).
  removed,

  /// Unchanged line (no band, onSurface text and a blank `  ` prefix).
  unchanged,
}
