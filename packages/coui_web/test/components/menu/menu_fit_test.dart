// A menu with more rows than the viewport has room for takes the room and
// scrolls inside it. The Web half of that is declarative: the positioner
// measures the panel and reports the height it is capped to (`onFit`), the
// host keeps it beside the panel's origin and hands it to the composed `Menu`
// through a `MenuFitScope`, and the `Menu` holds its own box to the cap and
// scrolls its rows in a list inside the box — the box keeps its border,
// corners, shadow and glass rim, which are drawn inside it and would scroll
// away with a scrolling box. What can be pinned without a browser is that
// structure and the rule behind the numbers; the positioner's measurement is a
// DOM read, and a real Chrome checks it
// (`tool/parity/test/web/menu_viewport_fit_probe_test.dart`).
//
// A menu that fits is not touched: the chrome is absent, not zero.
import 'dart:convert';
import 'dart:io';

import 'package:coui_web/coui_web.dart';
import 'package:coui_web/src/components/menu/menu/menu_fit_scope.dart';
import 'package:coui_web/src/overlay/overlay_fit.dart';
import 'package:coui_web/src/overlay/positioning/fit.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

/// The vector table shared with the Core test, the Flutter engine test and
/// the Chrome probe.
const String _kVectorsPath =
    '../coui_core/test/fixtures/overlay_fit_vectors.json';

Map<String, String> _css(Styles? styles) => styles?.properties ?? const {};

