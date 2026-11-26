/// Theme overrides for the Hero block.
library;

import 'package:coui_core/src/component/contracts/hero/hero_style.dart';
import 'package:meta/meta.dart';

/// Project-level style overrides for the `Hero` block.
///
/// One slot, no `variantStyles` map: `Hero` has no variant enum to key
/// one by. Its axis is [CoreHeroStyle.layout], and that is a style
/// field rather than a variant — the layouts are the same block
/// arranged differently, not chrome sets a project would tone
/// separately (the same reading as `CoreFooterTheme`).
@immutable
class CoreHeroTheme {
  /// Creates a [CoreHeroTheme].
  const CoreHeroTheme({this.style});

  /// Project-wide composite style applied to every `Hero`.
  ///
  /// Resolved before any per-instance `widget.heroStyle`. A `layout`
  /// set here applies only when the caller left `Hero(layout:)` null —
  /// the widget prop wins.
  final CoreHeroStyle? style;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CoreHeroTheme && other.style == style;
  }

  @override
  int get hashCode => style.hashCode;
}

/// Renamed to [CoreHeroTheme] (since 0.146).
///
/// `HeroSection` was the component name. `Hero` is the block. The slot
/// is the same object.
@Deprecated(
  'Renamed to CoreHeroTheme (since 0.146) — Hero is a Block, not a '
  'component. Same style slot.',
)
typedef CoreHeroSectionTheme = CoreHeroTheme;
