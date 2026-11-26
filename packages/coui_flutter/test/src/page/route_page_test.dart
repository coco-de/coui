import 'dart:async';

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RoutePage', () {
    testWidgets('createRoute 는 Material 전환 mixin 이 아닌 CoUI 의 PageRoute 를 만든다', (
      tester,
    ) async {
      late BuildContext capturedContext;
      await tester.pumpWidget(
        material.MaterialApp(
          home: Builder(
            builder: (context) {
              capturedContext = context;

              return const SizedBox.shrink();
            },
          ),
        ),
      );

      const page = RoutePage<void>(child: Text('content'));
      final route = page.createRoute(capturedContext);

      expect(route, isA<PageRoute<void>>());
      // The transition is CoUI's choice, not a Material theme's.
      expect(route, isNot(isA<material.MaterialRouteTransitionMixin<void>>()));
      expect(route.settings, same(page));
    });

    testWidgets('child 를 라우트 콘텐츠로 렌더링한다', (tester) async {
      await tester.pumpWidget(
        material.MaterialApp.router(
          routerDelegate: _TestRouterDelegate(
            const RoutePage<void>(
              key: ValueKey('page'),
              child: Text('hello route page'),
            ),
          ),
          routeInformationParser: _TestRouteParser(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('hello route page'), findsOneWidget);
    });

    test('maintainState / fullscreenDialog 기본값은 MaterialPage 와 동일하다', () {
      const page = RoutePage<void>(child: SizedBox.shrink());

      expect(page.maintainState, isTrue);
      expect(page.fullscreenDialog, isFalse);
      expect(page.allowSnapshotting, isTrue);
    });

    testWidgets('fullscreenDialog / maintainState 가 라우트에 전달된다', (
      tester,
    ) async {
      late BuildContext capturedContext;
      await tester.pumpWidget(
        material.MaterialApp(
          home: Builder(
            builder: (context) {
              capturedContext = context;

              return const SizedBox.shrink();
            },
          ),
        ),
      );

      const page = RoutePage<void>(
        maintainState: false,
        fullscreenDialog: true,
        child: Text('content'),
      );
      final route = page.createRoute(capturedContext) as PageRoute<void>;

      expect(route.maintainState, isFalse);
      expect(route.fullscreenDialog, isTrue);
    });
  });

  group('RoutePageRoute', () {
    testWidgets('builder 콘텐츠를 렌더링하고 Material 전환 mixin 은 쓰지 않는다', (
      tester,
    ) async {
      final route = RoutePageRoute<void>(
        builder: (context) => const Text('imperative content'),
      );

      expect(route, isA<PageRoute<void>>());
      expect(route, isNot(isA<material.MaterialRouteTransitionMixin<void>>()));

      late BuildContext capturedContext;
      await tester.pumpWidget(
        material.MaterialApp(
          home: Builder(
            builder: (context) {
              capturedContext = context;

              return const SizedBox.shrink();
            },
          ),
        ),
      );
      unawaited(Navigator.of(capturedContext).push(route));
      await tester.pumpAndSettle();

      expect(find.text('imperative content'), findsOneWidget);
    });

    test('기본값은 MaterialPageRoute 와 동일하다', () {
      final route = RoutePageRoute<void>(
        builder: (context) => const SizedBox.shrink(),
      );

      expect(route.maintainState, isTrue);
      expect(route.fullscreenDialog, isFalse);
      expect(route.allowSnapshotting, isTrue);
      expect(route.barrierDismissible, isFalse);
    });

    test('maintainState / fullscreenDialog 가 라우트에 전달된다', () {
      final route = RoutePageRoute<void>(
        maintainState: false,
        fullscreenDialog: true,
        builder: (context) => const SizedBox.shrink(),
      );

      expect(route.maintainState, isFalse);
      expect(route.fullscreenDialog, isTrue);
    });
  });
}

class _TestRouterDelegate extends RouterDelegate<Object>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<Object> {
  _TestRouterDelegate(this.page);

  final Page<void> page;

  @override
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) => Navigator(
    key: navigatorKey,
    pages: [page],
    onDidRemovePage: (_) {},
  );

  @override
  Future<void> setNewRoutePath(Object configuration) async {}
}

class _TestRouteParser extends RouteInformationParser<Object> {
  @override
  Future<Object> parseRouteInformation(
    RouteInformation routeInformation,
  ) async => routeInformation;
}
