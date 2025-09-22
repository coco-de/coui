import 'package:coui_flutter/coui_flutter.dart';

void _assertNotThemeModeSystem(String label, ThemeMode mode) {
  if (mode == ThemeMode.system) {
    final diagnosticList = <DiagnosticsNode>[];
    diagnosticList.add(ErrorSummary(
      'ColorSchemes.${label.toLowerCase()}(ThemeMode mode) can only be used with ThemeMode.light or ThemeMode.dark.',
    ));
    diagnosticList.add(ErrorDescription(
      'This method is only intended as a helper method to get either ColorSchemes.light$label() or ColorSchemes.dark$label().',
    ));
    diagnosticList.add(ErrorHint('To use system theme mode, do this:\n'
        'CoUIApp(\n'
        '  theme: ThemeData(colorScheme: ColorSchemes.${label.toLowerCase()}(ThemeMode.light)),\n'
        '  darkTheme: ThemeData(colorScheme: ColorSchemes.${label.toLowerCase()}(ThemeMode.dark)),\n'
        '  themeMode: ThemeMode.system, // optional, default is ThemeMode.system\n'
        ')\n'
        'or:\n'
        'CoUIApp(\n'
        '  theme: ThemeData(colorScheme: ColorSchemes.light$label),\n'
        '  darkTheme: ThemeData(colorScheme: ColorSchemes.dark$label),\n'
        ')\n'
        'instead of:\n'
        'CoUIApp(\n'
        '  theme: ThemeData(colorScheme: ColorSchemes.${label.toLowerCase()}(ThemeMode.system)),\n'
        ')'));
    throw FlutterError.fromParts(diagnosticList);
  }
}

abstract final class ColorSchemes {
  const ColorSchemes._();
  static const lightBlue = ColorScheme(
    accent: Color(0xFFF4F4F5),
    accentForeground: Color(0xFF18181B),
    background: Color(0xFFFFFFFF),
    border: Color(0xFFE4E4E7),
    brightness: Brightness.light,
    card: Color(0xFFFFFFFF),
    cardForeground: Color(0xFF09090B),
    chart1: Color(0xFFF54900),
    chart2: Color(0xFF009689),
    chart3: Color(0xFF104E64),
    chart4: Color(0xFFFFB900),
    chart5: Color(0xFFFE9A00),
    destructive: Color(0xFFE7000B),
    foreground: Color(0xFF09090B),
    input: Color(0xFFE4E4E7),
    muted: Color(0xFFF4F4F5),
    mutedForeground: Color(0xFF71717B),
    popover: Color(0xFFFFFFFF),
    popoverForeground: Color(0xFF09090B),
    primary: Color(0xFF2B7FFF),
    primaryForeground: Color(0xFFEFF6FF),
    ring: Color(0xFF2B7FFF),
    secondary: Color(0xFFF4F4F5),
    secondaryForeground: Color(0xFF18181B),
    sidebar: Color(0xFFFAFAFA),
    sidebarAccent: Color(0xFFF4F4F5),
    sidebarAccentForeground: Color(0xFF18181B),
    sidebarBorder: Color(0xFFE4E4E7),
    sidebarForeground: Color(0xFF09090B),
    sidebarPrimary: Color(0xFF2B7FFF),
    sidebarPrimaryForeground: Color(0xFFEFF6FF),
    sidebarRing: Color(0xFF2B7FFF),
  );

  static const darkBlue = ColorScheme(
    accent: Color(0xFF27272A),
    accentForeground: Color(0xFFFAFAFA),
    background: Color(0xFF09090B),
    border: Color(0x1AFFFFFF),
    brightness: Brightness.dark,
    card: Color(0xFF18181B),
    cardForeground: Color(0xFFFAFAFA),
    chart1: Color(0xFF1447E6),
    chart2: Color(0xFF00BC7D),
    chart3: Color(0xFFFE9A00),
    chart4: Color(0xFFAD46FF),
    chart5: Color(0xFFFF2056),
    destructive: Color(0xFFFF6467),
    foreground: Color(0xFFFAFAFA),
    input: Color(0x26FFFFFF),
    muted: Color(0xFF27272A),
    mutedForeground: Color(0xFF9F9FA9),
    popover: Color(0xFF18181B),
    popoverForeground: Color(0xFFFAFAFA),
    primary: Color(0xFF155DFC),
    primaryForeground: Color(0xFF1C398E),
    ring: Color(0xFF1447E6),
    secondary: Color(0xFF27272A),
    secondaryForeground: Color(0xFFFAFAFA),
    sidebar: Color(0xFF18181B),
    sidebarAccent: Color(0xFF27272A),
    sidebarAccentForeground: Color(0xFFFAFAFA),
    sidebarBorder: Color(0x1AFFFFFF),
    sidebarForeground: Color(0xFFFAFAFA),
    sidebarPrimary: Color(0xFF155DFC),
    sidebarPrimaryForeground: Color(0xFF1C398E),
    sidebarRing: Color(0xFF1447E6),
  );

