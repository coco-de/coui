// ignore_for_file: format-comment
import 'package:coui_web/src/base/common_style.dart';
import 'package:coui_web/src/base/style_type.dart' show StyleType;
import 'package:coui_web/src/base/ui_prefix_modifier.dart';

class BgUtil extends CommonStyle<BgUtil> {
  const BgUtil(super.cssClass, {super.modifiers})
    : super(type: StyleType.style);

  // Hintergrundfarben
  static const base100 = BgUtil('bg-base-100');

  static const base200 = BgUtil('bg-base-200');

  static const base300 = BgUtil('bg-base-300');

  static const primary = BgUtil('bg-primary');
  static const secondary = BgUtil('bg-secondary');
  static const neutral = BgUtil('bg-neutral'); // Hintergrund-Opacity
  static const opacity75 = BgUtil('bg-opacity-75');
  static const opacity50 = BgUtil('bg-opacity-50'); // Hintergrund-Verhalten

  static const fixed = BgUtil('bg-fixed');

  static const local = BgUtil('bg-local');

  @override
  BgUtil create(List<PrefixModifier> modifiers) {
    // Create a new instance with the original cssClass and new modifiers
    return BgUtil(cssClass, modifiers: modifiers);
  }
}
