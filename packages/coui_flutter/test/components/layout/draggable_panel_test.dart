import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_test/flutter_test.dart';

material.Widget _buildApp(
  material.Widget child, {
  ThemeData theme = const ThemeData(),
}) => material.MaterialApp(
  home: material.Scaffold(
    body: Theme(
      data: theme,
      child: SizedBox(
        width: _kViewWidth,
        height: _kViewHeight,
        child: child,
      ),
    ),
  ),
);

const double _kViewWidth = 800;
const double _kViewHeight = 600;

void main() {
  group('CoreDraggablePanelController', () {
    test('toggle flips open and notifies listeners', () {
      final controller = CoreDraggablePanelController();
      addTearDown(controller.dispose);
      var notifications = 0;
      controller.addListener((_) => notifications++);

      expect(controller.open, isFalse);
      controller.toggle();
      expect(controller.open, isTrue);
      expect(notifications, 1);
    });

    test('setPosition updates x/y in one notification, no-op when same', () {
      final controller = CoreDraggablePanelController(
        initialX: 10,
        initialY: 20,
      );
      addTearDown(controller.dispose);
      var notifications = 0;
      controller
        ..addListener((_) => notifications++)
        ..setPosition(10, 20); // same → no-op
      expect(notifications, 0);
      controller.setPosition(30, 40);
      expect(notifications, 1);
      expect(controller.x, 30);
      expect(controller.y, 40);
    });
  });

  group('CoreDraggablePanelStyle', () {
    test('merge overrides only non-null fields', () {
      const base = CoreDraggablePanelStyle(panelWidth: 100);
      const other = CoreDraggablePanelStyle(handleSize: 50);
      final merged = base.merge(other);

      expect(merged.panelWidth, 100);
      expect(merged.handleSize, 50);
    });

    test('equality compares all fields including shadow lists', () {
      const a = CoreDraggablePanelStyle(panelShadow: CoreShadow.lg);
      const b = CoreDraggablePanelStyle(panelShadow: CoreShadow.lg);
      const c = CoreDraggablePanelStyle(panelShadow: CoreShadow.md);

      expect(a, b);
      expect(a == c, isFalse);
    });
  });

  group('DraggablePanel', () {
    testWidgets('disabled renders only the child (no handle)', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const DraggablePanel(
            enabled: false,
            child: Text('BODY'),
          ),
        ),
      );

      expect(find.text('BODY'), findsOneWidget);
      expect(find.byType(AnimatedPositioned), findsNothing);
    });

    testWidgets('enabled overlays a draggable handle on the child', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          const DraggablePanel(
            panel: Text('PANEL'),
            child: Text('BODY'),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('BODY'), findsOneWidget);
      // Handle present; panel hidden until opened.
      expect(find.byType(AnimatedPositioned), findsOneWidget);
      expect(find.text('PANEL'), findsNothing);
    });

    testWidgets('tapping the handle toggles the panel open', (tester) async {
      var openState = false;
      await tester.pumpWidget(
        _buildApp(
          DraggablePanel(
            onOpenChanged: (open) => openState = open,
            panel: const Text('PANEL'),
            child: const SizedBox.expand(),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byType(AnimatedPositioned));
      await tester.pumpAndSettle();

      expect(openState, isTrue);
      expect(find.text('PANEL'), findsOneWidget);
    });

    testWidgets('dragging the handle moves it and snaps on release', (
      tester,
    ) async {
      double? lastX;
      await tester.pumpWidget(
        _buildApp(
          DraggablePanel(
            onPositionChanged: (x, _) => lastX = x,
            child: const SizedBox.expand(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Drag the handle towards the left edge; it should snap to the left.
      await tester.drag(find.byType(AnimatedPositioned), const Offset(-700, 0));
      await tester.pumpAndSettle();

      expect(lastX, isNotNull);
      // Snapped to the left dock offset (8) rather than staying mid-screen.
      expect(lastX, lessThan(_kViewWidth / 2));
    });

    testWidgets('routes the handle drag through the shared drag engine', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(const DraggablePanel(child: SizedBox.expand())),
      );
      await tester.pumpAndSettle();

      // The handle is an engine draggable inside this panel's own scope —
      // the same `coui_core` runtime the Web twin uses.
      expect(find.byType(DragScope), findsOneWidget);
      expect(find.byType(DragItem), findsOneWidget);
    });

    testWidgets('keyboard drag moves the handle (engine capability)', (
      tester,
    ) async {
      final controller = CoreDraggablePanelController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _buildApp(
          DraggablePanel(
            controller: controller,
            child: const SizedBox.expand(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final startX = controller.x;
      // Focus the handle, pick it up, walk it left, then drop it. The
      // focus node lives inside the engine draggable, below `DragItem`.
      final handleFocus = tester.widget<Focus>(
        find
            .descendant(of: find.byType(DragItem), matching: find.byType(Focus))
            .first,
      );
      handleFocus.focusNode!.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();

      // Assert mid-drag: the release always snaps back to an edge, so the
      // keyboard step is only observable while the drag is still held.
      expect(controller.x, lessThan(startX));

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
    });
  });

  group('DraggablePanel dockType', () {
    // The handle's own AnimatedPositioned — the panel has one too once open.
    Finder handleSlot() => find.ancestor(
      of: find.byType(DragItem),
      matching: find.byType(AnimatedPositioned),
    );

    AnimatedPositioned handleOf(WidgetTester tester) =>
        tester.widget<AnimatedPositioned>(handleSlot());

    // Taps inside the part of the handle that is still on screen.
    Future<void> tapVisibleHandle(WidgetTester tester) async {
      final handle = handleOf(tester);
      final left = handle.left!;
      final width = handle.width!;
      final visibleLeft = left < 0 ? 0.0 : left;
      final visibleRight = left + width > _kViewWidth
          ? _kViewWidth
          : left + width;
      await tester.tapAt(
        tester.getTopLeft(find.byType(DraggablePanel)) +
            Offset(
              (visibleLeft + visibleRight) / 2,
              handle.top! + handle.height! / 2,
            ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('inside rests dockOffset in from the right edge', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(const DraggablePanel(child: SizedBox.expand())),
      );
      await tester.pumpAndSettle();

      final handle = handleOf(tester);
      expect(
        handle.left,
        _kViewWidth -
            handle.width! -
            CoreDraggablePanelContract.defaultDockOffset,
      );
    });

    testWidgets('outside rests past the edge with the stated share visible', (
      tester,
    ) async {
      final controller = CoreDraggablePanelController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _buildApp(
          DraggablePanel(
            dockType: CoreDraggablePanelDockType.outside,
            controller: controller,
            child: const SizedBox.expand(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final handle = handleOf(tester);
      final width = handle.width!;
      expect(
        _kViewWidth - handle.left!,
        width * CoreDraggablePanelDockType.outsideVisibleFraction,
      );
      // The logical slot stays the inside one — that is where a tap
      // returns it to and what persistence reads back.
      expect(
        controller.x,
        _kViewWidth - width - CoreDraggablePanelContract.defaultDockOffset,
      );
    });

    testWidgets('tapping an outside handle pulls it in and opens the panel; '
        'closing slides it back out', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const DraggablePanel(
            dockType: CoreDraggablePanelDockType.outside,
            panel: Text('PANEL'),
            child: SizedBox.expand(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final restingLeft = handleOf(tester).left!;

      await tapVisibleHandle(tester);
      final width = handleOf(tester).width!;
      final pulledIn =
          _kViewWidth - width - CoreDraggablePanelContract.defaultDockOffset;
      expect(find.text('PANEL'), findsOneWidget);
      expect(handleOf(tester).left, pulledIn);
      expect(restingLeft, greaterThan(pulledIn));

      await tapVisibleHandle(tester);
      expect(find.text('PANEL'), findsNothing);
      expect(handleOf(tester).left, restingLeft);
    });

    testWidgets('an outside handle dragged left rests past the left edge', (
      tester,
    ) async {
      final controller = CoreDraggablePanelController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _buildApp(
          DraggablePanel(
            dockType: CoreDraggablePanelDockType.outside,
            controller: controller,
            child: const SizedBox.expand(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final handle = handleOf(tester);
      await tester.dragFrom(
        tester.getTopLeft(find.byType(DraggablePanel)) +
            Offset(handle.left! + handle.width! / 4, handle.top! + 4),
        const Offset(-700, 0),
      );
      await tester.pumpAndSettle();

      final width = handleOf(tester).width!;
      expect(
        handleOf(tester).left,
        -width * (1 - CoreDraggablePanelDockType.outsideVisibleFraction),
      );
      expect(controller.x, CoreDraggablePanelContract.defaultDockOffset);
    });

    testWidgets('a drag starts from where an outside handle is painted', (
      tester,
    ) async {
      // A short drag that stays clear of the clamp: anchoring at the
      // logical slot instead would make the handle jump inward by the
      // share hidden past the edge the moment the drag begins.
      await tester.pumpWidget(
        _buildApp(
          const DraggablePanel(
            dockType: CoreDraggablePanelDockType.outside,
            child: SizedBox.expand(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final handle = handleOf(tester);
      final restingLeft = handle.left!;
      const travel = 40.0;

      final gesture = await tester.startGesture(
        tester.getTopLeft(find.byType(DraggablePanel)) +
            Offset(restingLeft + handle.width! / 4, handle.top! + 4),
      );
      // In steps, so the engine claims the pointer past its activation
      // distance and then keeps tracking; the transform is measured from
      // the pointer-down position.
      for (var moved = 0.0; moved < travel; moved += travel / 4) {
        await gesture.moveBy(const Offset(-travel / 4, 0));
        await tester.pump();
      }

      // Read mid-drag, before the release snaps it back to the edge.
      final draggedLeft = handleOf(tester).left;
      await gesture.up();
      await tester.pumpAndSettle();

      expect(draggedLeft, restingLeft - travel);
    });

    testWidgets('a theme handle size moves the hidden share with it', (
      tester,
    ) async {
      // The Web twin resolves its dock geometry through the same merge
      // chain; both platforms must hide the same share of the handle the
      // theme actually paints.
      const themed = CoreSize.size64;
      await tester.pumpWidget(
        _buildApp(
          const DraggablePanel(
            dockType: CoreDraggablePanelDockType.outside,
            child: SizedBox.expand(),
          ),
          theme: const ThemeData(
            coreComponentTheme: CoreComponentTheme(
              draggablePanel: CoreDraggablePanelTheme(
                style: CoreDraggablePanelStyle(handleSize: themed),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final handle = handleOf(tester);
      expect(handle.width, themed);
      expect(
        (_kViewWidth - handle.left!) / themed,
        CoreDraggablePanelDockType.outsideVisibleFraction,
      );
    });
  });
}