  static const lightDefaultColor = ColorScheme(
    accent: Color(0xFFF5F5F5),
    accentForeground: Color(0xFF171717),
    background: Color(0xFFFFFFFF),
    border: Color(0xFFE5E5E5),
    brightness: Brightness.light,
    card: Color(0xFFFFFFFF),
    cardForeground: Color(0xFF0A0A0A),
    chart1: Color(0xFFF54900),
    chart2: Color(0xFF009689),
    chart3: Color(0xFF104E64),
    chart4: Color(0xFFFFB900),
    chart5: Color(0xFFFE9A00),
    destructive: Color(0xFFE7000B),
    foreground: Color(0xFF0A0A0A),
    input: Color(0xFFE5E5E5),
    muted: Color(0xFFF5F5F5),
    mutedForeground: Color(0xFF737373),
    popover: Color(0xFFFFFFFF),
    popoverForeground: Color(0xFF0A0A0A),
    primary: Color(0xFF171717),
    primaryForeground: Color(0xFFFAFAFA),
    ring: Color(0xFFA1A1A1),
    secondary: Color(0xFFF5F5F5),
    secondaryForeground: Color(0xFF171717),
    sidebar: Color(0xFFFAFAFA),
    sidebarAccent: Color(0xFFF5F5F5),
    sidebarAccentForeground: Color(0xFF171717),
    sidebarBorder: Color(0xFFE5E5E5),
    sidebarForeground: Color(0xFF0A0A0A),
    sidebarPrimary: Color(0xFF171717),
    sidebarPrimaryForeground: Color(0xFFFAFAFA),
    sidebarRing: Color(0xFFA1A1A1),
  );

  static const darkDefaultColor = ColorScheme(
    accent: Color(0xFF262626),
    accentForeground: Color(0xFFFAFAFA),
    background: Color(0xFF0A0A0A),
    border: Color(0x1AFFFFFF),
    brightness: Brightness.dark,
    card: Color(0xFF171717),
    cardForeground: Color(0xFFFAFAFA),
    chart1: Color(0xFF1447E6),
    chart2: Color(0xFF00BC7D),
    chart3: Color(0xFFFE9A00),
    chart4: Color(0xFFAD46FF),
    chart5: Color(0xFFFF2056),
    destructive: Color(0xFFFF6467),
    foreground: Color(0xFFFAFAFA),
    input: Color(0x26FFFFFF),
    muted: Color(0xFF262626),
    mutedForeground: Color(0xFFA1A1A1),
    popover: Color(0xFF171717),
    popoverForeground: Color(0xFFFAFAFA),
    primary: Color(0xFFE5E5E5),
    primaryForeground: Color(0xFF171717),
    ring: Color(0xFF737373),
    secondary: Color(0xFF262626),
    secondaryForeground: Color(0xFFFAFAFA),
    sidebar: Color(0xFF171717),
    sidebarAccent: Color(0xFF262626),
    sidebarAccentForeground: Color(0xFFFAFAFA),
    sidebarBorder: Color(0x1AFFFFFF),
    sidebarForeground: Color(0xFFFAFAFA),
    sidebarPrimary: Color(0xFF1447E6),
    sidebarPrimaryForeground: Color(0xFFFAFAFA),
    sidebarRing: Color(0xFF737373),
  );

