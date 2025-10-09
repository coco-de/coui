import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:coui_widgetbook/add_on/slang_addon.dart';
import 'package:coui_widgetbook/main.directories.g.dart';
import 'package:flutter/material.dart';
import 'package:i10n/i10n.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  LocaleSettings.useDeviceLocale();

  runApp(TranslationProvider(child: const WidgetbookApp()));
}

/// Main Widgetbook application for component showcase.
@App()
class WidgetbookApp extends StatelessWidget {
  /// Creates a WidgetbookApp instance.
  const WidgetbookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Widgetbook.material(
      directories: directories,
      appBuilder: (context, child) {
        // This is a temporary solution to apply the coui theme.
        // A custom theme addon would be a better approach for theme switching.
        final isDark = context.knobs.boolean(
          label: 'Dark Mode',
        );

        return coui.Theme(
          data: isDark ? const coui.ThemeData.dark() : const coui.ThemeData(),
          child: child,
        );
      },
      addons: [
        ViewportAddon([...Viewports.all]),
        InspectorAddon(),
        SlangAddon(
          locales: AppLocaleUtils.supportedLocales,
          localizationsDelegates: const [
            DefaultMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
          ],
          initialLocale: TranslationProvider.of(context).flutterLocale,
        ),
        AlignmentAddon(),
        TextScaleAddon(initialScale: 1),
      ],
    );
  }
}
