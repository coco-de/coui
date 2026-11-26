import 'dart:async';

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/overlay/overlay_controller.dart';
import 'package:coui_web/src/overlay/overlay_host.dart';
import 'package:coui_web/src/overlay/overlay_portal.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_test/jaspr_test.dart';

Component _panel() => const Component.text('panel');

/// Mounts one entry on the host's own controller so the rendered
/// backdrop can be inspected. Reaching the controller through the
/// portal is how real components do it.
class _Opener extends StatefulComponent {
  const _Opener({required this.modal});

  final bool modal;

  @override
  State<_Opener> createState() => _OpenerState();
}

class _OpenerState extends State<_Opener> {
  @override
  void initState() {
    super.initState();
    // Deferred for the same reason every real component defers its
    // portal sync: mounting notifies the host, and a host `setState`
    // reached from inside build throws.
    Future<void>.microtask(() {
      if (!mounted) return;
      OverlayPortal.of(context).controller.mount(
        layer: .dialog,
        panel: _panel(),
        modal: component.modal,
      );
    });
  }

  @override
  Component build(BuildContext context) => span([], id: 'marker');
}

/// The page-level backdrop wrapper, optionally narrowed to inert ones.
Finder _backdrop({bool inert = false}) => find.byComponentPredicate(
  (c) =>
      c is div &&
      (c.attributes?.containsKey('data-coui-backdrop') ?? false) &&
      (!inert || (c.attributes?.containsKey('inert') ?? false)),
);

void main() {
  group('the backdrop goes inert exactly while a modal entry is open', () {
    test('a non-modal entry leaves the background reachable', () {
      // A tooltip or hover card must not take the page away — the
      // whole point of routing modality through the mount call rather
      // than through the layer is that a layer holds both kinds.
      final controller = OverlayController();

      controller.mount(layer: .tooltip, panel: _panel());

      expect(controller.hasModalEntry, isFalse);
      controller.dispose();
    });

    test('a modal entry makes it inert, and closing gives it back', () {
      final controller = OverlayController();

      final token = controller.mount(
        layer: .dialog,
        panel: _panel(),
        modal: true,
      );
      expect(controller.hasModalEntry, isTrue);

      controller.unmount(token);
      expect(controller.hasModalEntry, isFalse);
      controller.dispose();
    });

    test('stacked modals do not release the page early', () {
      // A dialog that opens a confirm dialog. A counter decremented by
      // the inner close would hand the page back while the outer one
      // is still up.
      final controller = OverlayController();

      final outer = controller.mount(
        layer: .dialog,
        panel: _panel(),
        modal: true,
      );
      final inner = controller.mount(
        layer: .dialog,
        panel: _panel(),
        modal: true,
      );

      controller.unmount(inner);
      expect(
        controller.hasModalEntry,
        isTrue,
        reason: 'the outer dialog is still open',
      );

      controller.unmount(outer);
      expect(controller.hasModalEntry, isFalse);
      controller.dispose();
    });

    test('unmounting the same token twice does not strand the page', () {
      // The failure a counter would produce: two decrements for one
      // mount, and the page never comes back.
      final controller = OverlayController();

      final modal = controller.mount(
        layer: .dialog,
        panel: _panel(),
        modal: true,
      );
      final other = controller.mount(
        layer: .dialog,
        panel: _panel(),
        modal: true,
      );

      controller.unmount(modal);
      controller.unmount(modal);
      expect(controller.hasModalEntry, isTrue);

      controller.unmount(other);
      expect(controller.hasModalEntry, isFalse);
      controller.dispose();
    });

    test('a non-modal entry does not hold the page after a modal closes', () {
      final controller = OverlayController();

      controller.mount(layer: .menu, panel: _panel());
      final modal = controller.mount(
        layer: .dialog,
        panel: _panel(),
        modal: true,
      );

      controller.unmount(modal);

      expect(controller.hasModalEntry, isFalse);
      controller.dispose();
    });
  });

  group('the attribute actually reaches the rendered backdrop', () {
    testComponents('a modal entry marks the page inert', (tester) async {
      // The controller flag is not the contract — the attribute on the
      // element is. `inert` is what removes the subtree from the
      // accessibility tree, the tab order, and hit-testing all at once.
      tester.pumpComponent(const OverlayHost(child: _Opener(modal: true)));
      await tester.pump();

      expect(_backdrop(), findsOneComponent);
      expect(_backdrop(inert: true), findsOneComponent);
    });

    testComponents('a non-modal entry leaves it alone', (tester) async {
      tester.pumpComponent(const OverlayHost(child: _Opener(modal: false)));
      await tester.pump();

      expect(_backdrop(), findsOneComponent);
      expect(_backdrop(inert: true), findsNothing);
    });
  });
}
