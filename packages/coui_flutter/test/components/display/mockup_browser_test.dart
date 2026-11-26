import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

/// The `Container`s inside [subtree] painted with exactly [color].
Iterable<Container> _boxesFilled(
  WidgetTester tester,
  Widget subtree,
  Color color,
) => tester
    .widgetList<Container>(
      find.descendant(
        of: find.byWidget(subtree),
        matching: find.byType(Container),
      ),
    )
    .where((c) => (c.decoration as BoxDecoration?)?.color == color);

/// The coui `Icon`s inside [subtree].
Finder _icons(Widget subtree) =>
    find.descendant(of: find.byWidget(subtree), matching: find.byType(Icon));

/// Resolves `MockupBrowser` under the test app and hands the result out.
Future<ResolvedMockupBrowser> _resolve(
  WidgetTester tester, {
  CoreMockupBrowserStyle? style,
  ThemeData? theme,
}) async {
  late ResolvedMockupBrowser resolved;
  // `buildTestApp` mounts its child through `Overlay.initialEntries`,
  // which only applies on the overlay's first mount — a second pump in
  // the same test would keep the first entry's builder and never run this
  // one. Tear the tree down first so every call resolves fresh.
  await tester.pumpWidget(const SizedBox.shrink());
  await pumpTestApp(
    tester,
    Builder(
      builder: (context) {
        resolved = resolveMockupBrowser(context, mockupBrowserStyle: style);
        return const SizedBox.shrink();
      },
    ),
    theme: theme,
  );
  return resolved;
}

