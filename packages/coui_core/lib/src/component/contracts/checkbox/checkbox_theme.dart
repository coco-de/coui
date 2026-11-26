/// Theme data for `Checkbox` customisation.
library;

import 'package:coui_core/src/component/contracts/checkbox/checkbox_style.dart';
import 'package:meta/meta.dart';

/// Project-level theme overrides for `Checkbox`.
///
/// Holds the project [style] applied to every `Checkbox` whose
/// widget-level `checkboxStyle` is null.
///
/// Only the visual chrome slot ([style]) lives here
/// (style-contract.md "CoreXxxTheme — style + variantStyles 슬롯만" — and a
/// component with no variant enum carries `style` alone). Behaviour
/// (`tristate`) is a widget parameter, not a Theme override — it stays flat
/// on the widget / contract so the Theme cannot diverge from chrome-only
/// intent.
///
/// ### Resolve chain.
///
/// ```text
/// design system default
///   → CoreCheckboxTheme.style                       // 프로젝트 공통
///   → parent component slot override
///   → widget per-instance checkboxStyle
/// ```
@immutable
class CoreCheckboxTheme {
  /// Creates a [CoreCheckboxTheme].
  const CoreCheckboxTheme({this.style});

  /// Project-level base style. `null` → no project override.
  final CoreCheckboxStyle? style;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreCheckboxTheme &&
          runtimeType == other.runtimeType &&
          style == other.style;

  @override
  int get hashCode => style.hashCode;
}
