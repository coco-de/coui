/// Theme overrides for `Switcher`.
library;

import 'package:coui_core/src/component/contracts/switcher/switcher_style.dart';
import 'package:meta/meta.dart';

/// Project-level theme overrides for `Switcher`.
///
/// Platform-neutral (Epic #1415 option D) — no generic parameters.
@immutable
class CoreSwitcherTheme {
  /// Creates a [CoreSwitcherTheme].
  const CoreSwitcherTheme({this.style});

  /// Project-level base style. `null` → no project override.
  final CoreSwitcherStyle? style;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreSwitcherTheme &&
          runtimeType == other.runtimeType &&
          style == other.style;

  @override
  int get hashCode => style.hashCode;
}
