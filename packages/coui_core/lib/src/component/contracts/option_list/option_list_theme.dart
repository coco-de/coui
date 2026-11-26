/// Theme slot for `OptionList`.
library;

import 'package:coui_core/src/component/contracts/option_list/option_list_style.dart';
import 'package:meta/meta.dart';

/// Project-wide `OptionList` chrome override. One slot — the list has no
/// variant enum.
@immutable
class CoreOptionListTheme {
  /// Creates a theme.
  const CoreOptionListTheme({this.style});

  /// Chrome applied to every option list in the project.
  final CoreOptionListStyle? style;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreOptionListTheme &&
          runtimeType == other.runtimeType &&
          style == other.style;

  @override
  int get hashCode => style.hashCode;
}
