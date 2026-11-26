/// The outline a chip is drawn in.
library;

import 'package:coui_core/src/component/contracts/chip/chip_size.dart';
import 'package:coui_core/src/component/contracts/chip/chip_style.dart';

/// The outline a `Chip` is drawn in — a rounded rectangle or a pill.
///
/// A shape, not a corner value. A single corner value cannot stand for the
/// pill: the chip's sizes are three different heights ([CoreChipSize]), and
/// a pill's corner is half of whichever height is drawn. So the pill is the
/// full corner (`CoreRadius.radius9999`) on every size, and each platform's
/// renderer clamps that corner to half the drawn height — the same clamp that
/// makes a disc of `Avatar`. Neither resolver computes `height / 2`, and no
/// token value is added: the pill is the full rung the ladder already has.
///
/// The corner comes from [CoreChipStyle.defaultsByShape], laid over the size
/// row: [rounded] states nothing there and keeps the size row's corner,
/// [pill] states the full corner. A corner a caller states
/// (`chipStyle.borderRadius`, or the theme's) wins over both shapes.
enum CoreChipShape {
  /// The size row's own corner — the chip's height × 0.25 on a `CoreRadius`
  /// rung (6 · 8 · 10). The default, and the look every chip drew before this
  /// axis existed.
  rounded,

  /// A pill — both ends a half circle on every size.
  pill;

  /// Widget default shape — the Flutter / Web `Chip` constructors reference
  /// this so the default cannot silently diverge between platforms.
  ///
  /// [rounded] because it is what every chip already rendered; defaulting to
  /// [pill] would repaint every chip in the catalogue as a side effect of
  /// adding a capability.
  static const CoreChipShape defaultShape = rounded;
}
