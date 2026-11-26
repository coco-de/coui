import 'package:coui_core/coui_core.dart';

/// Configuration for an app whose initial setup follows the theming guide.
String surfaceSetupCode({required CoreSurfaceStyleId style, required bool dark, required bool forFlutter}) {
  final mode = dark ? 'dark' : 'light';
  if (forFlutter) {
    return '''import 'package:coui_flutter/coui_flutter.dart';

CoUIApp(
  theme: ThemeData.fromCore(CoreThemePresets.light),
  darkTheme: ThemeData.fromCore(CoreThemePresets.dark),
  themeMode: CoreThemeMode.$mode,
  surfaceStyle: CoreSurfaceStyleId.${style.name},
  home: const MyHomePage(),
)''';
  }
  return '''import 'package:coui_web/coui_web.dart';

// 테마 가이드에 따라 head에 ThemeConfig의 CSS 변수를 설정한 앱 기준입니다.
SurfaceStyleScope.setSurfaceStyle(CoreSurfaceStyleId.${style.name});
CoUIThemeController.setTheme(CoUIThemeController.$mode);

CoUIWeb(
  theme: ThemeData.coui,
  child: const MyHomePage(),
)''';
}
