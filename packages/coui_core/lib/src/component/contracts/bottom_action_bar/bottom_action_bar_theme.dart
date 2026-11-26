/// Theme slot for `BottomActionBar`.
library;

import 'package:coui_core/src/component/contracts/bottom_action_bar/bottom_action_bar_style.dart';
import 'package:meta/meta.dart';

/// Project-wide `BottomActionBar` chrome override. One slot — the layout is
/// an arrangement, not a variant, so the component has no variant enum.
///
/// ### Resolve chain.
///
/// ```text
/// design system default (CoreBottomActionBarStyle.defaultX)
///   → CoreBottomActionBarTheme.style                 // 프로젝트 공통
///   → widget per-instance bottomActionBarStyle
/// ```
@immutable
class CoreBottomActionBarTheme {
  /// Creates a theme.
  const CoreBottomActionBarTheme({this.style});

  /// Chrome applied to every `BottomActionBar` in the project.
  final CoreBottomActionBarStyle? style;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreBottomActionBarTheme &&
          runtimeType == other.runtimeType &&
          style == other.style;

  @override
  int get hashCode => style.hashCode;
}
