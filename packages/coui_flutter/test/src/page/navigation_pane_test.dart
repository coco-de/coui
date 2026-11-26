import 'dart:async';

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('a pane restores the previous page on host back', (tester) async {
    late BuildContext firstPage;
    var closeCount = 0;
    await tester.pumpWidget(
      CoUIApp(
        theme: const ThemeData(platform: .macOS),
        home: NavigationPane(
          onClose: () => closeCount++,
          builder: (context) {
            firstPage = context;

            return const Text('First page');
          },
        ),
      ),
    );
    unawaited(
      NavigationPane.maybePush(firstPage, (_) => const Text('Second page')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Second page'), findsOneWidget);
    expect(find.text('First page'), findsNothing);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('First page'), findsOneWidget);
    expect(NavigationPane.maybePop(firstPage), isTrue);
    expect(closeCount, 1);
  });

  testWidgets('host back can be declined by the active pane page', (
    tester,
  ) async {
    late BuildContext firstPage;
    var popAttempts = 0;
    await tester.pumpWidget(
      CoUIApp(
        theme: const ThemeData(platform: .macOS),
        home: NavigationPane(
          onClose: () {},
          builder: (context) {
            firstPage = context;

            return const Text('First page');
          },
        ),
      ),
    );
    unawaited(
      NavigationPane.maybePush(
        firstPage,
        (_) => PopScope(
          canPop: false,
          onPopInvokedWithResult: (_, _) => popAttempts++,
          child: const Text('Unsaved form'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (var attempt = 1; attempt <= 2; attempt++) {
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Unsaved form'), findsOneWidget);
      expect(popAttempts, attempt);
    }
  });

  testWidgets('the title resolves from blur as a page is pushed', (
    tester,
  ) async {
    late BuildContext firstPage;
    await tester.pumpWidget(
      CoUIApp(
        theme: const ThemeData(platform: .macOS),
        home: NavigationPane(
          onClose: () {},
          builder: (context) {
            firstPage = context;

            return const SizedBox.expand();
          },
        ),
      ),
    );
    unawaited(
      NavigationPane.maybePush(
        firstPage,
        (_) => const Scaffold(
          headers: [AppBar(title: Text('Details'))],
          child: SizedBox.expand(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: CoreDuration.instant));
    final titleFilter = find.ancestor(
      of: find.text('Details'),
      matching: find.byType(ImageFiltered),
    );
    expect(titleFilter, findsOneWidget);
    await tester.pumpAndSettle();
    expect(titleFilter, findsNothing);
    expect(find.text('Details'), findsOneWidget);
  });

  for (final reduceMotion in [false, true]) {
    testWidgets('pane entrance respects reduced motion: $reduceMotion', (
      tester,
    ) async {
      const content = Key('pane body');
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(disableAnimations: reduceMotion),
          child: const Directionality(
            textDirection: TextDirection.ltr,
            child: Align(
              alignment: Alignment.topLeft,
              child: PaneTransition(
                child: SizedBox.square(key: content, dimension: 40),
              ),
            ),
          ),
        ),
      );

      if (reduceMotion) {
        expect(tester.getTopLeft(find.byKey(content)).dx, 0);
      } else {
        expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 0);
        expect(tester.getTopLeft(find.byKey(content)).dx, greaterThan(0));
        await tester.pumpAndSettle();
        expect(tester.getTopLeft(find.byKey(content)).dx, 0);
      }
    });
  }

  testWidgets('a pane can slide in RTL without an opacity layer', (
    tester,
  ) async {
    const content = Key('pane body');
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.rtl,
        child: Align(
          alignment: Alignment.topLeft,
          child: PaneTransition(
            fade: false,
            child: SizedBox.square(key: content, dimension: 40),
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: CoreDuration.instant));
    expect(find.byType(Opacity), findsNothing);
    expect(tester.getTopLeft(find.byKey(content)).dx, lessThan(0));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.byKey(content)).dx, 0);
  });
}
