import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:flutter/material.dart';
import 'package:i10n/i10n.dart';
import 'package:coui_widgetbook/add_on/slang_addon.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

import 'main.directories.g.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  LocaleSettings.useDeviceLocale();

  runApp(TranslationProvider(child: const WidgetbookApp()));
}

@App()
class WidgetbookApp extends StatelessWidget {
  const WidgetbookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Widgetbook.material(
      addons: [
        ViewportAddon([
          ...Viewports.all,
        ]),
        InspectorAddon(),
        SlangAddon(
          initialLocale: TranslationProvider.of(context).flutterLocale,
          locales: AppLocaleUtils.supportedLocales,
          localizationsDelegates: const [
            DefaultMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
          ],
        ),
        AlignmentAddon(initialAlignment: Alignment.center),
        TextScaleAddon(initialScale: 1),
      ],
      appBuilder: (context, child) {
        // This is a temporary solution to apply the coui theme.
        // A custom theme addon would be a better approach for theme switching.
        final isDark = context.knobs.boolean(
          label: 'Dark Mode'
        );

        return coui.Theme(
          data: isDark ? const coui.ThemeData.dark() : const coui.ThemeData(),
          child: child,
        );
      },
      directories: directories,
    );
  }
}
