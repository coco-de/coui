/// Subfocus scope component theme overrides.
library;

import 'package:coui_core/src/component/contracts/subfocus/subfocus_style.dart';
import 'package:meta/meta.dart';

/// Project-level theme overrides for `SubfocusScope` / `Subfocus`.
///
/// Provides a single composite [style] slot that every `Subfocus`
/// item inside the scope reads for its focus-ring chrome.
///
/// ### Resolve chain.
///
/// ```text
/// CoreSubfocusStyle.defaultX
///   → CoreSubfocusScopeTheme.style                  // 프로젝트 공통
///   → widget.subfocusStyle                          // 인스턴스별
/// ```
@immutable
class CoreSubfocusScopeTheme {
  /// Creates a [CoreSubfocusScopeTheme].
  const CoreSubfocusScopeTheme({this.style});

  /// Project-wide focus-ring chrome applied to every `Subfocus`.
  ///
  /// Resolved before any per-instance `widget.subfocusStyle`.
  final CoreSubfocusStyle? style;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreSubfocusScopeTheme &&
          runtimeType == other.runtimeType &&
          style == other.style;

  @override
  int get hashCode => style.hashCode;
}
