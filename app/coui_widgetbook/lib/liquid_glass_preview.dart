import 'package:coui_flutter/coui_flutter.dart';
import 'package:coui_widgetbook/preview/liquid_glass_navigation_demo.dart';

/// Standalone native rendering preview of the same Widgetbook use case.
void main() => runApp(
  CoUIApp(
    theme: ThemeData.fromCore(CoreThemePresets.light),
    debugShowCheckedModeBanner: false,
    home: const LiquidGlassNavigationDemo(groupedToolbar: true),
  ),
);
