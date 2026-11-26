/// Stage enum for unified refresh-trigger components.
library;

/// The current lifecycle stage of a `RefreshTrigger`.
///
/// The stage drives the indicator's text and tone:
/// - [idle] — no refresh activity; indicator hidden.
/// - [pulling] — the user is pulling toward the refresh threshold.
/// - [refreshing] — an async refresh operation is in progress.
/// - [completed] — the refresh finished; a brief confirmation shows
///   before returning to [idle].
enum CoreRefreshStage {
  /// No refresh activity — indicator is hidden.
  idle,

  /// The user is pulling to trigger a refresh.
  pulling,

  /// A refresh operation is in progress.
  refreshing,

  /// A refresh operation has completed.
  completed;

  /// Widget default stage. The Flutter / Web `RefreshTrigger`
  /// constructor default references this value so the two platforms
  /// cannot silently diverge.
  static const CoreRefreshStage defaultStage = idle;
}
