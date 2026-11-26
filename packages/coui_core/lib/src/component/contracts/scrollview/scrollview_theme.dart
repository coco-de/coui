/// Scroll-view interceptor component theme overrides.
library;

import 'package:coui_core/src/component/contracts/scrollview/scrollview_style.dart';
import 'package:meta/meta.dart';

/// Project-level theme overrides for `ScrollViewInterceptor`.
///
/// Provides a single composite [style] slot read by
/// `ScrollViewInterceptor` through the inherited theme.
///
/// ### Resolve chain.
///
/// ```text
/// CoreScrollViewInterceptorStyle.defaultX
///   → CoreScrollViewInterceptorTheme.style          // 프로젝트 공통
///   → widget.scrollViewInterceptorStyle             // 인스턴스별
/// ```
@immutable
class CoreScrollViewInterceptorTheme {
  /// Creates a [CoreScrollViewInterceptorTheme].
  const CoreScrollViewInterceptorTheme({this.style});

  /// Project-wide composite tuning style applied to every
  /// `ScrollViewInterceptor`.
  ///
  /// Resolved before any per-instance `widget.scrollViewInterceptorStyle`.
  final CoreScrollViewInterceptorStyle? style;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreScrollViewInterceptorTheme &&
          runtimeType == other.runtimeType &&
          style == other.style;

  @override
  int get hashCode => style.hashCode;
}
