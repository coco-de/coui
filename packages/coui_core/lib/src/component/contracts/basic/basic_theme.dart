/// Theme overrides for Basic.
library;

import 'package:coui_core/src/component/contracts/basic/basic_style.dart';
import 'package:meta/meta.dart';

/// Project-level style overrides for `Basic`.
///
/// Per Epic #1302 / Phase 6f, all chrome (alignment / spacing / padding /
/// nested text styles) lives inside [style] — no flat chrome fields remain
/// on the theme. The merge chain is:
///
/// ```text
/// design system default (CoreBasicStyle.defaultX)
///   → CoreBasicTheme.style
///   → parent component slot override
///   → widget.basicStyle
/// ```
@immutable
class CoreBasicTheme {
  /// Creates a [CoreBasicTheme].
  const CoreBasicTheme({this.style});

  /// Project-wide composite style applied to every `Basic`.
  ///
  /// Resolved before any per-instance `widget.basicStyle`.
  final CoreBasicStyle? style;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CoreBasicTheme && other.style == style;
  }

  @override
  int get hashCode => style.hashCode;
}
