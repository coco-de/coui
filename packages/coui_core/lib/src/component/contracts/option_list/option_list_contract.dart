/// Cross-platform contract for `OptionList`.
library;

import 'package:coui_core/src/component/contracts/option_list/option_list_style.dart';

/// A vertical stack of `OptionItem`s — one list of choices.
///
/// The list owns the arrangement only: the rows stacked in order, one
/// [CoreOptionListStyle.spacing] apart, each as wide as the list. Which rows
/// are chosen, and whether one or many can be, is the caller's: each row
/// states its own `selection` and `selected`.
///
/// Type parameters:
/// - [W] — platform widget type (Flutter `Widget`, Web `Component`).
abstract interface class CoreOptionListContract<W> {
  /// The rows, top to bottom. Required.
  List<W> get children;

  /// Single chrome slot — see [CoreOptionListStyle].
  CoreOptionListStyle? get optionListStyle;
}
