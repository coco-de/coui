import 'package:coui_flutter/coui_flutter.dart' show CoUILocalizationsDelegate;
import 'package:cupertino_ui/cupertino_ui.dart' as cupertino;
import 'package:flutter/widgets.dart'
    show DefaultWidgetsLocalizations, Locale, Localizations, Widget;
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:material_ui/material_ui.dart' as material;

/// Supplies the localization infrastructure of the canonical docs app.
///
/// DocsApp uses CoUIApp's sole default supported locale, en-US. Keep its
/// delegate order and application-level policy without adding an app shell,
/// theme, or layout constraints to the existing capture tree.
Widget captureLocalizations({required Widget child}) => Localizations(
  locale: const Locale('en', 'US'),
  isApplicationLevel: true,
  delegates: const [
    GlobalWidgetsLocalizations.delegate,
    material.GlobalMaterialLocalizations.delegate,
    cupertino.GlobalCupertinoLocalizations.delegate,
    material.DefaultMaterialLocalizations.delegate,
    cupertino.DefaultCupertinoLocalizations.delegate,
    DefaultWidgetsLocalizations.delegate,
    CoUILocalizationsDelegate.delegate,
  ],
  child: child,
);
