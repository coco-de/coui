import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

material.Widget _buildApp(material.Widget child) => material.MaterialApp(
  home: material.Theme(data: material.ThemeData(), child: child),
);

const _kPopoverConstraintCount = 5;

void main() {
  group('Popover scroll policy', () {
    for (final closeOnScroll in [false, true]) {
      testWidgets('ancestor scroll respects $closeOnScroll', (tester) async {
        final scroll = material.ScrollController();
        final popover = PopoverController();
        var closed = 0;
        addTearDown(scroll.dispose);
        addTearDown(popover.dispose);
        await tester.pumpWidget(
          _buildApp(
            Theme(
              data: const ThemeData(),
              child: material.ListView(
                controller: scroll,
                children: [
                  Popover(
                    controller: popover,
                    openTrigger: CorePopoverTrigger.manual,
                    closeOnScroll: closeOnScroll,
                    onClose: () => closed++,
                    trigger: const material.SizedBox(height: 40),
                    content: const material.Text('Panel'),
                  ),
                  const material.SizedBox(height: 1200),
                ],
              ),
            ),
          ),
        );
        popover.show();
        await tester.pump(const Duration(seconds: 1));
        expect(popover.isOpen, isTrue);
        scroll.jumpTo(20);
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        expect(popover.isOpen, !closeOnScroll);
        expect(closed, closeOnScroll ? 1 : 0);
      });
    }

    test('default remains open on scroll and copyWith retains policy', () {
      const popover = Popover(
        trigger: material.Text('A'),
        content: material.Text('B'),
      );
      expect(popover.closeOnScroll, isFalse);
      expect(
        popover.copyWith(closeOnScroll: true).copyWith().closeOnScroll,
        isTrue,
      );
    });
  });

  group('CorePopoverConstraint', () {
    test('has correct enum values', () {
      expect(
        CorePopoverConstraint.values,
        containsAll([
          CorePopoverConstraint.anchorFixedSize,
          CorePopoverConstraint.anchorMaxSize,
          CorePopoverConstraint.anchorMinSize,
          CorePopoverConstraint.flexible,
          CorePopoverConstraint.intrinsic,
        ]),
      );
    });

    test('has exactly 5 values', () {
      expect(CorePopoverConstraint.values.length, _kPopoverConstraintCount);
    });

    test('anchorFixedSize value exists', () {
      expect(
        CorePopoverConstraint.anchorFixedSize,
        isA<CorePopoverConstraint>(),
      );
    });

    test('anchorMaxSize value exists', () {
      expect(CorePopoverConstraint.anchorMaxSize, isA<CorePopoverConstraint>());
    });

    test('anchorMinSize value exists', () {
      expect(CorePopoverConstraint.anchorMinSize, isA<CorePopoverConstraint>());
    });

    test('flexible value exists', () {
      expect(CorePopoverConstraint.flexible, isA<CorePopoverConstraint>());
    });

    test('intrinsic value exists', () {
      expect(CorePopoverConstraint.intrinsic, isA<CorePopoverConstraint>());
    });

    test('values are distinct', () {
      final values = CorePopoverConstraint.values.toSet();
      expect(values.length, equals(CorePopoverConstraint.values.length));
    });
  });

  group('PopoverController', () {
    test('can be constructed with default constructor', () {
      final controller = PopoverController();
      addTearDown(controller.dispose);

      expect(controller, isA<PopoverController>());
    });

    test('isOpen is false by default', () {
      final controller = PopoverController();
      addTearDown(controller.dispose);

      expect(controller.isOpen, isFalse);
    });

    test('dispose can be called without error', () {
      final controller = PopoverController();

      expect(() => controller.dispose(), returnsNormally);
    });

    test('isOpen remains false after construction', () {
      final controller = PopoverController();
      addTearDown(controller.dispose);

      expect(controller.isOpen, isFalse);
    });

    test('multiple controllers are independent', () {
      final controllerA = PopoverController();
      final controllerB = PopoverController();
      addTearDown(controllerA.dispose);
      addTearDown(controllerB.dispose);

      expect(controllerA.isOpen, isFalse);
      expect(controllerB.isOpen, isFalse);
    });

    testWidgets('renders without error in widget tree', (tester) async {
      final controller = PopoverController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _buildApp(const material.SizedBox()),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.byType(material.SizedBox), findsOneWidget);
    });
  });

  group('Popover keyboard (IME) inset avoidance', () {
    // Regression: a popover anchored to a trigger sitting just above the
    // soft keyboard must not render its panel behind the keyboard. The
    // collision engine measures against the full overlay height, so
    // `viewInsets.bottom` (the IME) has to be folded into the panel margin;
    // otherwise the panel opens downward into the keyboard region and the
    // suggestion list is hidden (kobic onboarding department field bug).
    //
    // Screen 400x800 @ dpr 1, keyboard 300 (top at y=500). Trigger sits at
    // 250..290 — just above the keyboard. Default `bottom` placement would
    // put the 240px panel at 290..530, i.e. 30px behind the keyboard. With
    // the inset folded in, collision flips/shifts the panel above the
    // trigger so its bottom stays at/above y=500.
    testWidgets('panel stays clear of the keyboard region', (tester) async {
      const keyboardHeight = 300.0;
      const screenHeight = 800.0;
      const keyboardTop = screenHeight - keyboardHeight;
      const contentKey = material.ValueKey('popover-ime-content');

      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const material.Size(400, screenHeight);
      tester.view.viewInsets = const FakeViewPadding(bottom: keyboardHeight);
      addTearDown(tester.view.reset);

      final controller = PopoverController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        material.MaterialApp(
          home: Theme(
            data: const ThemeData(),
            child: material.Stack(
              children: [
                material.Positioned(
                  top: 250,
                  left: 100,
                  child: Popover(
                    controller: controller,
                    openTrigger: CorePopoverTrigger.manual,
                    trigger: const material.SizedBox(width: 120, height: 40),
                    content: const material.SizedBox(
                      key: contentKey,
                      width: 200,
                      height: 240,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      controller.show();
      // The panel's `follow` ticker schedules a frame every tick, so
      // `pumpAndSettle` never quiesces — pump explicit frames to build the
      // overlay and finish the open animation instead.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final contentRect = tester.getRect(find.byKey(contentKey));

      expect(
        contentRect.bottom,
        lessThanOrEqualTo(keyboardTop),
        reason:
            'popover panel (bottom=${contentRect.bottom}) must stay above the '
            'keyboard top ($keyboardTop)',
      );

      // Close the overlay so its follow ticker is torn down before the test
      // harness checks for leaked tickers/timers.
      controller.close();
      await tester.pump(const Duration(milliseconds: 500));
    });
  });

  group('Popover follows its host while open', () {
    // The panel is mounted in the app's overlay, outside the host's own
    // subtree, so a host that rebuilds with new content has to reach it
    // explicitly. Web hosts re-sync the portalled panel on every build; this
    // is the Flutter half of that statement.
    testWidgets('swapping the content re-renders the open panel', (
      tester,
    ) async {
      final content = material.ValueNotifier<String>('Sorted every 5s');
      addTearDown(content.dispose);
      final controller = PopoverController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _buildApp(
          Theme(
            data: const ThemeData(),
            child: material.Center(
              child: material.ValueListenableBuilder<String>(
                valueListenable: content,
                builder: (_, value, _) => Popover(
                  controller: controller,
                  openTrigger: CorePopoverTrigger.manual,
                  trigger: const material.SizedBox(width: 120, height: 40),
                  content: material.Text(value),
                ),
              ),
            ),
          ),
        ),
      );

      controller.show();
      // The follow ticker schedules a frame every tick, so settle by pumping
      // explicit frames.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Sorted every 5s'), findsOneWidget);

      content.value = 'Sorted every 4s';
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(tester.takeException(), isNull);
      expect(find.text('Sorted every 4s'), findsOneWidget);
      expect(find.text('Sorted every 5s'), findsNothing);

      controller.close();
      await tester.pump(const Duration(milliseconds: 500));
    });
  });

  group('anchoring when overlay space differs from screen space', () {
    // Apps that lay their content out at a fixed logical width and then
    // scale it to fit (`ResponsiveScaledBox` and friends) put a transform
    // between the view and the `Navigator`/`Overlay`. The overlay is then
    // laid out in a *different* coordinate space than the screen, and an
    // anchor measured in screen space lands at the wrong spot — the error
    // grows toward the right/bottom edge.
    //
    // 480 laid out onto a 390 screen is the real-world case this was found
    // in: a `bottomEnd` panel rendered 25dp left of its trigger.
    const layoutWidth = 480.0;
    const screenWidth = 390.0;
    const layoutHeight = 1040.0;
    const screenHeight = 844.0;
    const triggerKey = material.ValueKey('scaled-trigger');
    const contentKey = material.ValueKey('scaled-content');

    testWidgets('bottomEnd panel stays aligned to its trigger', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const material.Size(screenWidth, screenHeight);
      addTearDown(tester.view.reset);

      final controller = PopoverController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        material.MaterialApp(
          // Wraps the `Navigator` (and therefore the `Overlay`), matching
          // where such apps install their scaler.
          // `FittedBox` hands the child unbounded constraints, so the
          // subtree really is laid out at `layoutWidth` and then scaled
          // onto the screen — a plain `Transform` would leave the incoming
          // tight constraints in place and the `SizedBox` would clamp.
          builder: (context, child) => material.FittedBox(
            fit: material.BoxFit.fill,
            alignment: material.Alignment.topLeft,
            child: material.SizedBox(
              width: layoutWidth,
              height: layoutHeight,
              child: child,
            ),
          ),
          home: Theme(
            data: const ThemeData(),
            child: material.Stack(
              children: [
                material.Positioned(
                  top: 100,
                  // Inset from the edge so the panel fits without a
                  // collision shift — this asserts anchoring, not clamping.
                  right: 60,
                  child: Popover(
                    controller: controller,
                    placement: CorePopoverPlacement.bottomEnd,
                    openTrigger: CorePopoverTrigger.manual,
                    // Drop the panel's default 16px padding so the content
                    // box *is* the panel box — the assertion then compares
                    // anchor edges directly instead of edge-minus-padding.
                    popoverStyle: const CorePopoverStyle(
                      panelStyle: CorePopupStyle(padding: CoreEdgeInsets.zero),
                    ),
                    trigger: const material.SizedBox(
                      key: triggerKey,
                      width: 120,
                      height: 40,
                    ),
                    content: const material.SizedBox(
                      key: contentKey,
                      width: 200,
                      height: 240,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      final triggerRect = tester.getRect(find.byKey(triggerKey));

      controller.show();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final contentRect = tester.getRect(find.byKey(contentKey));

      // Both rects come back in screen space, so the scale cancels out —
      // `bottomEnd` means the panel's right edge sits on the trigger's.
      expect(
        contentRect.right,
        closeTo(triggerRect.right, 1),
        reason:
            'bottomEnd panel right (${contentRect.right}) must sit on the '
            'trigger right (${triggerRect.right}); a screen-space anchor '
            'applied in overlay space drifts left as the trigger moves '
            'toward the right edge',
      );
      expect(
        contentRect.top,
        greaterThanOrEqualTo(triggerRect.bottom),
        reason: 'panel must hang below the trigger, not overlap it',
      );

      controller.close();
      await tester.pump(const Duration(milliseconds: 500));
    });
  });
}
