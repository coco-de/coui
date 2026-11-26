/// Theme slot for `PageHeader`.
library;

import 'package:coui_core/src/component/contracts/page_header/page_header_style.dart';
import 'package:meta/meta.dart';

/// Project-wide `PageHeader` chrome override. One slot — the component has
/// no variant enum.
///
/// ### Resolve chain.
///
/// ```text
/// design system default (CorePageHeaderStyle.defaultX)
///   → CorePageHeaderTheme.style                      // 프로젝트 공통
///   → widget per-instance pageHeaderStyle
/// ```
@immutable
class CorePageHeaderTheme {
  /// Creates a theme.
  const CorePageHeaderTheme({this.style});

  /// Chrome applied to every `PageHeader` in the project.
  final CorePageHeaderStyle? style;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CorePageHeaderTheme &&
          runtimeType == other.runtimeType &&
          style == other.style;

  @override
  int get hashCode => style.hashCode;
}