  static const lightGreen = ColorScheme(
    accent: Color(0xFFF4F4F5),
    accentForeground: Color(0xFF18181B),
    background: Color(0xFFFFFFFF),
    border: Color(0xFFE4E4E7),
    brightness: Brightness.light,
    card: Color(0xFFFFFFFF),
    cardForeground: Color(0xFF09090B),
    chart1: Color(0xFFF54900),
    chart2: Color(0xFF009689),
    chart3: Color(0xFF104E64),
    chart4: Color(0xFFFFB900),
    chart5: Color(0xFFFE9A00),
    destructive: Color(0xFFE7000B),
    foreground: Color(0xFF09090B),
    input: Color(0xFFE4E4E7),
    muted: Color(0xFFF4F4F5),
    mutedForeground: Color(0xFF71717B),
    popover: Color(0xFFFFFFFF),
    popoverForeground: Color(0xFF09090B),
    primary: Color(0xFF00C950),
    primaryForeground: Color(0xFFF0FDF4),
    ring: Color(0xFF00C950),
    secondary: Color(0xFFF4F4F5),
    secondaryForeground: Color(0xFF18181B),
    sidebar: Color(0xFFFAFAFA),
    sidebarAccent: Color(0xFFF4F4F5),
    sidebarAccentForeground: Color(0xFF18181B),
    sidebarBorder: Color(0xFFE4E4E7),
    sidebarForeground: Color(0xFF09090B),
    sidebarPrimary: Color(0xFF00C950),
    sidebarPrimaryForeground: Color(0xFFF0FDF4),
    sidebarRing: Color(0xFF00C950),
  );

  static const darkGreen = ColorScheme(
    accent: Color(0xFF27272A),
    accentForeground: Color(0xFFFAFAFA),
    background: Color(0xFF09090B),
    border: Color(0x1AFFFFFF),
    brightness: Brightness.dark,
    card: Color(0xFF18181B),
    cardForeground: Color(0xFFFAFAFA),
    chart1: Color(0xFF1447E6),
    chart2: Color(0xFF00BC7D),
    chart3: Color(0xFFFE9A00),
    chart4: Color(0xFFAD46FF),
    chart5: Color(0xFFFF2056),
    destructive: Color(0xFFFF6467),
    foreground: Color(0xFFFAFAFA),
    input: Color(0x26FFFFFF),
    muted: Color(0xFF27272A),
    mutedForeground: Color(0xFF9F9FA9),
    popover: Color(0xFF18181B),
    popoverForeground: Color(0xFFFAFAFA),
    primary: Color(0xFF00BC7D),
    primaryForeground: Color(0xFF0D542B),
    ring: Color(0xFF008236),
    secondary: Color(0xFF27272A),
    secondaryForeground: Color(0xFFFAFAFA),
    sidebar: Color(0xFF18181B),
    sidebarAccent: Color(0xFF27272A),
    sidebarAccentForeground: Color(0xFFFAFAFA),
    sidebarBorder: Color(0x1AFFFFFF),
    sidebarForeground: Color(0xFFFAFAFA),
    sidebarPrimary: Color(0xFF00BC7D),
    sidebarPrimaryForeground: Color(0xFF0D542B),
    sidebarRing: Color(0xFF008236),
  );

  static const lightOrange = ColorScheme(
    accent: Color(0xFFF4F4F5),
    accentForeground: Color(0xFF18181B),
    background: Color(0xFFFFFFFF),
    border: Color(0xFFE4E4E7),
    brightness: Brightness.light,
    card: Color(0xFFFFFFFF),
    cardForeground: Color(0xFF09090B),
    chart1: Color(0xFFF54900),
    chart2: Color(0xFF009689),
    chart3: Color(0xFF104E64),
    chart4: Color(0xFFFFB900),
    chart5: Color(0xFFFE9A00),
    destructive: Color(0xFFE7000B),
    foreground: Color(0xFF09090B),
    input: Color(0xFFE4E4E7),
    muted: Color(0xFFF4F4F5),
    mutedForeground: Color(0xFF71717B),
    popover: Color(0xFFFFFFFF),
    popoverForeground: Color(0xFF09090B),
    primary: Color(0xFFFF6900),
    primaryForeground: Color(0xFFFFF7ED),
    ring: Color(0xFFFF6900),
    secondary: Color(0xFFF4F4F5),
    secondaryForeground: Color(0xFF18181B),
    sidebar: Color(0xFFFAFAFA),
    sidebarAccent: Color(0xFFF4F4F5),
    sidebarAccentForeground: Color(0xFF18181B),
    sidebarBorder: Color(0xFFE4E4E7),
    sidebarForeground: Color(0xFF09090B),
    sidebarPrimary: Color(0xFFFF6900),
    sidebarPrimaryForeground: Color(0xFFFFF7ED),
    sidebarRing: Color(0xFFFF6900),
  );

