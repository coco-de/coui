/// Theme data for `Popover` customisation.
library;

import 'package:coui_core/src/component/contracts/popover/popover_style.dart';
import 'package:meta/meta.dart';

/// Project-level theme overrides for `Popover`.
///
/// Holds the project [style] applied to every `Popover` whose
/// widget-level `popoverStyle` is null. Animation policy
/// (`openAnimationDuration` / `closeAnimationDuration`) lives inside
/// [CorePopoverStyle] so the same field can be set at any layer of
/// the merge chain (project default vs per-instance) without
/// declaring it in two places.
///
/// ### Resolve chain.
///
/// ```text
/// design system default
///   → CorePopoverTheme.style                       // 프로젝트 공통
///   → parent component slot override
///   → widget per-instance popoverStyle
/// ```
@immutable
class CorePopoverTheme {
  /// Creates a [CorePopoverTheme].
  const CorePopoverTheme({this.style});

  /// Project-level base style. `null` → no project override.
  final CorePopoverStyle? style;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CorePopoverTheme &&
          runtimeType == other.runtimeType &&
          style == other.style;

  @override
  int get hashCode => style.hashCode;
}
