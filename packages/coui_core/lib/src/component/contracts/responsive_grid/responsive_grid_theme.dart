/// Theme data for `ResponsiveGrid` customisation.
library;

import 'package:coui_core/src/component/contracts/responsive_grid/responsive_grid_style.dart';
import 'package:meta/meta.dart';

/// Project-level theme overrides for `ResponsiveGrid`.
///
/// Holds the project [style] applied to every `ResponsiveGrid` whose
/// widget-level overrides are null. Per Epic #1603 (옵션 B 최종) the
/// theme exposes a single `style` slot — design-system defaults live on
/// `CoreResponsiveGridStyle.defaultX` and the resolver folds the chain
/// `design default → theme.style → widget.responsiveGridStyle →
/// widget per-instance params`.
///
/// ### Resolve chain.
///
/// ```text
/// design system default (`CoreResponsiveGridStyle.defaultX` static const)
///   → theme.responsiveGrid.style
///   → widget.responsiveGridStyle
///   → widget per-instance params (columns / gap / responsive / breakpoints)
/// ```
@immutable
class CoreResponsiveGridTheme {
  /// Creates a [CoreResponsiveGridTheme].
  const CoreResponsiveGridTheme({this.style});

  /// Project-level base style. `null` → no project override.
  final CoreResponsiveGridStyle? style;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreResponsiveGridTheme &&
          runtimeType == other.runtimeType &&
          style == other.style;

  @override
  int get hashCode => style.hashCode;
}
