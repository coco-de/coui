/// Theme overrides for validator-hint components.
library;

import 'package:coui_core/src/component/contracts/validator_hint/validator_hint_style.dart';
import 'package:meta/meta.dart';

/// Project-level theme overrides for `ValidatorHint`.
///
/// Platform-neutral (Epic #1415 option D) — no generic parameters.
@immutable
class CoreValidatorHintTheme {
  /// Creates a [CoreValidatorHintTheme].
  const CoreValidatorHintTheme({this.style});

  /// Project-level base style. `null` → no project override.
  final CoreValidatorHintStyle? style;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreValidatorHintTheme &&
          runtimeType == other.runtimeType &&
          style == other.style;

  @override
  int get hashCode => style.hashCode;
}
