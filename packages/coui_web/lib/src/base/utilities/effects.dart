// Ignoring format-comment for consistent CSS utility documentation style
// Ignoring no-magic-number and no-magic-string for CSS class names and values
// Ignoring newline-before-return for concise static const definitions
// ignore_for_file: format-comment, no-magic-number, no-magic-string
// ignore_for_file: newline-before-return
import 'package:coui_web/src/base/common_style.dart';
import 'package:coui_web/src/base/style_type.dart';
import 'package:coui_web/src/base/ui_prefix_modifier.dart';

class Effects extends CommonStyle<Effects> {
  const Effects(super.cssClass, {super.modifiers})
    : super(type: StyleType.effect);

  Effects.opacity(int value)
    : assert(
        value >= 0 && value <= 100 && value % 5 == 0,
        'Opacity value must be between 0 and 100, in steps of 5.',
      ),
      super('opacity-$value', type: StyleType.effect);

  // --- Opacity ---

  // Changed type to effect

  // --- Coow ---
  static const shadowXs = Effects('shadow-xs');

  static const shadowSm = Effects('shadow-sm');

  static const shadow = Effects('shadow'); // Often md by default in TW

  static const shadowMd = Effects('shadow-md');
  static const shadowLg = Effects('shadow-lg');
  static const shadowXl = Effects('shadow-xl');
  static const shadow2xl = Effects('shadow-2xl');
  static const shadowInner = Effects('shadow-inner');
  static const shadowNone = Effects('shadow-none');
  static const opacity0 = Effects('opacity-0');
  static const opacity25 = Effects('opacity-25');
  static const opacity50 = Effects('opacity-50');

  static const opacity75 = Effects('opacity-75');

  static const opacity100 = Effects('opacity-100'); // --- Rounded Corners ---
  static const rounded = Effects('rounded');
  static const roundedNone = Effects('rounded-none');
  static const roundedSm = Effects('rounded-sm');
  static const roundedMd = Effects('rounded-md');

  static const roundedLg = Effects('rounded-lg');
  static const roundedXl = Effects('rounded-xl');
  static const rounded2xl = Effects('rounded-2xl');
  static const rounded3xl = Effects('rounded-3xl');
  static const roundedFull = Effects('rounded-full'); // rounded-box
  static const roundedBox = Effects(
    'rounded-box',
  ); // Blend Mode (mix-blend-*) examples can be added when needed.

  // Background Blend Mode (bg-blend-*) examples can be added when needed.

  // Box shadow color helpers can be introduced in a future iteration.

  // --- DaisyUI Specific Effects (like glass) ---

  /// Glassmorphism effect. `glass` (This is a DaisyUI utility)
  static const glass = Effects('glass');

  // Additional utilities (transitions, transforms, animations) can be
  // added later.

  @override
  Effects create(List<PrefixModifier> modifiers) {
    return Effects(cssClass, modifiers: modifiers);
  }
}
