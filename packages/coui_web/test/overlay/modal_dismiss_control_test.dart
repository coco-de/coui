// The assistive-technology twin of a modal surface's scrim click.
//
// While a modal panel is open the page behind it is `inert` and the scrim is
// `aria-hidden`, so a screen-reader user has nothing to click and — on a touch
// device — no `Escape`. The Flutter seat attaches `Semantics(onDismiss:)` to
// the panel; the Web puts a phantom button beside it. These tests pin what a
// VM can see: which surfaces offer it, under which condition, what it is named
// and that it is not a tab stop. What a browser decides — that it is really
// clipped, never reached by Tab, and activated by `Enter` and space — is the
// Chrome probe's (`tool/parity/test/web/modal_dismiss_probe_test.dart`).

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/components/locale/coui_localizations/coui_localizations_scope.dart';
import 'package:coui_web/src/components/locale/coui_localizations/ko_coui_localizations.dart';
import 'package:coui_web/src/components/menu/dropdown_menu/dropdown_menu.dart';
import 'package:coui_web/src/components/overlay/popover/modal_dismiss_control.dart';
import 'package:coui_web/src/components/overlay/popover/popover.dart';
import 'package:coui_web/src/components/overlay/popover/popover_controller.dart';
import 'package:coui_web/src/overlay/overlay_host.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_test/jaspr_test.dart';

/// `Theme` above the host, the order `CoUIWeb` gives them.
Component _hosted(Component child) =>
    Theme.defaults(child: OverlayHost(child: child));

/// Every element carrying the control's marker.
Finder _controls() => find.byComponentPredicate(
  (c) => c is DomComponent && c.attributes?[kModalDismissAttribute] != null,
  description: 'a modal dismiss control',
);

DomComponent _only(Finder finder) =>
    finder.evaluate().single.component as DomComponent;

/// An open modal popover on [controller], the way the host mounts it.
Future<void> _openPopover(
  ComponentTester tester,
  PopoverController controller, {
  bool modal = true,
  bool dismissOnOutsideTap = true,
  Component Function(Component)? wrap,
}) async {
  final popover = Popover(
    controller: controller,
    modal: modal,
    dismissOnOutsideTap: dismissOnOutsideTap,
    trigger: const Component.text('Open'),
    content: const Component.text('Body'),
  );
  tester.pumpComponent(_hosted(wrap == null ? popover : wrap(popover)));
  await tester.pump();
  controller.show();
  await tester.pump();
  await tester.pump();
}

void main() {
  group('Popover', () {
    testComponents('a modal one that closes when clicked away offers it', (
      tester,
    ) async {
      final controller = PopoverController();
      await _openPopover(tester, controller);

      expect(_controls(), findsOneComponent);
      final control = _only(_controls());
      expect(control.attributes, {
        'role': 'button',
        // Out of the tab order: a tab stop nobody can see is a second bug.
        'tabindex': '-1',
        'aria-label': 'Dismiss',
        kModalDismissAttribute: '',
      });
      // Visually hidden, and not promoted into the top layer as a panel.
      expect(control.classes, 'sr-only');
      expect(control.attributes, isNot(contains('popover')));
    });

    testComponents('activating it closes the surface', (tester) async {
      final controller = PopoverController();
      await _openPopover(tester, controller);
      expect(controller.isOpen, isTrue);

      tester.dispatchEvent(_controls(), 'click');

      expect(controller.isOpen, isFalse);
    });

    testComponents("is named by the active locale's dismiss label", (
      tester,
    ) async {
      final controller = PopoverController();
      await _openPopover(
        tester,
        controller,
        wrap: (popover) => CouiLocalizationsScope(
          localizations: KoCouiLocalizations.instance,
          child: popover,
        ),
      );

      expect(_only(_controls()).attributes?['aria-label'], '닫기');
    });

    testComponents(
      'a non-modal one leaves the page reachable and offers none',
      (
        tester,
      ) async {
        final controller = PopoverController();
        await _openPopover(tester, controller, modal: false);

        expect(find.text('Body'), findsOneComponent);
        expect(_controls(), findsNothing);
      },
    );

    testComponents('a modal one that ignores outside clicks offers none', (
      tester,
    ) async {
      // The same condition as the scrim: "clicking away does not close this"
      // holds for every way of saying it.
      final controller = PopoverController();
      await _openPopover(tester, controller, dismissOnOutsideTap: false);

      expect(find.text('Body'), findsOneComponent);
      expect(_controls(), findsNothing);
    });

    testComponents('a closed one offers none', (tester) async {
      tester.pumpComponent(
        _hosted(
          const Popover(
            modal: true,
            trigger: Component.text('Open'),
            content: Component.text('Body'),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(_controls(), findsNothing);
    });
  });

  group('DropdownMenu', () {
    testComponents('offers it beside the panel once open, and it closes', (
      tester,
    ) async {
      final controller = PopoverController();
      tester.pumpComponent(
        _hosted(
          DropdownMenu(
            controller: controller,
            trigger: const Component.text('Open'),
            items: [CoreMenuItem.action('Profile', onPressed: () {})],
          ),
        ),
      );
      await tester.pump();
      expect(_controls(), findsNothing);

      final trigger = find.byComponentPredicate(
        (c) => c is div && c.attributes?['aria-expanded'] == 'false',
      );
      tester.dispatchEvent(trigger, 'click');
      await tester.pump();
      await tester.pump();

      expect(find.text('Profile'), findsOneComponent);
      expect(controller.isOpen, isTrue);
      expect(_controls(), findsOneComponent);
      expect(_only(_controls()).attributes?['aria-label'], 'Dismiss');

      tester.dispatchEvent(_controls(), 'click');

      // The menu plays its exit animation before it unmounts; the request to
      // close is what the control owns.
      expect(controller.isOpen, isFalse);
    });
  });
}