  static const darkOrange = ColorScheme(
    accent: Color(0xFF27272A),
    accentForeground: Color(0xFFFAFAFA),
    background: Color(0xFF09090B),
    border: Color(0x1AFFFFFF),
    brightness: Brightness.dark,
    card: Color(0xFF18181B),
    cardForeground: Color(0xFFFAFAFA),
    chart1: Color(0xFF1447E6),
    chart2: Color(0xFF00BC7D),
    chart3: Color(0xFFFE9A00),
    chart4: Color(0xFFAD46FF),
    chart5: Color(0xFFFF2056),
    destructive: Color(0xFFFF6467),
    foreground: Color(0xFFFAFAFA),
    input: Color(0x26FFFFFF),
    muted: Color(0xFF27272A),
    mutedForeground: Color(0xFF9F9FA9),
    popover: Color(0xFF18181B),
    popoverForeground: Color(0xFFFAFAFA),
    primary: Color(0xFFF54900),
    primaryForeground: Color(0xFFFFF7ED),
    ring: Color(0xFFF54900),
    secondary: Color(0xFF27272A),
    secondaryForeground: Color(0xFFFAFAFA),
    sidebar: Color(0xFF18181B),
    sidebarAccent: Color(0xFF27272A),
    sidebarAccentForeground: Color(0xFFFAFAFA),
    sidebarBorder: Color(0x1AFFFFFF),
    sidebarForeground: Color(0xFFFAFAFA),
    sidebarPrimary: Color(0xFFF54900),
    sidebarPrimaryForeground: Color(0xFFFFF7ED),
    sidebarRing: Color(0xFFF54900),
  );

  static const lightRed = ColorScheme(
    accent: Color(0xFFF4F4F5),
    accentForeground: Color(0xFF18181B),
    background: Color(0xFFFFFFFF),
    border: Color(0xFFE4E4E7),
    brightness: Brightness.light,
    card: Color(0xFFFFFFFF),
    cardForeground: Color(0xFF09090B),
    chart1: Color(0xFFF54900),
    chart2: Color(0xFF009689),
    chart3: Color(0xFF104E64),
    chart4: Color(0xFFFFB900),
    chart5: Color(0xFFFE9A00),
    destructive: Color(0xFFE7000B),
    foreground: Color(0xFF09090B),
    input: Color(0xFFE4E4E7),
    muted: Color(0xFFF4F4F5),
    mutedForeground: Color(0xFF71717B),
    popover: Color(0xFFFFFFFF),
    popoverForeground: Color(0xFF09090B),
    primary: Color(0xFFFB2C36),
    primaryForeground: Color(0xFFFEF2F2),
    ring: Color(0xFFFB2C36),
    secondary: Color(0xFFF4F4F5),
    secondaryForeground: Color(0xFF18181B),
    sidebar: Color(0xFFFAFAFA),
    sidebarAccent: Color(0xFFF4F4F5),
    sidebarAccentForeground: Color(0xFF18181B),
    sidebarBorder: Color(0xFFE4E4E7),
    sidebarForeground: Color(0xFF09090B),
    sidebarPrimary: Color(0xFFFB2C36),
    sidebarPrimaryForeground: Color(0xFFFEF2F2),
    sidebarRing: Color(0xFFFB2C36),
  );

