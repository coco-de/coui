import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/cupertino.dart' as c;
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart'
    show GestureVelocityTrackerBuilder, MultitouchDragStrategy;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/material.dart' as m;
import 'package:flutter/rendering.dart' as r show Selectable;
import 'package:flutter/services.dart';
import 'package:coui_flutter/coui_flutter.dart';

import 'package:coui_flutter/src/layout_gated_selection.dart';
import 'package:coui_flutter/src/platform_interface.dart'
    if (dart.library.js_interop) 'platform/platform_implementations_web.dart';

/// Default capacity of the app-root recent-colors history (matches
/// `RecentColorsScope`'s own default).
const _kDefaultMaxRecentColors = 10;

class CoUIApp extends StatefulWidget {
  const CoUIApp({
    this.actions,
    this.background,
    this.builder,
    this.color,
    this.cupertinoTheme,
    this.darkTheme,
    this.highContrastTheme,
    this.highContrastDarkTheme,
    this.surfaceStyle = CoreSurfaceStyleId.defaultId,
    this.surfaceTuning = .none,
    this.reduceTransparency = false,
    this.adaptiveQuality,
    this.density = CoreDensity.defaultDensity,
    this.typographyTier,
    this.debugShowCheckedModeBanner = true,
    this.debugShowMaterialGrid = false,
    this.disableBrowserContextMenu = true,
    this.enableScrollInterception = true,
    this.enableThemeAnimation = true,
    this.enableWebTextSelection = true,
    this.home,
    this.initialRecentColors = const [],
    this.initialRoute,
    super.key,
    this.locale,
    this.localeListResolutionCallback,
    this.localeResolutionCallback,
    this.localizationsDelegates,
    this.materialTheme,
    this.maxRecentColors = _kDefaultMaxRecentColors,
    this.navigatorKey,
    this.navigatorObservers = const [],
    this.onGenerateInitialRoutes,
    this.onGenerateRoute,
    this.onGenerateTitle,
    this.onNavigationNotification,
    this.onRecentColorsChanged,
    this.onUnknownRoute,
    this.pixelSnap = true,
    this.restorationScopeId,
    this.routes = const {},
    this.scaling,
    this.scrollBehavior,
    this.shortcuts,
    this.showPerformanceOverlay = false,
    this.showSemanticsDebugger = false,
    this.supportedLocales = const [Locale('en', 'US')],
    required this.theme,
    this.themeMode = CoreThemeMode.system,
    this.title = '',
  }) : routeInformationProvider = null,
       routeInformationParser = null,
       routerDelegate = null,
       backButtonDispatcher = null,
       routerConfig = null;

  const CoUIApp.router({
    this.actions,
    this.backButtonDispatcher,
    this.background,
    this.builder,
    this.color,
    this.cupertinoTheme,
    this.darkTheme,
    this.highContrastTheme,
    this.highContrastDarkTheme,
    this.surfaceStyle = CoreSurfaceStyleId.defaultId,
    this.surfaceTuning = .none,
    this.reduceTransparency = false,
    this.adaptiveQuality,
    this.density = CoreDensity.defaultDensity,
    this.typographyTier,
    this.debugShowCheckedModeBanner = true,
    this.debugShowMaterialGrid = false,
    this.disableBrowserContextMenu = true,
    this.enableScrollInterception = false,
    this.enableThemeAnimation = true,
    this.enableWebTextSelection = true,
    this.initialRecentColors = const [],
    super.key,
    this.locale,
    this.localeListResolutionCallback,
    this.localeResolutionCallback,
    this.localizationsDelegates,
    this.materialTheme,
    this.maxRecentColors = _kDefaultMaxRecentColors,
    this.onGenerateTitle,
    this.onNavigationNotification,
    this.onRecentColorsChanged,
    this.pixelSnap = true,
    this.restorationScopeId,
    this.routeInformationParser,
    this.routeInformationProvider,
    this.routerConfig,
    this.routerDelegate,
    this.scaling,
    this.scrollBehavior,
    this.shortcuts,
    this.showPerformanceOverlay = false,
    this.showSemanticsDebugger = false,
    this.supportedLocales = const [Locale('en', 'US')],
    required this.theme,
    this.themeMode = CoreThemeMode.system,
    this.title = '',
  }) : assert(routerDelegate != null || routerConfig != null),
       navigatorObservers = null,
       navigatorKey = null,
       onGenerateRoute = null,
       home = null,
       onGenerateInitialRoutes = null,
       onUnknownRoute = null,
       routes = null,
       initialRoute = null;

  final GlobalKey<NavigatorState>? navigatorKey;

  /// The size, text and radius scaling applied to [theme].
  ///
  /// With `null`, [AdaptiveScaler.defaultScaling] for [theme]'s platform —
  /// `1` on every platform today, the size the web renders at. An app that
  /// wants larger sizing on some platform passes its own factor, e.g.
  /// `AdaptiveScaling(1.25)`.
  final AdaptiveScaling? scaling;

  final Widget? home;

  final Map<String, WidgetBuilder>? routes;

  final String? initialRoute;

  final RouteFactory? onGenerateRoute;

  final InitialRouteListFactory? onGenerateInitialRoutes;

  final RouteFactory? onUnknownRoute;

  final NotificationListenerCallback<NavigationNotification>?
  onNavigationNotification;

  final List<NavigatorObserver>? navigatorObservers;

  final RouteInformationProvider? routeInformationProvider;

  final RouteInformationParser<Object>? routeInformationParser;

  final RouterDelegate<Object>? routerDelegate;

  final BackButtonDispatcher? backButtonDispatcher;

  final RouterConfig<Object>? routerConfig;

  final TransitionBuilder? builder;

  final String title;

  final GenerateAppTitle? onGenerateTitle;

  final ThemeData theme;
  final ThemeData? darkTheme;

  /// Theme used when the platform reports a high-contrast preference.
  ///
  /// Mirrors `MaterialApp.highContrastTheme`. Build it from the same
  /// colours as [theme] — `CouiSemanticColors.from(CouiColorPresets.source)
  /// .highContrastLight` for the CoUI look, or
  /// `CouiSemanticColors(palette).highContrastLight` for a brand's
  /// generated palette. The preference raises contrast on the *same*
  /// semantic slots, so no component learns that the mode exists.
  ///
  /// When null the ordinary [theme] is used, which is the correct fallback:
  /// an app that has not defined a high-contrast set should keep working,
  /// not render an unreviewed one.
  final ThemeData? highContrastTheme;

  /// Dark counterpart of [highContrastTheme].
  final ThemeData? highContrastDarkTheme;

  /// The surface style this app renders in.
  ///
  /// Published to the subtree so anything that needs to know which style is
  /// active can read it, and switched by rebuilding with a different value.
  /// The style reaches components by having already been applied where the
  /// palette resolves — `resolveThemeScheme(..., surfaceStyle:)` — which is
  /// the same single seat brightness and high contrast sit at. Components
  /// never read the style themselves, so none of them can be the one that
  /// forgets to.
  final CoreSurfaceStyleId surfaceStyle;

  /// What this app changes about that style.
  ///
  /// A preset ships one set of numbers; this is how an app states its
  /// own corners, cast and border weight without re-authoring the style.
  /// It reaches components the same way the style does — already folded
  /// in where the recipe resolves (`resolveThemeRecipe`) — so no
  /// component reads it and none of them can be the one that forgets to.
  final CoreSurfaceTuning surfaceTuning;

  /// Whether the platform's "reduce transparency" setting is on.
  ///
  /// Taken rather than read, because Flutter offers nothing to read it
  /// with: `AccessibilityFeatures` exposes reduce-motion, high contrast,
  /// invert colours, bold text, accessible navigation and on/off switch
  /// labels — and nothing for transparency, though the OS setting exists
  /// on Apple platforms. An app that obtains it by its own means passes
  /// it here and the surface seat applies the same fallback the Web
  /// stylesheet applies to `prefers-reduced-transparency`: an opaque
  /// fill and no backdrop pass, with the edge band kept.
  ///
  /// Defaults to off, so an app that says nothing renders exactly as
  /// before.
  final bool reduceTransparency;

