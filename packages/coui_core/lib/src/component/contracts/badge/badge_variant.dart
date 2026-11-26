import 'package:coui_core/src/component/contracts/badge/badge_style.dart';
import 'package:coui_core/src/component/contracts/badge/badge_tone.dart';

/// How loud a `Badge` is — a solid fill, a tinted fill, or a line.
///
/// Strength only. Which colour it is comes from [CoreBadgeTone]; each
/// tone row in [CoreBadgeStyle.defaultsByTone] states the colours for all
/// three strengths, so any tone can be worn at any strength.
///
/// The spellings match `Card` and `Chip` (`filled` / `outlined`), so the
/// same strength reads with the same word across components.
enum CoreBadgeVariant {
  /// Solid fill in the tone's colour — the loudest. Counts that must be
  /// noticed (an unread number) use this.
  filled,

  /// The tone's container colour behind the tone's container text — a
  /// label that reads as a status without shouting. The default.
  tonal,

  /// A line in the tone's colour around a transparent fill — the quietest
  /// strength that still states a colour.
  outlined;

  /// Widget default variant — the Flutter / Web `Badge` constructors
  /// reference this so the default cannot silently diverge.
  static const CoreBadgeVariant defaultVariant = tonal;
}