  static const darkRed = ColorScheme(
    accent: Color(0xFF27272A),
    accentForeground: Color(0xFFFAFAFA),
    background: Color(0xFF09090B),
    border: Color(0x1AFFFFFF),
    brightness: Brightness.dark,
    card: Color(0xFF18181B),
    cardForeground: Color(0xFFFAFAFA),
    chart1: Color(0xFF1447E6),
    chart2: Color(0xFF00BC7D),
    chart3: Color(0xFFFE9A00),
    chart4: Color(0xFFAD46FF),
    chart5: Color(0xFFFF2056),
    destructive: Color(0xFFFF6467),
    foreground: Color(0xFFFAFAFA),
    input: Color(0x26FFFFFF),
    muted: Color(0xFF27272A),
    mutedForeground: Color(0xFF9F9FA9),
    popover: Color(0xFF18181B),
    popoverForeground: Color(0xFFFAFAFA),
    primary: Color(0xFFFB2C36),
    primaryForeground: Color(0xFFFEF2F2),
    ring: Color(0xFFFB2C36),
    secondary: Color(0xFF27272A),
    secondaryForeground: Color(0xFFFAFAFA),
    sidebar: Color(0xFF18181B),
    sidebarAccent: Color(0xFF27272A),
    sidebarAccentForeground: Color(0xFFFAFAFA),
    sidebarBorder: Color(0x1AFFFFFF),
    sidebarForeground: Color(0xFFFAFAFA),
    sidebarPrimary: Color(0xFFFB2C36),
    sidebarPrimaryForeground: Color(0xFFFEF2F2),
    sidebarRing: Color(0xFFFB2C36),
  );

  static const lightRose = ColorScheme(
    accent: Color(0xFFF4F4F5),
    accentForeground: Color(0xFF18181B),
    background: Color(0xFFFFFFFF),
    border: Color(0xFFE4E4E7),
    brightness: Brightness.light,
    card: Color(0xFFFFFFFF),
    cardForeground: Color(0xFF09090B),
    chart1: Color(0xFFF54900),
    chart2: Color(0xFF009689),
    chart3: Color(0xFF104E64),
    chart4: Color(0xFFFFB900),
    chart5: Color(0xFFFE9A00),
    destructive: Color(0xFFE7000B),
    foreground: Color(0xFF09090B),
    input: Color(0xFFE4E4E7),
    muted: Color(0xFFF4F4F5),
    mutedForeground: Color(0xFF71717B),
    popover: Color(0xFFFFFFFF),
    popoverForeground: Color(0xFF09090B),
    primary: Color(0xFFFF2056),
    primaryForeground: Color(0xFFFFF1F2),
    ring: Color(0xFFFF2056),
    secondary: Color(0xFFF4F4F5),
    secondaryForeground: Color(0xFF18181B),
    sidebar: Color(0xFFFAFAFA),
    sidebarAccent: Color(0xFFF4F4F5),
    sidebarAccentForeground: Color(0xFF18181B),
    sidebarBorder: Color(0xFFE4E4E7),
    sidebarForeground: Color(0xFF09090B),
    sidebarPrimary: Color(0xFFFF2056),
    sidebarPrimaryForeground: Color(0xFFFFF1F2),
    sidebarRing: Color(0xFFFF2056),
  );

  static const darkRose = ColorScheme(
    accent: Color(0xFF27272A),
    accentForeground: Color(0xFFFAFAFA),
    background: Color(0xFF09090B),
    border: Color(0x1AFFFFFF),
    brightness: Brightness.dark,
    card: Color(0xFF18181B),
    cardForeground: Color(0xFFFAFAFA),
    chart1: Color(0xFF1447E6),
    chart2: Color(0xFF00BC7D),
    chart3: Color(0xFFFE9A00),
    chart4: Color(0xFFAD46FF),
    chart5: Color(0xFFFF2056),
    destructive: Color(0xFFFF6467),
    foreground: Color(0xFFFAFAFA),
    input: Color(0x26FFFFFF),
    muted: Color(0xFF27272A),
    mutedForeground: Color(0xFF9F9FA9),
    popover: Color(0xFF18181B),
    popoverForeground: Color(0xFFFAFAFA),
    primary: Color(0xFFFF2056),
    primaryForeground: Color(0xFFFFF1F2),
    ring: Color(0xFFFF2056),
    secondary: Color(0xFF27272A),
    secondaryForeground: Color(0xFFFAFAFA),
    sidebar: Color(0xFF18181B),
    sidebarAccent: Color(0xFF27272A),
    sidebarAccentForeground: Color(0xFFFAFAFA),
    sidebarBorder: Color(0x1AFFFFFF),
    sidebarForeground: Color(0xFFFAFAFA),
    sidebarPrimary: Color(0xFFFF2056),
    sidebarPrimaryForeground: Color(0xFFFFF1F2),
    sidebarRing: Color(0xFFFF2056),
  );

