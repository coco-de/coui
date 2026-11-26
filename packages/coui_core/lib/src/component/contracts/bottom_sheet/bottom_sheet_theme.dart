/// Theme slot for `BottomSheet`.
library;

import 'package:coui_core/src/component/contracts/bottom_sheet/bottom_sheet_style.dart';
import 'package:meta/meta.dart';

/// Project-wide `BottomSheet` chrome override. One slot — the sheet has no
/// variant enum.
///
/// ### Resolve chain.
///
/// ```text
/// design system default (CoreBottomSheetStyle.defaultX)
///   → CoreBottomSheetTheme.style                     // 프로젝트 공통
///   → widget per-instance bottomSheetStyle
/// ```
@immutable
class CoreBottomSheetTheme {
  /// Creates a theme.
  const CoreBottomSheetTheme({this.style});

  /// Chrome applied to every `BottomSheet` in the project.
  final CoreBottomSheetStyle? style;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreBottomSheetTheme &&
          runtimeType == other.runtimeType &&
          style == other.style;

  @override
  int get hashCode => style.hashCode;
}
