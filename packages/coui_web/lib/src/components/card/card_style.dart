import 'package:coui_web/src/base/component_style.dart';
import 'package:coui_web/src/base/styling.dart';
import 'package:coui_web/src/base/ui_prefix_modifier.dart';
import 'package:coui_web/src/components/card/card.dart';

/// Marker interface for any utility that can be passed to a [Card]'s `modifiers` list.
abstract class _CardStyling implements Styling {}

/// Public interface for CardStyling.
typedef CardStyling = _CardStyling;

/// Defines specific styling options for a [Card] component.
/// Implements the [CardStyling] interface.
class CardStyle extends ComponentStyle<CardStyle>
    with Breakpoints<CardStyle>
    implements CardStyling {
  // Implements the CardModifier INTERFACE
  const CardStyle(super.cssClass, {super.modifiers, required super.type});

  @override
  CardStyle create(List<PrefixModifier> modifiers) {
    return CardStyle(cssClass, modifiers: modifiers, type: type);
  }
}
