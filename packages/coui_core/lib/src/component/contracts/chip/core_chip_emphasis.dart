/// How loudly a chip states its colour.
library;

import 'package:coui_core/src/component/contracts/chip/chip_variant.dart';

/// How loudly a chip states its colour.
///
/// This is orthogonal to `selected` — a chip is selected or not, and
/// separately it speaks at one of two volumes. The two axes together give
/// the four rows the colour table authors:
///
/// | selected | emphasis | fill | border | label |
/// |---|---|---|---|---|
/// | no | low | none | `outlineVariant` | `onSurfaceVariant` |
/// | no | high | none | `outlineVariant` | `onSurface` |
/// | yes | low | `{color}Container` | — | `on{color}Container` |
/// | yes | high | `{color}` | — | `on{color}` |
///
/// An *unselected* chip states no colour at either volume: a quiet hairline
/// and a neutral label, the same picture for every colour. The two volumes
/// differ there only in how dark the label reads. The colour first appears
/// when the chip is selected, so `chipColor` names the colour a chip takes on
/// selection, not the colour it rests in.
///
/// `neutral` states its own pair when selected at [high]: `inverseSurface`
/// with `inverseOnSurface`, a dark chip with a light label.
///
/// The "none" fill of an unselected chip is the outlined look
/// ([CoreChipVariant.outlined]); at [CoreChipVariant.filled] it is a grey
/// fill and the border mirrors it. `filled` belongs with [high] — see
/// [CoreChipVariant].
enum CoreChipEmphasis {
  /// The quiet register — tinted when selected, colourless when not.
  low,

  /// The loud register — a solid fill when selected, a colourless outline
  /// (or grey fill) when not.
  high;

  /// Widget default chip emphasis — the Flutter / Web `Chip`
  /// constructors reference this so the default cannot silently diverge
  /// between platforms.
  ///
  /// [high] rather than [low] because it is what every chip already
  /// rendered before this axis existed; defaulting to [low] would have
  /// repainted every chip in the catalogue as a side effect of adding a
  /// capability.
  static const CoreChipEmphasis defaultEmphasis = high;
}
