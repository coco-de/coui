/// Theme slot for `MenuItem`.
library;

import 'package:coui_core/src/component/contracts/menu_item/menu_item_style.dart';
import 'package:meta/meta.dart';

/// Project-wide `MenuItem` chrome override. One slot — the component has
/// no variant enum (size and tone are axes with their own default tables
/// on [CoreMenuItemStyle]).
@immutable
class CoreMenuItemTheme {
  /// Creates a theme.
  const CoreMenuItemTheme({this.style});

  /// Chrome applied to every menu row in the project.
  final CoreMenuItemStyle? style;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreMenuItemTheme &&
          runtimeType == other.runtimeType &&
          style == other.style;

  @override
  int get hashCode => style.hashCode;
}
