import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

const _kConstraintsMinSize = 200.0;
const _kNavigatorWidth = 800.0;
const _kNavigatorHeight = 600.0;
const _kProbeLeft = 10.0;
const _kProbeTop = 20.0;
const _kProbeWidth = 300.0;
const _kProbeHeight = 400.0;
const _kDragStep = Offset(15, 15);
const _kDragStepCount = 10;

/// Drains `pumpAndSettle`'s frame-count return in one place so call
/// sites stay single-expression awaits.
Future<void> _settle(WidgetTester tester) async {
  final _ = await tester.pumpAndSettle();
}

void main() {
  group('CoreWindowRect', () {
    test('fromLTWH stores fields', () {
      const rect = CoreWindowRect.fromLTWH(
        _kProbeLeft,
        _kProbeTop,
        _kProbeWidth,
        _kProbeHeight,
      );

      expect(rect.left, equals(_kProbeLeft));
      expect(rect.top, equals(_kProbeTop));
      expect(rect.width, equals(_kProbeWidth));
      expect(rect.height, equals(_kProbeHeight));
    });

    test('equality with same values', () {
      const a = CoreWindowRect.fromLTWH(0, 0, 100, 100);
      const b = CoreWindowRect.fromLTWH(0, 0, 100, 100);

      expect(a, equals(b));
    });

    test('inequality with different values', () {
      const a = CoreWindowRect.fromLTWH(0, 0, 100, 100);
      const b = CoreWindowRect.fromLTWH(0, 0, 200, 100);

      expect(a, isNot(equals(b)));
    });
  });

  group('CoreWindowConstraints', () {
    test('minimum sets min sizes', () {
      const constraints = CoreWindowConstraints.minimum(_kConstraintsMinSize);

      expect(constraints.minWidth, equals(_kConstraintsMinSize));
      expect(constraints.minHeight, equals(_kConstraintsMinSize));
    });

    test('kCoreDefaultWindowConstraints minimum is 200', () {
      expect(
        kCoreDefaultWindowConstraints.minWidth,
        equals(_kConstraintsMinSize),
      );
      expect(
        kCoreDefaultWindowConstraints.minHeight,
        equals(_kConstraintsMinSize),
      );
    });
  });

  group('CoreWindowController', () {
    test('initializes with provided bounds', () {
      final controller = CoreWindowController(
        bounds: const CoreWindowRect.fromLTWH(0, 0, 300, 200),
      );

      expect(
        controller.bounds,
        equals(const CoreWindowRect.fromLTWH(0, 0, 300, 200)),
      );
      controller.dispose();
    });

    test('bounds setter updates bounds', () {
      final controller = CoreWindowController(
        bounds: const CoreWindowRect.fromLTWH(0, 0, 300, 200),
      );
      controller.bounds = const CoreWindowRect.fromLTWH(10, 10, 400, 300);

      expect(
        controller.bounds,
        equals(const CoreWindowRect.fromLTWH(10, 10, 400, 300)),
      );
      controller.dispose();
    });

    test('minimized setter toggles minimized state', () {
      final controller = CoreWindowController(
        bounds: const CoreWindowRect.fromLTWH(0, 0, 300, 200),
      );
      controller.minimized = true;

      expect(controller.minimized, isTrue);
      controller.dispose();
    });

    test('alwaysOnTop setter updates flag', () {
      final controller = CoreWindowController(
        bounds: const CoreWindowRect.fromLTWH(0, 0, 300, 200),
      );
      controller.alwaysOnTop = true;

      expect(controller.alwaysOnTop, isTrue);
      controller.dispose();
    });

    test('setter notifies listeners', () {
      final controller = CoreWindowController(
        bounds: const CoreWindowRect.fromLTWH(0, 0, 300, 200),
      );
      var notified = false;
      void handleChange(CoreWindowState state) => notified = true;
      controller.addListener(handleChange);

      controller.minimized = true;

      expect(notified, isTrue);
      controller.removeListener(handleChange);
      controller.dispose();
    });
  });

  group('WindowNavigator snapped-window interaction', () {
    Widget buildNavigator(Window window) => material.MaterialApp(
      home: Theme(
        data: const ThemeData(),
        child: SizedBox(
          width: _kNavigatorWidth,
          height: _kNavigatorHeight,
          child: WindowNavigator(
            initialWindows: [window],
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );

    testWidgets('small wiggle on a snapped title bar keeps the snap', (
      tester,
    ) async {
      final window = Window(
        bounds: const CoreWindowRect.fromLTWH(100, 100, 200, 200),
        title: const material.Text('Snappy'),
      );
      final _ = await tester.pumpWidget(buildNavigator(window));
      await _settle(tester);

      window.handle.maximized = const CoreWindowRect.fromLTWH(0, 0, 0.5, 1);
      await _settle(tester);

      // A grab attempt that only wobbles a few px (past the 2px pan
      // slop, below the 18px restore slop) must NOT pop the window
      // back to floating size.
      final gesture = await tester.startGesture(const Offset(80, 16));
      await gesture.moveBy(const Offset(4, 4));
      await tester.pump();
      await gesture.moveBy(const Offset(2, 2));
      await tester.pump();
      await gesture.up();
      await _settle(tester);

      expect(
        window.handle.maximized,
        equals(const CoreWindowRect.fromLTWH(0, 0, 0.5, 1)),
      );
    });

    testWidgets(
      'real drag keeps the snapped size as floating bounds, follows the '
      'pointer and does not re-snap on release',
      (tester) async {
        final window = Window(
          bounds: const CoreWindowRect.fromLTWH(100, 100, 200, 200),
          title: const material.Text('Snappy'),
        );
        final _ = await tester.pumpWidget(buildNavigator(window));
        await _settle(tester);

        window.handle.maximized = const CoreWindowRect.fromLTWH(0, 0, 0.5, 1);
        await _settle(tester);

        // Grab the snapped title bar (which sits inside the top snap
        // strip) and drag well past the restore slop toward the middle.
        final gesture = await tester.startGesture(const Offset(80, 16));
        for (var i = 0; i < _kDragStepCount; i++) {
          await gesture.moveBy(_kDragStep);
          await tester.pump(const Duration(milliseconds: 16));
        }
        await _settle(tester);

        // Un-snapped, but the panel KEEPS its snapped (left-half) size —
        // the snap rect becomes the new floating bounds.
        expect(window.handle.maximized, isNull);
        expect(window.handle.bounds.width, equals(_kNavigatorWidth / 2));
        expect(window.handle.bounds.height, equals(_kNavigatorHeight));

        // ...and still draggable: further movement keeps following.
        final beforeMore = window.handle.bounds;
        await gesture.moveBy(const Offset(40, 20));
        await tester.pump(const Duration(milliseconds: 16));
        expect(window.handle.bounds.left, greaterThan(beforeMore.left));

        // Releasing mid-desktop must NOT re-snap (the drag started
        // inside the top strip — the re-entry gate holds until the
        // pointer sampled outside every zone).
        await gesture.up();
        await _settle(tester);
        expect(window.handle.maximized, isNull);
      },
    );

    testWidgets(
      'window snapped by a REAL mouse drag stays grabbable after another '
      'window takes focus',
      (tester) async {
        // Reproduces the live regression: drag-snap W1 to the left half
        // with a real mouse gesture (edge strip hover), focus W2, then
        // grab W1's title again — the grab used to hit-test against a
        // stale drag-time render state and go completely dead.
        final w1 = Window(
          bounds: const CoreWindowRect.fromLTWH(0, 0, 200, 200),
          title: const material.Text('W1'),
        );
        final w2 = Window(
          bounds: const CoreWindowRect.fromLTWH(300, 0, 200, 200),
          title: const material.Text('W2'),
        );
        final _ = await tester.pumpWidget(
          material.MaterialApp(
            home: Theme(
              data: const ThemeData(),
              child: SizedBox(
                width: _kNavigatorWidth,
                height: _kNavigatorHeight,
                child: WindowNavigator(
                  initialWindows: [w1, w2],
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ),
        );
        await _settle(tester);

        // Real mouse drag from W1's title into the LEFT border strip so
        // the left-half snap strategy arms via MouseRegion hover.
        final snapDrag = await tester.startGesture(
          const Offset(80, 16),
          kind: PointerDeviceKind.mouse,
        );
        for (var i = 0; i < 20; i++) {
          await snapDrag.moveBy(const Offset(-3.6, 15));
          await tester.pump(const Duration(milliseconds: 16));
        }
        await snapDrag.up();
        await _settle(tester);
        expect(
          w1.handle.maximized,
          equals(const CoreWindowRect.fromLTWH(0, 0, 0.5, 1)),
          reason: 'edge drag must snap W1 to the left half',
        );

        // Focus W2 (the reorder that used to freeze W1's hit geometry).
        await tester.tapAt(const Offset(400, 100));
        await _settle(tester);

        // Grab snapped W1's title with a fresh mouse drag well past the
        // restore slop — it must un-snap (keeping the snapped size) and
        // follow.
        final grab = await tester.startGesture(
          const Offset(60, 12),
          kind: PointerDeviceKind.mouse,
        );
        for (var i = 0; i < _kDragStepCount; i++) {
          await grab.moveBy(_kDragStep);
          await tester.pump(const Duration(milliseconds: 16));
        }
        expect(
          w1.handle.maximized,
          isNull,
          reason: 'grabbing the snapped window must un-snap it',
        );
        expect(w1.handle.bounds.width, equals(_kNavigatorWidth / 2));
        await grab.up();
        await _settle(tester);
      },
    );

    testWidgets(
      'drag released on a peeking snap-bar tile arms that preset '
      '(tiles win over the maximize strip)',
      (tester) async {
        final window = Window(
          bounds: const CoreWindowRect.fromLTWH(100, 200, 200, 200),
          title: const material.Text('Tiley'),
        );
        final _ = await tester.pumpWidget(buildNavigator(window));
        await _settle(tester);

        // Drag starts OUTSIDE every snap zone (title bar at y≈216), so
        // the re-entry gate never suppresses; move up-left into the
        // snap bar's peek band where the FIRST preset group's left tile
        // sits — the tile must take over from the maximize strip (Web
        // parity: inside the bar only tiles arm).
        final gesture = await tester.startGesture(
          const Offset(200, 216),
          kind: PointerDeviceKind.mouse,
        );
        for (var i = 0; i < 20; i++) {
          await gesture.moveBy(const Offset(-7, -10.4));
          await tester.pump(const Duration(milliseconds: 16));
        }
        await gesture.up();
        await _settle(tester);

        expect(
          window.handle.maximized,
          equals(const CoreWindowRect.fromLTWH(0, 0, 0.5, 1)),
          reason: 'the peeking left-half preset tile must arm the snap',
        );
      },
    );

    testWidgets(
      'diagonal drag through the snap bar that is released in the maximize '
      'strip beside it maximizes (leaving the bar must not disarm)',
      (tester) async {
        final window = Window(
          bounds: const CoreWindowRect.fromLTWH(100, 200, 200, 200),
          title: const material.Text('Grazey'),
        );
        final _ = await tester.pumpWidget(buildNavigator(window));
        await _settle(tester);

        // Starts outside every zone (title bar at y≈216) and climbs
        // diagonally up-right: the path crosses the snap bar's band, enters
        // the title-bar-height maximize strip inside the bar and ends in
        // that strip just past the bar's right edge. Hover callbacks let
        // the bar's exit clear the maximize the strip had armed, and the
        // strip — already under the pointer — never re-armed; the pointer
        // position must decide what a release does.
        final gesture = await tester.startGesture(
          const Offset(200, 216),
          kind: PointerDeviceKind.mouse,
        );
        for (var i = 0; i < 20; i++) {
          await gesture.moveBy(const Offset(29, -10.4));
          await tester.pump(const Duration(milliseconds: 16));
        }
        await gesture.up();
        await _settle(tester);

        expect(
          window.handle.maximized,
          equals(CoreWindowContract.fullMaximizeRect),
          reason:
              'a release in the maximize strip must maximize, whatever '
              'the path crossed on the way',
        );
      },
    );

    group('tile then maximize strip', () {
      // Shared path prefix: from outside every zone up onto the full-pose
      // left-half tile of the third preset group (the bar slides fully in
      // once the pointer is over it), then one small move so a sample is
      // taken against the settled tile geometry.
      Future<TestGesture> dragOntoTile(WidgetTester tester) async {
        final gesture = await tester.startGesture(
          const Offset(200, 216),
          kind: PointerDeviceKind.mouse,
        );
        for (var i = 0; i < 10; i++) {
          await gesture.moveBy(const Offset(11.2, -14.6));
          await tester.pump(const Duration(milliseconds: 16));
        }
        await tester.pump(const Duration(milliseconds: 600));
        await gesture.moveBy(const Offset(1, 0));
        await tester.pump(const Duration(milliseconds: 16));
        return gesture;
      }

      Window buildWindow() => Window(
        bounds: const CoreWindowRect.fromLTWH(100, 200, 200, 200),
        title: const material.Text('Tile then strip'),
      );

      testWidgets('released on the tile arms that preset', (tester) async {
        final window = buildWindow();
        final _ = await tester.pumpWidget(buildNavigator(window));
        await _settle(tester);

        final gesture = await dragOntoTile(tester);
        await gesture.up();
        await _settle(tester);

        expect(
          window.handle.maximized,
          equals(const CoreWindowRect.fromLTWH(0, 0, 0.5, 1)),
          reason: 'the tile under the pointer must be what a release applies',
        );
      });

      testWidgets(
        'moved off the tile into the maximize strip above it maximizes',
        (tester) async {
          final window = buildWindow();
          final _ = await tester.pumpWidget(buildNavigator(window));
          await _settle(tester);

          // The tile highlight is keyed off the same sample as the armed
          // strategy, so exactly one tile lights up while it is armed and
          // none once the pointer leaves it.
          final hover = resolveWindow(
            tester.element(find.byType(WindowNavigator)),
          ).snapTileHoverBackgroundColor;
          final highlightedTiles = find.byWidgetPredicate(
            (widget) =>
                widget is Container &&
                widget.decoration is BoxDecoration &&
                (widget.decoration! as BoxDecoration).color == hover,
          );

          // Same prefix as the tile release above, then straight up off
          // the tile into the strip — the grazed tile must not stay armed.
          final gesture = await dragOntoTile(tester);
          expect(highlightedTiles, findsOneWidget);
          for (var i = 0; i < 4; i++) {
            await gesture.moveBy(const Offset(0, -15));
            await tester.pump(const Duration(milliseconds: 16));
          }
          expect(highlightedTiles, findsNothing);
          await gesture.up();
          await _settle(tester);

          expect(
            window.handle.maximized,
            equals(CoreWindowContract.fullMaximizeRect),
            reason:
                'the last sample sits in the maximize strip clear of every '
                'tile — the tile the path crossed must not be applied',
          );
        },
      );
    });

    testWidgets(
      'drag that never crosses a tile and is released in the maximize '
      'strip maximizes',
      (tester) async {
        final window = Window(
          bounds: const CoreWindowRect.fromLTWH(100, 200, 200, 200),
          title: const material.Text('Straight'),
        );
        final _ = await tester.pumpWidget(buildNavigator(window));
        await _settle(tester);

        // Horizontal leg out to the right of the bar, then straight up —
        // the path stays clear of the tile band entirely.
        final gesture = await tester.startGesture(
          const Offset(200, 216),
          kind: PointerDeviceKind.mouse,
        );
        for (var i = 0; i < 10; i++) {
          await gesture.moveBy(const Offset(55, 0));
          await tester.pump(const Duration(milliseconds: 16));
        }
        for (var i = 0; i < 10; i++) {
          await gesture.moveBy(const Offset(0, -20.8));
          await tester.pump(const Duration(milliseconds: 16));
        }
        await gesture.up();
        await _settle(tester);

        expect(
          window.handle.maximized,
          equals(CoreWindowContract.fullMaximizeRect),
        );
      },
    );

    testWidgets(
      'drag that leaves the maximize strip for the desktop before release '
      'does not snap',
      (tester) async {
        final window = Window(
          bounds: const CoreWindowRect.fromLTWH(100, 200, 200, 200),
          title: const material.Text('Backout'),
        );
        final _ = await tester.pumpWidget(buildNavigator(window));
        await _settle(tester);

        // Up into the maximize strip right of the bar, then back down to
        // the middle of the desktop: the last sample is outside every
        // zone, so nothing may stay armed.
        final gesture = await tester.startGesture(
          const Offset(200, 216),
          kind: PointerDeviceKind.mouse,
        );
        for (var i = 0; i < 10; i++) {
          await gesture.moveBy(const Offset(55, -20.8));
          await tester.pump(const Duration(milliseconds: 16));
        }
        for (var i = 0; i < 10; i++) {
          await gesture.moveBy(const Offset(-20, 25));
          await tester.pump(const Duration(milliseconds: 16));
        }
        await gesture.up();
        await _settle(tester);

        expect(window.handle.maximized, isNull);
      },
    );
  });

  group('snap-tile border width reaches a strokeFloor preset', () {
    testWidgets('resolveWindow.snapTileBorderWidth is floored', (
      tester,
    ) async {
      // `_SnapHoverState` (the persistent hoverable/clickable snap-bar
      // preset tile) paints `Border.all(color: resolved
      // .snapTileBorderColor, width: resolved.snapTileBorderWidth)`
      // directly — unlike the snap bar's own outer border (which
      // raw-forwards into the composed, self-geometry-resolving
      // `OutlinedContainer`), this is the tile's own paint site, so the
      // resolver itself must run the value through `theme.geometry
      // .stroke(...)`. Checked at the resolver level (rather than
      // dragging the snap bar into its peeking state through a full
      // `WindowNavigator`) because the fix lives entirely in
      // `resolveWindow`.
      const geometry = CoreSurfaceGeometryConstraint(
        strokeFloor: CoreStrokeWidth.stroke4,
      );
      late ResolvedWindow resolved;
      await tester.pumpWidget(
        material.MaterialApp(
          home: Theme(
            data: ThemeData(geometry: geometry),
            child: Builder(
              builder: (context) {
                resolved = resolveWindow(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
      await _settle(tester);

      expect(
        resolved.snapTileBorderWidth,
        greaterThanOrEqualTo(CoreStrokeWidth.stroke4),
        reason:
            'the snap-tile border stayed under the strokeFloor: '
            '${resolved.snapTileBorderWidth}',
      );
    });
  });

  group('Window snap bar and tile chrome', () {
    Future<ResolvedWindow> resolve(WidgetTester tester) async {
      late ResolvedWindow resolved;
      await tester.pumpWidget(
        material.MaterialApp(
          home: Theme(
            data: const ThemeData(),
            child: Builder(
              builder: (context) {
                resolved = resolveWindow(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
      await _settle(tester);
      return resolved;
    }

    testWidgets('a tile carries its own corners, not the preview or banner', (
      tester,
    ) async {
      final resolved = await resolve(tester);

      expect(resolved.snapTileBorderRadius, BorderRadius.circular(4));
      expect(resolved.snapTileInnerBorderRadius, BorderRadius.circular(2));
      // The ghost and the banner take the panel corner.
      expect(resolved.snapPreviewBorderRadius, BorderRadius.circular(12));
      expect(
        resolved.snapBarBorderRadius,
        const CoreBorderRadius.all(CoreRadiusRole.panel),
      );
    });

    testWidgets('the banner states the lg cast', (tester) async {
      final resolved = await resolve(tester);

      expect(resolved.snapBarShadow, CoreShadow.lg);
    });

    testWidgets('the banner is the bright surface with the subtle outline', (
      tester,
    ) async {
      final resolved = await resolve(tester);

      expect(
        resolved.snapBarBackgroundColor,
        const CoreColor.token(CoreColors.surfaceBright),
      );
      expect(
        resolved.snapBarBorderColor,
        const CoreColor.token(CoreColors.outlineSubtle),
      );
    });

    testWidgets('the banner container is handed its own corner and cast', (
      tester,
    ) async {
      final window = Window(
        bounds: const CoreWindowRect.fromLTWH(100, 100, 200, 200),
        title: const material.Text('Banner'),
      );
      await tester.pumpWidget(
        material.MaterialApp(
          home: Theme(
            data: const ThemeData(),
            child: SizedBox(
              width: _kNavigatorWidth,
              height: _kNavigatorHeight,
              child: WindowNavigator(
                initialWindows: [window],
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ),
      );
      await _settle(tester);

      final banner = find.byWidgetPredicate(
        (widget) =>
            widget is OutlinedContainer &&
            widget.containerStyle?.boxShadow == CoreShadow.lg,
        description: 'snap bar OutlinedContainers casting the lg step',
      );
      // The navigator keeps one banner for ordinary windows and one for
      // always-on-top ones; both are handed the same corner and cast.
      expect(banner, findsNWidgets(2));
      for (final container in tester.widgetList<OutlinedContainer>(banner)) {
        expect(
          container.containerStyle!.borderRadius,
          const CoreBorderRadius.all(CoreRadiusRole.panel),
        );
      }
    });

    testWidgets('a style override reaches the tile corners and the cast', (
      tester,
    ) async {
      late ResolvedWindow resolved;
      await tester.pumpWidget(
        material.MaterialApp(
          home: Theme(
            data: const ThemeData(),
            child: Builder(
              builder: (context) {
                resolved = resolveWindow(
                  context,
                  windowStyle: const CoreWindowStyle(
                    snapTileBorderRadius: CoreBorderRadius.all(8),
                    snapTileInnerBorderRadius: CoreBorderRadius.all(6),
                    snapBarShadow: CoreShadow.sm,
                  ),
                );
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
      await _settle(tester);

      expect(resolved.snapTileBorderRadius, BorderRadius.circular(8));
      expect(resolved.snapTileInnerBorderRadius, BorderRadius.circular(6));
      expect(resolved.snapBarShadow, CoreShadow.sm);
    });
  });
}
