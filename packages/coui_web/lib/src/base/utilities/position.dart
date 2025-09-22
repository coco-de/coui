import 'package:coui_web/src/base/common_style.dart';
import 'package:coui_web/src/base/style_type.dart';
import 'package:coui_web/src/base/ui_prefix_modifier.dart';

class Position extends CommonStyle<Position> {
  const Position(super.cssClass, {super.modifiers})
    : super(type: StyleType.layout);

  static const static = Position('static');
  static const fixed = Position('fixed');
  static const absolute = Position('absolute');

  static const relative = Position('relative');
  static const sticky = Position('sticky');

  @override
  Position create(List<PrefixModifier> modifiers) {
    return Position(cssClass, modifiers: modifiers);
  }
}
