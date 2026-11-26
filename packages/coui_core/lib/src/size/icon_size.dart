import 'package:coui_core/src/size/size.dart';

/// Icon size primitive tokens.
///
/// A separate ladder from [CoreSize] because an icon is measured
/// differently from a box. A 24 box is 24 of anything; a 24 icon is a
/// glyph drawn on a 24 grid, and the step below it is the next size the
/// glyph still reads at rather than the next number on a spacing scale.
/// Naming the ladder is what lets a new component pick a step instead of
/// a number.
///
/// Values are a subset of [CoreSize] — every step here has an identical
/// twin there, so this is a rename of where the number lives, not a
/// requantisation. Nothing renders differently for having moved.
///
/// ## The ladder is the one the kit already draws
///
/// Taken from a census of every icon size in the shipped components
/// rather than from a table someone would like to be true. Four steps
/// carry almost all of it — 16 (42 sites), 20 (19), 12 (9), 14 (8) —
/// and the rest are shaped by the components that need them.
///
/// A stated ladder that a quarter of the kit could not sit on would be
/// worse than none: the sites that fell off would either be snapped, a
/// silent visual change nobody asked for, or exempted, at which point
/// the ladder stops meaning anything.
///
/// The census is also why there is no 22 step, despite one being
/// proposed: nothing draws at 22, and the dimension scale has no such
/// value either. A step exists here because something stands on it.
abstract final class CoreIconSize {
  const CoreIconSize._();

  /// 10 — a glyph inside a badge, at the size where it stops being a
  /// shape and starts being a texture.
  static const double size10 = CoreSize.size10;

  /// 12 — dense controls: a chip's close affordance, a small checkbox.
  static const double size12 = CoreSize.size12;

  /// 14 — the step between dense and default.
  static const double size14 = CoreSize.size14;

  /// 16 — the default for a control-sized glyph, and the most common
  /// size in the kit by a wide margin.
  static const double size16 = CoreSize.size16;

  /// 18 — a chip at its largest.
  static const double size18 = CoreSize.size18;

  /// 20 — the second most common; a glyph that leads a row of text.
  static const double size20 = CoreSize.size20;

  /// 24 — a standalone icon, and the default when nothing states one.
  static const double size24 = CoreSize.size24;

  /// 28 — a dock item at its larger size.
  static const double size28 = CoreSize.size28;

  /// 32 — a glyph carrying a whole empty state.
  static const double size32 = CoreSize.size32;

  /// 48 — the glyph in the largest avatar (`xl2`, 96), about half its
  /// diameter.
  static const double size48 = CoreSize.size48;

  /// The size an icon draws at when nothing in the resolve chain states
  /// one and no ambient theme supplies it.
  static const double defaultSize = size24;

  // No Tailwind class-key record, deliberately.
  //
  // The other scales carry one because the Web emits a utility class
  // when a value is a step. Icons do not take that path: the size is
  // written inline as `rem` on width, height and font-size together, so
  // the glyph and its box stay 1:1. A class path would also run into the
  // documented trap that the dimension scale's keys do not produce
  // working `w-` / `h-` utilities.
  //
  // A record here would be a value nobody reads — the shape this
  // repository has spent a lot of effort removing.
}
