/// Theme slot for `PanelHeader`.
library;

import 'package:coui_core/src/component/contracts/panel_header/panel_header_style.dart';
import 'package:meta/meta.dart';

/// Project-wide `PanelHeader` chrome override. One slot — the component has
/// no variant enum.
///
/// ### Resolve chain.
///
/// ```text
/// design system default (CorePanelHeaderStyle.defaultX)
///   → CorePanelHeaderTheme.style                     // 프로젝트 공통
///   → widget per-instance panelHeaderStyle
/// ```
@immutable
class CorePanelHeaderTheme {
  /// Creates a theme.
  const CorePanelHeaderTheme({this.style});

  /// Chrome applied to every `PanelHeader` in the project.
  final CorePanelHeaderStyle? style;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CorePanelHeaderTheme &&
          runtimeType == other.runtimeType &&
          style == other.style;

  @override
  int get hashCode => style.hashCode;
}
