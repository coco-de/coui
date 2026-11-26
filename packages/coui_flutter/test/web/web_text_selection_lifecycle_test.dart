@TestOn('browser')
library;

// Runs in a browser only: the app-wide selection scope and the structural
// branch that broke it are both gated on `kIsWeb`, so a VM run cannot
// reach either. Run with:
//
//   cd packages/coui_flutter && flutter test --platform chrome test/web/

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // The browser context-menu channel has no host under `flutter test`, so
  // without this handler `disableContextMenu()` never resolves and
  // `BrowserContextMenu.enabled` never flips — which is exactly the late
  // flip a real page sees a moment after its first frame.
  setUp(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          SystemChannels.contextMenu,
          (_) async => null,
        );
    // The flag is process-global; start every variant from the browser
    // default so each one sees the true → false flip.
    await BrowserContextMenu.enableContextMenu();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.contextMenu, null);
  });

  Widget app({
    required CoreThemeMode themeMode,
    required Locale locale,
    String route = 'home',
  }) {
    return CoUIApp(
      theme: const ThemeData(),
      darkTheme: const ThemeData.dark(),
      themeMode: themeMode,
      locale: locale,
      supportedLocales: const [Locale('en'), Locale('ar'), Locale('ko')],
      home: _Page(route: route),
    );
  }

  testWidgets(
    'locale · theme change after the context menu settles keeps the '
    'selection registrar consistent (#5268)',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        app(themeMode: CoreThemeMode.light, locale: const Locale('en')),
      );
      final pageState = tester.state(find.byType(_Page));
      // Let `disableContextMenu()` resolve: `BrowserContextMenu.enabled`
      // goes true → false after the selection region already built once.
      await tester.pumpAndSettle();
      expect(BrowserContextMenu.enabled, isFalse);
      expect(tester.takeException(), isNull);
      // The region is rebuilt for the new flag; the app under it is not.
      expect(tester.state(find.byType(_Page)), same(pageState));

      // Each of these rebuilds the app root — the region rebuilds with it.
      await tester.pumpWidget(
        app(themeMode: CoreThemeMode.dark, locale: const Locale('ar')),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(
        app(themeMode: CoreThemeMode.light, locale: const Locale('ko')),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Late accessibility + reduced motion, the two MediaQuery changes the
      // demo saw ahead of the crash.
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(
            accessibleNavigation: true,
            disableAnimations: true,
          );
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Selection still works after the rebuilds: select-all over the
      // page text.
      await _dragSelect(tester, 'Body copy');
      expect(tester.takeException(), isNull);
      expect(_selections(tester, 'Body copy'), isNotEmpty);

      // Tearing the tree down unregisters every selectable exactly once.
      await tester.pumpWidget(const SizedBox.shrink());
      expect(tester.takeException(), isNull);
      semantics.dispose();
    },
    // Desktop browsers — the context-menu branch of the selection region
    // is skipped on Android/iOS targets, and the test default is Android.
    variant: TargetPlatformVariant.desktop(),
  );

  testWidgets(
    'a nested deep link builds covered pages that were never laid out '
    'without a selection error (#5348)',
    (tester) async {
      await tester.pumpWidget(
        CoUIApp(
          theme: const ThemeData(),
          initialRoute: '/orders/checkout',
          routes: {
            '/': (_) => const _Page(route: 'home'),
            '/orders': (_) => const _Page(route: 'orders'),
            '/orders/checkout': (_) => const _Page(route: 'checkout'),
          },
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      // Only the top page is on stage; the two under it were built for
      // the stack and never laid out.
      expect(find.text('Title checkout'), findsOneWidget);
      expect(find.text('Title orders', skipOffstage: false), findsOneWidget);

      // Selecting on the visible page orders every registered paragraph —
      // including the covered ones.
      await _dragSelect(tester, 'Body copy');
      expect(tester.takeException(), isNull);
      expect(_selections(tester, 'Body copy'), isNotEmpty);

      // Back to the page under it: it lays out for the first time and
      // its text takes part in selection again.
      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await tester.pumpAndSettle();
      expect(find.text('Title orders'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await _dragSelect(tester, 'Body copy');
      expect(tester.takeException(), isNull);
      expect(_selections(tester, 'Body copy'), isNotEmpty);
    },
    variant: TargetPlatformVariant.desktop(),
  );

  testWidgets(
    'a text field focused before the context menu settles keeps its focus, '
    'its input connection and every keystroke (#5361)',
    (tester) async {
      final controller = TextEditingController(text: '10');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        CoUIApp(
          theme: const ThemeData(),
          home: Column(
            children: [
              const Text('Body copy'),
              TextField(controller: controller),
            ],
          ),
        ),
      );
      // Focus lands while the region is still the one built for the
      // browser default — the settle that follows swaps the region and
      // moves the field across under it.
      await tester.showKeyboard(find.byType(EditableText));
      final focusNode = tester
          .widget<EditableText>(find.byType(EditableText))
          .focusNode;
      await tester.pumpAndSettle();
      expect(BrowserContextMenu.enabled, isFalse);
      expect(tester.takeException(), isNull);
      expect(focusNode.hasFocus, isTrue);
      expect(tester.testTextInput.hasAnyClients, isTrue);

      // Select everything, then type over it one key at a time — the
      // browser reports each keystroke as a new editing value.
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: '10',
          selection: TextSelection(baseOffset: 0, extentOffset: 2),
        ),
      );
      await tester.pump();
      for (final typed in ['7', '73', '732']) {
        tester.testTextInput.updateEditingValue(
          TextEditingValue(
            text: typed,
            selection: TextSelection.collapsed(offset: typed.length),
          ),
        );
        await tester.pump();
      }
      expect(tester.takeException(), isNull);
      expect(controller.text, '732');
      expect(controller.selection, const TextSelection.collapsed(offset: 3));
      expect(focusNode.hasFocus, isTrue);
    },
    variant: TargetPlatformVariant.desktop(),
  );

  for (final chrome in _ScrollChrome.values) {
    testWidgets(
      'text inside a scrollable (${chrome.name}) on a covered page that was '
      'never laid out survives data and locale changes without a selection '
      'error (#5361)',
      (tester) async {
        final items = ValueNotifier<int>(3);
        addTearDown(items.dispose);
        Widget listApp(Locale locale) => CoUIApp(
          theme: const ThemeData(),
          locale: locale,
          supportedLocales: const [Locale('en'), Locale('ar'), Locale('ko')],
          initialRoute: '/list/detail',
          routes: {
            '/': (_) => const _Page(route: 'home'),
            '/list': (_) => _ScrollPage(items: items, chrome: chrome),
            '/list/detail': (_) => const _Page(route: 'detail'),
          },
        );

        // The deep link builds the list page under the detail page for the
        // stack; the overlay never lays it out while it is covered, yet its
        // scrollable collects — and orders — the text inside it.
        await tester.pumpWidget(listApp(const Locale('en')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Row 0', skipOffstage: false), findsOneWidget);

        // Data arriving for the covered page adds text it has never laid out.
        items.value = 6;
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // A locale change rebuilds every page in the stack, covered or not —
        // into right-to-left and back, the cycle the demo smoke runs.
        await tester.pumpWidget(listApp(const Locale('ar')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(listApp(const Locale('ko')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // Selecting on the visible page still works.
        await _dragSelect(tester, 'Body copy');
        expect(tester.takeException(), isNull);
        expect(_selections(tester, 'Body copy'), isNotEmpty);

        // Back to the list: it lays out for the first time, and its rows
        // join selection in screen order.
        tester.state<NavigatorState>(find.byType(Navigator)).pop();
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Row 5'), findsOneWidget);
        await _dragSelect(tester, 'Row 1');
        expect(tester.takeException(), isNull);
        expect(_selections(tester, 'Row 1'), isNotEmpty);

        // More rows once it is on stage, and a scroll, keep it consistent.
        items.value = 40;
        await tester.pumpAndSettle();
        final before = tester.getTopLeft(find.text('Row 3'));
        final fadePosition = chrome == _ScrollChrome.fadeScroll
            ? tester
                  .state<ScrollableState>(
                    find.descendant(
                      of: find.byType(FadeScroll),
                      matching: find.byType(Scrollable),
                    ),
                  )
                  .position
            : null;
        if (fadePosition != null) {
          // A fade's own behavior keeps the platform drag defaults, so
          // scroll it the way its owner would.
          fadePosition.jumpTo(200);
        } else {
          await tester.drag(find.text('Row 3'), const Offset(0, -200));
        }
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        if (fadePosition != null) {
          expect(fadePosition.pixels, greaterThan(0));
        } else {
          expect(
            tester.getTopLeft(find.text('Row 3')).dy,
            lessThan(before.dy),
          );
        }
      },
      variant: TargetPlatformVariant.desktop(),
    );
  }
}

/// How the list's scroll behavior builds the chrome its text registers
/// through.
enum _ScrollChrome {
  /// The ambient behavior, scrollbar and overscroll indicator included.
  ambient,

  /// Both turned off through `copyWith` — the shape inner scroll views
  /// (text fields, breadcrumbs, scrollbars of their own) derive.
  noScrollbarNoOverscroll,

  /// The list is a `FadeScroll` without its scrollbar — CoUI's own scroll
  /// view, which installs a behavior of its own instead of deriving one.
  fadeScroll,

  /// A consumer replaces the ambient behavior with one of its own that
  /// extends `CoUIScrollBehavior` instead of deriving from the ambient one.
  consumerBehavior,
}

/// Drags a mouse across the paragraph showing [text], the way a user
/// selects on the web.
Future<void> _dragSelect(WidgetTester tester, String text) async {
  final rect = tester.getRect(find.text(text));
  final gesture = await tester.startGesture(
    rect.centerLeft + const Offset(1, 0),
    kind: PointerDeviceKind.mouse,
  );
  await tester.pump();
  await gesture.moveTo(rect.centerRight - const Offset(1, 0));
  await tester.pump();
  await gesture.up();
  await tester.pumpAndSettle();
}

/// The selection the paragraph showing [text] paints — non-empty once
/// select-all reached it through the scope.
List<TextSelection> _selections(WidgetTester tester, String text) => tester
    .renderObject<RenderParagraph>(
      find.descendant(of: find.text(text), matching: find.byType(RichText)),
    )
    .selections;

class _Page extends StatefulWidget {
  const _Page({required this.route});

  final String route;

  @override
  State<_Page> createState() => _PageState();
}

class _PageState extends State<_Page> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [Text('Title ${widget.route}'), const Text('Body copy')],
    );
  }
}

class _ScrollPage extends StatelessWidget {
  const _ScrollPage({required this.items, required this.chrome});

  final ValueListenable<int> items;
  final _ScrollChrome chrome;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: items,
      // Not lazy: every row is built with the page, laid out or not.
      builder: (context, count, _) {
        final rows = Column(
          children: [
            for (var index = 0; index < count; index += 1) Text('Row $index'),
          ],
        );
        if (chrome == _ScrollChrome.fadeScroll) return FadeScroll(child: rows);
        Widget list = SingleChildScrollView(child: rows);
        switch (chrome) {
          case _ScrollChrome.noScrollbarNoOverscroll:
            list = ScrollConfiguration(
              behavior: ScrollConfiguration.of(
                context,
              ).copyWith(scrollbars: false, overscroll: false),
              child: list,
            );
          case _ScrollChrome.consumerBehavior:
            list = ScrollConfiguration(
              behavior: const _ConsumerScrollBehavior(),
              child: list,
            );
          case _ScrollChrome.ambient:
          case _ScrollChrome.fadeScroll:
            break;
        }

        return list;
      },
    );
  }
}

/// A consumer behavior that does not derive from the ambient one, but
/// extends CoUI's — with a physics of its own, the usual reason to write
/// one.
class _ConsumerScrollBehavior extends CoUIScrollBehavior {
  const _ConsumerScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const ClampingScrollPhysics();
}
