/// Theme data for `Dialog` customisation.
library;

import 'package:coui_core/src/component/contracts/dialog/dialog_style.dart';
import 'package:meta/meta.dart';

/// Project-level theme overrides for `Dialog`.
///
/// Holds the project [style] applied to every `Dialog` whose
/// widget-level `dialogStyle` is null.
///
/// ### Resolve chain.
///
/// ```text
/// design system default
///   → CoreDialogTheme.style                       // 프로젝트 공통
///   → parent component slot override
///   → widget per-instance dialogStyle
/// ```
@immutable
class CoreDialogTheme {
  /// Creates a [CoreDialogTheme].
  const CoreDialogTheme({this.style});

  /// Project-level base style. `null` → no project override.
  final CoreDialogStyle? style;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreDialogTheme &&
          runtimeType == other.runtimeType &&
          style == other.style;

  @override
  int get hashCode => style.hashCode;
}
