/// The moment both capture harnesses render every entry at.
///
/// A calendar opens on the current month and marks today, so a capture that
/// reads the wall clock changes every day with no code change, and a capture
/// taken on another day fails against the baseline. Both harnesses render
/// under `withClock(Clock.fixed(kCaptureNow))` — the Flutter matrix test
/// around each entry, the Web harness around the server render — and the
/// calendar reads that clock on both platforms
/// (`CoreCalendarView.currentTime`). It is the date the calendar baselines
/// show as today.
///
/// Reach: the few Web entries that settle in the browser
/// (`requiresClientCapture`) read the browser's clock, not this one. No
/// calendar is captured that way.
final DateTime kCaptureNow = DateTime(2026, 11, 11);