  static const lightViolet = ColorScheme(
    accent: Color(0xFFF4F4F5),
    accentForeground: Color(0xFF18181B),
    background: Color(0xFFFFFFFF),
    border: Color(0xFFE4E4E7),
    brightness: Brightness.light,
    card: Color(0xFFFFFFFF),
    cardForeground: Color(0xFF09090B),
    chart1: Color(0xFFF54900),
    chart2: Color(0xFF009689),
    chart3: Color(0xFF104E64),
    chart4: Color(0xFFFFB900),
    chart5: Color(0xFFFE9A00),
    destructive: Color(0xFFE7000B),
    foreground: Color(0xFF09090B),
    input: Color(0xFFE4E4E7),
    muted: Color(0xFFF4F4F5),
    mutedForeground: Color(0xFF71717B),
    popover: Color(0xFFFFFFFF),
    popoverForeground: Color(0xFF09090B),
    primary: Color(0xFF8E51FF),
    primaryForeground: Color(0xFFF5F3FF),
    ring: Color(0xFF8E51FF),
    secondary: Color(0xFFF4F4F5),
    secondaryForeground: Color(0xFF18181B),
    sidebar: Color(0xFFFAFAFA),
    sidebarAccent: Color(0xFFF4F4F5),
    sidebarAccentForeground: Color(0xFF18181B),
    sidebarBorder: Color(0xFFE4E4E7),
    sidebarForeground: Color(0xFF09090B),
    sidebarPrimary: Color(0xFF8E51FF),
    sidebarPrimaryForeground: Color(0xFFF5F3FF),
    sidebarRing: Color(0xFF8E51FF),
  );

  static const darkViolet = ColorScheme(
    accent: Color(0xFF27272A),
    accentForeground: Color(0xFFFAFAFA),
    background: Color(0xFF09090B),
    border: Color(0x1AFFFFFF),
    brightness: Brightness.dark,
    card: Color(0xFF18181B),
    cardForeground: Color(0xFFFAFAFA),
    chart1: Color(0xFF1447E6),
    chart2: Color(0xFF00BC7D),
    chart3: Color(0xFFFE9A00),
    chart4: Color(0xFFAD46FF),
    chart5: Color(0xFFFF2056),
    destructive: Color(0xFFFF6467),
    foreground: Color(0xFFFAFAFA),
    input: Color(0x26FFFFFF),
    muted: Color(0xFF27272A),
    mutedForeground: Color(0xFF9F9FA9),
    popover: Color(0xFF18181B),
    popoverForeground: Color(0xFFFAFAFA),
    primary: Color(0xFF7F22FE),
    primaryForeground: Color(0xFFF5F3FF),
    ring: Color(0xFF7F22FE),
    secondary: Color(0xFF27272A),
    secondaryForeground: Color(0xFFFAFAFA),
    sidebar: Color(0xFF18181B),
    sidebarAccent: Color(0xFF27272A),
    sidebarAccentForeground: Color(0xFFFAFAFA),
    sidebarBorder: Color(0x1AFFFFFF),
    sidebarForeground: Color(0xFFFAFAFA),
    sidebarPrimary: Color(0xFF7F22FE),
    sidebarPrimaryForeground: Color(0xFFF5F3FF),
    sidebarRing: Color(0xFF7F22FE),
  );

  static const lightYellow = ColorScheme(
    accent: Color(0xFFF4F4F5),
    accentForeground: Color(0xFF18181B),
    background: Color(0xFFFFFFFF),
    border: Color(0xFFE4E4E7),
    brightness: Brightness.light,
    card: Color(0xFFFFFFFF),
    cardForeground: Color(0xFF09090B),
    chart1: Color(0xFFF54900),
    chart2: Color(0xFF009689),
    chart3: Color(0xFF104E64),
    chart4: Color(0xFFFFB900),
    chart5: Color(0xFFFE9A00),
    destructive: Color(0xFFE7000B),
    foreground: Color(0xFF09090B),
    input: Color(0xFFE4E4E7),
    muted: Color(0xFFF4F4F5),
    mutedForeground: Color(0xFF71717B),
    popover: Color(0xFFFFFFFF),
    popoverForeground: Color(0xFF09090B),
    primary: Color(0xFFF0B100),
    primaryForeground: Color(0xFF733E0A),
    ring: Color(0xFFF0B100),
    secondary: Color(0xFFF4F4F5),
    secondaryForeground: Color(0xFF18181B),
    sidebar: Color(0xFFFAFAFA),
    sidebarAccent: Color(0xFFF4F4F5),
    sidebarAccentForeground: Color(0xFF18181B),
    sidebarBorder: Color(0xFFE4E4E7),
    sidebarForeground: Color(0xFF09090B),
    sidebarPrimary: Color(0xFFF0B100),
    sidebarPrimaryForeground: Color(0xFF733E0A),
    sidebarRing: Color(0xFFF0B100),
  );

