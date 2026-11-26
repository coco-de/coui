/// Theme data for Resizable customization.
library;

import 'package:coui_core/src/component/contracts/resizable/resizable_style.dart';
import 'package:meta/meta.dart';

/// Resizable component theme overrides.
///
/// Per Epic #1302 chrome / dimensional overrides flow through the
/// single [style] field — see [CoreResizableStyle] for the merge chain.
///
/// ### Resolve chain.
///
/// ```text
/// design system default
///   → CoreResizableTheme.style                       // 프로젝트 공통
///   → parent component slot override
///   → widget per-instance resizableStyle
/// ```
@immutable
class CoreResizableTheme {
  /// Creates a [CoreResizableTheme].
  const CoreResizableTheme({this.style});

  /// Project-wide composite style applied to every `Resizable`.
  ///
  /// Resolved before any per-instance `widget.resizableStyle`.
  final CoreResizableStyle? style;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreResizableTheme &&
          runtimeType == other.runtimeType &&
          style == other.style;

  @override
  int get hashCode => style.hashCode;
}
