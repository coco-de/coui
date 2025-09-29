import 'package:flutter/material.dart';
import 'package:i10n/i10n.dart';
import 'package:coui_widgetbook/add_on/slang_addon.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

import 'main.directories.g.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  LocaleSettings.useDeviceLocale();

  runApp(TranslationProvider(child: WidgetbookApp()));
}

/// WidgetbookApp 위젯
@App()
class WidgetbookApp extends StatelessWidget {
  /// WidgetbookApp 생성자
  WidgetbookApp({super.key});

  final List<Breakpoint> _breakpoints = <Breakpoint>[
    const Breakpoint(end: Constant.mobileBreakpoint, name: MOBILE, start: 0),
    const Breakpoint(
      end: Constant.tabletBreakpoint,
      name: TABLET,
      start: Constant.mobileBreakpoint + 1,
    ),
    const Breakpoint(
      end: double.infinity,
      name: DESKTOP,
      start: Constant.tabletBreakpoint + 1,
    ),
  ];

  List<Condition<double>> _getResponsiveWidth(BuildContext context) =>
      <Condition<double>>[
        const Condition<double>.equals(
          name: MOBILE,
          value: Constant.mobileBreakpoint,
        ),
        const Condition<double>.equals(
          name: TABLET,
          value: Constant.tabletBreakpoint,
        ),
        Condition<double>.equals(name: DESKTOP, value: context.screenWidth),
      ];

  @override
  Widget build(BuildContext context) {
    return Widgetbook.material(
      addons: [
        ViewportAddon(Viewports.all),
        InspectorAddon(),
        SlangAddon(
          initialLocale: TranslationProvider.of(context).flutterLocale,
          locales: AppLocaleUtils.supportedLocales,
          localizationsDelegates: [
            DefaultMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
          ],
        ),
        MaterialThemeAddon(
          themes: [
            WidgetbookTheme(data: AppTheme.lightTheme, name: 'Light'),
            WidgetbookTheme(data: AppTheme.darkTheme, name: 'Dark'),
          ],
        ),
        AlignmentAddon(initialAlignment: Alignment.topLeft),
        TextScaleAddon(initialScale: 1),
        BuilderAddon(
          builder: (_, child) => ResponsiveBreakpoints.builder(
            breakpoints: _breakpoints,
            child: Builder(
              builder: (BuildContext context) => ResponsiveScaledBox(
                width: ResponsiveValue<double>(
                  context,
                  conditionalValues: _getResponsiveWidth(context),
                  defaultValue: Constant.mobileBreakpoint,
                ).value,
                child: child,
              ),
            ),
          ),
          name: 'SafeArea',
        ),
      ],
      appBuilder: (context, child) => child,
      directories: directories,
      initialRoute: '/StorePage',
    );
  }
}