  static const darkYellow = ColorScheme(
    accent: Color(0xFF27272A),
    accentForeground: Color(0xFFFAFAFA),
    background: Color(0xFF09090B),
    border: Color(0x1AFFFFFF),
    brightness: Brightness.dark,
    card: Color(0xFF18181B),
    cardForeground: Color(0xFFFAFAFA),
    chart1: Color(0xFF1447E6),
    chart2: Color(0xFF00BC7D),
    chart3: Color(0xFFFE9A00),
    chart4: Color(0xFFAD46FF),
    chart5: Color(0xFFFF2056),
    destructive: Color(0xFFFF6467),
    foreground: Color(0xFFFAFAFA),
    input: Color(0x26FFFFFF),
    muted: Color(0xFF27272A),
    mutedForeground: Color(0xFF9F9FA9),
    popover: Color(0xFF18181B),
    popoverForeground: Color(0xFFFAFAFA),
    primary: Color(0xFFF0B100),
    primaryForeground: Color(0xFF733E0A),
    ring: Color(0xFFA65F00),
    secondary: Color(0xFF27272A),
    secondaryForeground: Color(0xFFFAFAFA),
    sidebar: Color(0xFF18181B),
    sidebarAccent: Color(0xFF27272A),
    sidebarAccentForeground: Color(0xFFFAFAFA),
    sidebarBorder: Color(0x1AFFFFFF),
    sidebarForeground: Color(0xFFFAFAFA),
    sidebarPrimary: Color(0xFFF0B100),
    sidebarPrimaryForeground: Color(0xFF733E0A),
    sidebarRing: Color(0xFFA65F00),
  );

  static ColorScheme blue(ThemeMode mode) {
    assert(() {
      _assertNotThemeModeSystem(mode, 'Blue');

      return true;
    }());

    return mode == ThemeMode.light ? lightBlue : darkBlue;
  }

  static ColorScheme defaultcolor(ThemeMode mode) {
    assert(() {
      _assertNotThemeModeSystem(mode, 'DefaultColor');

      return true;
    }());

    return mode == ThemeMode.light ? lightDefaultColor : darkDefaultColor;
  }

  static ColorScheme green(ThemeMode mode) {
    assert(() {
      _assertNotThemeModeSystem(mode, 'Green');

      return true;
    }());

    return mode == ThemeMode.light ? lightGreen : darkGreen;
  }

  static ColorScheme orange(ThemeMode mode) {
    assert(() {
      _assertNotThemeModeSystem(mode, 'Orange');

      return true;
    }());

    return mode == ThemeMode.light ? lightOrange : darkOrange;
  }

  static ColorScheme red(ThemeMode mode) {
    assert(() {
      _assertNotThemeModeSystem(mode, 'Red');

      return true;
    }());

    return mode == ThemeMode.light ? lightRed : darkRed;
  }

  static ColorScheme rose(ThemeMode mode) {
    assert(() {
      _assertNotThemeModeSystem(mode, 'Rose');

      return true;
    }());

    return mode == ThemeMode.light ? lightRose : darkRose;
  }

  static ColorScheme violet(ThemeMode mode) {
    assert(() {
      _assertNotThemeModeSystem(mode, 'Violet');

      return true;
    }());

    return mode == ThemeMode.light ? lightViolet : darkViolet;
  }

  static ColorScheme yellow(ThemeMode mode) {
    assert(() {
      _assertNotThemeModeSystem(mode, 'Yellow');

      return true;
    }());

    return mode == ThemeMode.light ? lightYellow : darkYellow;
  }
}
