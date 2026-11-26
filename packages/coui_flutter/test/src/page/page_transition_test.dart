import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/services.dart' show MethodCall, SystemChannels;
import 'package:flutter_test/flutter_test.dart';

const Duration _kEnter = CorePageTransitionStyle.defaultEnterDuration;
const Duration _kExit = CorePageTransitionStyle.defaultExitDuration;
const double _kDistance = CorePageTransitionStyle.defaultSlideDistance;
const _kFastEnter = Duration(milliseconds: 260);
const _kFastExit = Duration(milliseconds: 210);
const _kFastMotion = CoreComponentTheme(
  pageTransition: CorePageTransitionTheme(
    style: CorePageTransitionStyle(
      enterDuration: _kFastEnter,
      exitDuration: _kFastExit,
      usePlatformDurations: false,
      animateAppBarTitle: false,
    ),
  ),
);

/// Pumps a `CoUIApp` whose theme states [platform], and returns its
/// navigator.
Future<NavigatorState> _pumpApp(
  WidgetTester tester, {
  TargetPlatform platform = .macOS,
  CoreComponentTheme? componentTheme,
  AdaptiveScaling? scaling,
  Map<String, WidgetBuilder> routes = const {},
}) async {
  final navigatorKey = GlobalKey<NavigatorState>();
  await tester.pumpWidget(
    CoUIApp(
      navigatorKey: navigatorKey,
      theme: ThemeData(
        platform: platform,
        coreComponentTheme: componentTheme,
      ),
      scaling: scaling,
      routes: routes,
      home: const Text('home'),
    ),
  );

  return navigatorKey.currentState!;
}

RoutePageRoute<void> _detail() =>
    RoutePageRoute<void>(builder: (context) => const Text('detail'));

/// The opacity CoUI's transition gives the screen showing [text].
double _opacityOf(WidgetTester tester, String text) {
  final fade = tester.widget<FadeTransition>(
    find
        .ancestor(of: find.text(text), matching: find.byType(FadeTransition))
        .first,
  );

  return fade.opacity.value;
}

/// How far below its place the screen showing [text] is drawn.
double _dropOf(WidgetTester tester, String text) {
  final transform = tester.widget<Transform>(
    find.ancestor(of: find.text(text), matching: find.byType(Transform)).first,
  );

  return transform.transform.getTranslation().y;
}

