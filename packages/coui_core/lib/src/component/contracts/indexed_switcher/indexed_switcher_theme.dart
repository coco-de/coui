/// Theme overrides for `IndexedSwitcher`.
library;

import 'package:coui_core/src/component/contracts/indexed_switcher/indexed_switcher_style.dart';
import 'package:meta/meta.dart';

/// Project-level theme overrides for `IndexedSwitcher`.
///
/// Platform-neutral — no generic parameters.
@immutable
class CoreIndexedSwitcherTheme {
  /// Creates a [CoreIndexedSwitcherTheme].
  const CoreIndexedSwitcherTheme({this.style});

  /// Project-level base style. `null` → no project override.
  final CoreIndexedSwitcherStyle? style;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreIndexedSwitcherTheme &&
          runtimeType == other.runtimeType &&
          style == other.style;

  @override
  int get hashCode => style.hashCode;
}
