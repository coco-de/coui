import 'package:coui_core/src/component/contracts/badge/badge_form.dart';
import 'package:coui_core/src/component/contracts/badge/badge_style.dart';
import 'package:coui_core/src/component/contracts/badge/badge_variant.dart';

/// What a `Badge`'s colour means.
///
/// One of Badge's three design axes. This one answers "which meaning does
/// the colour carry"; [CoreBadgeVariant] answers "how loud is it" and
/// [CoreBadgeForm] "what does it hold". They are separate axes because
/// they are orthogonal — a success badge can be filled, tonal or outlined,
/// and folding meaning and strength into one axis is what left the old
/// values unable to say "a quiet red label".
///
/// The member names are the ones `Alert` uses for the same meanings, so a
/// status reads with the same word on every component that shows one.
///
/// Each tone's colours live in one row of [CoreBadgeStyle.defaultsByTone].
enum CoreBadgeTone {
  /// No status — a plain tag or a neutral count. The default.
  neutral,

  /// The brand accent.
  primary,

  /// Information, or something new.
  info,

  /// Done, healthy, approved.
  success,

  /// Needs attention soon.
  warning,

  /// Failed, blocked, removed.
  destructive;

  /// Widget default tone — the Flutter / Web `Badge` constructors reference
  /// this so the default cannot silently diverge.
  static const CoreBadgeTone defaultTone = neutral;
}
