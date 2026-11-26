/// The rule a navigation bar follows scrolling content by.
library;

/// Decides, from how the content scrolls, whether a navigation bar that
/// follows it (`CoreNavigationCompact.onScroll`) is compact.
///
/// Both platforms feed it the same three numbers for every scroll step of
/// the content — where the content is, how far that step moved it, and how
/// far it can go — and draw what [compact] answers. The decision lives here
/// so the two cannot disagree about when the bar steps back: Flutter reads
/// the numbers off scroll notifications and the Web off scroll events, and
/// neither holds a rule of its own.
///
/// The rule:
///
/// - Content at its start is never followed by a compact bar — reaching the
///   top brings the bar back, and content too short to scroll never moves
///   it.
/// - Scrolling toward the end by [travel] makes the bar compact; scrolling
///   back by [travel] returns it. Turning round starts the count again, so
///   a finger that wobbles does not flicker the bar.
/// - A step that starts or ends outside the content is not counted: the
///   content is overscrolled or rebounding, and the way back from an
///   overscroll is not the reader asking for the bar.
class CoreNavigationScrollCompaction {
  /// How far the content travels one way before the bar changes, in logical
  /// pixels — 12. Designer judgement: under it a resting finger's drift
  /// would move the bar, and much over it the bar lags the gesture it
  /// answers.
  static const double travel = 12;

  bool _compact = false;

  /// Distance travelled since the content last turned round: positive
  /// toward the end, negative toward the start.
  double _travelled = 0;

  /// Whether the bar is compact.
  bool get compact => _compact;

  /// Takes one scroll step and returns whether the bar is compact after it.
  ///
  /// [offset] is where the content is after the step and [delta] how far the
  /// step moved it — positive toward the end. [minExtent] and [maxExtent]
  /// are the offsets of the content's start and end; an [offset] outside
  /// them is an overscroll.
  bool update({
    required double offset,
    required double delta,
    required double maxExtent,
    double minExtent = 0,
  }) {
    if (offset <= minExtent) {
      _travelled = 0;

      return _compact = false;
    }
    // A step that starts or ends outside the content is an overscroll, on
    // its way out or rebounding.
    final from = offset - delta;
    if (offset > maxExtent || from > maxExtent || from < minExtent) {
      _travelled = 0;

      return _compact;
    }
    if (delta == 0) return _compact;
    // Turning round starts the count again.
    _travelled = _travelled.sign == delta.sign ? _travelled + delta : delta;
    if (_travelled >= travel) {
      _compact = true;
    } else if (_travelled <= -travel) {
      _compact = false;
    }

    return _compact;
  }

  /// Returns the bar to its resting size and forgets the travel so far —
  /// the content it followed has been replaced (another destination was
  /// selected), and what replaces it starts with the bar in full.
  void reset() {
    _travelled = 0;
    _compact = false;
  }
}
