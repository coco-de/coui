import 'package:coui_web/src/base/common_style.dart';
import 'package:coui_web/src/base/style_type.dart';
import 'package:coui_web/src/base/ui_prefix_modifier.dart';

class FontUtil extends CommonStyle<FontUtil> {
  const FontUtil(super.cssClass, {super.modifiers})
    : super(type: StyleType.typography);

  // --- Font Weight ---
  static const thin = FontUtil('font-thin');

  static const extralight = FontUtil('font-extralight');

  static const light = FontUtil('font-light');
  static const normal = FontUtil('font-normal');

  static const medium = FontUtil('font-medium');
  static const semibold = FontUtil('font-semibold');
  static const bold = FontUtil('font-bold');
  static const extrabold = FontUtil('font-extrabold');
  static const black = FontUtil('font-black'); // --- Font Style ---
  static const italic = FontUtil('italic');
  static const notItalic = FontUtil('not-italic');

  @override
  FontUtil create(List<PrefixModifier> modifiers) {
    return FontUtil(cssClass, modifiers: modifiers);
  }

  // Font families can be added if needed in future versions.
}
