/// What a `MockupCode` line means — the meaning of a log or terminal line,
/// not its colour.
///
/// A log line carries a meaning (a command, a path, a success, a failure) and
/// the product states that meaning here. The colour that meaning is drawn
/// with is decided by the `CoreMockupCodeStyle` tone slots, so an app never
/// has to put its own hex on a line.
enum CoreCodeLineTone {
  /// Plain code or output — drawn with the code text colour.
  neutral,

  /// De-emphasised text such as a command echo or a timestamp.
  muted,

  /// A path or URL.
  link,

  /// A step that finished well.
  success,

  /// Something worth attention that did not fail.
  warning,

  /// A failure.
  error;

  /// Tone of a line that states none. Flutter / Web `MockupCode` and
  /// `CoreCodeLine` reference this single source.
  static const CoreCodeLineTone defaultTone = neutral;
}
