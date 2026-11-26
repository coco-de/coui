/// Platform-neutral edge insets (4-direction padding / margin) for CoUI
/// component styles.
///
/// CoUI components share a single Style class across Flutter and Web
/// (Epic #1415 option D). Padding is expressed as [CoreEdgeInsets] in
/// the platform-neutral Style; resolvers convert to `EdgeInsets`
/// (Flutter) or a CSS `padding` string (Web) at render time via the
/// `core_to_flutter.dart` / `core_to_css.dart` extension utilities.
library;

import 'package:meta/meta.dart';

/// Four-sided insets in logical pixels.
///
/// Mirrors Flutter's `EdgeInsets` surface but is platform-neutral so
/// the same value flows through Flutter and Web pipelines unchanged.
@immutable
class CoreEdgeInsets {
  /// Creates [CoreEdgeInsets] with the four sides given explicitly.
  const CoreEdgeInsets.fromLTRB(this.left, this.top, this.right, this.bottom)
    : isDirectional = false;

  /// Creates [CoreEdgeInsets] with all four sides equal to [value].
  const CoreEdgeInsets.all(double value)
    : left = value,
      top = value,
      right = value,
      bottom = value,
      isDirectional = false;

  /// Creates [CoreEdgeInsets] with symmetric horizontal / vertical
  /// values.
  const CoreEdgeInsets.symmetric({
    double horizontal = 0,
    double vertical = 0,
  }) : left = horizontal,
       right = horizontal,
       top = vertical,
       bottom = vertical,
       isDirectional = false;

  /// Creates [CoreEdgeInsets] with only the supplied sides non-zero.
  const CoreEdgeInsets.only({
    this.left = 0,
    this.top = 0,
    this.right = 0,
    this.bottom = 0,
  }) : isDirectional = false;

  /// Creates insets whose horizontal sides follow the reading direction.
  ///
  /// [start] is the side text begins on and [end] the side it runs
  /// toward — the left and right respectively in a left-to-right locale,
  /// and swapped in a right-to-left one.
  ///
  /// Use this whenever the two horizontal values differ *because of what
  /// they are*: a blockquote indented away from the margin, a step
  /// separated from the next one, a title set in from a rail. Those are
  /// statements about reading order, and writing them as left and right
  /// makes them wrong in half the world's locales — silently, because
  /// the layout still renders.
  ///
  /// Symmetric insets need nothing: a value that is the same on both
  /// sides is already direction-invariant, which is why the overwhelming
  /// majority of this kit's padding needs no thought here.
  const CoreEdgeInsets.directional({
    double start = 0,
    this.top = 0,
    double end = 0,
    this.bottom = 0,
  }) : left = start,
       right = end,
       isDirectional = true;

  /// Zero insets on all four sides.
  static const CoreEdgeInsets zero = CoreEdgeInsets.all(0);

  /// A copy with the given sides replaced. Directionality is preserved:
  /// on a [CoreEdgeInsets.directional] value [left] / [right] address
  /// `start` / `end` (they are the same storage — see [start]), so the
  /// copy still emits as logical insets on both platforms.
  CoreEdgeInsets copyWith({
    double? left,
    double? top,
    double? right,
    double? bottom,
  }) => isDirectional
      ? CoreEdgeInsets.directional(
          start: left ?? this.left,
          top: top ?? this.top,
          end: right ?? this.right,
          bottom: bottom ?? this.bottom,
        )
      : CoreEdgeInsets.fromLTRB(
          left ?? this.left,
          top ?? this.top,
          right ?? this.right,
          bottom ?? this.bottom,
        );

  /// Leading inset (px).
  final double left;

  /// Top inset (px).
  final double top;

  /// Trailing inset (px).
  final double right;

  /// Bottom inset (px).
  final double bottom;

  /// Whether [left] and [right] mean start and end rather than left and
  /// right.
  ///
  /// Part of equality on purpose. The same two numbers mean different
  /// things depending on this flag, so a value that differs only here is
  /// a different value — and a theme swap that changed only this would
  /// otherwise compare equal and never repaint.
  final bool isDirectional;

  /// The inset on the side text begins on.
  double get start => left;

  /// The inset on the side text runs toward.
  double get end => right;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreEdgeInsets &&
          runtimeType == other.runtimeType &&
          left == other.left &&
          top == other.top &&
          right == other.right &&
          bottom == other.bottom &&
          isDirectional == other.isDirectional;

  @override
  int get hashCode => Object.hash(left, top, right, bottom, isDirectional);

  @override
  String toString() => isDirectional
      ? 'CoreEdgeInsets.directional(start: $left, top: $top, '
            'end: $right, bottom: $bottom)'
      : 'CoreEdgeInsets($left, $top, $right, $bottom)';
}
