// Portaled panels must reach the browser top layer.
//
// A panel is `position: fixed` and is placed with viewport coordinates, so it
// only lands on its trigger when the viewport is its containing block. Under a
// host nested in a transformed ancestor (a client island inside a centred
// header) it is not — unless the panel is promoted into the top layer. The
// promotion itself needs a browser; these tests pin the part the server can
// see and the contract the browser half relies on: which elements carry the
// marker, that nothing is marked without a host (nothing would promote it, and
// the UA hides an unpromoted `[popover]`), and that the host ships the reset
// that keeps the UA popover defaults off the panel.

import 'dart:async';

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/components/menu/dropdown_menu/dropdown_menu.dart';
import 'package:coui_web/src/components/menu/menubar/menubar.dart';
import 'package:coui_web/src/components/menu/navigation_menu/navigation_menu.dart';
import 'package:coui_web/src/components/overlay/dialog/dialog.dart';
import 'package:coui_web/src/components/overlay/hover_card/hover_card.dart';
import 'package:coui_web/src/components/overlay/popover/popover.dart';
import 'package:coui_web/src/components/overlay/popover/popover_controller.dart';
import 'package:coui_web/src/components/overlay/tooltip/tooltip.dart';
import 'package:coui_web/src/overlay/overlay_host.dart';
import 'package:coui_web/src/overlay/top_layer.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_test/jaspr_test.dart';

/// Panels the host will promote: anything carrying the marker attribute.
Finder _promoted() => find.byComponentPredicate(
  (c) =>
      c is div && (c.attributes?.containsKey(kTopLayerPanelAttribute) ?? false),
  description: 'a top-layer panel',
);

/// The host's stylesheet when it holds [text].
///
/// The host writes its stylesheet as raw text: a `<style>` is not decoded, so
/// a `>` the server escaped is a rule the browser drops. `find.textContaining`
/// does not look inside raw text, so this does.
Finder _hostStyleContaining(String text) => find.byComponentPredicate(
  (c) => c is RawText && c.text.contains(text),
  description: 'the host stylesheet containing `$text`',
);

/// Records what [TopLayer.attributesFor] answers at its position in the tree.
class _Probe extends StatelessComponent {
  const _Probe(this.onBuild);

  final void Function(Map<String, String> attributes) onBuild;

  @override
  Component build(BuildContext context) {
    onBuild(TopLayer.attributesFor(context));
    return const span([], id: 'probe');
  }
}

/// `Theme` above the host, the order `CoUIWeb` gives them. A portaled panel
/// renders in the host's layer, not under the subtree that mounted it, so it
/// only sees what sits above the host.
Component _hosted(Component child) =>
    Theme.defaults(child: OverlayHost(child: child));

Component _menu({int? activeIndex}) => NavigationMenu(
  activeIndex: activeIndex,
  items: const [
    CoreNavigationMenuItem(
      label: 'Products',
      content: Component.text('Products content'),
    ),
  ],
);