  /// Lets the app trade the glass for smoothness when the device cannot hold
  /// the display's rate — or fixes the trade. Off (`null`) by default.
  ///
  /// A theme axis beside [reduceTransparency], applied where it is: each
  /// surface goes without the bend at its rim, then without its backdrop pass,
  /// as the frames it is drawn in take too long
  /// ([CoreQualityTier], [CoreQualityLadder]). The tier is folded into the
  /// theme where the recipe becomes a material (`applySurfaceStyle`), so no
  /// component reads it and none of them can be the one that forgets to; a
  /// tier never adds an effect the style did not state.
  ///
  /// What it states: [CoreAdaptiveQuality.forced] holds a tier without
  /// measuring; [CoreAdaptiveQuality.initialQuality] starts at a tier an
  /// earlier session settled on, so a repeat launch skips the warm-up;
  /// [CoreAdaptiveQuality.onQualityChanged] hears each change with the
  /// measurement behind it.
  ///
  /// The frames measured are the engine's raster times, judged against the
  /// display's refresh rate. A reduce-transparency preference is the lowest
  /// tier whatever is stated here, and nothing is measured while it holds.
  /// Read the tier with [AdaptiveQualityScope.of]; hold measurement around
  /// heavy work of your own with [AdaptiveQualityScope.holdMeasurement].
  final CoreAdaptiveQuality? adaptiveQuality;

  /// How tightly this app sets its spacing, its control rows and the
  /// corners that follow those rows.
  ///
  /// A theme axis beside [surfaceStyle], published and switched the same
  /// way: the app reads it through [DensityScope] and switches it by
  /// rebuilding with a different value. It reaches components by having
  /// been folded into the theme's geometry where the style is
  /// (`applySurfaceStyle`), and every conversion of a spacing, an inset, a
  /// control row or a corner already takes that geometry. No component
  /// reads the density itself, so none of them can be the one that forgets
  /// to.
  ///
  /// Each value moves one rung on the scale it already sits on (see
  /// [CoreDensity]) rather than by a factor. Defaults to
  /// [CoreDensity.standard] — the values as authored, so an app that says
  /// nothing renders exactly as before.
  final CoreDensity density;

  /// The typography tier this app's headings are drawn at, or `null` to
  /// follow the viewport.
  ///
  /// A theme axis beside [density]. The display and headline roles step
  /// down with the width of the view — below 768px to the mobile sizes,
  /// below 1024px to the tablet ones ([CoreHeadingSizes.couiByTier]) — and
  /// every other role keeps one size. It reaches components by having been
  /// folded into the theme's typography where the style is
  /// (`applySurfaceStyle`), so every text that takes a role from the theme
  /// follows it and no component reads the tier itself.
  ///
  /// With `null`, the default, the tier is the one the viewport's width
  /// resolves to ([CoreBreakpoint.forWidth]). The theme is folded again
  /// only when the width crosses into another tier, so a resize inside one
  /// rebuilds nothing below the root. A value pins the tier at every
  /// width: [CoreBreakpointTier.desktop] keeps the sizes as authored, which
  /// is what an app whose view is not the screen — an embed, a preview —
  /// states. A subtree takes another tier with [TypographyTierScope].
  final CoreBreakpointTier? typographyTier;
  final CoreThemeMode themeMode;
  final Color? color;
  final Color? background;
  final Locale? locale;

  final Iterable<LocalizationsDelegate<dynamic>>? localizationsDelegates;
  final LocaleListResolutionCallback? localeListResolutionCallback;
  final LocaleResolutionCallback? localeResolutionCallback;
  final Iterable<Locale> supportedLocales;
  final bool showPerformanceOverlay;
  final bool showSemanticsDebugger;
  final bool debugShowCheckedModeBanner;
  final Map<ShortcutActivator, Intent>? shortcuts;
  final Map<Type, Action<Intent>>? actions;
  final String? restorationScopeId;
  final ScrollBehavior? scrollBehavior;
  final bool debugShowMaterialGrid;
  final m.ThemeData? materialTheme;
  final c.CupertinoThemeData? cupertinoTheme;
  final bool disableBrowserContextMenu;

  /// Initial recent-color history for the app-root [RecentColorsScope]
  /// (most-recent-first). Seed it from persisted storage to restore the
  /// user's palette across launches.
  final List<CoreColor> initialRecentColors;

  /// Maximum retained entries in the app-root recent-color history.
  final int maxRecentColors;

  /// Fired whenever the app-root recent-color history mutates, so the
  /// host app can persist it (e.g. write to local storage).
  final void Function(List<CoreColor> colors)? onRecentColorsChanged;

  final bool pixelSnap;
  final bool enableScrollInterception;
  final bool enableThemeAnimation;

  /// Whether running on the web makes text selectable by default.
  ///
  /// Browsers let users drag-select any text, but Flutter renders to a
  /// canvas where `Text` is not selectable unless wrapped in a
  /// `SelectionArea`. When true (default) and running on the web, the
  /// whole app content is wrapped in a selection scope so labels, values
  /// and body copy behave like native web text. Has no effect off-web.
  final bool enableWebTextSelection;

  @override
  State<CoUIApp> createState() => _CoUIAppState();
}

/// CoUI's scroll behavior — bouncing physics, the design-system
/// scrollbar on desktop, and a layout gate inside every `Scrollable`'s
/// chrome.
///
/// The gate keeps text a covered, never-laid-out page builds out of the
/// scrollable's selection ordering until it has a size (#5361). A
/// behavior that extends this one and leaves both builders to it — or
/// calls `super` from its own — keeps the gate; one that replaces the
/// ambient behavior with a plain [ScrollBehavior] does not.
class CoUIScrollBehavior extends ScrollBehavior {
  const CoUIScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics();
  }

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    child = LayoutGatedSelectionScope(child: child);
    // When modifying this function, consider modifying the implementation in
    // the base class ScrollBehavior as well.
    switch (axisDirectionToAxis(details.direction)) {
      case .horizontal:
        return child;

      case .vertical:
        switch (getPlatform(context)) {
          case .linux:
          case .macOS:
          case .windows:
            return Scrollbar(controller: details.controller, child: child);

          case .android:
          case .fuchsia:
          case .iOS:
            return child;
        }
    }
  }

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    child = LayoutGatedSelectionScope(child: child);
    // When modifying this function, consider modifying the implementation in
    // the base class ScrollBehavior as well.
    switch (getPlatform(context)) {
      case .iOS:
      case .linux:
      case .macOS:
      case .windows:
        return child;

      case .android:
        return StretchingOverscrollIndicator(
          axisDirection: details.direction,
          clipBehavior: details.decorationClipBehavior ?? .hardEdge,
          child: child,
        );

      case .fuchsia:
        break;
    }

    return GlowingOverscrollIndicator(
      axisDirection: details.direction,
      color: Theme.of(context).colorScheme.secondary.toValue(),
      child: child,
    );
  }
}

class _CoUIAppState extends State<CoUIApp> {
  late HeroController _heroController;

