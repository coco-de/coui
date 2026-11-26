/// Theme slot for `CommandSearch`.
library;

import 'package:coui_core/src/component/contracts/command_search/command_search_style.dart';
import 'package:meta/meta.dart';

/// Project-wide `CommandSearch` chrome override. One slot — the component
/// has no variant enum (size is an axis with its own default table on
/// [CoreCommandSearchStyle]).
///
/// ### Resolve chain.
///
/// ```text
/// design system default (CoreCommandSearchStyle.defaultX / defaultsBySize)
///   → CoreCommandSearchTheme.style                   // 프로젝트 공통
///   → widget per-instance commandSearchStyle
/// ```
@immutable
class CoreCommandSearchTheme {
  /// Creates a theme.
  const CoreCommandSearchTheme({this.style});

  /// Chrome applied to every `CommandSearch` in the project.
  final CoreCommandSearchStyle? style;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreCommandSearchTheme &&
          runtimeType == other.runtimeType &&
          style == other.style;

  @override
  int get hashCode => style.hashCode;
}