void main() {
  group('Page transition — desktop and web', () {
    testWidgets('a new screen fades in while it rises into place', (
      tester,
    ) async {
      final navigator = await _pumpApp(tester);
      navigator.push(_detail());
      await tester.pump();

      await tester.pump(_kEnter ~/ 2);
      expect(_opacityOf(tester, 'detail'), inExclusiveRange(0, 1));
      expect(_dropOf(tester, 'detail'), inExclusiveRange(0, _kDistance));
      // The screen underneath does not move.
      expect(find.text('home'), findsOneWidget);

      await tester.pump(_kEnter ~/ 2);
      expect(_opacityOf(tester, 'detail'), 1);
      expect(_dropOf(tester, 'detail'), 0);
    });

    testWidgets('a closed screen sinks while it fades out, over the exit '
        'duration', (tester) async {
      final navigator = await _pumpApp(tester);
      navigator.push(_detail());
      await tester.pumpAndSettle();

      navigator.pop();
      await tester.pump();
      await tester.pump(_kExit ~/ 2);
      expect(_opacityOf(tester, 'detail'), inExclusiveRange(0, 1));
      expect(_dropOf(tester, 'detail'), inExclusiveRange(0, _kDistance));

      await tester.pump(_kExit ~/ 2 + const Duration(milliseconds: 1));
      expect(find.text('detail'), findsNothing);
    });

    testWidgets('the departure starts at rest and speeds up', (tester) async {
      // The exit curve states real time. A route plays its departure
      // backwards, so the curve has to be flipped — unflipped, the screen
      // would leap away and settle instead.
      final navigator = await _pumpApp(tester);
      navigator.push(_detail());
      await tester.pumpAndSettle();

      navigator.pop();
      await tester.pump();
      await tester.pump(_kExit ~/ 4);
      final quarter = 1 - _opacityOf(tester, 'detail');
      await tester.pump(_kExit ~/ 2);
      final threeQuarters = 1 - _opacityOf(tester, 'detail');

      // A quarter of the way in, far less than a quarter of the way out;
      // the second half covers most of the distance.
      expect(quarter, lessThan(0.25));
      expect(threeQuarters - quarter, greaterThan(quarter));
    });

    testWidgets('the component theme sets the timing and distance', (
      tester,
    ) async {
      const fast = Duration(milliseconds: CoreDuration.fast);
      const theme = CoreComponentTheme(
        pageTransition: CorePageTransitionTheme(
          style: CorePageTransitionStyle(
            enterDuration: fast,
            slideDistance: CoreSpace.space48,
          ),
        ),
      );
      final navigator = await _pumpApp(tester, componentTheme: theme);
      final route = _detail();
      navigator.push(route);
      await tester.pump();
      expect(route.transitionDuration, fast);

      await tester.pump(fast ~/ 4);
      // A quarter of the way in, the theme's distance has more left to go
      // than the whole default distance.
      expect(_dropOf(tester, 'detail'), greaterThan(_kDistance));
      expect(_dropOf(tester, 'detail'), lessThan(CoreSpace.space48));

      await tester.pump(fast);
      expect(_opacityOf(tester, 'detail'), 1);
      expect(_dropOf(tester, 'detail'), 0);
    });

    testWidgets("the distance grows with the theme's scaling", (tester) async {
      Future<double> dropHalfway(AdaptiveScaling scaling) async {
        final navigator = await _pumpApp(tester, scaling: scaling);
        navigator.push(_detail());
        await tester.pump();
        await tester.pump(_kEnter ~/ 2);
        final drop = _dropOf(tester, 'detail');
        await tester.pumpAndSettle();
        // A new app, so the next measurement starts from its own home.
        await tester.pumpWidget(const SizedBox());

        return drop;
      }

      final plain = await dropHalfway(AdaptiveScaling.desktop);
      final doubled = await dropHalfway(const AdaptiveScaling(2));
      expect(plain, greaterThan(0));
      expect(doubled, moreOrLessEquals(plain * 2));
    });

    testWidgets('a reduced-motion request makes the push instant', (
      tester,
    ) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );

      final navigator = await _pumpApp(tester);
      navigator.push(_detail());
      await tester.pump();
      await tester.pump();

      expect(_opacityOf(tester, 'detail'), 1);
      expect(_dropOf(tester, 'detail'), 0);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('CoUIApp opens a named route as a CoUI page', (tester) async {
      final navigator = await _pumpApp(
        tester,
        routes: {'/detail': (context) => const Text('detail')},
      );
      navigator.pushNamed('/detail');
      await tester.pump();
      await tester.pump(_kEnter ~/ 2);

      final route = ModalRoute.of(tester.element(find.text('detail')));
      expect(route, isA<RoutePageRoute<dynamic>>());
      expect(_opacityOf(tester, 'detail'), inExclusiveRange(0, 1));
    });

    testWidgets('a declarative RoutePage arrives the same way', (
      tester,
    ) async {
      final pages = ValueNotifier<List<Page<void>>>(const [
        RoutePage<void>(key: ValueKey('home'), child: Text('home')),
      ]);
      addTearDown(pages.dispose);
      await tester.pumpWidget(
        CoUIApp(
          theme: const ThemeData(platform: .linux),
          home: ValueListenableBuilder<List<Page<void>>>(
            valueListenable: pages,
            builder: (context, value, _) => Navigator(
              pages: value,
              onDidRemovePage: (_) {},
            ),
          ),
        ),
      );

      pages.value = const [
        RoutePage<void>(key: ValueKey('home'), child: Text('home')),
        RoutePage<void>(key: ValueKey('detail'), child: Text('detail')),
      ];
      await tester.pump();
      await tester.pump(_kEnter ~/ 2);

      expect(_opacityOf(tester, 'detail'), inExclusiveRange(0, 1));
      expect(_dropOf(tester, 'detail'), inExclusiveRange(0, _kDistance));
    });
  });

  group('Page transition — iOS and Android keep the platform motion', () {
    for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
      testWidgets('${platform.name} keeps its slide with theme timing and '
          'a static title', (tester) async {
        final navigator = await _pumpApp(
          tester,
          platform: platform,
          componentTheme: _kFastMotion,
        );
        final route = RoutePageRoute<void>(
          builder: (_) => const Scaffold(
            headers: [AppBar(title: Text('detail'))],
            child: SizedBox.expand(),
          ),
        );
        navigator.push(route);
        await tester.pump();
        await tester.pump(_kFastEnter ~/ 2);

        expect(route.transitionDuration, _kFastEnter);
        expect(route.reverseTransitionDuration, _kFastExit);
        expect(route.animation?.status, AnimationStatus.forward);
        expect(find.byType(ImageFiltered), findsNothing);
        expect(find.byType(SlideTransition), findsWidgets);

        await tester.pumpAndSettle();
        if (platform == .iOS) {
          await tester.dragFrom(const Offset(4, 300), const Offset(500, 0));
        } else {
          const channel = SystemChannels.backGesture;
          Future<void> send(MethodCall call) =>
              tester.binding.defaultBinaryMessenger.handlePlatformMessage(
                channel.name,
                channel.codec.encodeMethodCall(call),
                (_) {},
              );
          await send(
            const MethodCall('startBackGesture', {
              'touchOffset': [5.0, 300.0],
              'progress': 0.0,
              'swipeEdge': 0,
            }),
          );
          expect(route.popGestureInProgress, isTrue);
          await send(const MethodCall('commitBackGesture'));
        }
        await tester.pumpAndSettle();
        expect(find.text('home'), findsOneWidget);
      });
    }

    testWidgets('iOS slides the screen in, and an edge swipe takes it '
        'back', (tester) async {
      final navigator = await _pumpApp(tester, platform: .iOS);
      navigator.push(_detail());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.ancestor(
          of: find.text('detail'),
          matching: find.byType(SlideTransition),
        ),
        findsWidgets,
      );

      await tester.pumpAndSettle();
      // From the left edge across the screen: the swipe the platform
      // transition carries.
      await tester.dragFrom(const Offset(4, 300), const Offset(500, 0));
      await tester.pumpAndSettle();
      expect(find.text('detail'), findsNothing);
      expect(find.text('home'), findsOneWidget);
    });

    testWidgets("Android keeps Flutter's predictive-back transition, not "
        "CoUI's rise", (tester) async {
      final navigator = await _pumpApp(tester, platform: .android);
      navigator.push(_detail());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Flutter's transition brings the screen in from the side; CoUI's
      // raises it from below. Nothing above the arriving screen lowers it.
      expect(
        find.ancestor(
          of: find.text('detail'),
          matching: find.byType(SlideTransition),
        ),
        findsWidgets,
      );
      final transforms = tester.widgetList<Transform>(
        find.ancestor(
          of: find.text('detail'),
          matching: find.byType(Transform),
        ),
      );
      for (final transform in transforms) {
        expect(transform.transform.getTranslation().y, 0);
      }
    });

    testWidgets('a reduced-motion request makes the platform transition '
        'instant too', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );

      final navigator = await _pumpApp(
        tester,
        platform: .android,
        componentTheme: _kFastMotion,
      );
      final route = _detail();
      navigator.push(route);
      await tester.pump();

      expect(route.transitionDuration, Duration.zero);
      expect(route.reverseTransitionDuration, Duration.zero);
    });
  });
}