  @override
  void initState() {
    super.initState();
    CoUIFlutterPlatformImplementations.onThemeChanged(widget.theme);
    _warmUpRefraction();
    _heroController = HeroController(
      createRectTween: (begin, end) {
        return CoUIRectArcTween(begin: begin, end: end);
      },
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _dispatchAppInitialized();
    });
    if (kIsWeb) {
      // BrowserContextMenu uses a platform channel that throws when no
      // host (e.g. embedded Flutter Web inside jaspr) is registered. Wrap
      // so the host check fails gracefully instead of crashing the app
      // tree on every (re)mount — including light/dark theme switches.
      unawaited(_applyBrowserContextMenu());
    }
  }

  Future<void> _applyBrowserContextMenu() async {
    try {
      if (widget.disableBrowserContextMenu) {
        await BrowserContextMenu.disableContextMenu();
      } else {
        await BrowserContextMenu.enableContextMenu();
      }
    } catch (_) {}
    // The flag changes when the channel call resolves — after the first
    // frame. The web selection scope keys on it, so tell it to look again.
    _browserContextMenuSettled.value = BrowserContextMenu.enabled;
  }

  void _dispatchAppInitialized() {
    CoUIFlutterPlatformImplementations.onAppInitialized();
  }

  /// Asks for the refraction program the moment the style is known to
  /// bend, so the first surface to mount finds it already there instead of
  /// painting one frame flat and snapping. The Web twin makes the same
  /// decision at document level (`SurfaceRefractionHost`); this is the
  /// Flutter seat for it. Idle where the style bends nothing — the recipe
  /// is what states a bend, and tuning cannot add one.
  void _warmUpRefraction() {
    final styles = <CoreSurfaceStyleId?>[widget.surfaceStyle];
    for (final theme in [widget.theme, widget.darkTheme]) {
      final components = theme?.coreComponentTheme;
      styles.addAll([
        components?.appBar?.style?.surfaceStyle,
        components?.navigationBar?.style?.surfaceStyle,
        components?.popup?.style?.surfaceStyle,
        components?.menu?.style?.popupStyle?.surfaceStyle,
        components?.dropdownMenu?.style?.menuStyle?.popupStyle?.surfaceStyle,
        components?.contextMenu?.style?.menuStyle?.popupStyle?.surfaceStyle,
        components?.menubar?.style?.surfaceStyle,
        components?.menubar?.style?.menuPanelStyle?.surfaceStyle,
        ...?components?.menubar?.variantStyles?.values.expand(
          (s) => [s.surfaceStyle, s.menuPanelStyle?.surfaceStyle],
        ),
        ...?components?.appBar?.variantStyles?.values.map(
          (s) => s.surfaceStyle,
        ),
        ...?components?.navigationBar?.variantStyles?.values.map(
          (s) => s.surfaceStyle,
        ),
      ]);
    }
    if (!styles.any(
      (id) => id != null && CoreSurfaceRecipe.of(id).refraction != null,
    ))
      return;

    unawaited(SurfaceRefractionProgram.warmUp());
  }

  Widget handleBuild(BuildContext context, Widget? child) {
    return CoUILayer(
      darkTheme: widget.darkTheme,
      highContrastTheme: widget.highContrastTheme,
      highContrastDarkTheme: widget.highContrastDarkTheme,
      surfaceStyle: widget.surfaceStyle,
      surfaceTuning: widget.surfaceTuning,
      reduceTransparency: widget.reduceTransparency,
      adaptiveQuality: widget.adaptiveQuality,
      density: widget.density,
      typographyTier: widget.typographyTier,
      enableScrollInterception: widget.enableScrollInterception,
      enableThemeAnimation: widget.enableThemeAnimation,
      enableWebTextSelection: widget.enableWebTextSelection,
      initialRecentColors: widget.initialRecentColors,
      maxRecentColors: widget.maxRecentColors,
      onRecentColorsChanged: widget.onRecentColorsChanged,
      pixelSnap: widget.pixelSnap,
      scaling: widget.scaling,
      theme: widget.theme,
      themeMode: widget.themeMode,
      builder: widget.builder,
      child: child,
    );
  }

  Widget _buildWidgetApp(BuildContext context) {
    final primaryColor =
        widget.color ?? widget.theme.colorScheme.primary.toValue();
    return _usesRouter
        ? WidgetsApp.router(
            key: GlobalObjectKey(this),
            routeInformationProvider: widget.routeInformationProvider,
            routeInformationParser: widget.routeInformationParser,
            routerDelegate: widget.routerDelegate,
            routerConfig: widget.routerConfig,
            backButtonDispatcher: widget.backButtonDispatcher,
            title: widget.title,
            onGenerateTitle: widget.onGenerateTitle,
            onNavigationNotification: widget.onNavigationNotification,
            // See non-router branch — bodyMedium for full base style.
            textStyle: widget.theme.typography.bodyMedium
                .toValue(theme: widget.theme)
                .copyWith(color: widget.theme.colorScheme.onSurface.toValue()),
            color: primaryColor,
            locale: widget.locale,
            localizationsDelegates: _localizationsDelegates,
            localeListResolutionCallback: widget.localeListResolutionCallback,
            localeResolutionCallback: widget.localeResolutionCallback,
            supportedLocales: widget.supportedLocales,
            showPerformanceOverlay: widget.showPerformanceOverlay,
            showSemanticsDebugger: widget.showSemanticsDebugger,
            debugShowCheckedModeBanner: widget.debugShowCheckedModeBanner,
            shortcuts: widget.shortcuts,
            actions: widget.actions,
            restorationScopeId: widget.restorationScopeId,
            builder: handleBuild,
          )
        : WidgetsApp(
            key: GlobalObjectKey(this),
            navigatorKey: widget.navigatorKey,
            onGenerateRoute: widget.onGenerateRoute,
            onGenerateInitialRoutes: widget.onGenerateInitialRoutes,
            onUnknownRoute: widget.onUnknownRoute,
            onNavigationNotification: widget.onNavigationNotification,
            navigatorObservers: widget.navigatorObservers!,
            initialRoute: widget.initialRoute,
            // Named routes and `home` open as CoUI pages, so they arrive with
            // the page transition every `RoutePage` uses — the platform's own
            // on iOS and Android, CoUI's fade-and-rise elsewhere.
            pageRouteBuilder:
                <T>(RouteSettings settings, WidgetBuilder builder) {
                  return RoutePageRoute<T>(
                    settings: settings,
                    builder: builder,
                  );
                },
            // MaterialApp implicitly wraps `home` in a `Material` so that
            // child Text widgets pick up the InheritedWidget tree they
            // need for proper baseline/alignment. WidgetsApp does not, so
            // wrap explicitly here to match MaterialApp's behaviour.
            //
            // `textStyle` must be pinned to CoUI's typography baseline:
            // `Material` re-installs `DefaultTextStyle` from the ambient
            // *Material* textTheme (14px / Roboto by default), and this
            // wrapper sits BELOW the CoUI `DefaultTextStyle.merge`
            // (bodyMedium 14 + onSurface) mounted higher in the app
            // chain — without the pin every inheritance-reliant bare
            // `Text` inside `home` silently renders Roboto at Material's
            // own line height and tracking while the Web twin's root
            // cascade serves bodyMedium.
            home: widget.home == null
                ? null
                : m.Material(
                    color: m.Colors.transparent,
                    textStyle: widget.theme.typography.bodyMedium
                        .toValue(theme: widget.theme)
                        .copyWith(
                          color: widget.theme.colorScheme.onSurface.toValue(),
                        ),
                    child: widget.home,
                  ),
            routes: widget.routes!,
            title: widget.title,
            onGenerateTitle: widget.onGenerateTitle,
            // Use the full bodyMedium token (fontSize / height /
            // letterSpacing / fontFamily) so plain `Text` widgets
            // inherit CoUI's typography baseline. Previously this was
            // `theme.typography.sans` which only set fontFamily, leaving
            // fontSize to fall back to Flutter's 14 px system default.
            textStyle: widget.theme.typography.bodyMedium
                .toValue(theme: widget.theme)
                .copyWith(color: widget.theme.colorScheme.onSurface.toValue()),
            color: primaryColor,
            locale: widget.locale,
            localizationsDelegates: _localizationsDelegates,
            localeListResolutionCallback: widget.localeListResolutionCallback,
            localeResolutionCallback: widget.localeResolutionCallback,
            supportedLocales: widget.supportedLocales,
            showPerformanceOverlay: widget.showPerformanceOverlay,
            showSemanticsDebugger: widget.showSemanticsDebugger,
            debugShowCheckedModeBanner: widget.debugShowCheckedModeBanner,
            shortcuts: widget.shortcuts,
            actions: widget.actions,
            restorationScopeId: widget.restorationScopeId,
            builder: handleBuild,
          );
  }

  bool get _usesRouter =>
      widget.routerDelegate != null || widget.routerConfig != null;

  @override
  void didUpdateWidget(covariant CoUIApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.surfaceStyle != oldWidget.surfaceStyle ||
        widget.theme != oldWidget.theme ||
        widget.darkTheme != oldWidget.darkTheme) {
      _warmUpRefraction();
    }
    if (kIsWeb &&
        widget.disableBrowserContextMenu !=
            oldWidget.disableBrowserContextMenu) {
      unawaited(_applyBrowserContextMenu());
    }
    if (widget.theme != oldWidget.theme) {
      CoUIFlutterPlatformImplementations.onThemeChanged(widget.theme);
    }
  }

  @override
  void dispose() {
    _heroController.dispose();
    super.dispose();
  }

  Iterable<LocalizationsDelegate<dynamic>> get _localizationsDelegates {
    return [
      ...?widget.localizationsDelegates,
      // Ahead of the `Default*` trio, which answers every locale with
      // English strings and — the part that matters here —
      // `TextDirection.ltr` regardless of what the locale is written
      // in. Without this an app set to Arabic laid itself out
      // left-to-right and nothing said so.
      //
      // Consumer delegates still come first, so an app that supplies
      // its own keeps winning.
      GlobalWidgetsLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
      m.DefaultMaterialLocalizations.delegate,
      c.DefaultCupertinoLocalizations.delegate,
      DefaultWidgetsLocalizations.delegate,
      CoUILocalizationsDelegate.delegate,
    ];
  }

  @override
  Widget build(BuildContext context) {
    Widget result = _buildWidgetApp(context);
    assert(() {
      if (widget.debugShowMaterialGrid) {
        const gridInterval = 8.0;
        const gridSubdivisions = 1;
        result = GridPaper(
          color: const Color(0xE0F9BBE0),
          interval: gridInterval,
          subdivisions: gridSubdivisions,
          child: result,
        );
      }

      return true;
    }());

    return m.Theme(
      data:
          widget.materialTheme ??
          m.ThemeData.from(
            colorScheme: m.ColorScheme.fromSeed(
              seedColor: widget.theme.colorScheme.primary.toValue(),
              brightness: widget.theme.brightness,
              primary: widget.theme.colorScheme.primary.toValue(),
              secondary: widget.theme.colorScheme.secondary.toValue(),
              error: widget.theme.colorScheme.error.toValue(),
              surface: widget.theme.colorScheme.surface.toValue(),
            ),
          ),
      child: c.CupertinoTheme(
        data:
            widget.cupertinoTheme ??
            c.CupertinoThemeData(
              brightness: widget.theme.brightness,
              primaryColor: widget.theme.colorScheme.primary.toValue(),
              primaryContrastingColor: widget.theme.colorScheme.onPrimary
                  .toValue(),
              barBackgroundColor: widget.theme.colorScheme.tertiary.toValue(),
              scaffoldBackgroundColor: widget.theme.colorScheme.surface
                  .toValue(),
              applyThemeToAll: true,
            ),
        child: m.Material(
          color: widget.background ?? m.Colors.transparent,
          child: m.ScaffoldMessenger(
            child: ScrollConfiguration(
              behavior: widget.scrollBehavior ?? const CoUIScrollBehavior(),
              child: HeroControllerScope(
                controller: _heroController,
                child: result,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CoUILayer extends StatelessWidget {
  const CoUILayer({
    this.builder,
    this.child,
    this.darkTheme,
    this.highContrastTheme,
    this.highContrastDarkTheme,
    this.surfaceStyle = CoreSurfaceStyleId.defaultId,
    this.surfaceTuning = .none,
    this.reduceTransparency = false,
    this.adaptiveQuality,
    this.density = CoreDensity.defaultDensity,
    this.typographyTier,
    this.enableScrollInterception = false,
    this.enableThemeAnimation = true,
    this.enableWebTextSelection = true,
    this.initialRecentColors = const [],
    super.key,
    this.maxRecentColors = _kDefaultMaxRecentColors,
    this.onRecentColorsChanged,
    this.pixelSnap = true,
    this.scaling,
    required this.theme,
    this.themeMode = CoreThemeMode.system,
  });

  final Widget? child;
  final ThemeData theme;
  final ThemeData? darkTheme;

  /// Theme used when the platform reports a high-contrast preference.
  ///
  /// Mirrors `MaterialApp.highContrastTheme`. Build it from the same
  /// colours as [theme] — `CouiSemanticColors.from(CouiColorPresets.source)
  /// .highContrastLight` for the CoUI look, or
  /// `CouiSemanticColors(palette).highContrastLight` for a brand's
  /// generated palette. The preference raises contrast on the *same*
  /// semantic slots, so no component learns that the mode exists.
  ///
  /// When null the ordinary [theme] is used, which is the correct fallback:
  /// an app that has not defined a high-contrast set should keep working,
  /// not render an unreviewed one.
  final ThemeData? highContrastTheme;

  /// Dark counterpart of [highContrastTheme].
  final ThemeData? highContrastDarkTheme;

  /// The surface style this app renders in.
  ///
  /// Published to the subtree so anything that needs to know which style is
  /// active can read it, and switched by rebuilding with a different value.
  /// The style reaches components by having already been applied where the
  /// palette resolves — `resolveThemeScheme(..., surfaceStyle:)` — which is
  /// the same single seat brightness and high contrast sit at. Components
  /// never read the style themselves, so none of them can be the one that
  /// forgets to.
  final CoreSurfaceStyleId surfaceStyle;

  /// What this app changes about that style.
  ///
  /// A preset ships one set of numbers; this is how an app states its
  /// own corners, cast and border weight without re-authoring the style.
  /// It reaches components the same way the style does — already folded
  /// in where the recipe resolves (`resolveThemeRecipe`) — so no
  /// component reads it and none of them can be the one that forgets to.
  final CoreSurfaceTuning surfaceTuning;

  /// Whether the platform's "reduce transparency" setting is on.
  ///
  /// Taken rather than read, because Flutter offers nothing to read it
  /// with: `AccessibilityFeatures` exposes reduce-motion, high contrast,
  /// invert colours, bold text, accessible navigation and on/off switch
  /// labels — and nothing for transparency, though the OS setting exists
  /// on Apple platforms. An app that obtains it by its own means passes
  /// it here and the surface seat applies the same fallback the Web
  /// stylesheet applies to `prefers-reduced-transparency`: an opaque
  /// fill and no backdrop pass, with the edge band kept.
  ///
  /// Defaults to off, so an app that says nothing renders exactly as
  /// before.
  final bool reduceTransparency;

  /// Lets the app trade the glass for smoothness when the device cannot hold
  /// the display's rate — or fixes the trade. Off (`null`) by default.
  ///
  /// A theme axis beside [reduceTransparency], applied where it is: each
  /// surface goes without the bend at its rim, then without its backdrop pass,
  /// as the frames it is drawn in take too long
  /// ([CoreQualityTier], [CoreQualityLadder]). The tier is folded into the
  /// theme where the recipe becomes a material (`applySurfaceStyle`), so no
  /// component reads it and none of them can be the one that forgets to; a
  /// tier never adds an effect the style did not state.
  ///
  /// What it states: [CoreAdaptiveQuality.forced] holds a tier without
  /// measuring; [CoreAdaptiveQuality.initialQuality] starts at a tier an
  /// earlier session settled on, so a repeat launch skips the warm-up;
  /// [CoreAdaptiveQuality.onQualityChanged] hears each change with the
  /// measurement behind it.
  ///
  /// The frames measured are the engine's raster times, judged against the
  /// display's refresh rate. A reduce-transparency preference is the lowest
  /// tier whatever is stated here, and nothing is measured while it holds.
  /// Read the tier with [AdaptiveQualityScope.of]; hold measurement around
  /// heavy work of your own with [AdaptiveQualityScope.holdMeasurement].
  final CoreAdaptiveQuality? adaptiveQuality;

  /// How tightly this app sets its spacing, its control rows and the
  /// corners that follow those rows.
  ///
  /// A theme axis beside [surfaceStyle], published and switched the same
  /// way: the app reads it through [DensityScope] and switches it by
  /// rebuilding with a different value. It reaches components by having
  /// been folded into the theme's geometry where the style is
  /// (`applySurfaceStyle`), and every conversion of a spacing, an inset, a
  /// control row or a corner already takes that geometry. No component
  /// reads the density itself, so none of them can be the one that forgets
  /// to.
  ///
  /// Each value moves one rung on the scale it already sits on (see
  /// [CoreDensity]) rather than by a factor. Defaults to
  /// [CoreDensity.standard] — the values as authored, so an app that says
  /// nothing renders exactly as before.
  final CoreDensity density;

  /// The typography tier the headings are drawn at, or `null` to follow
  /// the viewport. Mirrors `CoUIApp.typographyTier`, which documents the
  /// axis.
  final CoreBreakpointTier? typographyTier;
  final CoreThemeMode themeMode;

  /// The scaling applied to the theme, or `null` for the platform default.
  /// Mirrors `CoUIApp.scaling`, which documents the default.
  final AdaptiveScaling? scaling;
  final Widget Function(BuildContext context, Widget? child)? builder;
  final bool enableScrollInterception;

  final bool enableThemeAnimation;

  /// Default-selectable text on the web. Mirrors
  /// `CoUIApp.enableWebTextSelection`.
  final bool enableWebTextSelection;

  /// Initial recent-color history seeded into the app-root
  /// [RecentColorsScope]. Mirrors `CoUIApp.initialRecentColors`.
  final List<CoreColor> initialRecentColors;

  /// Maximum retained recent-color entries. Mirrors
  /// `CoUIApp.maxRecentColors`.
  final int maxRecentColors;

  /// Recent-color history mutation callback. Mirrors
  /// `CoUIApp.onRecentColorsChanged`.
  final void Function(List<CoreColor> colors)? onRecentColorsChanged;

  /// Whether to mount a [PixelSnap] scope so descendants can align
  /// dimensions to the physical-pixel grid. Mirrors `CoUIApp.pixelSnap`.
  final bool pixelSnap;

  @override
  Widget build(BuildContext context) => FoldScopeHost(
    // Above everything the layer mounts, so the toasts, a drawer drawn
    // through the backdrop layer and every route below read the same fold.
    child: AdaptiveQualityHost(
      adaptiveQuality: adaptiveQuality,
      reduceTransparency: reduceTransparency,
      child: _ViewportTypographyTier(layer: this),
    ),
  );
}

/// Picks the typography tier for [layer] and builds its body only when the
/// tier changes.
///
/// The tier follows the viewport's width, and the width changes on every
/// frame of a window resize. Reading it in the body would fold the theme
/// again on each of those frames — every fold the body publishes, the app's
/// builder run again and the theme animation restarted — for a value that
/// changes at two widths only. Reading it here, a resize inside one tier
/// costs this build and hands back the same body, which the framework
/// leaves alone; the body's own inputs (brightness, high contrast, pixel
/// ratio) are read in the body's context and rebuild it as before. A pinned
/// tier reads no width, so a resize costs nothing at all.
class _ViewportTypographyTier extends StatefulWidget {
  const _ViewportTypographyTier({required this.layer});

  final CoUILayer layer;

  @override
  State<_ViewportTypographyTier> createState() =>
      _ViewportTypographyTierState();
}

class _ViewportTypographyTierState extends State<_ViewportTypographyTier> {
  _CoUILayerBody? _body;

  @override
  void didUpdateWidget(covariant _ViewportTypographyTier oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A new layer is a new configuration: the cached body describes the
    // old one.
    _body = null;
  }

  @override
  Widget build(BuildContext context) {
    final tier =
        widget.layer.typographyTier ??
        CoreBreakpoint.forWidth(MediaQuery.widthOf(context)).toTier();
    final body = _body;
    if (body != null && body.typographyTier == tier) return body;

    return _body = _CoUILayerBody(layer: widget.layer, typographyTier: tier);
  }
}

/// What [CoUILayer] renders at one typography tier.
class _CoUILayerBody extends StatelessWidget {
  const _CoUILayerBody({required this.layer, required this.typographyTier});

  final CoUILayer layer;

  /// The tier the theme's type scale is folded at.
  final CoreBreakpointTier typographyTier;

  @override
  Widget build(BuildContext context) {
    final appScaling =
        layer.scaling ?? AdaptiveScaler.defaultScaling(layer.theme);
    final platformBrightness = MediaQuery.platformBrightnessOf(context);
    final isDark =
        layer.themeMode == .dark ||
        (layer.themeMode == .system && platformBrightness == .dark);

    // The high-contrast axis sits here, at the point the theme is chosen —
    // the same seat as brightness. It swaps the whole 62-slot scheme for a
    // higher-contrast resolution of the same tokens, so no component reads
    // the preference and none of them can forget to.
    //
    // Falling back to the ordinary theme when no high-contrast set was
    // supplied is deliberate: an app that never defined one should keep
    // working rather than render a set nobody reviewed.
    final highContrast = MediaQuery.highContrastOf(context);
    ThemeData selectedFor({required bool dark}) => dark
        ? ((highContrast ? layer.highContrastDarkTheme : null) ??
              layer.darkTheme ??
              layer.theme)
        : ((highContrast ? layer.highContrastTheme : null) ?? layer.theme);

    // The surface style joins the theme at the same seat, so a style switch
    // rebuilds with it exactly as a brightness switch does. It goes on last
    // of the theme-level axes for the same reason the colour order puts
    // accessibility last: whichever axis writes here last is the one that
    // decides, and that has to be a stated position rather than whichever
    // line happened to be added most recently. The density rides in the
    // same fold, on the geometry the style builds, so a density switch
    // rebuilds the same way; the typography tier rides on the type scale,
    // stepped before the style's weight floor.
    //
    // The fold itself lives in `applySurfaceStyle` so the verification
    // harness can call the *same* function. A harness that reimplements it
    // becomes a second source for preset resolution, and the moment the two
    // drift the checker answers differently from the thing it checks —
    // which is the exact failure this pipeline exists to catch.
    final quality = AdaptiveQualityScope.of(context);
    // The screen's ratio decides how wide a hairline draws, so the fold
    // carries it to the geometry every stroke passes through.
    final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
    ThemeData fold(ThemeData selected, {CoreBreakpointTier? tier}) =>
        appScaling.scale(
          applySurfaceStyle(
            selected,
            surfaceStyle: layer.surfaceStyle,
            highContrast: highContrast,
            surfaceTuning: layer.surfaceTuning,
            reduceTransparency: layer.reduceTransparency,
            quality: quality,
            density: layer.density,
            typographyTier: tier ?? typographyTier,
            devicePixelRatio: devicePixelRatio,
          ),
        );

    final activeSelected = selectedFor(dark: isDark);
    final scaledTheme = fold(activeSelected);

    // The app's theme in each brightness, folded the same way — what a
    // `BrightnessScope` below renders with. Published beside the active one
    // rather than recomputed there, so the two can only differ by brightness.
    //
    // A theme counts for the brightness it *is*, not the slot it was passed
    // in: an app may hand one theme of either brightness to `theme` and
    // switch it itself. A brightness the app gives no theme for is CoUI's
    // preset for it, folded the same way, so a style's colour bends reach it
    // as they reach the active one.
    final otherSelected = selectedFor(dark: !isDark);
    final otherTheme = fold(otherSelected);
    ThemeData publishedFor(CoreBrightness brightness) {
      if (scaledTheme.coreBrightness == brightness) return scaledTheme;
      if (otherTheme.coreBrightness == brightness) return otherTheme;
      final preset = ThemeData.fromCore(switch (brightness) {
        .light => CoreThemePresets.light,
        .dark => CoreThemePresets.dark,
      });

      return fold(
        otherSelected.copyWith(colorScheme: () => preset.colorScheme),
      );
    }

    // The app's type scale at each tier, folded the same way — what a
    // `TypographyTierScope` below renders with, for the same reason the
    // brightness pair is published: a scope that stepped the scale itself
    // would be a second fold, free to differ from this one. The tier in
    // effect is the active theme's own scale.
    CoreTypography typographyAt(CoreBreakpointTier tier) =>
        tier == typographyTier
        ? scaledTheme.typography
        : fold(activeSelected, tier: tier).typography;

    final isLight = scaledTheme.brightness == .light;
    final overlayStyle = SystemUiOverlayStyle(
      statusBarBrightness: isLight ? .light : .dark,
      statusBarIconBrightness: isLight ? .dark : .light,
    );

    final Widget app = AnnotatedRegion(
      value: overlayStyle,
      // Anchored overlays (popover/tooltip/menu) use the unified shared
      // engine (`PopoverOverlayHandler` in `co_popover_overlay.dart`) which
      // each component invokes directly; there is no central overlay manager.
      child: CoUIAnimatedTheme(
        data: scaledTheme,
        duration: layer.enableThemeAnimation ? kDefaultDuration : .zero,
        child: Builder(
          builder: (context) {
            final theme = Theme.of(context);

            // DrawerBackdropLayer sits inside ToastLayer so an open
            // drawer's backdrop transform (shadcn zoom-out) scales the
            // app content but never the toasts stacked above it.
            Widget content = ToastLayer(
              child: DrawerBackdropLayer(
                child: layer.builder == null
                    ? (layer.child ?? const SizedBox.shrink())
                    : Builder(
                        builder: (BuildContext context) {
                          return layer.builder!(context, layer.child);
                        },
                      ),
              ),
            );
            if (kIsWeb && layer.enableWebTextSelection) {
              // Browsers make text selectable by default while Flutter's
              // canvas does not — wrap the app content in a SelectionArea
              // so labels/values/body copy behave like native web text.
              content = _WebTextSelectionScope(
                selectionColor: theme.colorScheme
                    .resolve(CoreSelectableTextStyle.defaultSelectionColor)
                    .toValue(),
                child: content,
              );
            }

            return DataMessengerRoot(
              child: ScrollViewInterceptor(
                enabled: layer.enableScrollInterception,
                child: CoUISkeletonizerConfigLayer(
                  theme: theme,
                  child: DefaultTextStyle.merge(
                    style: theme.typography.bodyMedium
                        .toValue(theme: theme)
                        .copyWith(
                          // ColorScheme.onSurface is nullable and goes
                          // through nullable intermediate values during
                          // theme lerp animation. Fall back to a sane
                          // default instead of asserting non-null.
                          color: theme.colorScheme.onSurface.toValue(),
                        ),
                    child: IconTheme.merge(
                      data: theme.iconTheme.medium.copyWith(
                        color: theme.colorScheme.onSurface.toValue(),
                      ),
                      child: RecentColorsScope(
                        initialRecentColors: layer.initialRecentColors,
                        maxRecentColors: layer.maxRecentColors,
                        onRecentColorsChanged: layer.onRecentColorsChanged,
                        child: ColorPickingLayer(child: content),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );

    // Published above everything so a switch rebuilds the whole subtree,
    // which is this platform's transport for both axes — the Web
    // equivalent sets an attribute the stylesheet keys off. Components read
    // neither scope; they are for the app to ask what is active.
    //
    // The reduced-motion scope is a different kind: it carries a platform
    // signal `MediaQuery` has no field for (iOS "Reduce Motion"), so a
    // change made while the app runs reaches the subtree. Components do not
    // read it either; `resolveReducedMotion` does, for all of them.
    final styled = ReducedMotionScope(
      child: SurfaceStyleScope(
        surfaceStyle: layer.surfaceStyle,
        child: DensityScope(
          density: layer.density,
          child: AppBrightnessThemes(
            light: publishedFor(.light),
            dark: publishedFor(.dark),
            child: AppTypographyTiers(
              mobile: typographyAt(.mobile),
              tablet: typographyAt(.tablet),
              desktop: typographyAt(.desktop),
              child: app,
            ),
          ),
        ),
      ),
    );

    if (!layer.pixelSnap) return styled;
    // Mount a `PixelSnap` scope so descendants can align dimensions to the
    // device's physical-pixel grid (sharper edges on fractional DPRs).
    return PixelSnap(
      devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
      child: styled,
    );
  }
}

/// Web-only default text-selection scope mounted by [CoUILayer].
///
/// Widget tree:
///
/// ```text
/// Overlay (root — hosts the selection toolbar/handles;
///   │      `SelectionOverlay` looks up `Overlay.of(rootOverlay: true)`
///   │      and this scope sits above the Navigator's own overlay)
///   └─ DefaultSelectionStyle (CoUI selection tint — not Material's)
///        └─ SelectionArea (focusNode: skipTraversal, keyed on the
///             │                 browser context-menu flag)
///             └─ SelectionContainer (_LaidOutSelectionDelegate)
///                  └─ ScrollConfiguration (_LayoutGatedScrollBehavior —
///                       │                  the same gate inside every
///                       │                  Scrollable's chrome)
///                       └─ KeyedSubtree (GlobalKey)
///                            └─ child (app content)
/// ```
///
/// The region is keyed on [BrowserContextMenu.enabled]. `SelectableRegion`
/// reads that flag in `build` and wraps its inner `SelectionContainer` in
/// a context-menu widget only while it is true — so when the flag flips
/// under a live region (CoUIApp turns it off a moment after the first
/// frame), the next rebuild of the region (a theme, locale or motion
/// change) mounts a second container that registers with the region
/// before the first one unregisters. The region holds one selectable, so
/// the bookkeeping desyncs and the next unregister dereferences null
/// (#5268). A new region per flag value keeps one container per region;
/// the app content moves across under a [GlobalKey], so its state —
/// navigator, routes, controllers — survives the swap.
///
/// Owns the [SelectionArea]'s [FocusNode] with `skipTraversal: true`:
/// focus-traversal sorting reads every traversable node's rect, and in
/// multi-view embeds a sibling view may not be laid out yet — an
/// app-root traversable node then throws `RenderBox was not laid out`
/// during `didChangeViewFocus`. Skipping traversal keeps click/shortcut
/// selection working (the region still takes focus on interaction)
/// without joining tab-order sorting.
class _WebTextSelectionScope extends StatefulWidget {
  const _WebTextSelectionScope({
    required this.selectionColor,
    required this.child,
  });

  final Color selectionColor;
  final Widget child;

  @override
  State<_WebTextSelectionScope> createState() => _WebTextSelectionScopeState();
}

class _WebTextSelectionScopeState extends State<_WebTextSelectionScope> {
  final GlobalKey _contentKey = GlobalKey(
    debugLabel: 'CoUIWebTextSelectionContent',
  );

  /// The flag value the current region was built for. A region never
  /// outlives a flip of it — see [_WebTextSelectionScope].
  late bool _regionContextMenuEnabled = BrowserContextMenu.enabled;

  /// One node per region: the outgoing region still holds its node while
  /// the incoming one attaches, so they cannot share.
  late FocusNode _focusNode = _createFocusNode();

  /// One delegate per region for the same reason — a container clears
  /// its delegate's back-reference when it unmounts.
  _LaidOutSelectionDelegate _delegate = _LaidOutSelectionDelegate();

  static FocusNode _createFocusNode() =>
      FocusNode(debugLabel: 'CoUIWebTextSelection', skipTraversal: true);

  @override
  void initState() {
    super.initState();
    _browserContextMenuSettled.addListener(_handleContextMenuSettled);
  }

  void _handleContextMenuSettled() {
    if (BrowserContextMenu.enabled == _regionContextMenuEnabled) return;
    setState(() {});
  }

  @override
  void dispose() {
    _browserContextMenuSettled.removeListener(_handleContextMenuSettled);
    _focusNode.dispose();
    _delegate.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Read on every build, not only on notification: whoever flipped the
    // flag, the region this build produces must have been built for the
    // value its own build will see.
    final contextMenuEnabled = BrowserContextMenu.enabled;
    if (contextMenuEnabled != _regionContextMenuEnabled) {
      _regionContextMenuEnabled = contextMenuEnabled;
      final retiredFocusNode = _focusNode;
      final retiredDelegate = _delegate;
      _focusNode = _createFocusNode();
      _delegate = _LaidOutSelectionDelegate();
      // The outgoing region lets go of both when it unmounts at the end
      // of this frame.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        retiredFocusNode.dispose();
        retiredDelegate.dispose();
      });
    }

    return Overlay.wrap(
      child: DefaultSelectionStyle(
        selectionColor: widget.selectionColor,
        child: m.SelectionArea(
          key: ValueKey<bool>(contextMenuEnabled),
          focusNode: _focusNode,
          child: SelectionContainer(
            delegate: _delegate,
            child: ScrollConfiguration(
              behavior: _LayoutGatedScrollBehavior(
                ScrollConfiguration.of(context),
              ),
              child: KeyedSubtree(key: _contentKey, child: widget.child),
            ),
          ),
        ),
      ),
    );
  }
}

/// Admits a selectable into screen-order sorting only once it has been
/// laid out.
///
/// This scope sits above the app's navigator, so it collects text from
/// every page in the stack — not just the visible one. A deep link to a
/// nested route builds the pages under the target for the stack but the
/// overlay never lays them out while they are covered, and sorting reads
/// each selectable's box: the first sort after such a page is built hits
/// a box with no size (#5348). Text on a page that has never been laid
/// out has never been on screen, so it has no place in a screen order
/// yet; it joins on the first frame its box has a size — when the page
/// above it is popped. Selectables of other kinds pass straight through.
class _LaidOutSelectionDelegate extends StaticSelectionContainerDelegate {
  late final _gate = LayoutGate(admit: super.add, withdraw: super.remove);

  @override
  void add(r.Selectable selectable) => _gate.add(selectable);

  @override
  void remove(r.Selectable selectable) => _gate.remove(selectable);

  @override
  void dispose() {
    _gate.dispose();
    super.dispose();
  }
}

/// The ambient scroll behavior, plus a layout gate inside every
/// [Scrollable]'s chrome.
///
/// A [Scrollable] under a selection scope collects the selectables in its
/// subtree into a container of its own, and that container orders them
/// by their boxes the same way the app-wide one does — so the gate at the
/// top of [_WebTextSelectionScope] cannot reach them: they register with
/// the scrollable, not with it. A covered page that was never laid out
/// still builds its scrollables and their text, and the next data or
/// locale change there sorts boxes with no size (#5361). The scrollable
/// builds its chrome — scrollbar and overscroll indicator — between its
/// selection container and its content, which is the one seat the text
/// inside it resolves its registrar through; [LayoutGatedSelectionScope]
/// sits there.
///
/// Everything else is the ambient behavior's: this wrapper changes where
/// selectables register, not how anything scrolls.
class _LayoutGatedScrollBehavior extends ScrollBehavior {
  const _LayoutGatedScrollBehavior(this.inner);

  final ScrollBehavior inner;

  @override
  TargetPlatform getPlatform(BuildContext context) =>
      inner.getPlatform(context);

  @override
  Set<PointerDeviceKind> get dragDevices => inner.dragDevices;

  @override
  MultitouchDragStrategy getMultitouchDragStrategy(BuildContext context) =>
      inner.getMultitouchDragStrategy(context);

  @override
  Set<LogicalKeyboardKey> get pointerAxisModifiers =>
      inner.pointerAxisModifiers;

  // A derived behavior stays gated: `copyWith` on a plain behavior returns
  // one that skips the scrollbar or the overscroll indicator it was told
  // to drop — and an inner scroll view that drops both (a text field
  // does) would otherwise build its content with no gate above it.
  // Wrapping the derived behavior keeps every setting it carries and puts
  // the gate back in front of both builders.
  @override
  ScrollBehavior copyWith({
    bool? scrollbars,
    bool? overscroll,
    Set<PointerDeviceKind>? dragDevices,
    MultitouchDragStrategy? multitouchDragStrategy,
    Set<LogicalKeyboardKey>? pointerAxisModifiers,
    ScrollPhysics? physics,
    TargetPlatform? platform,
    ScrollViewKeyboardDismissBehavior? keyboardDismissBehavior,
  }) => _LayoutGatedScrollBehavior(
    inner.copyWith(
      scrollbars: scrollbars,
      overscroll: overscroll,
      dragDevices: dragDevices,
      multitouchDragStrategy: multitouchDragStrategy,
      pointerAxisModifiers: pointerAxisModifiers,
      physics: physics,
      platform: platform,
      keyboardDismissBehavior: keyboardDismissBehavior,
    ),
  );

  // Gated in both, ahead of the inner behavior: a derived behavior that
  // drops one of them still runs the other — or, through [copyWith],
  // still runs this wrapper. The inner gate sees the outer one and
  // passes through.
  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => inner.buildScrollbar(
    context,
    LayoutGatedSelectionScope(child: child),
    details,
  );

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => inner.buildOverscrollIndicator(
    context,
    LayoutGatedSelectionScope(child: child),
    details,
  );

  @override
  GestureVelocityTrackerBuilder velocityTrackerBuilder(BuildContext context) =>
      inner.velocityTrackerBuilder(context);

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      inner.getScrollPhysics(context);

  @override
  ScrollViewKeyboardDismissBehavior getKeyboardDismissBehavior(
    BuildContext context,
  ) => inner.getKeyboardDismissBehavior(context);

  @override
  bool shouldNotify(_LayoutGatedScrollBehavior oldDelegate) =>
      inner.runtimeType != oldDelegate.inner.runtimeType ||
      inner.shouldNotify(oldDelegate.inner);

  @override
  bool operator ==(Object other) =>
      other is _LayoutGatedScrollBehavior && other.inner == inner;

  @override
  int get hashCode => inner.hashCode;
}

/// Published by [CoUIApp] each time its `BrowserContextMenu` call
/// resolves, so the web selection scope can rebuild for the new flag.
final ValueNotifier<bool> _browserContextMenuSettled = ValueNotifier<bool>(
  BrowserContextMenu.enabled,
);

class CoUIAnimatedTheme extends StatelessWidget {
  const CoUIAnimatedTheme({
    required this.child,
    this.curve = Curves.linear,
    required this.data,
    required this.duration,
    super.key,
    this.onEnd,
  });

  final Widget child;
  final ThemeData data;
  final Duration duration;
  final Curve curve;

  final VoidCallback? onEnd;

  @override
  Widget build(BuildContext context) {
    return duration == .zero
        ? Theme(data: data, child: child)
        : AnimatedTheme(
            curve: curve,
            data: data,
            duration: duration,
            child: child,
          );
  }
}

class CoUIRectArcTween extends RectTween {
  CoUIRectArcTween({super.begin, super.end});

  bool _dirty = true;

  late CoUIPointArcTween _beginArc;

  late CoUIPointArcTween _endArc;

  @override
  Rect lerp(double t) {
    if (_dirty) {
      _initialize();
    }
    if (t == 0.0) {
      return begin!;
    }

    return t == 1.0
        ? end!
        : Rect.fromPoints(_beginArc.lerp(t), _endArc.lerp(t));
  }

  void _initialize() {
    assert(begin != null);
    assert(end != null);
    final centersVector = end!.center - begin!.center;
    final diagonal = _findMax<_BorderRadiusCorner>(
      _kAllDiagonals,
      (_BorderRadiusCorner d) => _diagonalSupport(centersVector, d),
    );
    _beginArc = CoUIPointArcTween(
      begin: _cornerFor(diagonal.beginId, begin!),
      end: _cornerFor(diagonal.beginId, end!),
    );
    _endArc = CoUIPointArcTween(
      begin: _cornerFor(diagonal.endId, begin!),
      end: _cornerFor(diagonal.endId, end!),
    );
    _dirty = false;
  }

  double _diagonalSupport(Offset centersVector, _BorderRadiusCorner diagonal) {
    final delta =
        _cornerFor(diagonal.endId, begin!) -
        _cornerFor(diagonal.beginId, begin!);
    final length = delta.distance;

    return centersVector.dx * delta.dx / length +
        centersVector.dy * delta.dy / length;
  }

  static Offset _cornerFor(_CornerType id, Rect rect) {
    return switch (id) {
      .topLeft => rect.topLeft,
      .topRight => rect.topRight,
      .bottomLeft => rect.bottomLeft,
      .bottomRight => rect.bottomRight,
    };
  }

  CoUIPointArcTween? get beginArc {
    if (begin == null) {
      return null;
    }
    if (_dirty) {
      _initialize();
    }

    return _beginArc;
  }

  CoUIPointArcTween? get endArc {
    if (end == null) {
      return null;
    }
    if (_dirty) {
      _initialize();
    }

    return _endArc;
  }

  @override
  set begin(Rect? value) {
    if (value != begin) {
      super.begin = value;
      _dirty = true;
    }
  }

  @override
  set end(Rect? value) {
    if (value != end) {
      super.end = value;
      _dirty = true;
    }
  }
}

T _findMax<T>(Iterable<T> input, _KeyFunc<T> keyFunc) {
  final iterator = input.iterator;
  if (!iterator.moveNext()) {
    throw StateError('input must not be empty');
  }
  var maxValue = iterator.current;
  var maxKey = keyFunc(maxValue);
  while (iterator.moveNext()) {
    final value = iterator.current;
    final key = keyFunc(value);
    if (key > maxKey) {
      maxValue = value;
      maxKey = key;
    }
  }
  return maxValue;
}

const _kAllDiagonals = [
  _BorderRadiusCorner(.topLeft, .bottomRight),
  _BorderRadiusCorner(.bottomRight, .topLeft),
  _BorderRadiusCorner(.topRight, .bottomLeft),
  _BorderRadiusCorner(.bottomLeft, .topRight),
];

typedef _KeyFunc<T> = double Function(T input);

enum _CornerType { bottomLeft, bottomRight, topLeft, topRight }

class _BorderRadiusCorner {
  const _BorderRadiusCorner(this.beginId, this.endId);
  final _CornerType beginId;
  final _CornerType endId;
}

const _kOnAxisDelta = 2;

class CoUIPointArcTween extends Tween<Offset> {
  CoUIPointArcTween({super.begin, super.end});

  bool _dirty = true;

  Offset? _center;

  double? _radius;

  double? _beginAngle;
  double? _endAngle;

  @override
  Offset lerp(double t) {
    if (_dirty) {
      _initialize();
    }
    if (t == 0.0) {
      return begin!;
    }
    if (t == 1.0) {
      return end!;
    }
    if (_beginAngle == null || _endAngle == null) {
      return Offset.lerp(begin, end, t)!;
    }
    final angle = lerpDouble(_beginAngle, _endAngle, t)!;
    final x = cos(angle) * _radius!;
    final y = sin(angle) * _radius!;

    return _center! + Offset(x, y);
  }

  void _initialize() {
    assert(this.begin != null);
    assert(this.end != null);

    final begin = this.begin!;
    final end = this.end!;

    // An explanation with a diagram can be found at https://goo.gl/vMSdRg
    final delta = end - begin;
    final deltaX = delta.dx.abs();
    final deltaY = delta.dy.abs();
    final distanceFromAtoB = delta.distance;
    final c = Offset(end.dx, begin.dy);

    double sweepAngle() => asin(distanceFromAtoB / (_radius! * 2.0)) * 2.0;

    if (deltaX > _kOnAxisDelta && deltaY > _kOnAxisDelta) {
      if (deltaX < deltaY) {
        _radius =
            distanceFromAtoB * distanceFromAtoB / (c - begin).distance / 2.0;
        _center = Offset(end.dx + _radius! * (begin.dx - end.dx).sign, end.dy);
        if (begin.dx < end.dx) {
          _beginAngle = sweepAngle() * (begin.dy - end.dy).sign;
          _endAngle = 0.0;
        } else {
          _beginAngle = pi + sweepAngle() * (end.dy - begin.dy).sign;
          _endAngle = pi;
        }
      } else {
        _radius =
            distanceFromAtoB * distanceFromAtoB / (c - end).distance / 2.0;
        _center = Offset(
          begin.dx,
          begin.dy + (end.dy - begin.dy).sign * _radius!,
        );
        if (begin.dy < end.dy) {
          _beginAngle = -pi / 2.0;
          _endAngle = _beginAngle! + sweepAngle() * (end.dx - begin.dx).sign;
        } else {
          _beginAngle = pi / 2.0;
          _endAngle = _beginAngle! + sweepAngle() * (begin.dx - end.dx).sign;
        }
      }
      assert(_beginAngle != null);
      assert(_endAngle != null);
    } else {
      _beginAngle = null;
      _endAngle = null;
    }
    _dirty = false;
  }

  Offset? get center {
    if (begin == null || end == null) {
      return null;
    }
    if (_dirty) {
      _initialize();
    }

    return _center;
  }

  double? get radius {
    if (begin == null || end == null) {
      return null;
    }
    if (_dirty) {
      _initialize();
    }

    return _radius;
  }

  double? get beginAngle {
    if (begin == null || end == null) {
      return null;
    }
    if (_dirty) {
      _initialize();
    }

    return _beginAngle;
  }

  double? get endAngle {
    if (begin == null || end == null) {
      return null;
    }
    if (_dirty) {
      _initialize();
    }

    return _beginAngle;
  }

  @override
  set begin(Offset? value) {
    if (value != begin) {
      super.begin = value;
      _dirty = true;
    }
  }

  @override
  set end(Offset? value) {
    if (value != end) {
      super.end = value;
      _dirty = true;
    }
  }
}

class CoUIUI extends StatelessWidget {
  const CoUIUI({required this.child, super.key, this.textStyle});

  final TextStyle? textStyle;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedDefaultTextStyle(
      style:
          textStyle ??
          kCoreSansTextStyle.copyWith(
            color: theme.colorScheme.onSurface.toValue(),
          ),
      duration: kDefaultDuration,
      curve: CoreEasing.move.toValue(),
      child: IconTheme(
        data: IconThemeData(color: theme.colorScheme.onSurface.toValue()),
        child: child,
      ),
    );
  }
}

class _GlobalPointerListener extends c.StatefulWidget {
  const _GlobalPointerListener({required this.child});

  final Widget child;

  @override
  c.State<_GlobalPointerListener> createState() =>
      _GlobalPointerListenerState();
}

class PointerData {
  const PointerData({required this.position});

  final Offset position;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PointerData && other.position == position;
  }

  @override
  String toString() => 'PointerData(position: $position)';

  @override
  int get hashCode => position.hashCode;
}

class _GlobalPointerListenerState extends c.State<_GlobalPointerListener> {
  final _key = GlobalKey();
  Offset? _position;

  @override
  Widget build(c.BuildContext context) {
    Widget child = MouseRegion(
      key: _key,
      onEnter: (event) {
        setState(() {
          _position = event.position;
        });
      },
      onExit: (event) {
        setState(() {
          _position = null;
        });
      },
      onHover: (event) {
        setState(() {
          _position = event.position;
        });
      },
      child: widget.child,
    );
    if (_position != null) {
      child = Data.inherit(
        data: PointerData(position: _position!),
        child: child,
      );
    }

    return child;
  }
}
