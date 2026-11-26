import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/components/infra/drag_item/drag_item.dart';
import 'package:coui_web/src/components/infra/drag_scope/drag_scope.dart';
import 'package:coui_web/src/components/layout/draggable_panel/draggable_panel.dart';
import 'package:coui_web/src/components/layout/draggable_panel/draggable_panel_style.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/theme/theme_data.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

void main() {
  group('DraggablePanel', () {
    testComponents('disabled renders only the child (no handle)', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const DraggablePanel(child: span([Component.text('BODY')])),
      );

      expect(find.text('BODY'), findsOneComponent);
    });

    testComponents('routes the handle drag through the shared drag engine', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const DraggablePanel(child: span([Component.text('BODY')])),
      );

      // The handle is an engine draggable inside this panel's own scope —
      // the same `coui_core` runtime the Flutter twin uses.
      expect(find.byType(DragScope), findsOneComponent);
      expect(find.byType(DragItem), findsOneComponent);
    });

    testComponents(
      'panel keeps its surface marker + published fill mid-drag (#4359)',
      (tester) async {
        // `dragging` only suppresses the handle's CSS transition (Flutter
        // parity: `_animate = false`) — it must not touch the panel's
        // marker/fill pair, or the material would flicker off for the
        // duration of every drag.
        late ResolvedDraggablePanel rest;
        late ResolvedDraggablePanel dragging;
        pumpWithTheme(
          tester,
          Builder(
            builder: (context) {
              rest = resolveDraggablePanel(context);
              dragging = resolveDraggablePanel(context, dragging: true);
              return const Component.text('ok');
            },
          ),
        );

        for (final resolved in [rest, dragging]) {
          expect(resolved.panel.className, contains(kWebSurfaceMarker));
          expect(
            resolved.panel.inlineStyles?.properties ?? const {},
            contains(kWebSurfaceFillVar),
          );
        }
      },
    );

    testComponents('the panel does not scroll — the scroller inside it does', (
      tester,
    ) async {
      // A scrolling box clips its own content at its padding box, which cuts
      // the surface's edge band off at the border. Flutter's panel is a
      // `SingleChildScrollView` inside the `Padding` inside the box that draws
      // the border, so the scroller is inside here too.
      late ResolvedDraggablePanel resolved;
      pumpWithTheme(
        tester,
        Builder(
          builder: (context) {
            resolved = resolveDraggablePanel(context);
            return const Component.text('ok');
          },
        ),
      );

      final panel = resolved.panel.className.split(' ');
      expect(panel, containsAll(['absolute', 'flex', 'flex-col']));
      expect(panel, isNot(contains('overflow-y-auto')));
      final scroller = resolved.panelScroller.className.split(' ');
      expect(scroller, containsAll(['overflow-y-auto', 'min-h-0']));
      // Layout only: the surface (border, fill, shadow, padding) stays the
      // panel's.
      expect(resolved.panelScroller.inlineStyles, isNull);
    });

    testComponents('the panel says its border, so the band reaches over it', (
      tester,
    ) async {
      late ResolvedDraggablePanel resolved;
      pumpWithTheme(
        tester,
        Builder(
          builder: (context) {
            resolved = resolveDraggablePanel(context);
            return const Component.text('ok');
          },
        ),
      );

      final inline = resolved.panel.inlineStyles!.properties;
      expect(inline[kWebSurfaceBleedVar], inline['border-width']);
      // It does not clip, so it says nothing of the clip kind.
      expect(inline.containsKey(kWebSurfaceClipPadVar), isFalse);
      expect(inline['border-style'], isNot(contains(kWebSurfaceEdgeStyleVar)));
      expect(
        resolved.panel.className.split(' '),
        isNot(contains(kWebSurfaceClipMarker)),
      );
    });

    testComponents('an open panel scrolls in the scroller, never on itself', (
      tester,
    ) async {
      // The widget adds the placement to the panel's own inline style, and an
      // `overflow-y` there would put the scroll back on the surface — which
      // the class-level resolver output above cannot show. Only the placement
      // before the first measurement is reachable here (the measured one needs
      // a laid-out container, which a unit test has no browser to give), so the
      // measured one is read off a real page instead.
      final controller = CoreDraggablePanelController(initiallyOpen: true);
      addTearDown(controller.dispose);
      pumpWithTheme(
        tester,
        DraggablePanel(
          controller: controller,
          panel: const span([Component.text('PANEL')]),
          child: const span([Component.text('BODY')]),
        ),
      );

      final surfaces = find
          .byType(DomComponent)
          .evaluate()
          .map((e) => e.component as DomComponent)
          .where((d) => (d.classes ?? '').contains(kWebSurfaceMarker))
          .toList();
      expect(surfaces, hasLength(1), reason: 'the open panel is the surface');
      final panel = surfaces.single;
      expect(panel.styles!.properties.keys, isNot(contains('overflow-y')));
      expect(panel.styles!.properties.keys, isNot(contains('overflow')));

      final scrollers = find
          .byType(DomComponent)
          .evaluate()
          .map((e) => e.component as DomComponent)
          .where(
            (d) => (d.classes ?? '').split(' ').contains('overflow-y-auto'),
          )
          .toList();
      expect(scrollers, hasLength(1), reason: 'the one scroller, inside');
      expect(scrollers.single.classes, isNot(contains(kWebSurfaceMarker)));
      expect(find.text('PANEL'), findsOneComponent);
    });

    testComponents('panel content stays hidden until opened', (tester) async {
      pumpWithTheme(
        tester,
        const DraggablePanel(
          panel: span([Component.text('PANEL')]),
          child: span([Component.text('BODY')]),
        ),
      );

      expect(find.text('BODY'), findsOneComponent);
      expect(find.text('PANEL'), findsNothing);
    });

    test('handle drag activation matches the Flutter twin', () {
      // Both platforms read the same shared behaviour default, so the
      // handle disambiguates tap from drag identically.
      expect(
        CoreDraggablePanelContract.defaultDragActivationDistance,
        greaterThan(0),
      );
    });
    testComponents('an outside dock clips the root; inside does not', (
      tester,
    ) async {
      // The outside handle rests partly past the edge — the part beyond
      // must be cut off rather than widen the page (Flutter parity: the
      // Stacks root clips hard-edge).
      late ResolvedDraggablePanel inside;
      late ResolvedDraggablePanel outside;
      pumpWithTheme(
        tester,
        Builder(
          builder: (context) {
            inside = resolveDraggablePanel(context);
            outside = resolveDraggablePanel(
              context,
              dockType: CoreDraggablePanelDockType.outside,
            );
            return const Component.text('ok');
          },
        ),
      );

      expect(
        inside.root.className.split(' '),
        isNot(contains('overflow-hidden')),
      );
      expect(outside.root.className.split(' '), contains('overflow-hidden'));
    });
  });

  // The client path — what runs after hydration, once the root box is
  // measured. The browser is the only place that measures, so the
  // placement arithmetic lives in the style file where a unit test can
  // drive it: the widget hands its controller state straight through.
  group('DraggablePanel dock geometry (client runtime)', () {
    const width = 800.0;
    const handle = CoreDraggablePanelStyle.defaultHandleSize;
    const offset = CoreDraggablePanelContract.defaultDockOffset;
    const rightSlot = width - handle - offset;
    const hidden =
        handle * (1 - CoreDraggablePanelDockType.outsideVisibleFraction);

    ResolvedDraggablePanelRuntime runtimeFor(
      ComponentTester tester, {
      required CoreDraggablePanelDockType dockType,
      ThemeData? theme,
    }) {
      late ResolvedDraggablePanelRuntime runtime;
      final probe = Builder(
        builder: (context) {
          runtime = resolveDraggablePanelRuntime(context, dockType: dockType);
          return const Component.text('ok');
        },
      );
      if (theme == null) {
        pumpWithTheme(tester, probe);
      } else {
        tester.pumpComponent(Theme(data: theme, child: probe));
      }
      return runtime;
    }

    String? leftOf(Styles styles) => styles.properties['left'];
    String rem(double px) => '${px / kRemDivisor}rem';

    testComponents('a closed outside handle is painted past the edge; '
        'opening pulls it in, closing sends it back out', (tester) async {
      final runtime = runtimeFor(tester, dockType: .outside);

      Styles at({required bool open}) =>
          buildDraggablePanelHandlePositionInlineStyles(
            runtime,
            positioned: true,
            x: rightSlot,
            y: 0,
            open: open,
            dragging: false,
            initialTop: '25%',
            containerWidth: width,
          );

      final closed = at(open: false);
      final opened = at(open: true);
      final closedAgain = at(open: false);

      expect(leftOf(closed), rem(width - handle + hidden));
      expect(leftOf(opened), rem(rightSlot));
      expect(leftOf(closedAgain), leftOf(closed));
    });

    testComponents('an outside handle snapped left rests past the left edge', (
      tester,
    ) async {
      final runtime = runtimeFor(tester, dockType: .outside);

      final snapped = runtime.dockSlotX(containerWidth: width, left: true);
      final styles = buildDraggablePanelHandlePositionInlineStyles(
        runtime,
        positioned: true,
        x: snapped,
        y: 0,
        open: false,
        dragging: false,
        initialTop: '25%',
        containerWidth: width,
      );

      expect(snapped, offset);
      expect(leftOf(styles), rem(-hidden));
    });

    testComponents('a live drag tracks the pointer instead of the rest slot', (
      tester,
    ) async {
      final runtime = runtimeFor(tester, dockType: .outside);

      expect(
        runtime.paintedX(
          x: rightSlot,
          open: false,
          dragging: true,
          containerWidth: width,
        ),
        rightSlot,
      );
      // The drag range opens past both edges by the hidden share.
      expect(runtime.dragMinX, -hidden);
      expect(runtime.dragMaxX(width), width - handle + hidden);
    });

    testComponents('inside paints the logical slot in every state', (
      tester,
    ) async {
      final runtime = runtimeFor(tester, dockType: .inside);

      for (final open in [false, true]) {
        expect(
          runtime.paintedX(
            x: rightSlot,
            open: open,
            dragging: false,
            containerWidth: width,
          ),
          rightSlot,
        );
      }
      expect(runtime.dragMinX, offset);
      expect(runtime.dragMaxX(width), rightSlot);
    });

    testComponents('a theme handle size moves the hidden share with it', (
      tester,
    ) async {
      // Flutter reads its resolved handle size for both painting and
      // docking; the Web runtime must read the same merged value, or a
      // theme override would paint one width and hide another.
      const themed = CoreSize.size64;
      final runtime = runtimeFor(
        tester,
        dockType: .outside,
        theme: const ThemeData(
          coreComponentTheme: CoreComponentTheme(
            draggablePanel: CoreDraggablePanelTheme(
              style: CoreDraggablePanelStyle(handleSize: themed),
            ),
          ),
        ),
      );

      final painted = runtime.paintedX(
        x: runtime.dockSlotX(containerWidth: width, left: false),
        open: false,
        dragging: false,
        containerWidth: width,
      );

      expect(runtime.handleSize, themed);
      expect(
        (width - painted) / themed,
        CoreDraggablePanelDockType.outsideVisibleFraction,
      );
    });
  });
}
