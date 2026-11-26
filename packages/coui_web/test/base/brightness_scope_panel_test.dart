// A panel opened inside a `BrightnessScope` renders in its brightness.
//
// The panel is portalled to the overlay host, outside the scope's
// `data-theme` wrapper, so the attribute around the trigger does not reach
// it. The component states the scope again around the panel — what Flutter's
// `InheritedTheme.capture` does for a panel opened there.
//
// This file pins that the attribute lands where the scope's rules look for
// it; the rules themselves are `brightness_scope_css_test.dart`'s, and what
// Chrome draws with them is the panel probe's
// (`tool/parity/test/web/brightness_scope_panel_probe_test.dart`).
import 'dart:async';

import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../helpers/panel_openers.dart';

/// The attribute a scope writes — spelled out rather than read from the
/// scope, so the test is a second source for it.
const String _kAttribute = 'data-theme';

/// How many times a [_CountedPanel] has been mounted. A panel that is
/// mounted again has lost what its state held — focus, scroll, an input's
/// text.
int _panelMounts = 0;

/// Panel content that counts its mounts in [_panelMounts].
class _CountedPanel extends StatefulComponent {
  const _CountedPanel();

  @override
  State<_CountedPanel> createState() => _CountedPanelState();
}

class _CountedPanelState extends State<_CountedPanel> {
  @override
  void initState() {
    super.initState();
    _panelMounts++;
  }

  @override
  Component build(BuildContext context) => const Text('panel');
}

/// A [BrightnessScope] whose brightness the test changes — [onReady] hands
/// it the setter once the scope is mounted.
class _BrightnessSwitch extends StatefulComponent {
  const _BrightnessSwitch({
    required this.initial,
    required this.onReady,
    required this.child,
  });

  final CoreBrightness initial;
  final void Function(void Function(CoreBrightness brightness) set) onReady;
  final Component child;

  @override
  State<_BrightnessSwitch> createState() => _BrightnessSwitchState();
}

class _BrightnessSwitchState extends State<_BrightnessSwitch> {
  late CoreBrightness _brightness = component.initial;

  @override
  void initState() {
    super.initState();
    component.onReady((brightness) => setState(() => _brightness = brightness));
  }

  @override
  Component build(BuildContext context) =>
      BrightnessScope(brightness: _brightness, child: component.child);
}

/// The brightnesses the elements around [finder] name, nearest first — what
/// the stylesheet's scope rules see from inside the panel.
List<String> _brightnessesAround(Finder finder) => _attributesAround(
  finder,
  _kAttribute,
);

/// The typography tiers the elements around [finder] name, nearest first.
List<String> _tiersAround(Finder finder) => _attributesAround(
  finder,
  'data-coui-typography-tier',
);

List<String> _attributesAround(Finder finder, String attribute) => [
  for (final element
      in find
          .ancestor(
            of: finder,
            matching: find.byComponentPredicate(
              (component) =>
                  component is div &&
                  (component.attributes?.containsKey(attribute) ?? false),
            ),
          )
          .evaluate())
    (element.component as div).attributes![attribute]!,
];

/// A popover opened from inside [around], its panel holding [panel].
Future<void> _openPopover(
  ComponentTester tester,
  Component Function(Component popover) around, {
  Component panel = const Text('panel'),
}) async {
  final controller = PopoverController();
  tester.pumpComponent(
    around(
      Popover(
        controller: controller,
        trigger: const Text('trigger'),
        content: panel,
      ),
    ),
  );
  await tester.pump();
  controller.show();
  await tester.pump();
  await tester.pump();
}

