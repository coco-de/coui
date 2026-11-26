/// Scrollbar component theme overrides.
library;

import 'package:coui_core/src/component/contracts/scrollbar/scrollbar_style.dart';
import 'package:meta/meta.dart';

/// Project-level theme overrides for `Scrollbar`.
///
/// Provides a single composite [style] slot read by `Scrollbar`
/// through the inherited theme.
///
/// ### Resolve chain.
///
/// ```text
/// CoreScrollbarStyle.defaultX
///   → CoreScrollbarTheme.style                  // 프로젝트 공통
///   → widget.scrollbarStyle                     // 인스턴스별
/// ```
@immutable
class CoreScrollbarTheme {
  /// Creates a [CoreScrollbarTheme].
  const CoreScrollbarTheme({this.style});

  /// Project-wide composite chrome style applied to every `Scrollbar`.
  ///
  /// Resolved before any per-instance `widget.scrollbarStyle`.
  final CoreScrollbarStyle? style;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreScrollbarTheme &&
          runtimeType == other.runtimeType &&
          style == other.style;

  @override
  int get hashCode => style.hashCode;
}
