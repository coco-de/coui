/// Theme slot for `OptionItem`.
library;

import 'package:coui_core/src/component/contracts/option_item/option_item_style.dart';
import 'package:meta/meta.dart';

/// Project-wide `OptionItem` chrome override. One slot — the selection is an
/// axis with its own default table on [CoreOptionItemStyle], not a variant.
@immutable
class CoreOptionItemTheme {
  /// Creates a theme.
  const CoreOptionItemTheme({this.style});

  /// Chrome applied to every option row in the project.
  final CoreOptionItemStyle? style;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreOptionItemTheme &&
          runtimeType == other.runtimeType &&
          style == other.style;

  @override
  int get hashCode => style.hashCode;
}
