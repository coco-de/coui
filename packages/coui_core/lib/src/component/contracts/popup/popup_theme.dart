/// Theme overrides for `Popup`.
library;

import 'package:coui_core/src/component/contracts/popup/popup_style.dart';
import 'package:meta/meta.dart';

/// Project-level theme overrides for `Popup`.
///
/// Platform-neutral (Epic #1415 option D) — no generic parameters.
@immutable
class CorePopupTheme {
  /// Creates a [CorePopupTheme].
  const CorePopupTheme({this.style});

  /// Project-level base style. `null` → no project override.
  final CorePopupStyle? style;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CorePopupTheme &&
          runtimeType == other.runtimeType &&
          style == other.style;

  @override
  int get hashCode => style.hashCode;
}
