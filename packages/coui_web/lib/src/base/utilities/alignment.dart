// ignore_for_file: format-comment, member-ordering
import 'package:coui_web/src/base/common_style.dart';
import 'package:coui_web/src/base/style_type.dart';
import 'package:coui_web/src/base/ui_prefix_modifier.dart';

class Alignment extends CommonStyle<Alignment> {
  // stretch

  const Alignment(super.cssClass, {super.modifiers})
    : super(type: StyleType.layout);
  static const justifyEnd = Alignment('justify-end'); // flex-end

  @override
  Alignment create(List<PrefixModifier> modifiers) {
    return Alignment(cssClass, modifiers: modifiers);
  }
}
