// The components that portal a panel to the overlay host, and what it takes
// to open each one in the VM — for the tests that check a scope around the
// opener is stated again around the panel (`OverlayPortal.capture`).
//
// ContextMenu also portals its panel, but opens only on a browser
// `contextmenu` event, which the VM cannot build — the Chrome probes open
// that one.
import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

/// [child] under a host, as `CoUIWeb` mounts one: a panel renders in the
/// host's layer, not under the subtree that opened it.
Component hosted(Component child) =>
    Theme.defaults(child: OverlayHost(child: child));

/// The id of the host layer the component found by [finder] renders in —
/// `null` when it renders in place, outside every layer.
///
/// A panel that rendered in place would sit under the scope that opened it
/// and read that scope's attributes without anything stating them again, so
/// a test that checks the restated scope checks this first.
String? hostLayerAround(Finder finder) {
  final layers = find
      .ancestor(
        of: finder,
        matching: find.byComponentPredicate(
          (component) =>
              component is div &&
              (component.id?.startsWith('coui-overlay-') ?? false),
        ),
      )
      .evaluate();

  return layers.isEmpty ? null : (layers.first.component as div).id;
}

/// One component that portals a panel: its `name`, the text its open
/// `panel` shows, and how to `open` it inside what `around` wraps it in.
typedef PanelOpener = ({
  String name,
  String panel,
  Future<void> Function(
    ComponentTester tester,
    Component Function(Component opener) around,
  )
  open,
});

/// Every component the VM can open whose panel passes through
/// `OverlayPortal.capture`.
final List<PanelOpener> panelOpeners = [
  (
    name: 'Popover',
    panel: 'popover panel',
    open: (tester, around) async {
      final controller = PopoverController();
      await _pumpOpener(
        tester,
        around,
        Popover(
          controller: controller,
          trigger: const Text('trigger'),
          content: const Text('popover panel'),
        ),
      );
      controller.show();
      await tester.pump();
      await tester.pump();
    },
  ),
  (
    name: 'Dialog',
    panel: 'dialog panel',
    open: (tester, around) => _pumpOpener(
      tester,
      around,
      const Dialog(title: Text('title'), content: Text('dialog panel')),
    ),
  ),
  (
    name: 'DropdownMenu',
    panel: 'Profile',
    open: (tester, around) async {
      await _pumpOpener(
        tester,
        around,
        DropdownMenu(
          trigger: const Text('Open'),
          items: [CoreMenuItem.action('Profile', onPressed: () {})],
        ),
      );
      tester.dispatchEvent(
        find.byComponentPredicate(
          (c) => c is div && c.attributes?['aria-expanded'] == 'false',
        ),
        'click',
      );
      await tester.pump();
      await tester.pump();
    },
  ),
  (
    name: 'Menubar',
    panel: 'New',
    open: (tester, around) => _pumpOpener(
      tester,
      around,
      Menubar(
        activeIndex: 0,
        menus: [
          CoreMenubarMenu(
            label: 'File',
            entries: [CoreMenubarEntry.action(label: 'New', onSelect: () {})],
          ),
        ],
      ),
    ),
  ),
  (
    name: 'NavigationMenu',
    panel: 'Products content',
    open: (tester, around) => _pumpOpener(
      tester,
      around,
      const NavigationMenu(
        activeIndex: 0,
        items: [
          CoreNavigationMenuItem(
            label: 'Products',
            content: Text('Products content'),
          ),
        ],
      ),
    ),
  ),
  (
    name: 'HoverCard',
    panel: 'hover panel',
    open: (tester, around) async {
      await _pumpOpener(
        tester,
        around,
        const HoverCard(
          openDelay: Duration.zero,
          trigger: Text('hover target'),
          content: Text('hover panel'),
        ),
      );
      await _hover(tester, 'hover target');
    },
  ),
  (
    name: 'Tooltip',
    panel: 'Hint',
    open: (tester, around) async {
      await _pumpOpener(
        tester,
        around,
        const Tooltip(
          message: 'Hint',
          waitDuration: Duration.zero,
          child: Text('anchor'),
        ),
      );
      await _hover(tester, 'anchor');
    },
  ),
];

/// Pumps [opener] inside [around] and gives a panel that opens with it the
/// time it takes to portal.
Future<void> _pumpOpener(
  ComponentTester tester,
  Component Function(Component opener) around,
  Component opener,
) async {
  tester.pumpComponent(around(opener));
  await tester.pump();
  await tester.pump();
}

/// How long a hover waits for a zero open delay to fire — a timer, not a
/// design value.
const Duration _kOpenDelaySettle = Duration(milliseconds: 20);

/// Hovers the element around [text] and waits out a zero open delay.
Future<void> _hover(ComponentTester tester, String text) async {
  tester.dispatchEvent(
    find.ancestor(of: find.text(text), matching: find.tag('div')).first,
    'mouseenter',
  );
  await Future<void>.delayed(_kOpenDelaySettle);
  await tester.pump();
  await tester.pump();
}
