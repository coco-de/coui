/// Platform-independent prompt mode for `ColorPicker`.
library;

/// How the picker UI is presented.
enum CoreColorPickerPromptMode {
  /// A field-shaped trigger that opens the picker in a floating popover
  /// anchored to it, committed with Cancel / Save.
  popover,

  /// Modal dialog overlay covering the screen.
  dialog,

  /// The picker panel drawn in place, always open, with no trigger and no
  /// shadow — for surfaces that keep the picker in view, such as a theme
  /// editor. Every change is committed as it happens, so the panel shows a
  /// previous / current comparison cell instead of Cancel / Save.
  inline,
}