void main() {
  group('TopLayer attributes', () {
    test('ask for a manual popover and carry the marker', () {
      // `manual`: the UA's light dismiss and Escape handling would race the
      // components' own dismissal. The marker is what the host promotes and
      // styles — a panel without it is left alone.
      expect(TopLayer.attributes, {
        'popover': 'manual',
        kTopLayerPanelAttribute: '',
      });
    });

    testComponents('are answered only under a host', (tester) async {
      Map<String, String>? hosted;
      Map<String, String>? bare;

      tester.pumpComponent(
        OverlayHost(child: _Probe((attributes) => hosted = attributes)),
      );
      expect(hosted, TopLayer.attributes);

      tester.pumpComponent(_Probe((attributes) => bare = attributes));
      // No host, nobody calls `showPopover()`, and the UA hides every
      // `[popover]:not(:popover-open)`: an inline panel must stay visible.
      expect(bare, isEmpty);
    });
  });

  group('OverlayHost stylesheet', () {
    testComponents('resets the UA popover defaults at zero specificity', (
      tester,
    ) async {
      tester.pumpComponent(const OverlayHost(child: span([], id: 'app')));

      // `:where()` keeps the specificity at zero so a panel's own utilities
      // (`inset-0` on a scrim) and the positioner's inline `left`/`top` win,
      // while an author rule still beats the UA sheet whatever it weighs.
      expect(
        _hostStyleContaining(
          ':where([$kTopLayerPanelAttribute]){margin:0;',
        ),
        findsOneComponent,
      );
      // `inset: auto` — the UA's `inset: 0` would pin the right and bottom
      // edges and stretch an auto-sized panel across the viewport.
      expect(_hostStyleContaining('inset:auto;'), findsOneComponent);
    });

    testComponents('keeps a panel that is not promoted yet visible', (
      tester,
    ) async {
      tester.pumpComponent(const OverlayHost(child: span([], id: 'app')));

      expect(
        _hostStyleContaining(
          ':where([$kTopLayerPanelAttribute][popover]:not(:popover-open)){'
          'display:block}',
        ),
        findsOneComponent,
      );
    });
  });

  group('hosted panels carry the top-layer attributes', () {
    testComponents('NavigationMenu — the panel, once open', (tester) async {
      tester.pumpComponent(_hosted(_menu(activeIndex: 0)));
      await tester.pump();
      await tester.pump();

      expect(_promoted(), findsOneComponent);
      final panel = find.byComponentPredicate(
        (c) =>
            c is div &&
            (c.id?.startsWith('co-navigation-menu-panel-') ?? false) &&
            c.attributes?['popover'] == 'manual',
      );
      expect(panel, findsOneComponent);
    });

    testComponents(
      'NavigationMenu without a host — rendered inline, unmarked',
      (
        tester,
      ) async {
        tester.pumpComponent(Theme.defaults(child: _menu(activeIndex: 0)));
        await tester.pump();
        await tester.pump();

        final panel = find.byComponentPredicate(
          (c) =>
              c is div &&
              (c.id?.startsWith('co-navigation-menu-panel-') ?? false),
        );
        expect(panel, findsOneComponent);
        expect(_promoted(), findsNothing);
      },
    );

    testComponents("Menubar — the open menu's panel", (tester) async {
      tester.pumpComponent(
        _hosted(
          Menubar(
            activeIndex: 0,
            menus: [
              CoreMenubarMenu(
                label: 'File',
                entries: [
                  CoreMenubarEntry.action(label: 'New', onSelect: () {}),
                ],
              ),
            ],
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('New'), findsOneComponent);
      expect(_promoted(), findsOneComponent);
    });

    testComponents('DropdownMenu — the panel, once the trigger is clicked', (
      tester,
    ) async {
      tester.pumpComponent(
        _hosted(
          DropdownMenu(
            trigger: const Component.text('Open'),
            items: [CoreMenuItem.action('Profile', onPressed: () {})],
          ),
        ),
      );
      await tester.pump();
      expect(_promoted(), findsNothing);

      tester.dispatchEvent(
        find.byComponentPredicate(
          (c) => c is div && c.attributes?['aria-expanded'] == 'false',
        ),
        'click',
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('Profile'), findsOneComponent);
      expect(_promoted(), findsOneComponent);
    });

    testComponents('HoverCard — the panel, once the trigger is hovered', (
      tester,
    ) async {
      tester
        ..pumpComponent(
          _hosted(
            const HoverCard(
              openDelay: Duration.zero,
              trigger: Component.text('Target'),
              content: Component.text('Panel'),
            ),
          ),
        )
        ..dispatchEvent(
          find
              .ancestor(of: find.text('Target'), matching: find.tag('div'))
              .first,
          'mouseenter',
        );
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await tester.pump();
      await tester.pump();

      expect(find.text('Panel'), findsOneComponent);
      expect(_promoted(), findsOneComponent);
    });

    testComponents('Tooltip — the panel, once the trigger is hovered', (
      tester,
    ) async {
      tester
        ..pumpComponent(
          _hosted(
            const Tooltip(
              message: 'Hint',
              waitDuration: Duration.zero,
              child: Component.text('Anchor'),
            ),
          ),
        )
        ..dispatchEvent(
          find
              .ancestor(of: find.text('Anchor'), matching: find.tag('div'))
              .first,
          'mouseenter',
        );
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await tester.pump();
      await tester.pump();

      expect(find.text('Hint'), findsOneComponent);
      expect(_promoted(), findsOneComponent);
    });

    testComponents('Popover — the panel and, when modal, its scrim', (
      tester,
    ) async {
      final controller = PopoverController();
      tester.pumpComponent(
        _hosted(
          Popover(
            controller: controller,
            modal: true,
            trigger: const Component.text('Open'),
            content: const Component.text('Body'),
          ),
        ),
      );
      await tester.pump();
      controller.show();
      await tester.pump();
      await tester.pump();

      // The scrim is `fixed inset-0` — it needs the viewport as containing
      // block exactly as the panel does.
      expect(_promoted(), findsNComponents(2));
    });

    testComponents('Dialog — the scrim and the panel', (tester) async {
      tester.pumpComponent(
        _hosted(
          const Dialog(
            title: Component.text('Title'),
            content: Component.text('Body'),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      // Two separate top-layer elements: the `contents` root they share
      // cannot be one. Both are `fixed`.
      expect(_promoted(), findsNComponents(2));
      expect(
        find.byComponentPredicate(
          (c) =>
              c is div &&
              c.attributes?['role'] == 'dialog' &&
              c.attributes?['popover'] == 'manual',
        ),
        findsOneComponent,
      );
    });
  });
}