void main() {
  group('the chrome a held panel gets', () {
    test('the box is held to the cap and keeps clipping its corners', () {
      expect(_css(resolveOverlayFitBox(maxHeight: 464)), {
        'box-sizing': 'border-box',
        'max-height': '464px',
      });
    });

    test('keeps a fractional height the browser measured', () {
      // A height read back from layout goes back in as it is: rem would
      // rescale it by the root font size and put it off the viewport.
      expect(
        _css(resolveOverlayFitBox(maxHeight: 650.5))['max-height'],
        '650.50px',
      );
    });

    test('the rows scroll in a list that takes the height the box leaves', () {
      final scroller = resolveOverlayFitScroller();

      expect(_css(scroller.inlineStyles), {
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'inherit',
        'flex': '1 1 auto',
        'min-height': '0',
        'overflow-x': 'hidden',
        'overflow-y': 'auto',
        'overscroll-behavior-y': 'contain',
        'scrollbar-gutter': 'stable',
      });
    });

    test('marks the scroller so the positioner can read its overflow', () {
      expect(resolveOverlayFitScroller().className, kOverlayFitScrollerClass);
    });
  });

  group('the composed Menu holds its own box and scrolls a list inside it', () {
    /// The `<div role="menu">` the `Menu` renders — its own box.
    Finder menuBox() => find.byComponentPredicate(
      (c) => c is div && c.attributes?['role'] == 'menu',
      description: 'the menu box',
    );

    div boxOf() => menuBox().evaluate().first.component as div;

    const items = [
      CoreMenuItem<Component>.action('First'),
      CoreMenuItem<Component>.action('Second'),
    ];

    testComponents('the box keeps its chrome and the rows scroll inside it', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const MenuFitScope(maxHeight: 464, child: Menu(items: items)),
      );
      await tester.pump();

      final box = boxOf();
      final css = _css(box.styles);
      expect(css['max-height'], '464px');
      expect(css['box-sizing'], 'border-box');
      // Still the Popup's own box, with its border, radius and shadow: the cap
      // sits on it and it does not scroll, so what is drawn inside it — the
      // glass rim among it — stays where it is while the rows move.
      expect(css, contains('border-radius'));
      expect(css, contains('box-shadow'));
      expect(css, isNot(contains('overflow-y')));
      final classes = box.classes!.split(' ');
      expect(classes, contains('overflow-hidden'));
      expect(classes, isNot(contains(kOverlayFitScrollerClass)));

      // The rows are one level down, in the list that scrolls.
      final children = box.children;
      expect(children, hasLength(1));
      final scroller = children.single as div;
      expect(scroller.classes!.split(' '), contains(kOverlayFitScrollerClass));
      expect(_css(scroller.styles)['overflow-y'], 'auto');
      expect(scroller.children, hasLength(items.length));
    });

    testComponents("the caller's own css still reaches the box", (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const MenuFitScope(
          maxHeight: 464,
          child: Menu(
            items: items,
            css: Styles(raw: {'z-index': '7'}),
          ),
        ),
      );
      await tester.pump();

      final css = _css(boxOf().styles);
      expect(css['z-index'], '7');
      expect(css['max-height'], '464px');
    });

    testComponents('a menu that fits carries none of it', (tester) async {
      pumpWithTheme(tester, const Menu(items: items));
      await tester.pump();

      final box = boxOf();
      final css = _css(box.styles);
      expect(css, isNot(contains('max-height')));
      expect(css, isNot(contains('overflow-y')));
      expect(box.children, hasLength(items.length));
      expect(
        box.classes!.split(' '),
        isNot(contains(kOverlayFitScrollerClass)),
      );
    });

    testComponents('a panel that fits in a scope is not touched either', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const MenuFitScope(maxHeight: null, child: Menu(items: items)),
      );
      await tester.pump();

      final box = boxOf();
      expect(_css(box.styles), isNot(contains('max-height')));
      expect(box.children, hasLength(items.length));
    });

    testComponents('a horizontal menu has no rows to scroll', (tester) async {
      pumpWithTheme(
        tester,
        const MenuFitScope(
          maxHeight: 464,
          child: Menu(items: items, vertical: false),
        ),
      );
      await tester.pump();

      final box =
          find
                  .byComponentPredicate(
                    (c) => c is div && c.attributes?['role'] == 'menubar',
                  )
                  .evaluate()
                  .first
                  .component
              as div;
      expect(_css(box.styles), isNot(contains('max-height')));
      expect(box.children, hasLength(items.length));
    });
  });

  group('the natural height of a panel that may be held', () {
    // `scrollHeight` and `clientHeight` are whole numbers while a box is
    // laid out in fractions, so a panel that is exactly the room can read as
    // a pixel over it and then a pixel under it.
    test('is the box plus what its scroller holds beyond what it shows', () {
      expect(
        overlayNaturalHeight(
          measuredHeight: 464,
          overflow: 616,
          room: 464,
          wasCapped: true,
        ),
        1080,
      );
    });

    test('is the box itself when nothing scrolls', () {
      expect(
        overlayNaturalHeight(
          measuredHeight: 200,
          overflow: 0,
          room: 464,
          wasCapped: false,
        ),
        200,
      );
    });

    test('never counts a negative overflow', () {
      expect(
        overlayNaturalHeight(
          measuredHeight: 200,
          overflow: -3,
          room: 464,
          wasCapped: false,
        ),
        200,
      );
    });

    test('keeps a held panel that fills the room held', () {
      // It fills the room and the scroller reports no more beyond: that is
      // the rounding, not a panel that now fits. Letting it go would
      // re-measure it free one update later and hold it again the next.
      final natural = overlayNaturalHeight(
        measuredHeight: 464,
        overflow: 0,
        room: 464,
        wasCapped: true,
      );

      expect(natural, greaterThan(464));
    });

    test('lets a held panel go once it is clearly shorter than the room', () {
      expect(
        overlayNaturalHeight(
          measuredHeight: 300,
          overflow: 0,
          room: 464,
          wasCapped: true,
        ),
        300,
      );
    });

    test('does not hold a panel that was never held', () {
      expect(
        overlayNaturalHeight(
          measuredHeight: 464,
          overflow: 0,
          room: 464,
          wasCapped: false,
        ),
        464,
      );
    });
  });

  group('the Web chrome against the shared vectors', () {
    // The vector says whether a panel is capped and to what; the box chrome
    // emitted for that cap must say the same thing in CSS.
    final doc =
        jsonDecode(File(_kVectorsPath).readAsStringSync())
            as Map<String, Object?>;
    final cases = (doc['cases']! as List).cast<Map<String, Object?>>();

    for (final c in cases) {
      test(c['name']! as String, () {
        final fit = CoreOverlayFit.fit(
          viewport: (c['viewport']! as num).toDouble(),
          paddingBefore: (c['paddingBefore']! as num).toDouble(),
          paddingAfter: (c['paddingAfter']! as num).toDouble(),
          start: (c['start']! as num).toDouble(),
          extent: (c['extent']! as num).toDouble(),
        );
        final expected = c['fit']! as Map<String, Object?>;
        expect(fit.capped, expected['capped']);

        // The cap the positioner reports is the extent, only when held.
        final cap = fit.capped ? fit.extent : null;
        final box = cap == null ? null : resolveOverlayFitBox(maxHeight: cap);
        if (expected['capped']! as bool) {
          final extent = (expected['extent']! as num).toDouble();
          expect(
            double.parse(_css(box)['max-height']!.replaceAll('px', '')),
            closeTo(extent, 0.01),
          );
        } else {
          expect(box, isNull);
        }
      });
    }
  });

  group('hosts re-sync an open panel on every build', () {
    // The Flutter hosts have to be told to run the panel builder again; the
    // Web hosts rebuild the portalled panel with the host, so new items
    // reach it by themselves. This pins that behaviour, which the Flutter
    // twin is measured against.
    testComponents('DropdownMenu shows swapped items without reopening', (
      tester,
    ) async {
      late _Swap swap;
      tester.pumpComponent(
        Theme.defaults(
          child: OverlayHost(
            child: _Swap(
              onReady: (handle) => swap = handle,
              builder: (title) => DropdownMenu(
                trigger: const Component.text('Open'),
                items: [
                  CoreMenuItem.action(title, onPressed: () {}),
                  CoreMenuItem.action('Sort 10s', onPressed: () {}),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      tester.dispatchEvent(
        find.byComponentPredicate(
          (c) => c is div && c.attributes?['aria-expanded'] == 'false',
        ),
        'click',
      );
      await tester.pump();
      await tester.pump();
      expect(find.text('Sort 5s'), findsOneComponent);

      swap.to('Sort 4s');
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(find.text('Sort 4s'), findsOneComponent);
      expect(find.text('Sort 5s'), findsNothing);
      expect(find.text('Sort 10s'), findsOneComponent);
    });

    testComponents('Popover shows swapped content without reopening', (
      tester,
    ) async {
      late _Swap swap;
      final controller = PopoverController();
      tester.pumpComponent(
        Theme.defaults(
          child: OverlayHost(
            child: _Swap(
              onReady: (handle) => swap = handle,
              builder: (title) => Popover(
                controller: controller,
                trigger: const Component.text('Open'),
                content: Component.text(title),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      controller.show();
      await tester.pump();
      await tester.pump();
      expect(find.text('Sort 5s'), findsOneComponent);

      swap.to('Sort 4s');
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(find.text('Sort 4s'), findsOneComponent);
      expect(find.text('Sort 5s'), findsNothing);
    });

    testComponents('Menubar shows swapped entries without reopening', (
      tester,
    ) async {
      late _Swap swap;
      tester.pumpComponent(
        Theme.defaults(
          child: OverlayHost(
            child: _Swap(
              onReady: (handle) => swap = handle,
              builder: (title) => Menubar(
                activeIndex: 0,
                menus: [
                  CoreMenubarMenu(
                    label: 'File',
                    entries: [
                      CoreMenubarEntry.action(label: title, onSelect: () {}),
                      CoreMenubarEntry.action(label: 'Open', onSelect: () {}),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(find.text('Sort 5s'), findsOneComponent);

      swap.to('Sort 4s');
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(find.text('Sort 4s'), findsOneComponent);
      expect(find.text('Sort 5s'), findsNothing);
      expect(find.text('Open'), findsOneComponent);
    });
  });
}

/// A host whose child is rebuilt with a different label on demand — the way
/// an app rebuilds a menu whose items change while it is open.
class _Swap extends StatefulComponent {
  const _Swap({required this.builder, required this.onReady});

  final Component Function(String title) builder;
  final void Function(_Swap handle) onReady;

  /// Set by the state; swaps the label the child is built with.
  static void Function(String title)? _to;

  void to(String title) => _to!(title);

  @override
  State<_Swap> createState() => _SwapState();
}

class _SwapState extends State<_Swap> {
  String _label = 'Sort 5s';

  @override
  void initState() {
    super.initState();
    _Swap._to = (title) => setState(() => _label = title);
    component.onReady(component);
  }

  @override
  Component build(BuildContext context) => component.builder(_label);
}
