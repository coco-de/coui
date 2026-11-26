/// Platform-independent contract for color picker components.
library;

import 'package:coui_core/src/component/contracts/color_picker/color_picker_style.dart';
import 'package:coui_core/src/component/contracts/color_picker/core_color_picker_prompt_mode.dart';
import 'package:coui_core/src/size/component_size.dart';

/// Supported color picker interaction modes.
enum CoreColorPickerMode {
  /// HSL (Hue, Saturation, Lightness) color space.
  hsl,

  /// HSV (Hue, Saturation, Value) color space.
  hsv,

  /// RGB (Red, Green, Blue) color space.
  rgb,
}

/// Contract for a color picker component.
///
/// Per Epic #1302, every chrome / dimensional override flows through
/// the single [colorPickerStyle] field — see [CoreColorPickerStyle]
/// for the merge chain. Behaviour fields (color / onChanged / enabled
/// / showAlpha / showLabel / showHexInput / pickerMode /
/// enableEyeDropper / promptMode / dialogTitle / placeholder /
/// controller) stay flat on the contract.
///
/// Type parameters:
/// - [W] — platform widget type (Flutter `Widget`, Web `Component`).
/// - [Clr] — colour value type (Flutter `Color`, Web `CoreColor`).
/// - [ChangedCb] — value change callback.
/// - [Ctrl] — color picker controller type.
abstract interface class CoreColorPickerContract<W, Clr, ChangedCb, Ctrl> {
  /// Default for the alpha (transparency) controls when neither the
  /// widget value nor a project override is supplied. Single source of
  /// truth shared by the Flutter and Web widgets — replaces the former
  /// per-platform literal `false` fallback.
  static const bool defaultShowAlpha = false;

  /// Default for the color value labels / channel input.
  static const bool defaultShowLabel = false;

  /// Default for the hex text input field.
  static const bool defaultShowHexInput = false;

  /// Default picker interaction mode (HSL / HSV / RGB).
  static const CoreColorPickerMode defaultPickerMode = .rgb;

  /// Size of the panel's RGB / HSL / HSV mode tabs (`ToggleGroup`) — `sm`
  /// (24 px segments, 30 px track). Shared by Flutter and Web.
  static const CoreComponentSize defaultModeTabsSize = CoreComponentSize.sm;

  /// Default for the screen color sampling (eye dropper) button.
  static const bool defaultEnableEyeDropper = true;

  /// Default presentation of the picker UI — the field-shaped trigger
  /// that opens a popover.
  static const CoreColorPickerPromptMode defaultPromptMode = .popover;

  /// Size of the panel's HEX and channel inputs (`TextField`) — `sm`.
  /// Shared by Flutter and Web.
  static const CoreComponentSize defaultModeInputSize = CoreComponentSize.sm;

  /// Current selected color value.
  Clr get color;

  /// Called when the selected color changes.
  ChangedCb get onChanged;

  /// Whether the color picker is enabled.
  bool? get enabled;

  /// Whether to display alpha (transparency) controls.
  bool? get showAlpha;

  /// Whether to display color value labels.
  bool? get showLabel;

  /// Whether to show hex text input alongside picker.
  bool? get showHexInput;

  /// Color picker interface type (HSL, HSV, RGB).
  CoreColorPickerMode? get pickerMode;

  /// Whether to enable screen color sampling (eye dropper).
  bool? get enableEyeDropper;

  /// How the picker UI is presented: a popover anchored to a field-shaped
  /// trigger, a modal dialog, or a panel drawn in place (`inline`).
  CoreColorPickerPromptMode? get promptMode;

  /// Optional title for the picker dialog.
  W? get dialogTitle;

  /// Optional placeholder widget when no color is selected.
  W? get placeholder;

  /// Color picker controller for programmatic state management.
  Ctrl? get controller;

  /// Per-instance color-picker style covering popover / dialog /
  /// swatch button / hex input slot styles plus label / description
  /// / error text styles.
  ///
  /// Resolves through the nested-merge chain:
  ///
  /// ```text
  /// design system default
  ///   → CoreColorPickerTheme.style
  ///   → parent component slot override
  ///   → widget.colorPickerStyle
  /// ```
  CoreColorPickerStyle? get colorPickerStyle;
}