void main() {
  testWidgets('local chrome follows geometry and scales once', (
    tester,
  ) async {
    late ResolvedMockupBrowser resolved;
    await tester.pumpWidget(
      Theme(
        data: const ThemeData(
          scaling: 2,
          geometry: CoreSurfaceGeometryConstraint(
            shadowOffsetScale: 3,
            strokeFloor: 4,
          ),
        ),
        child: Builder(
          builder: (context) {
            resolved = resolveMockupBrowser(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(resolved.highlightShadows.single.offset, const Offset(0, 6));
    expect(resolved.highlightShadows.single.blurStyle, BlurStyle.inner);
    expect(resolved.windowBorderDecoration.border?.top.width, 4);
    expect(resolved.toolbarBorderWidth, 4);
  });

  group('MockupBrowser — web page composition', () {
    testWidgets('renders the address bar, both chevrons and the action', (
      tester,
    ) async {
      const browser = MockupBrowser(
        addressBar: 'https://coui.dev',
        child: Text('page'),
      );
      await pumpTestApp(tester, browser);

      expect(find.text('https://coui.dev'), findsOneWidget);
      expect(find.text('page'), findsOneWidget);
      // Back, forward, lock, reload, share and plus.
      expect(_icons(browser), findsNWidgets(6));
    });

    testWidgets('a bare MockupBrowser reads as example.com', (tester) async {
      await pumpTestApp(tester, const MockupBrowser());

      expect(find.text('example.com'), findsOneWidget);
    });
  });

  group('MockupBrowser — app window composition (addressBar: null)', () {
    testWidgets('leaves the address bar, chevrons and action out of the tree', (
      tester,
    ) async {
      const browser = MockupBrowser(addressBar: null, child: Text('app'));
      await pumpTestApp(tester, browser);

      expect(find.text('example.com'), findsNothing);
      expect(_icons(browser), findsNothing);
      expect(find.text('app'), findsOneWidget);
    });

    testWidgets('still paints the three window controls', (tester) async {
      const browser = MockupBrowser(addressBar: null, child: Text('app'));
      await pumpTestApp(tester, browser);

      expect(
        _boxesFilled(
          tester,
          browser,
          Theme.of(
            tester.element(find.byWidget(browser)),
          ).colorScheme.error.toValue(),
        ),
        hasLength(1),
      );
      expect(
        _boxesFilled(
          tester,
          browser,
          Theme.of(
            tester.element(find.byWidget(browser)),
          ).colorScheme.warning.toValue(),
        ),
        hasLength(1),
      );
      expect(
        _boxesFilled(
          tester,
          browser,
          Theme.of(
            tester.element(find.byWidget(browser)),
          ).colorScheme.success.toValue(),
        ),
        hasLength(1),
      );
    });

    testWidgets('without a child the window keeps only the toolbar height', (
      tester,
    ) async {
      await pumpTestApp(
        tester,
        const Align(
          alignment: .topLeft,
          child: SizedBox(width: 280, child: MockupBrowser(addressBar: null)),
        ),
      );

      expect(tester.takeException(), isNull);
      // A missing child leaves the toolbar height, with zero side chrome.
      expect(tester.getSize(find.byType(MockupBrowser)).height, 44);
    });
  });

  group('MockupBrowser — addressBarTextAlign places the URL', () {
    const url = 'a.io';

    /// Pumps a 400px-wide browser and measures, in global coordinates, the
    /// pill's content box and the painted URL glyph run.
    ///
    /// The glyph run is read from the paragraph's caret offsets rather than
    /// the `Text` widget's rect: the label spans the whole pill, so its rect
    /// is the same whatever the alignment — only where the glyphs land
    /// tells the alignments apart.
    Future<({Rect pill, double glyphLeft, double glyphRight})> measure(
      WidgetTester tester,
      CoreTextAlign align,
    ) async {
      await pumpTestApp(
        tester,
        Center(
          child: SizedBox(
            width: 400,
            child: MockupBrowser(
              showControls: false,
              addressBar: url,
              mockupBrowserStyle: CoreMockupBrowserStyle(
                addressBarTextAlign: align,
              ),
            ),
          ),
        ),
      );
      final pill = tester.getRect(find.text(url));
      final paragraph = tester.renderObject<RenderParagraph>(find.text(url));
      final first = paragraph.getOffsetForCaret(
        const TextPosition(offset: 0),
        Rect.zero,
      );
      final last = paragraph.getOffsetForCaret(
        const TextPosition(offset: url.length),
        Rect.zero,
      );

      return (
        pill: pill,
        glyphLeft: paragraph.localToGlobal(first).dx,
        glyphRight: paragraph.localToGlobal(last).dx,
      );
    }

    testWidgets('start puts the URL at the pill leading edge', (tester) async {
      final m = await measure(tester, .start);

      expect(m.glyphLeft, closeTo(m.pill.left, 1));
    });

    testWidgets('center puts the URL in the middle of the pill', (
      tester,
    ) async {
      final m = await measure(tester, .center);

      expect(
        (m.glyphLeft + m.glyphRight) / 2,
        closeTo(m.pill.center.dx, 1),
      );
      // Guards against a vacuous pass: the run is far narrower than the pill.
      expect(m.glyphLeft - m.pill.left, greaterThan(40));
    });

    testWidgets('end puts the URL at the pill trailing edge', (tester) async {
      final m = await measure(tester, .end);

      expect(m.glyphRight, closeTo(m.pill.right, 1));
    });
  });

  group('MockupBrowser — showControls', () {
    testWidgets('false removes the control dots from the tree', (
      tester,
    ) async {
      const browser = MockupBrowser(showControls: false, child: Text('c'));
      await pumpTestApp(tester, browser);

      for (final colour in [
        Theme.of(
          tester.element(find.byWidget(browser)),
        ).colorScheme.error.toValue(),
        Theme.of(
          tester.element(find.byWidget(browser)),
        ).colorScheme.warning.toValue(),
        Theme.of(
          tester.element(find.byWidget(browser)),
        ).colorScheme.success.toValue(),
      ]) {
        expect(_boxesFilled(tester, browser, colour), isEmpty);
      }
      // The browser affordances are untouched by the flag.
      expect(find.text('example.com'), findsOneWidget);
    });
  });

  group('MockupBrowser — window geometry is measured from the outer edge', () {
    // The final border paints over the full window without taking layout
    // space; child content starts below the 44px toolbar.
    const cardKey = ValueKey('card');

    Future<(Rect, Rect)> pumpWindow(
      WidgetTester tester, {
      CoreMockupBrowserStyle? style,
    }) async {
      await pumpTestApp(
        tester,
        Align(
          alignment: .topLeft,
          child: SizedBox(
            width: 280,
            child: MockupBrowser(
              mockupBrowserStyle: style,
              child: const SizedBox(key: cardKey, height: 81),
            ),
          ),
        ),
      );
      return (
        tester.getRect(find.byType(MockupBrowser)),
        tester.getRect(find.byKey(cardKey)),
      );
    }

    testWidgets('content reaches the sides and bottom with a 44px top inset', (
      tester,
    ) async {
      final (window, card) = await pumpWindow(tester);

      expect(window.height, 125);
      expect(card.left - window.left, 0);
      expect(window.right - card.right, 0);
      expect(window.bottom - card.bottom, 0);
      expect(card.top - window.top, 44);
      expect(
        (await _resolve(tester)).contentBorderRadius,
        BorderRadius.circular(14),
      );
    });

    testWidgets('a thicker outline does not grow the window', (tester) async {
      final (window, card) = await pumpWindow(
        tester,
        style: const CoreMockupBrowserStyle(borderWidth: 3),
      );

      expect(window.height, 125);
      expect(card.left - window.left, 0);
      expect(window.bottom - card.bottom, 0);
      expect(card.top - window.top, 44);
    });

    testWidgets('the toolbar controls sit toolbarPadding in from the outer '
        'edge', (tester) async {
      await pumpTestApp(
        tester,
        const Align(
          alignment: .topLeft,
          child: SizedBox(width: 280, child: MockupBrowser()),
        ),
      );
      final window = tester.getRect(find.byType(MockupBrowser));
      final dots = tester.widgetList<Container>(
        find.descendant(
          of: find.byType(MockupBrowser),
          matching: find.byType(Container),
        ),
      );
      final close = dots.firstWhere(
        (c) =>
            (c.decoration as BoxDecoration?)?.color ==
            Theme.of(
              tester.element(find.byType(MockupBrowser)),
            ).colorScheme.error.toValue(),
      );

      expect(tester.getRect(find.byWidget(close)).left - window.left, 12);
    });
  });

  group('MockupBrowser — copyWith', () {
    test('a getter clears the address bar into the app-window composition', () {
      const page = MockupBrowser(addressBar: 'coui.dev');

      expect(page.copyWith(addressBar: () => null).addressBar, isNull);
      expect(page.copyWith(addressBar: () => 'b.io').addressBar, 'b.io');
      expect(page.copyWith().addressBar, 'coui.dev');
    });
  });

  group('MockupBrowser — resolver', () {
    testWidgets('the content card radius is the body radius minus the '
        'window thickness', (tester) async {
      final resolved = await _resolve(tester);

      expect(resolved.contentBorderRadius, BorderRadius.circular(14));
      // Child content is offset below the toolbar, with no side inset.
      expect(
        resolved.contentInset,
        const EdgeInsets.only(top: 44),
      );
    });

    testWidgets('a thicker chrome tightens the derived radius; an explicit '
        'override wins over it', (tester) async {
      final thicker = await _resolve(
        tester,
        style: const CoreMockupBrowserStyle(chromeWidth: 4),
      );
      expect(thicker.contentBorderRadius, BorderRadius.circular(10));

      final explicit = await _resolve(
        tester,
        style: const CoreMockupBrowserStyle(
          contentBorderRadius: CoreBorderRadius.all(2),
        ),
      );
      expect(explicit.contentBorderRadius, BorderRadius.circular(2));
    });

    testWidgets('a chrome thicker than the radius yields a square card, '
        'not a negative radius', (tester) async {
      final resolved = await _resolve(
        tester,
        style: const CoreMockupBrowserStyle(chromeWidth: 20),
      );

      expect(resolved.contentBorderRadius, BorderRadius.zero);
    });

    testWidgets('the frame uses the low surface and the designer shadow', (
      tester,
    ) async {
      final resolved = await _resolve(tester);

      expect(
        resolved.containerStyle.backgroundColor,
        const CoreColor.token(CoreColors.surfaceContainerLow),
      );
      expect(
        resolved.containerStyle.borderColor,
        CoreColor.transparent,
      );
      expect(
        resolved.containerStyle.boxShadow,
        CoreMockupBrowserStyle.defaultBoxShadow,
      );
    });

    testWidgets('the card and capsule use their own semantic fills', (
      tester,
    ) async {
      late Color surface;
      await pumpTestApp(
        tester,
        Builder(
          builder: (context) {
            surface = Theme.of(context).colorScheme.surface.toValue();
            return const SizedBox.shrink();
          },
        ),
      );
      final resolved = await _resolve(tester);

      expect(resolved.contentBackgroundColor, surface);
      final context = tester.element(find.byType(Builder).last);
      expect(
        resolved.addressBarBackgroundColor,
        Theme.of(context).colorScheme
            .resolve(CoreMockupBrowserStyle.defaultAddressBarBackgroundColor)
            .toValue(),
      );
      expect(resolved.addressBarTextAlign, TextAlign.center);
    });

    testWidgets('the control colours follow the active scheme', (
      tester,
    ) async {
      final light = await _resolve(
        tester,
        theme: ThemeData.fromCore(CoreThemePresets.light),
      );
      final dark = await _resolve(
        tester,
        theme: ThemeData.fromCore(CoreThemePresets.dark),
      );

      expect(dark.controlCloseColor, isNot(light.controlCloseColor));
      expect(dark.controlMinimizeColor, isNot(light.controlMinimizeColor));
      expect(dark.controlMaximizeColor, isNot(light.controlMaximizeColor));
    });

    testWidgets('icon chrome merges a colour-only override onto the '
        'default size', (tester) async {
      final resolved = await _resolve(
        tester,
        style: const CoreMockupBrowserStyle(
          navIconStyle: CoreIconStyle(color: CoreColor.token(CoreColors.error)),
        ),
      );

      expect(resolved.navIconStyle.size, CoreIconSize.size12);
      expect(
        resolved.navIconStyle.color,
        const CoreColor.token(CoreColors.error),
      );
      expect(
        resolved.navDisabledIconStyle,
        CoreMockupBrowserStyle.defaultNavDisabledIconStyle,
      );
    });
  });
}
