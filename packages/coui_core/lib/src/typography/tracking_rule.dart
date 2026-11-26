import 'package:coui_core/src/typography/core_text_style_token.dart';
import 'package:coui_core/src/typography/font_family.dart';
import 'package:coui_core/src/typography/letter_spacing.dart';
import 'package:coui_core/src/typography/text_style_token.dart';
import 'package:coui_core/src/typography/typography_scale.dart';

/// Role tracking (em) by rendered size — the rule a type scale's sans roles
/// state, read off the scale rather than restated.
///
/// A role states its own tracking, but a reader that draws a role at a size
/// it is not authored at needs the rule and not only the role: a heading at
/// its tablet or mobile size (`CoreTypography.atTier`) tracks by that size,
/// and the Figma export's size-keyed tier covers every rung of the font-size
/// scale, most of which no role sits on. Written out again, the rule would
/// be a third statement of it beside the role table and [CoreLetterSpacing],
/// held to neither; read off the table, the table IS the rule and a reader
/// only extends it to the sizes the table has no role at.
///
/// The sans roles must fall into two tracking steps split by size — every
/// role from some size up on the tighter step, every role below it on the
/// looser one. When they stop doing that, the table no longer states a
/// two-step rule, and how to extend it to sizes between its roles is a
/// design decision, so [CoreTrackingRule.read] refuses instead of guessing.
final class CoreTrackingRule {
  const CoreTrackingRule._({
    required this.from,
    required this.above,
    required this.below,
  });

  /// Reads the rule off [roles].
  ///
  /// Throws a [FormatException] saying why when their sans roles do not
  /// form two steps split by size.
  factory CoreTrackingRule.read(Iterable<CoreTextStyle> roles) {
    final sizesBySpacing = <double, List<double>>{};
    for (final role in roles) {
      // A monospace role tracks by its column grid, not by size.
      if (role.fontFamily == CoreFontFamily.mono) continue;
      final (size, spacing) = (role.fontSize, role.letterSpacing);
      if (size == null || spacing == null) {
        throw const FormatException(
          'a sans role states no font size or no tracking',
        );
      }
      (sizesBySpacing[spacing] ??= []).add(size);
    }
    if (sizesBySpacing.length != 2) {
      throw FormatException(
        'the sans roles track at ${sizesBySpacing.keys.join(', ')} em — '
        'not two steps, so there is no rule to extend to the sizes no role '
        'sits at',
      );
    }
    // Ascending, so the more negative (tighter) ratio comes first.
    final [tighter, looser] = sizesBySpacing.keys.toList()..sort();
    final from = sizesBySpacing[tighter]!.reduce((a, b) => a < b ? a : b);
    final looserTop = sizesBySpacing[looser]!.reduce((a, b) => a > b ? a : b);
    if (looserTop >= from) {
      throw FormatException(
        'a ${looserTop}px sans role tracks looser than a ${from}px one — the '
        'two steps are not split by size',
      );
    }
    return CoreTrackingRule._(from: from, above: tighter, below: looser);
  }

  /// The rule [CoreTypography.coui] states.
  static final CoreTrackingRule coui = CoreTrackingRule.read([
    for (final token in CoreTextStyles.values) token.read(CoreTypography.coui),
  ]);

  /// The smallest size on the tighter step.
  final double from;

  /// Tracking (em) at [from] and above.
  final double above;

  /// Tracking (em) below [from].
  final double below;

  /// Tracking (em) a sans glyph of [fontSize] takes.
  double atSize(double fontSize) => fontSize >= from ? above : below;

  /// Tracking (em) [role] draws at [fontSize]. A monospace role keeps its
  /// own (0) at every size: its advance is the column grid.
  double forRole(CoreTextStyle role, double fontSize) =>
      role.fontFamily == CoreFontFamily.mono
      ? role.letterSpacing ?? CoreLetterSpacing.normal
      : atSize(fontSize);
}
