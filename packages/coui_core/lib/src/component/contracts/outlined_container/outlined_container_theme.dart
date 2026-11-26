/// Theme data for `OutlinedContainer` customisation.
library;

import 'package:coui_core/src/component/contracts/outlined_container/outlined_container_style.dart';
import 'package:meta/meta.dart';

/// Project-level theme overrides for `OutlinedContainer`.
///
/// Holds the project [style] applied to every `OutlinedContainer`
/// whose widget-level `containerStyle` is null. Unlike `CoreCardTheme`,
/// the outlined-container does not expose variantStyles — it is an
/// infrastructure primitive without user-facing variants; higher-level
/// composites (Card / Window / Alert …) carry their own variant lookup.
///
/// ### Resolve chain.
///
/// ```text
/// design system default
///   → theme.outlinedContainer.style
///   → parent component slot override
///   → widget per-instance containerStyle
/// ```
@immutable
class CoreOutlinedContainerTheme {
  /// Creates a [CoreOutlinedContainerTheme].
  const CoreOutlinedContainerTheme({this.style});

  /// Project-level base style. `null` → no project override.
  final CoreOutlinedContainerStyle? style;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreOutlinedContainerTheme &&
          runtimeType == other.runtimeType &&
          style == other.style;

  @override
  int get hashCode => style.hashCode;
}
