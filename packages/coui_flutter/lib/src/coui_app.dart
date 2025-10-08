import 'dart:math';
import 'dart:ui';

import 'package:flutter/cupertino.dart' as c;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' as m;
import 'package:flutter/services.dart';
import 'package:coui_flutter/coui_flutter.dart';

import 'package:coui_flutter/src/platform_interface.dart'
    if (dart.library.js_interop) 'platform/platform_implementations_web.dart';

class CoUIApp extends StatefulWidget {
  const CoUIApp({
    this.actions,
    this.background,
    this.builder,
    this.color,
    this.cupertinoTheme,
    this.darkTheme,
    this.debugShowCheckedModeBanner = true,
    this.debugShowMaterialGrid = false,
    this.disableBrowserContextMenu = true,
    this.enableScrollInterception = true,
    this.enableThemeAnimation = true,
    this.home,
    this.initialRecentColors = const [],
    this.initialRoute,
    super.key,
    this.locale,
    this.localeListResolutionCallback,
    this.localeResolutionCallback,
    this.localizationsDelegates,
    this.materialTheme,
    this.maxRecentColors = 10,
    this.menuHandler,
    this.navigatorKey,
    this.navigatorObservers = const [],
    this.onGenerateInitialRoutes,
    this.onGenerateRoute,
    this.onGenerateTitle,
    this.onNavigationNotification,
    this.onRecentColorsChanged,
    this.onUnknownRoute,
    this.pixelSnap = true,
    this.popoverHandler,
    this.restorationScopeId,
    this.routes = const {},
    this.scaling,
    this.scrollBehavior,
    this.shortcuts,
    this.showPerformanceOverlay = false,
    this.showSemanticsDebugger = false,
    this.supportedLocales = const [Locale('en', 'US')],
    required this.theme,
    this.themeMode = ThemeMode.system,
    this.title = '',
    this.tooltipHandler,
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
    this.debugShowCheckedModeBanner = true,
    this.debugShowMaterialGrid = false,
    this.disableBrowserContextMenu = true,
    this.enableScrollInterception = false,
    this.enableThemeAnimation = true,
    this.initialRecentColors = const [],
    super.key,
    this.locale,
    this.localeListResolutionCallback,
    this.localeResolutionCallback,
    this.localizationsDelegates,
    this.materialTheme,
    this.maxRecentColors = 50,
    this.menuHandler,
    this.onGenerateTitle,
    this.onNavigationNotification,
    this.onRecentColorsChanged,
    this.pixelSnap = true,
    this.popoverHandler,
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
    this.themeMode = ThemeMode.system,
    this.title = '',
    this.tooltipHandler,
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
  final ThemeMode themeMode;
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
  final List<Color> initialRecentColors;
  final int maxRecentColors;
  final ValueChanged<List<Color>>? onRecentColorsChanged;
  final bool pixelSnap;
  final bool enableScrollInterception;
  final OverlayHandler? popoverHandler;
  final OverlayHandler? tooltipHandler;
  final OverlayHandler? menuHandler;
  final bool enableThemeAnimation;

  @override
  State<CoUIApp> createState() => _CoUIAppState();
}

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
    // When modifying this function, consider modifying the implementation in
    // the base class ScrollBehavior as well.
    switch (axisDirectionToAxis(details.direction)) {
      case Axis.horizontal:
        return child;

      case Axis.vertical:
        switch (getPlatform(context)) {
          case TargetPlatform.linux:
          case TargetPlatform.macOS:
          case TargetPlatform.windows:
            return Scrollbar(controller: details.controller, child: child);

          case TargetPlatform.android:
          case TargetPlatform.fuchsia:
          case TargetPlatform.iOS:
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
    // When modifying this function, consider modifying the implementation in
    // the base class ScrollBehavior as well.
    switch (getPlatform(context)) {
      case TargetPlatform.iOS:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        return child;

      case TargetPlatform.android:
        return StretchingOverscrollIndicator(
          axisDirection: details.direction,
          clipBehavior: details.decorationClipBehavior ?? Clip.hardEdge,
          child: child,
        );

      case TargetPlatform.fuchsia:
        break;
    }

    return GlowingOverscrollIndicator(
      axisDirection: details.direction,
      color: Theme.of(context).colorScheme.secondary,
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
    _heroController = HeroController(
      createRectTween: (begin, end) {
        return CoUIRectArcTween(begin: begin, end: end);
      },
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _dispatchAppInitialized();
    });
    if (kIsWeb) {
      if (widget.disableBrowserContextMenu) {
        BrowserContextMenu.disableContextMenu();
      } else {
        BrowserContextMenu.enableContextMenu();
      }
    }
  }

  void _dispatchAppInitialized() {
    CoUIFlutterPlatformImplementations.onAppInitialized();
  }

  Widget _builder(BuildContext context, Widget? child) {
    return CoUILayer(
      builder: widget.builder,
      darkTheme: widget.darkTheme,
      enableScrollInterception: widget.enableScrollInterception,
      enableThemeAnimation: widget.enableThemeAnimation,
      initialRecentColors: widget.initialRecentColors,
      maxRecentColors: widget.maxRecentColors,
      menuHandler: widget.menuHandler,
      onRecentColorsChanged: widget.onRecentColorsChanged,
      popoverHandler: widget.popoverHandler,
      scaling: widget.scaling,
      theme: widget.theme,
      themeMode: widget.themeMode,
      tooltipHandler: widget.tooltipHandler,
      child: child,
    );
  }

  Widget _buildWidgetApp(BuildContext context) {
    final primaryColor = widget.color ?? widget.theme.colorScheme.primary;
    return _usesRouter
        ? WidgetsApp.router(
            key: GlobalObjectKey(this),
            actions: widget.actions,
            backButtonDispatcher: widget.backButtonDispatcher,
            builder: _builder,
            color: primaryColor,
            debugShowCheckedModeBanner: widget.debugShowCheckedModeBanner,
            locale: widget.locale,
            localeListResolutionCallback: widget.localeListResolutionCallback,
            localeResolutionCallback: widget.localeResolutionCallback,
            localizationsDelegates: _localizationsDelegates,
            onGenerateTitle: widget.onGenerateTitle,
            restorationScopeId: widget.restorationScopeId,
            routeInformationParser: widget.routeInformationParser,
            routeInformationProvider: widget.routeInformationProvider,
            routerConfig: widget.routerConfig,
            routerDelegate: widget.routerDelegate,
            shortcuts: widget.shortcuts,
            showPerformanceOverlay: widget.showPerformanceOverlay,
            showSemanticsDebugger: widget.showSemanticsDebugger,
            supportedLocales: widget.supportedLocales,
            textStyle: widget.theme.typography.sans.copyWith(
              color: widget.theme.colorScheme.foreground,
            ),
            title: widget.title,
          )
        : WidgetsApp(
            key: GlobalObjectKey(this),
            actions: widget.actions,
            builder: _builder,
            color: primaryColor,
            debugShowCheckedModeBanner: widget.debugShowCheckedModeBanner,
            home: widget.home,
            initialRoute: widget.initialRoute,
            locale: widget.locale,
            localeListResolutionCallback: widget.localeListResolutionCallback,
            localeResolutionCallback: widget.localeResolutionCallback,
            localizationsDelegates: _localizationsDelegates,
            navigatorKey: widget.navigatorKey,
            navigatorObservers: widget.navigatorObservers!,
            onGenerateInitialRoutes: widget.onGenerateInitialRoutes,
            onGenerateRoute: widget.onGenerateRoute,
            onGenerateTitle: widget.onGenerateTitle,
            onNavigationNotification: widget.onNavigationNotification,
            onUnknownRoute: widget.onUnknownRoute,
            pageRouteBuilder:
                <T>(RouteSettings settings, WidgetBuilder builder) {
                  return MaterialPageRoute<T>(
                    builder: builder,
                    settings: settings,
                  );
                },
            restorationScopeId: widget.restorationScopeId,
            routes: widget.routes!,
            shortcuts: widget.shortcuts,
            showPerformanceOverlay: widget.showPerformanceOverlay,
            showSemanticsDebugger: widget.showSemanticsDebugger,
            supportedLocales: widget.supportedLocales,
            textStyle: widget.theme.typography.sans.copyWith(
              color: widget.theme.colorScheme.foreground,
            ),
            title: widget.title,
          );
  }

  bool get _usesRouter =>
      widget.routerDelegate != null || widget.routerConfig != null;

  @override
  void didUpdateWidget(covariant CoUIApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (kIsWeb &&
        widget.disableBrowserContextMenu !=
            oldWidget.disableBrowserContextMenu) {
      if (widget.disableBrowserContextMenu) {
        BrowserContextMenu.disableContextMenu();
      } else {
        BrowserContextMenu.enableContextMenu();
      }
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
      if (widget.localizationsDelegates != null)
        ...widget.localizationsDelegates!,
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
        result = GridPaper(
          color: const Color(0xE0F9BBE0),
          interval: 8,
          subdivisions: 1,
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
              brightness: widget.theme.brightness,
              error: widget.theme.colorScheme.destructive,
              primary: widget.theme.colorScheme.primary,
              secondary: widget.theme.colorScheme.secondary,
              seedColor: widget.theme.colorScheme.primary,
              surface: widget.theme.colorScheme.background,
            ),
          ),
      child: c.CupertinoTheme(
        data:
            widget.cupertinoTheme ??
            c.CupertinoThemeData(
              applyThemeToAll: true,
              barBackgroundColor: widget.theme.colorScheme.accent,
              brightness: widget.theme.brightness,
              primaryColor: widget.theme.colorScheme.primary,
              primaryContrastingColor:
                  widget.theme.colorScheme.primaryForeground,
              scaffoldBackgroundColor: widget.theme.colorScheme.background,
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
    this.enableScrollInterception = false,
    this.enableThemeAnimation = true,
    this.initialRecentColors = const [],
    super.key,
    this.maxRecentColors = 50,
    this.menuHandler,
    this.onRecentColorsChanged,
    this.popoverHandler,
    this.scaling,
    required this.theme,
    this.themeMode = ThemeMode.system,
    this.tooltipHandler,
  });

  final Widget? child;
  final ThemeData theme;
  final ThemeData? darkTheme;
  final ThemeMode themeMode;
  final AdaptiveScaling? scaling;
  final List<Color> initialRecentColors;
  final int maxRecentColors;
  final ValueChanged<List<Color>>? onRecentColorsChanged;
  final Widget Function(BuildContext context, Widget? child)? builder;
  final bool enableScrollInterception;
  final OverlayHandler? popoverHandler;
  final OverlayHandler? tooltipHandler;
  final OverlayHandler? menuHandler;

  final bool enableThemeAnimation;

  @override
  Widget build(BuildContext context) {
    final appScaling = scaling ?? AdaptiveScaler.defaultScaling(theme);
    final platformBrightness = MediaQuery.platformBrightnessOf(context);
    final mobileMode = isMobile(theme.platform);
    final scaledTheme =
        themeMode == ThemeMode.dark ||
            (themeMode == ThemeMode.system &&
                platformBrightness == Brightness.dark)
        ? appScaling.scale(darkTheme ?? theme)
        : appScaling.scale(theme);

    return OverlayManagerLayer(
      menuHandler:
          menuHandler ??
          (mobileMode
              ? const SheetOverlayHandler()
              : const PopoverOverlayHandler()),
      popoverHandler:
          popoverHandler ??
          (mobileMode
              ? const SheetOverlayHandler()
              : const PopoverOverlayHandler()),
      tooltipHandler:
          tooltipHandler ??
          (mobileMode
              ? const FixedTooltipOverlayHandler()
              : const PopoverOverlayHandler()),
      child: CoUIAnimatedTheme(
        data: scaledTheme,
        duration: kDefaultDuration,
        child: Builder(
          builder: (context) {
            final theme = Theme.of(context);

            return DataMessengerRoot(
              child: ScrollViewInterceptor(
                enabled: enableScrollInterception,
                child: CoUISkeletonizerConfigLayer(
                  theme: theme,
                  child: DefaultTextStyle.merge(
                    style: theme.typography.base.copyWith(
                      color: theme.colorScheme.foreground,
                    ),
                    child: IconTheme.merge(
                      data: theme.iconTheme.medium.copyWith(
                        color: theme.colorScheme.foreground,
                      ),
                      child: RecentColorsScope(
                        initialRecentColors: initialRecentColors,
                        maxRecentColors: maxRecentColors,
                        onRecentColorsChanged: onRecentColorsChanged,
                        child: ColorPickingLayer(
                          child: KeyboardShortcutDisplayMapper(
                            child: ToastLayer(
                              child: builder == null
                                  ? child ?? const SizedBox.shrink()
                                  : Builder(
                                      builder: (BuildContext context) {
                                        return builder!(context, child);
                                      },
                                    ),
                            ),
                          ),
                        ),
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
  }
}

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
    return duration == Duration.zero
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
      _allDiagonals,
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
      _CornerType.topLeft => rect.topLeft,
      _CornerType.topRight => rect.topRight,
      _CornerType.bottomLeft => rect.bottomLeft,
      _CornerType.bottomRight => rect.bottomRight,
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

const _allDiagonals = [
  _BorderRadiusCorner(_CornerType.topLeft, _CornerType.bottomRight),
  _BorderRadiusCorner(_CornerType.bottomRight, _CornerType.topLeft),
  _BorderRadiusCorner(_CornerType.topRight, _CornerType.bottomLeft),
  _BorderRadiusCorner(_CornerType.bottomLeft, _CornerType.topRight),
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
      duration: kDefaultDuration,
      style:
          textStyle ??
          theme.typography.sans.copyWith(
            color: theme.colorScheme.foreground,
          ),
      child: IconTheme(
        data: IconThemeData(color: theme.colorScheme.foreground),
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
