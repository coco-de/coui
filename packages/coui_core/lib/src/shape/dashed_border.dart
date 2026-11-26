import 'package:coui_core/src/shape/stroke_width.dart';

/// Platform-independent dashed border tokens.
///
/// Defines dash length, gap, and stroke thickness so that
/// Flutter and Web renderings stay visually consistent.
///
/// CSS `border-dashed` renders approximately a 3px dash + 2px gap
/// at 1px stroke in Chrome (measured against the rendered border, not
/// the spec — the pattern is engine-defined). These tokens mirror that
/// baseline so the Flutter dash painter and the Web native dashed
/// border read as the same pattern.
abstract final class CoreDashedBorder {
  const CoreDashedBorder._();

  /// Dash segment length (3px). Matches CSS `border-dashed` visual.
  static const double dashLength = 3;

  /// Gap between dashes (2px). Reflects the measured CSS
  /// `border-dashed` rendering in Chrome — a 3px gap read visibly
  /// sparser than the Web twin.
  static const double dashGap = 2;

  /// Default stroke thickness (1px). Same as [CoreStrokeWidth.stroke1].
  static const double strokeWidth = CoreStrokeWidth.stroke1;
}
