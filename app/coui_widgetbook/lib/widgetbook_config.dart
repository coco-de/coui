import 'package:coui_flutter/coui_flutter.dart';
import 'package:coui_i10n/coui_i10n.dart';
import 'package:coui_widgetbook/add_on/slang_addon.dart';
import 'package:coui_widgetbook/add_on/surface_material_addon.dart';
import 'package:coui_widgetbook/components.g.dart';
import 'package:coui_widgetbook/preview/surface_preview.dart';
import 'package:flutter/material.dart' as material;
import 'package:widgetbook/widgetbook.dart';

/// Creates the same preview environment for the app and its regression tests.
Config createWidgetbookConfig({String initialRoute = '/'}) {
  return Config(
    initialRoute: initialRoute,
    components: components,
    // TranslationProvider uses one process-wide GlobalKey. Docs renders many
    // previews at once; SlangAddon installs a keyless locale scope per preview.
    appBuilder: (context, child) => material.Material(
      type: material.MaterialType.transparency,
      child: child,
    ),
    addons: [
      SurfaceMaterialAddon(),
      ThemeAddon<ThemeData>(
        {
          'Light': ThemeData.fromCore(CoreThemePresets.light),
          // the first entry is the initial theme.
          'Dark': ThemeData.fromCore(CoreThemePresets.dark),
        },
        (context, theme, child) => CoUILayer(
          theme: theme,
          surfaceStyle: SurfaceStyleScope.of(context),
          // CoUILayer already provides ToastLayer and the backdrop hosts.
          builder: (context, _) => ColoredBox(
            key: const ValueKey('widgetbook-preview-surface'),
            color: Theme.of(context).colorScheme.surface.toValue(),
            child: SurfacePreviewBackground(child: child),
          ),
        ),
      ),
      SlangAddon(
        locales: AppLocaleUtils.supportedLocales,
        initialLocale: LocaleSettings.currentLocale.flutterLocale,
        localizationsDelegates: const [
          CoUILocalizationsDelegate.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      ),
      AlignmentAddon(),
      TextScaleAddon(),
    ],
  );
}
