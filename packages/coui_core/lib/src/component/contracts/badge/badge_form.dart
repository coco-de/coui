import 'package:coui_core/src/component/contracts/badge/badge_style.dart';
import 'package:coui_core/src/component/contracts/badge/badge_tone.dart';
import 'package:coui_core/src/component/contracts/badge/badge_tone_style.dart';

/// What a `Badge` holds — a word, a number, or nothing.
///
/// One of Badge's three design axes. [CoreBadgeTone] answers "what does
/// the colour mean" and `CoreBadgeVariant` "how loud is it"; this one
/// answers "what is inside". The shape follows the content: a word sits in
/// a rounded rectangle, a number in a pill, nothing in a circle. They stay
/// separate axes because they are orthogonal — a dot still wears a tone,
/// and folding the two would make "a red dot" unexpressible.
///
/// Named `Form` rather than mirroring Figma's `Style` axis label
/// because `CoreBadgeStyle` is already this component's chrome-slot
/// class — a `CoreBadgeStyle` enum next to a `CoreBadgeStyle` style
/// class would be unreadable at every call site. `CoreBannerEmphasis`
/// carries the same divergence for the same reason.
///
/// The member spellings are the canvas's `Style` axis values — in this
/// pipeline a variant's name *is* its identity.
enum CoreBadgeForm {
  /// A word — a status, a category, a tag. The default.
  ///
  /// A rounded rectangle at the step's fixed height: the corner is a
  /// quarter of the height, taken down to the radius ladder, from
  /// [CoreBadgeStyle.defaultsBySize]. The label is set at 600.
  label,

  /// A number — an unread count, a total.
  ///
  /// A pill at the step's fixed height, never narrower than it is tall so
  /// a single digit stays a circle. The figure is set at 700.
  count,

  /// A bare circle with no content, sized by the step alone.
  ///
  /// Says "there is something here" without saying how much. The
  /// diameter comes from [CoreBadgeStyle.dotSize]; `child`, `leading`,
  /// `trailing` and the leading status dot are not drawn, and padding does
  /// not apply — a dot that padded itself would stop being the size the
  /// step names.
  ///
  /// The circle paints its tone's dot colour
  /// ([CoreBadgeToneStyle.dotColor]) whatever the variant: a dot has no
  /// label to keep legible, so the three strengths have nothing to differ
  /// in.
  dot;

  /// Widget default form — the Flutter / Web `Badge` constructors
  /// reference this so the default cannot silently diverge.
  static const CoreBadgeForm defaultForm = label;
}
