/// Cross-platform contract for `OptionItem`.
library;

import 'package:coui_core/src/component/contracts/option_item/option_item_selection.dart';
import 'package:coui_core/src/component/contracts/option_item/option_item_style.dart';

/// One choosable row of a list of options — a sheet's "sort by", a filter's
/// "colour".
///
/// Anatomy, start to end: `[ leading ] [ label / description ] [ mark ]`,
/// one [CoreOptionItemStyle.spacing] between the seats. The mark is the
/// chosen state: a check at the end of the chosen row
/// ([CoreOptionItemSelection.single]) or a `Checkbox` on every row
/// ([CoreOptionItemSelection.multiple]).
///
/// The row draws no fill at rest. While it is pressed it paints a rounded
/// face that reaches past the row's sides, over the label and the mark.
///
/// Type parameters:
/// - [W] — platform widget type (Flutter `Widget`, Web `Component`).
abstract interface class CoreOptionItemContract<W> {
  /// The option's name. Required.
  W get label;

  /// A short line under [label]. Absent by default.
  W? get description;

  /// A glyph before the label. Absent by default.
  W? get leading;

  /// How the chosen state is shown — see [CoreOptionItemSelection].
  CoreOptionItemSelection get selection;

  /// Whether this row is chosen.
  bool get selected;

  /// Whether the row accepts a tap. `null` → whether [onPressed] is set.
  bool? get enabled;

  /// Called when the row is tapped. The list owns which rows are chosen, so
  /// the row only reports the tap.
  void Function()? get onPressed;

  /// Single chrome slot — see [CoreOptionItemStyle].
  CoreOptionItemStyle? get optionItemStyle;
}
