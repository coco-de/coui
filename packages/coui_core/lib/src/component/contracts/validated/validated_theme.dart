/// Theme overrides for validation-wrapper components.
library;

import 'package:coui_core/src/component/contracts/validated/validated_style.dart';
import 'package:meta/meta.dart';

/// Project-level theme overrides for `Validated`.
///
/// Platform-neutral (Epic #1415 option D) — no generic parameters.
@immutable
class CoreValidatedTheme {
  /// Creates a [CoreValidatedTheme].
  const CoreValidatedTheme({this.style});

  /// Project-level base style. `null` → no project override.
  final CoreValidatedStyle? style;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreValidatedTheme &&
          runtimeType == other.runtimeType &&
          style == other.style;

  @override
  int get hashCode => style.hashCode;
}
