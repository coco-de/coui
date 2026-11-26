/// Theme overrides for form-label components.
library;

import 'package:coui_core/src/component/contracts/form_label/form_label_style.dart';
import 'package:meta/meta.dart';

/// Project-level theme overrides for `FormLabel`.
///
/// Platform-neutral (Epic #1415 option D) — no generic parameters.
@immutable
class CoreFormLabelTheme {
  /// Creates a [CoreFormLabelTheme].
  const CoreFormLabelTheme({this.style});

  /// Project-level base style. `null` → no project override.
  final CoreFormLabelStyle? style;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreFormLabelTheme &&
          runtimeType == other.runtimeType &&
          style == other.style;

  @override
  int get hashCode => style.hashCode;
}
