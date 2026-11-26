/// Theme data for Collapsible customization.
library;

import 'package:coui_core/src/component/contracts/collapsible/collapsible_style.dart';
import 'package:meta/meta.dart';

/// Theme overrides for Collapsible.
///
/// Per Epic #1302 / Phase 6f, all chrome (inset / gap / animation
/// duration / nested slot styles) lives inside the composite [style]
/// field — see [CoreCollapsibleStyle]. No flat chrome fields remain on
/// the theme. The merge chain is:
///
/// ```text
/// design system default (CoreCollapsibleStyle.defaultX)
///   → CoreCollapsibleTheme.style
///   → parent component slot override
///   → widget.collapsibleStyle
/// ```
@immutable
class CoreCollapsibleTheme {
  /// Creates a [CoreCollapsibleTheme].
  const CoreCollapsibleTheme({this.style});

  /// Project-wide composite style applied to every `Collapsible`.
  ///
  /// Resolved before any per-instance `widget.collapsibleStyle`.
  final CoreCollapsibleStyle? style;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreCollapsibleTheme &&
          runtimeType == other.runtimeType &&
          style == other.style;

  @override
  int get hashCode => style.hashCode;
}