void main() {
  group('a panel opened inside a scope renders in its brightness', () {
    testComponents('a popover', (tester) async {
      await _openPopover(
        tester,
        (popover) => hosted(BrightnessScope(brightness: .dark, child: popover)),
      );

      expect(_brightnessesAround(find.text('trigger')), ['dark']);
      // One scope only: the trigger's is not an ancestor of the panel, so
      // this is the one stated again around it.
      expect(_brightnessesAround(find.text('panel')), ['dark']);
    });

    testComponents('a dialog, and a popover opened inside it', (
      tester,
    ) async {
      // The dialog's content renders in the host's layer too, so the scope
      // the popover inside it finds is the one stated around the dialog.
      final controller = PopoverController();
      tester.pumpComponent(
        hosted(
          BrightnessScope(
            brightness: .dark,
            child: Dialog(
              title: const Text('title'),
              content: Popover(
                controller: controller,
                trigger: const Text('trigger'),
                content: const Text('panel'),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      controller.show();
      await tester.pump();
      await tester.pump();

      expect(_brightnessesAround(find.text('title')), ['dark']);
      expect(_brightnessesAround(find.text('panel')), ['dark']);
    });

    testComponents('no scope states nothing around the panel', (tester) async {
      await _openPopover(tester, hosted);

      expect(find.text('panel'), findsOneComponent);
      expect(_brightnessesAround(find.text('panel')), isEmpty);
    });

    testComponents('a scope around the host is not stated twice', (
      tester,
    ) async {
      // The host's layers are inside that scope already — a preview pane
      // that puts its whole app in one brightness is one.
      await _openPopover(
        tester,
        (popover) => BrightnessScope(brightness: .dark, child: hosted(popover)),
      );

      expect(_brightnessesAround(find.text('panel')), ['dark']);
    });

    testComponents('the nearer scope is the one stated', (tester) async {
      await _openPopover(
        tester,
        (popover) => BrightnessScope(
          brightness: .dark,
          child: hosted(BrightnessScope(brightness: .light, child: popover)),
        ),
      );

      expect(_brightnessesAround(find.text('panel')), ['light', 'dark']);
    });

    testComponents('a typography tier scope is stated beside it', (
      tester,
    ) async {
      // Both scopes are left behind by the portal, so both are stated again
      // — neither wrapper drops the other.
      await _openPopover(
        tester,
        (popover) => hosted(
          BrightnessScope(
            brightness: .dark,
            child: TypographyTierScope(tier: .desktop, child: popover),
          ),
        ),
      );

      expect(_brightnessesAround(find.text('panel')), ['dark']);
      expect(_tiersAround(find.text('panel')), ['desktop']);
    });

    testComponents(
      "an open panel keeps its state when its brightness meets the host's",
      (tester) async {
        // Whether the scope is stated again depends on where the scope sits,
        // not on its brightness: a wrapper that dropped out once the
        // brightness equals the host's would remount the open panel.
        _panelMounts = 0;
        late void Function(CoreBrightness brightness) setBrightness;
        await _openPopover(
          tester,
          (popover) => BrightnessScope(
            brightness: .light,
            child: hosted(
              _BrightnessSwitch(
                initial: .dark,
                onReady: (set) => setBrightness = set,
                child: popover,
              ),
            ),
          ),
          panel: const _CountedPanel(),
        );
        expect(_panelMounts, 1);
        expect(_brightnessesAround(find.text('panel')), ['dark', 'light']);

        setBrightness(.light);
        await tester.pump();
        await tester.pump();
        expect(_panelMounts, 1, reason: 'the panel was not mounted again');
        expect(_brightnessesAround(find.text('panel')), ['light', 'light']);

        setBrightness(.dark);
        await tester.pump();
        await tester.pump();
        expect(_panelMounts, 1, reason: 'the panel was not mounted again');
        expect(_brightnessesAround(find.text('panel')), ['dark', 'light']);
      },
    );

    // Every component that portals a panel states the scope again around
    // it. ContextMenu opens only on a browser `contextmenu` event, which the
    // VM cannot build — the Chrome probe opens that one.
    for (final opener in panelOpeners) {
      testComponents('${opener.name} states the scope around its panel', (
        tester,
      ) async {
        await opener.open(
          tester,
          (child) => hosted(BrightnessScope(brightness: .dark, child: child)),
        );

        expect(find.text(opener.panel), findsOneComponent);
        expect(
          hostLayerAround(find.text(opener.panel)),
          isNotNull,
          reason: 'the panel is portalled, not rendered under the scope',
        );
        expect(_brightnessesAround(find.text(opener.panel)), ['dark']);
      });
    }
  });

  group('a drawer renders in the brightness around its host', () {
    testComponents('opened inside a scope, it states none', (tester) async {
      // The Flutter drawer route captures no theme from the place it was
      // opened, so the Web drawer does not pass through the capture either.
      tester.pumpComponent(
        hosted(
          const BrightnessScope(
            brightness: .dark,
            child: _DrawerOpener(
              Drawer(content: Text('drawer panel')),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(find.text('drawer panel'), findsOneComponent);
      expect(hostLayerAround(find.text('drawer panel')), isNotNull);
      expect(_brightnessesAround(find.text('drawer panel')), isEmpty);
    });
  });
}

/// Opens [drawer] from where it sits, the way a page does.
class _DrawerOpener extends StatefulComponent {
  const _DrawerOpener(this.drawer);

  final Drawer drawer;

  @override
  State<_DrawerOpener> createState() => _DrawerOpenerState();
}

class _DrawerOpenerState extends State<_DrawerOpener> {
  @override
  void initState() {
    super.initState();
    // Deferred like every real caller: mounting notifies the host, and a
    // host `setState` reached from inside build throws.
    unawaited(
      Future<void>.microtask(() {
        if (!mounted) return;
        unawaited(
          openDrawer<void>(
            context: context,
            side: component.drawer.side,
            builder: (close) => component.drawer,
          ),
        );
      }),
    );
  }

  @override
  Component build(BuildContext context) => const span([], id: 'opener');
}
