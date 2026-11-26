/// The brightness axis. Two values, always — CoUI does not have a "system"
/// theme at the render level, only light/dark resolved values (see
/// `coui_web` `ThemeConfig.darkVariableBlock` / Flutter `ColorScheme`).
enum ParityTheme {
  light,
  dark;

  static ParityTheme? tryParse(String raw) => switch (raw) {
    'light' => .light,
    'dark' => .dark,
    _ => null,
  };
}
