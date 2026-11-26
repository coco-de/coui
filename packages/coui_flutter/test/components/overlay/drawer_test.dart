import 'dart:convert';
import 'dart:io';

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

const _kDrawerSideCount = 4;
const _kContentHeight = 120.0;
const _kFixedPanelHeight = 300.0;

/// The vector table coui_core shares with the Web seat and the Chrome drawer
/// probe: how fast and how far a release must be to dismiss (cwd is
/// `packages/coui_flutter` under `flutter test`).
const String _kDragVectorsPath =
    '../coui_core/test/fixtures/drag_release_vectors.json';

/// Wraps every route (including the drawer route pushed on the root
/// `Navigator`) with the CoUI `Theme` via `MaterialApp.builder`, so the
/// drawer panel can resolve `Theme.of`.
material.Widget _buildThemedApp(material.Widget home) => material.MaterialApp(
  builder: (context, built) => Theme(data: const ThemeData(), child: built!),
  home: home,
);

/// A screen with a button that opens a bottom drawer holding [content].
material.Widget _bottomDrawerHost(
  material.Widget content, {
  CoreDrawerStyle? drawerStyle,
}) {
  return _buildThemedApp(
    material.Builder(
      builder: (context) => material.Center(
        child: material.ElevatedButton(
          onPressed: () => openDrawer<void>(
            context: context,
            side: .bottom,
            drawerStyle: drawerStyle,
            builder: (context) => Drawer(
              content: content,
              side: .bottom,
              drawerStyle: drawerStyle,
            ),
          ),
          child: const material.Text('open'),
        ),
      ),
    ),
  );
}

/// A screen with a button that opens a drawer on [side] whose panel is
/// [extent] px long on its slide axis, so "half the panel" is a known number
/// of pixels.
///
/// [routeSettings] and [observers] let a test see the route the drawer is
/// pushed as; [content] is what the panel holds.
material.Widget _fixedExtentDrawerHost(
  CoreDrawerSide side, {
  double extent = _kFixedPanelHeight,
  material.RouteSettings? routeSettings,
  List<material.NavigatorObserver> observers = const [],
  material.Widget content = const material.SizedBox(
    height: _kContentHeight,
    width: _kContentHeight,
    child: material.Text('content'),
  ),
}) {
  final horizontal = side == .left || side == .right;
  final style = horizontal
      ? CoreDrawerStyle(panelWidth: extent)
      : CoreDrawerStyle(panelHeight: extent);
  return material.MaterialApp(
    navigatorObservers: observers,
    builder: (context, built) => Theme(data: const ThemeData(), child: built!),
    home: material.Builder(
      builder: (context) => material.Center(
        child: material.ElevatedButton(
          onPressed: () => openDrawer<void>(
            context: context,
            side: side,
            routeSettings: routeSettings,
            drawerStyle: style,
            builder: (context) =>
                Drawer(content: content, side: side, drawerStyle: style),
          ),
          child: const material.Text('open'),
        ),
      ),
    ),
  );
}

/// A display's frame: how often a moving pointer is reported.
const Duration _kFrame = Duration(milliseconds: 16);

/// Presses at [start] and moves [offset] over [duration] — one move per
/// frame, each stamped with the time it happened — and returns the gesture
/// still held, with the clock at the last move.
///
/// The tester's clock moves with the stamps (a pump between moves), because
/// Flutter's velocity tracker asks the clock, not only the stamps, whether the
/// pointer has stopped.
Future<({TestGesture gesture, Duration clock})> _pressAndStroke(
  WidgetTester tester,
  material.Offset start,
  material.Offset offset,
  Duration duration,
) async {
  final gesture = await tester.startGesture(start);
  final steps = (duration.inMicroseconds / _kFrame.inMicroseconds).ceil();
  final step = Duration(
    microseconds: (duration.inMicroseconds / steps).round(),
  );
  var clock = Duration.zero;
  for (var i = 1; i <= steps; i++) {
    clock += step;
    await gesture.moveTo(start + offset * (i / steps), timeStamp: clock);
    if (i < steps) await tester.pump(step);
  }

  return (gesture: gesture, clock: clock);
}

/// Lifts the held `stroke` [hold] after its last move — the pointer rests for
/// [hold] first.
Future<void> _lift(
  WidgetTester tester,
  ({TestGesture gesture, Duration clock}) stroke, {
  Duration hold = Duration.zero,
}) async {
  if (hold > Duration.zero) await tester.pump(hold);
  await stroke.gesture.up(timeStamp: stroke.clock + hold);
}

/// The opt-in zoom-out backdrop: the drawer's default is no zoom-out, so the
/// tests that exercise the effect state it.
const CoreDrawerStyle _kZoomBackdrop = CoreDrawerStyle(
  backdropScale: CoreDrawerStyle.zoomBackdropScale,
  backdropCornerRadius: CoreDrawerStyle.zoomBackdropCornerRadius,
);

/// A themed app with the [DrawerBackdropLayer] host above the
/// navigator (mirroring the CoUI app shell) and a button that opens a
/// left drawer.
material.Widget _backdropHostApp({
  required bool transformBackdrop,
  CoreDrawerStyle? drawerStyle,
}) {
  return material.MaterialApp(
    builder: (context, built) => Theme(
      data: const ThemeData(),
      child: DrawerBackdropLayer(child: built!),
    ),
    home: material.Builder(
      builder: (context) => material.Center(
        child: material.ElevatedButton(
          onPressed: () => openDrawer<void>(
            context: context,
            side: .left,
            transformBackdrop: transformBackdrop,
            drawerStyle: drawerStyle,
            builder: (context) => Drawer(
              content: const material.Text('panel'),
              drawerStyle: drawerStyle,
            ),
          ),
          child: const material.Text('open'),
        ),
      ),
    ),
  );
}

/// Themed app with the [DrawerBackdropLayer] host above the navigator and
/// a button that opens a left (backdrop-transform) drawer whose panel
/// content is built by [panelBuilder] — used to exercise navigator access
/// from *inside* the host-rendered panel.
material.Widget _backdropHostAppWithPanel(material.WidgetBuilder panelBuilder) {
  return material.MaterialApp(
    builder: (context, built) => Theme(
      data: const ThemeData(),
      child: DrawerBackdropLayer(child: built!),
    ),
    home: material.Builder(
      builder: (context) => material.Center(
        child: material.ElevatedButton(
          onPressed: () => openDrawer<void>(
            context: context,
            side: .left,
            builder: (context) => Drawer(
              content: material.Builder(builder: panelBuilder),
            ),
          ),
          child: const material.Text('open'),
        ),
      ),
    ),
  );
}

/// Records the routes a `Navigator` pushes and pops, so a test can say
/// *which* navigator a drawer route landed on and which one closed it.
class _RouteRecorder extends material.NavigatorObserver {
  final List<material.Route<dynamic>> pushed = [];
  final List<material.Route<dynamic>> popped = [];

  /// Popup routes only — the drawer route is the one `PopupRoute` in these
  /// harnesses, and the app's own pages are `MaterialPageRoute`s.
  int get pushedPopups =>
      pushed.whereType<material.PopupRoute<dynamic>>().length;
  int get poppedPopups =>
      popped.whereType<material.PopupRoute<dynamic>>().length;

  @override
  void didPush(
    material.Route<dynamic> route,
    material.Route<dynamic>? previousRoute,
  ) => pushed.add(route);

  @override
  void didPop(
    material.Route<dynamic> route,
    material.Route<dynamic>? previousRoute,
  ) => popped.add(route);
}

const _kShellBodyKey = material.ValueKey<String>('shell-body');
const _kShellFooterHeight = 56.0;

/// An app shaped like a tabbed shell: the body is its own nested
/// `Navigator` (the tab's branch) and the footer sits *outside* it, on the
/// root route — a stand-in for a bottom navigation bar.
///
/// [onOpen] runs with a context that lives inside the nested navigator, the
/// way a tab page opens a sheet. [onFooterTap] runs when a tap reaches the
/// footer button.
material.Widget _shellApp({
  required _RouteRecorder rootRecorder,
  required _RouteRecorder branchRecorder,
  required void Function(BuildContext context) onOpen,
  required void Function() onFooterTap,
  bool backdropHost = false,
}) {
  return material.MaterialApp(
    navigatorObservers: [rootRecorder],
    // The host renders the panel above the navigator, outside `built`, so
    // the `Theme` has to sit above the host.
    builder: (context, built) => Theme(
      data: const ThemeData(),
      child: backdropHost ? DrawerBackdropLayer(child: built!) : built!,
    ),
    home: material.Column(
      children: [
        material.Expanded(
          key: _kShellBodyKey,
          child: material.Navigator(
            observers: [branchRecorder],
            onGenerateRoute: (settings) => material.MaterialPageRoute<void>(
              settings: settings,
              builder: (context) => material.Center(
                child: material.ElevatedButton(
                  onPressed: () => onOpen(context),
                  child: const material.Text('open'),
                ),
              ),
            ),
          ),
        ),
        material.SizedBox(
          height: _kShellFooterHeight,
          child: material.ElevatedButton(
            onPressed: onFooterTap,
            child: const material.Text('footer'),
          ),
        ),
      ],
    ),
  );
}

/// Whether any mounted `Transform` carries the given uniform [scale].
bool _hasScaleTransform(WidgetTester tester, double scale) {
  return tester
      .widgetList<material.Transform>(find.byType(material.Transform))
      .any(
        (transform) => (transform.transform.storage[0] - scale).abs() < 0.001,
      );
}

void main() {
  group('CoreDrawerSide', () {
    test('has exactly 4 values', () {
      expect(CoreDrawerSide.values, hasLength(_kDrawerSideCount));
    });

    test('contains left', () {
      expect(CoreDrawerSide.values, contains(CoreDrawerSide.left));
    });

    test('contains right', () {
      expect(CoreDrawerSide.values, contains(CoreDrawerSide.right));
    });

    test('contains top', () {
      expect(CoreDrawerSide.values, contains(CoreDrawerSide.top));
    });

    test('contains bottom', () {
      expect(CoreDrawerSide.values, contains(CoreDrawerSide.bottom));
    });

    test('values are in the declared order', () {
      const expected = [
        CoreDrawerSide.left,
        CoreDrawerSide.right,
        CoreDrawerSide.top,
        CoreDrawerSide.bottom,
      ];

      expect(CoreDrawerSide.values, equals(expected));
    });
  });

  group('Drawer backdrop transform', () {
    testWidgets('scales the app content behind the panel', (tester) async {
      await tester.pumpWidget(
        _backdropHostApp(transformBackdrop: true, drawerStyle: _kZoomBackdrop),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('panel'), findsOneWidget);
      // Host scales the backdrop down; the panel renders through the
      // host above the clip, so no counter-transform exists.
      expect(_hasScaleTransform(tester, 0.95), isTrue);
    });

    testWidgets('the default drawer does not zoom the app out', (tester) async {
      await tester.pumpWidget(_backdropHostApp(transformBackdrop: true));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('panel'), findsOneWidget);
      // Only the scrim dims the page: no 95 % zoom-out unless a style asks.
      expect(_hasScaleTransform(tester, 0.95), isFalse);
      expect(
        resolveDrawer(
          tester.element(find.text('panel')),
          side: .left,
        ).backdropScale,
        1.0,
      );
    });

    testWidgets('panel keeps exact viewport geometry under the transform', (
      tester,
    ) async {
      await tester.pumpWidget(_backdropHostApp(transformBackdrop: true));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // The left panel must sit flush at the viewport edge at its
      // resolved width — the counter-scale cancels the host scale.
      final panelRect = tester.getRect(find.byType(Drawer));
      final screen = tester.getRect(find.byType(DrawerBackdropLayer));
      expect(panelRect.left, moreOrLessEquals(0, epsilon: 0.5));
      expect(panelRect.top, moreOrLessEquals(0, epsilon: 0.5));
      expect(panelRect.height, moreOrLessEquals(screen.height, epsilon: 0.5));
    });

    testWidgets(
      'asymmetric backdropCornerRadius survives to the clip (all 4 corners)',
      (tester) async {
        await tester.pumpWidget(
          _backdropHostApp(
            transformBackdrop: true,
            drawerStyle: const CoreDrawerStyle(
              backdropCornerRadius: CoreBorderRadius.only(
                topLeft: 4,
                topRight: 40,
                bottomLeft: 12,
                bottomRight: 28,
              ),
            ),
          ),
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();

        final clip = tester
            .widgetList<ClipRRect>(find.byType(ClipRRect))
            .firstWhere(
              (c) => c.borderRadius != BorderRadius.zero,
            );
        final radius = clip.borderRadius as BorderRadius;
        expect(radius.topLeft.x, moreOrLessEquals(4, epsilon: 0.5));
        expect(radius.topRight.x, moreOrLessEquals(40, epsilon: 0.5));
        expect(radius.bottomLeft.x, moreOrLessEquals(12, epsilon: 0.5));
        expect(radius.bottomRight.x, moreOrLessEquals(28, epsilon: 0.5));
        // The four corners must differ — proof the fix doesn't just
        // widen one representative corner while the rest stay uniform.
        expect(radius.topLeft, isNot(equals(radius.topRight)));
      },
    );

    testWidgets('in-page barrier tap dismisses the drawer', (tester) async {
      await tester.pumpWidget(_backdropHostApp(transformBackdrop: true));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('panel'), findsOneWidget);

      // Tap the scrim far away from the left panel.
      await tester.tapAt(const material.Offset(700, 300));
      await tester.pumpAndSettle();
      expect(find.text('panel'), findsNothing);
    });

    testWidgets('transformBackdrop false leaves the backdrop untouched', (
      tester,
    ) async {
      await tester.pumpWidget(_backdropHostApp(transformBackdrop: false));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('panel'), findsOneWidget);
      expect(_hasScaleTransform(tester, 0.95), isFalse);
    });
  });

  group('Drawer backdrop transform — navigator access', () {
    testWidgets('panel has a Navigator ancestor (Navigator.of resolves)', (
      tester,
    ) async {
      BuildContext? panelContext;
      await tester.pumpWidget(
        _backdropHostAppWithPanel((context) {
          panelContext = context;
          return const material.SizedBox.shrink();
        }),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(panelContext, isNotNull);
      // Before the fix the host-rendered panel had no Navigator ancestor,
      // so this was null and every showDialog / Navigator.of from inside
      // the drawer threw.
      expect(material.Navigator.maybeOf(panelContext!), isNotNull);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'Flutter showDialog opens from inside the panel (no Navigator throw)',
      (tester) async {
        await tester.pumpWidget(
          _backdropHostAppWithPanel(
            (context) => material.ElevatedButton(
              onPressed: () => material.showDialog<void>(
                context: context,
                builder: (_) => const material.Text(
                  'flutter-dialog-body',
                  textDirection: material.TextDirection.ltr,
                ),
              ),
              child: const material.Text('confirm'),
            ),
          ),
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('confirm'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('flutter-dialog-body'), findsOneWidget);
      },
    );

    testWidgets(
      'CoUI showDialog opens from inside the panel '
      '(regression: the reported re-confirmation crash path)',
      (tester) async {
        await tester.pumpWidget(
          _backdropHostAppWithPanel(
            (context) => material.ElevatedButton(
              // CoUI showDialog → Navigator.of(context, rootNavigator:) —
              // the exact call that hard-failed downstream.
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => const material.Text(
                  'coui-dialog-body',
                  textDirection: material.TextDirection.ltr,
                ),
              ),
              child: const material.Text('confirm'),
            ),
          ),
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('confirm'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('coui-dialog-body'), findsOneWidget);
      },
    );

    testWidgets('dismissing a panel-opened dialog keeps the drawer open', (
      tester,
    ) async {
      await tester.pumpWidget(
        _backdropHostAppWithPanel(
          (context) => material.Column(
            mainAxisSize: material.MainAxisSize.min,
            children: [
              const material.Text('drawer-marker'),
              material.ElevatedButton(
                onPressed: () => material.showDialog<void>(
                  context: context,
                  builder: (_) => material.Center(
                    child: material.ElevatedButton(
                      // Pops the dialog off the nested navigator, not the
                      // drawer.
                      onPressed: () => material.Navigator.of(context).pop(),
                      child: const material.Text('close-dialog'),
                    ),
                  ),
                ),
                child: const material.Text('confirm'),
              ),
            ],
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('confirm'));
      await tester.pumpAndSettle();
      expect(find.text('close-dialog'), findsOneWidget);

      await tester.tap(find.text('close-dialog'));
      await tester.pumpAndSettle();
      expect(find.text('close-dialog'), findsNothing);
      expect(find.text('drawer-marker'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('closeDrawer still closes a backdrop-transform drawer', (
      tester,
    ) async {
      await tester.pumpWidget(
        _backdropHostAppWithPanel(
          (context) => material.ElevatedButton(
            onPressed: () => closeDrawer<void>(context),
            child: const material.Text('close-me'),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('close-me'), findsOneWidget);

      await tester.tap(find.text('close-me'));
      await tester.pumpAndSettle();
      expect(find.text('close-me'), findsNothing);
    });
  });

  group('Drawer vertical panel sizing', () {
    testWidgets('bottom drawer wraps its content by default', (tester) async {
      await tester.pumpWidget(
        _bottomDrawerHost(
          const material.SizedBox(
            height: _kContentHeight,
            child: material.Text('short-content'),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      final panelHeight = tester.getSize(find.byType(Drawer)).height;
      // Content-sized: content + default panel padding, nowhere near
      // the screen extent — and no overflow error is thrown.
      final screenHeight = tester
          .getSize(find.byType(material.MaterialApp))
          .height;
      expect(panelHeight, greaterThanOrEqualTo(_kContentHeight));
      expect(panelHeight, lessThan(screenHeight / 2));
      expect(tester.takeException(), isNull);
    });

    testWidgets('explicit panelHeight fixes the extent', (tester) async {
      await tester.pumpWidget(
        _bottomDrawerHost(
          const material.SizedBox(
            height: _kContentHeight,
            child: material.Text('short-content'),
          ),
          drawerStyle: const CoreDrawerStyle(panelHeight: _kFixedPanelHeight),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(
        tester.getSize(find.byType(Drawer)).height,
        _kFixedPanelHeight,
      );
    });

    testWidgets('greedy content is capped at the viewport, not overflowed', (
      tester,
    ) async {
      await tester.pumpWidget(
        _bottomDrawerHost(
          material.ListView(
            children: [
              for (var i = 0; i < 100; i++) material.Text('item $i'),
            ],
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      final panelHeight = tester.getSize(find.byType(Drawer)).height;
      final screenHeight = tester
          .getSize(find.byType(material.MaterialApp))
          .height;
      expect(panelHeight, lessThanOrEqualTo(screenHeight));
      expect(tester.takeException(), isNull);
    });
  });
  group('openDrawer useRootNavigator', () {
    late _RouteRecorder rootRecorder;
    late _RouteRecorder branchRecorder;
    late int footerTaps;

    setUp(() {
      rootRecorder = _RouteRecorder();
      branchRecorder = _RouteRecorder();
      footerTaps = 0;
    });

    material.Widget shell({
      required bool useRootNavigator,
      bool transformBackdrop = false,
      bool backdropHost = false,
      void Function(Future<String?> result)? onResult,
    }) {
      return _shellApp(
        rootRecorder: rootRecorder,
        branchRecorder: branchRecorder,
        backdropHost: backdropHost,
        onFooterTap: () => footerTaps++,
        onOpen: (context) {
          final result = openDrawer<String>(
            context: context,
            side: .bottom,
            useRootNavigator: useRootNavigator,
            transformBackdrop: transformBackdrop,
            drawerStyle: _kZoomBackdrop,
            builder: (context) => Drawer(
              side: .bottom,
              drawerStyle: _kZoomBackdrop,
              content: material.Column(
                mainAxisSize: material.MainAxisSize.min,
                children: [
                  const material.Text('sheet'),
                  material.ElevatedButton(
                    onPressed: () => closeDrawer<String>(context, 'picked'),
                    child: const material.Text('close-sheet'),
                  ),
                ],
              ),
            ),
          );
          onResult?.call(result);
        },
      );
    }

    testWidgets('defaults to the root navigator', (tester) async {
      await tester.pumpWidget(shell(useRootNavigator: true));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('sheet'), findsOneWidget);
      expect(rootRecorder.pushedPopups, 1);
      expect(branchRecorder.pushedPopups, 0);
    });

    testWidgets('a root-navigator sheet covers the footer outside the body', (
      tester,
    ) async {
      await tester.pumpWidget(shell(useRootNavigator: true));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // The scrim spans the root navigator, footer included: a tap over
      // the footer lands on the scrim and dismisses the sheet, and never
      // reaches the footer button.
      await tester.tap(find.text('footer'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(footerTaps, 0);
      expect(find.text('sheet'), findsNothing);
    });

    testWidgets('false pushes onto the nearest (nested) navigator', (
      tester,
    ) async {
      await tester.pumpWidget(shell(useRootNavigator: false));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('sheet'), findsOneWidget);
      expect(branchRecorder.pushedPopups, 1);
      expect(rootRecorder.pushedPopups, 0);
    });

    testWidgets('a nested sheet leaves the footer outside its navigator '
        'uncovered and tappable', (tester) async {
      await tester.pumpWidget(shell(useRootNavigator: false));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('footer'));
      await tester.pumpAndSettle();
      expect(footerTaps, 1);
      // Tapping the footer did not dismiss the sheet — the scrim is
      // confined to the body.
      expect(find.text('sheet'), findsOneWidget);
    });

    testWidgets('a nested sheet dims only the body', (tester) async {
      await tester.pumpWidget(shell(useRootNavigator: false));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      final body = tester.getRect(find.byKey(_kShellBodyKey));
      final screen = tester.getRect(find.byType(material.MaterialApp));
      final barrier = tester.getRect(
        find.byType(material.ModalBarrier).last,
      );
      expect(barrier.bottom, moreOrLessEquals(body.bottom, epsilon: 0.5));
      expect(barrier.bottom, lessThan(screen.bottom));
    });

    testWidgets('a nested sheet has no gap under it: it docks to the '
        'navigator, not the screen', (tester) async {
      await tester.pumpWidget(shell(useRootNavigator: false));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      final body = tester.getRect(find.byKey(_kShellBodyKey));
      final sheet = tester.getRect(find.byType(Drawer));
      expect(sheet.bottom, moreOrLessEquals(body.bottom, epsilon: 0.5));
    });

    testWidgets('barrier tap dismisses a nested sheet on its own navigator', (
      tester,
    ) async {
      await tester.pumpWidget(shell(useRootNavigator: false));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tapAt(const material.Offset(200, 40));
      await tester.pumpAndSettle();

      expect(find.text('sheet'), findsNothing);
      expect(branchRecorder.poppedPopups, 1);
      expect(rootRecorder.poppedPopups, 0);
      // The tab page underneath is untouched.
      expect(find.text('open'), findsOneWidget);
    });

    testWidgets('the root navigator still takes a sheet opened with false '
        'when there is no nested navigator', (tester) async {
      await tester.pumpWidget(
        material.MaterialApp(
          navigatorObservers: [rootRecorder],
          builder: (context, built) =>
              Theme(data: const ThemeData(), child: built!),
          home: material.Builder(
            builder: (context) => material.Center(
              child: material.ElevatedButton(
                onPressed: () => openDrawer<void>(
                  context: context,
                  side: .bottom,
                  useRootNavigator: false,
                  builder: (context) =>
                      const Drawer(content: material.Text('sheet')),
                ),
                child: const material.Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('sheet'), findsOneWidget);
      expect(rootRecorder.pushedPopups, 1);
    });

    group('closeDrawer from inside the panel', () {
      testWidgets('closes a nested sheet on the navigator that holds it', (
        tester,
      ) async {
        await tester.pumpWidget(shell(useRootNavigator: false));
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('close-sheet'));
        await tester.pumpAndSettle();

        expect(find.text('sheet'), findsNothing);
        expect(branchRecorder.poppedPopups, 1);
        // Nothing was popped from the root navigator — before the panel
        // carried its owning navigator, closeDrawer reached for the root
        // one and popped the app's own page instead of the sheet.
        expect(rootRecorder.popped, isEmpty);
        expect(find.text('open'), findsOneWidget);
        expect(find.text('footer'), findsOneWidget);
      });

      testWidgets('completes the open future with the popped result', (
        tester,
      ) async {
        late Future<String?> result;
        await tester.pumpWidget(
          shell(useRootNavigator: false, onResult: (r) => result = r),
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('close-sheet'));
        await tester.pumpAndSettle();

        expect(await result, 'picked');
      });

      testWidgets('closes a root-navigator sheet as before', (tester) async {
        await tester.pumpWidget(shell(useRootNavigator: true));
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('close-sheet'));
        await tester.pumpAndSettle();

        expect(find.text('sheet'), findsNothing);
        expect(rootRecorder.poppedPopups, 1);
        expect(branchRecorder.popped, isEmpty);
      });

      testWidgets('drag-to-dismiss closes a nested sheet on its own '
          'navigator', (tester) async {
        await tester.pumpWidget(shell(useRootNavigator: false));
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();

        await tester.fling(
          find.byType(Drawer),
          const material.Offset(0, 600),
          2000,
        );
        await tester.pumpAndSettle();

        expect(find.text('sheet'), findsNothing);
        expect(branchRecorder.poppedPopups, 1);
        expect(rootRecorder.popped, isEmpty);
      });
    });

    group('backdrop transform', () {
      testWidgets('is skipped for a sheet on a nested navigator', (
        tester,
      ) async {
        await tester.pumpWidget(
          shell(
            useRootNavigator: false,
            transformBackdrop: true,
            backdropHost: true,
          ),
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();

        expect(find.text('sheet'), findsOneWidget);
        // The transform scales the whole shell; a route owned by one
        // nested navigator cannot drive it, so it must not half-apply.
        expect(_hasScaleTransform(tester, 0.95), isFalse);
      });

      testWidgets('still applies to a root-navigator sheet', (tester) async {
        await tester.pumpWidget(
          shell(
            useRootNavigator: true,
            transformBackdrop: true,
            backdropHost: true,
          ),
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();

        expect(_hasScaleTransform(tester, 0.95), isTrue);
      });

      testWidgets('still applies when the nearest navigator is the root', (
        tester,
      ) async {
        await tester.pumpWidget(
          material.MaterialApp(
            builder: (context, built) => Theme(
              data: const ThemeData(),
              child: DrawerBackdropLayer(child: built!),
            ),
            home: material.Builder(
              builder: (context) => material.Center(
                child: material.ElevatedButton(
                  onPressed: () => openDrawer<void>(
                    context: context,
                    side: .left,
                    useRootNavigator: false,
                    drawerStyle: _kZoomBackdrop,
                    builder: (context) => const Drawer(
                      content: material.Text('panel'),
                      drawerStyle: _kZoomBackdrop,
                    ),
                  ),
                  child: const material.Text('open'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();

        expect(find.text('panel'), findsOneWidget);
        expect(_hasScaleTransform(tester, 0.95), isTrue);
      });
    });
  });

  group('openDrawer fillSafeArea', () {
    const screen = material.Size(400, 800);
    const bottomInset = 34.0;
    const topInset = 47.0;
    const sideInset = 10.0;

    /// Pins the test view to [screen] at 1:1 with the given system insets.
    void setInsets(WidgetTester tester) {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = screen;
      const padding = FakeViewPadding(
        left: sideInset,
        top: topInset,
        right: sideInset,
        bottom: bottomInset,
      );
      tester.view.padding = padding;
      tester.view.viewPadding = padding;
      addTearDown(tester.view.reset);
    }

    const contentKey = material.ValueKey<String>('sheet-content');
    late double contentInsetSeen;

    material.Widget host({
      required CoreDrawerSide side,
      required bool fillSafeArea,
      bool backdropHost = false,
      CoreDrawerStyle? drawerStyle,
    }) {
      final vertical = side == .top || side == .bottom;
      return material.MaterialApp(
        builder: (context, built) => Theme(
          data: const ThemeData(),
          child: backdropHost ? DrawerBackdropLayer(child: built!) : built!,
        ),
        home: material.Builder(
          builder: (context) => material.Center(
            child: material.ElevatedButton(
              onPressed: () => openDrawer<void>(
                context: context,
                side: side,
                transformBackdrop: backdropHost,
                fillSafeArea: fillSafeArea,
                drawerStyle: drawerStyle,
                builder: (context) => Drawer(
                  side: side,
                  drawerStyle: drawerStyle,
                  content: material.Builder(
                    builder: (context) {
                      final padding = MediaQuery.paddingOf(context);
                      contentInsetSeen = switch (side) {
                        .left => padding.left,
                        .right => padding.right,
                        .top => padding.top,
                        .bottom => padding.bottom,
                      };
                      return material.SizedBox(
                        key: contentKey,
                        height: vertical ? 100 : null,
                        width: vertical ? null : 100,
                        child: const material.Text('sheet'),
                      );
                    },
                  ),
                ),
              ),
              child: const material.Text('open'),
            ),
          ),
        ),
      );
    }

    Future<void> open(WidgetTester tester, material.Widget app) async {
      // Unmount whatever the previous case left, so a reopened app starts
      // with no drawer route on its navigator.
      await tester.pumpWidget(const material.SizedBox.shrink());
      await tester.pumpWidget(app);
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    /// The height of a bottom `Drawer` opened over the current insets.
    Future<double> bottomSheetHeight(
      WidgetTester tester, {
      required bool fillSafeArea,
    }) async {
      await open(tester, host(side: .bottom, fillSafeArea: fillSafeArea));
      return tester.getSize(find.byType(Drawer)).height;
    }

    group('off (the default)', () {
      testWidgets('a bottom sheet stops at the safe area, as before', (
        tester,
      ) async {
        setInsets(tester);
        await open(tester, host(side: .bottom, fillSafeArea: false));

        final sheet = tester.getRect(find.byType(Drawer));
        expect(sheet.bottom, moreOrLessEquals(800 - bottomInset));
        expect(sheet.left, moreOrLessEquals(sideInset));
        expect(sheet.right, moreOrLessEquals(400 - sideInset));
      });

      testWidgets('the default is off on the widget, the route and the '
          'contract', (tester) async {
        expect(CoreDrawerContract.defaultFillSafeArea, isFalse);
        expect(
          const Drawer(content: material.SizedBox.shrink()).fillSafeArea,
          isFalse,
        );
      });

      testWidgets('the panel does not pad by the system inset itself', (
        tester,
      ) async {
        setInsets(tester);
        await open(tester, host(side: .bottom, fillSafeArea: false));

        final offFrame = tester.getSize(find.byType(Drawer)).height;
        // Same content, so the height is content + chrome alone.
        expect(
          tester.getRect(find.byKey(contentKey)).bottom,
          lessThanOrEqualTo(800 - bottomInset),
        );
        expect(offFrame, lessThan(200));
      });
    });

    group('on', () {
      testWidgets('a bottom sheet reaches the bottom of the screen', (
        tester,
      ) async {
        setInsets(tester);
        await open(tester, host(side: .bottom, fillSafeArea: true));

        expect(
          tester.getRect(find.byType(Drawer)).bottom,
          moreOrLessEquals(800),
        );
      });

      testWidgets('its content still clears the home-indicator inset', (
        tester,
      ) async {
        setInsets(tester);
        await open(tester, host(side: .bottom, fillSafeArea: true));

        final content = tester.getRect(find.byKey(contentKey));
        expect(content.bottom, lessThanOrEqualTo(800 - bottomInset + 0.01));
      });

      testWidgets('the surface grows by exactly the inset it absorbs', (
        tester,
      ) async {
        setInsets(tester);
        final offHeight = await bottomSheetHeight(tester, fillSafeArea: false);
        final onHeight = await bottomSheetHeight(tester, fillSafeArea: true);

        expect(onHeight - offHeight, moreOrLessEquals(bottomInset));
      });

      testWidgets('the other edges keep their inset', (tester) async {
        setInsets(tester);
        await open(tester, host(side: .bottom, fillSafeArea: true));

        final sheet = tester.getRect(find.byType(Drawer));
        expect(sheet.left, moreOrLessEquals(sideInset));
        expect(sheet.right, moreOrLessEquals(400 - sideInset));
      });

      testWidgets('the content does not see the inset a second time', (
        tester,
      ) async {
        setInsets(tester);
        await open(tester, host(side: .bottom, fillSafeArea: true));

        // A `SafeArea` inside the content would otherwise pad again.
        expect(contentInsetSeen, 0);
      });

      testWidgets('a top drawer reaches the top of the screen', (
        tester,
      ) async {
        setInsets(tester);
        await open(tester, host(side: .top, fillSafeArea: true));

        final sheet = tester.getRect(find.byType(Drawer));
        expect(sheet.top, moreOrLessEquals(0));
        expect(
          tester.getRect(find.byKey(contentKey)).top,
          greaterThanOrEqualTo(topInset - 0.01),
        );
        expect(sheet.left, moreOrLessEquals(sideInset));
        expect(contentInsetSeen, 0);
      });

      testWidgets('a left drawer reaches the left of the screen and keeps '
          'the top and bottom inset', (tester) async {
        setInsets(tester);
        await open(tester, host(side: .left, fillSafeArea: true));

        final sheet = tester.getRect(find.byType(Drawer));
        expect(sheet.left, moreOrLessEquals(0));
        expect(sheet.top, moreOrLessEquals(topInset));
        expect(sheet.bottom, moreOrLessEquals(800 - bottomInset));
        expect(
          tester.getRect(find.byKey(contentKey)).left,
          greaterThanOrEqualTo(sideInset - 0.01),
        );
        expect(contentInsetSeen, 0);
      });

      testWidgets('a right drawer reaches the right of the screen', (
        tester,
      ) async {
        setInsets(tester);
        await open(tester, host(side: .right, fillSafeArea: true));

        final sheet = tester.getRect(find.byType(Drawer));
        expect(sheet.right, moreOrLessEquals(400));
        expect(sheet.top, moreOrLessEquals(topInset));
        expect(
          tester.getRect(find.byKey(contentKey)).right,
          lessThanOrEqualTo(400 - sideInset + 0.01),
        );
      });

      testWidgets('is a no-op on a screen with no inset', (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = screen;
        addTearDown(tester.view.reset);
        final offHeight = await bottomSheetHeight(tester, fillSafeArea: false);
        final onHeight = await bottomSheetHeight(tester, fillSafeArea: true);

        expect(onHeight, offHeight);
        expect(tester.getRect(find.byType(Drawer)).bottom, 800);
      });

      testWidgets('also reaches the bottom when rendered through the '
          'backdrop host', (tester) async {
        setInsets(tester);
        await open(
          tester,
          host(side: .bottom, fillSafeArea: true, backdropHost: true),
        );

        expect(
          tester.getRect(find.byType(Drawer)).bottom,
          moreOrLessEquals(800),
        );
        expect(
          tester.getRect(find.byKey(contentKey)).bottom,
          lessThanOrEqualTo(800 - bottomInset + 0.01),
        );
        expect(contentInsetSeen, 0);
      });

      testWidgets('keeps a fixed panelHeight as the whole surface extent', (
        tester,
      ) async {
        setInsets(tester);
        await open(
          tester,
          host(
            side: .bottom,
            fillSafeArea: true,
            drawerStyle: const CoreDrawerStyle(panelHeight: _kFixedPanelHeight),
          ),
        );

        expect(
          tester.getSize(find.byType(Drawer)).height,
          moreOrLessEquals(_kFixedPanelHeight),
        );
        expect(
          tester.getRect(find.byType(Drawer)).bottom,
          moreOrLessEquals(800),
        );
      });
    });

    testWidgets('a Drawer nested in the content does not absorb the inset '
        'a second time', (tester) async {
      setInsets(tester);

      Future<double> innerHeight({required bool fillSafeArea}) async {
        await tester.pumpWidget(const material.SizedBox.shrink());
        await tester.pumpWidget(
          material.MaterialApp(
            builder: (context, built) =>
                Theme(data: const ThemeData(), child: built!),
            home: material.Builder(
              builder: (context) => material.Center(
                child: material.ElevatedButton(
                  onPressed: () => openDrawer<void>(
                    context: context,
                    side: .bottom,
                    transformBackdrop: false,
                    fillSafeArea: fillSafeArea,
                    builder: (context) => const Drawer(
                      side: .bottom,
                      content: Drawer(
                        side: .bottom,
                        content: material.SizedBox(height: 100),
                      ),
                    ),
                  ),
                  child: const material.Text('open'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        return tester.getSize(find.byType(Drawer).last).height;
      }

      // The outer panel absorbs the inset (its surface grows by it); the
      // inner one must be the same size either way — it has nothing left
      // to absorb.
      expect(
        await innerHeight(fillSafeArea: true),
        moreOrLessEquals(await innerHeight(fillSafeArea: false)),
      );
    });

    testWidgets('a custom panel (not a Drawer) still sees the unconsumed '
        'inset through MediaQuery', (tester) async {
      setInsets(tester);
      late double seen;
      await tester.pumpWidget(
        material.MaterialApp(
          builder: (context, built) =>
              Theme(data: const ThemeData(), child: built!),
          home: material.Builder(
            builder: (context) => material.Center(
              child: material.ElevatedButton(
                onPressed: () => openDrawer<void>(
                  context: context,
                  side: .bottom,
                  transformBackdrop: false,
                  fillSafeArea: true,
                  builder: (context) => material.Builder(
                    builder: (context) {
                      seen = MediaQuery.paddingOf(context).bottom;
                      return const material.SizedBox(
                        key: contentKey,
                        height: 100,
                      );
                    },
                  ),
                ),
                child: const material.Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // The route skipped the docked edge, so a panel that is not a
      // `Drawer` reaches the screen bottom and reads the inset itself.
      expect(seen, bottomInset);
      expect(
        tester.getRect(find.byKey(contentKey)).bottom,
        moreOrLessEquals(800),
      );
    });

    testWidgets('an inline Drawer outside any route never pads by insets', (
      tester,
    ) async {
      setInsets(tester);
      await tester.pumpWidget(
        material.MaterialApp(
          builder: (context, built) =>
              Theme(data: const ThemeData(), child: built!),
          home: const material.Align(
            alignment: material.Alignment.bottomCenter,
            child: Drawer(
              side: .bottom,
              fillSafeArea: true,
              content: material.SizedBox(height: 100),
            ),
          ),
        ),
      );

      final inline = tester.getSize(find.byType(Drawer)).height;
      // Content + chrome only: no scope, so no inset was handed over.
      expect(inline, lessThan(200));
    });
  });

  group('Drawer release speed', () {
    final doc =
        jsonDecode(File(_kDragVectorsPath).readAsStringSync())
            as Map<String, Object?>;
    final gestures = doc['gestures']! as Map<String, Object?>;
    final extent = (gestures['extent']! as num).toDouble();

    /// Opens a [side] drawer with an [extent]-long panel and returns where
    /// the panel sits docked.
    Future<material.Offset> openDocked(
      WidgetTester tester,
      CoreDrawerSide side, {
      List<material.NavigatorObserver> observers = const [],
    }) async {
      await tester.pumpWidget(
        _fixedExtentDrawerHost(side, extent: extent, observers: observers),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.byType(Drawer), findsOneWidget);
      return tester.getTopLeft(find.byType(Drawer));
    }

    group('bottom drawer', () {
      testWidgets('a short quick fling dismisses although it covers well '
          'under half the panel', (tester) async {
        final recorder = _RouteRecorder();
        await openDocked(tester, .bottom, observers: [recorder]);
        // The scene this exists for: 120 px of a 300 px panel is 40 % of it,
        // short of the 50 % that distance alone asks for.
        const stroke = 120.0;
        expect(
          stroke / tester.getSize(find.byType(Drawer)).height,
          lessThan(CoreDrawerContract.defaultDragDismissThreshold),
        );

        await tester.fling(
          find.byType(Drawer),
          const material.Offset(0, stroke),
          1500,
        );
        await tester.pumpAndSettle();

        expect(find.byType(Drawer), findsNothing);
        expect(recorder.poppedPopups, 1);
      });

      testWidgets('the same stroke dragged slowly snaps back', (tester) async {
        final recorder = _RouteRecorder();
        final docked = await openDocked(tester, .bottom, observers: [recorder]);

        // 120 px over 1.2 s: 100 px/s, sampled the way a display would.
        final stroke = await _pressAndStroke(
          tester,
          tester.getCenter(find.byType(Drawer)),
          const material.Offset(0, 120),
          const Duration(milliseconds: 1200),
        );
        // The panel followed the finger — so what happens next is the
        // release being judged, not a drag that never began.
        expect(
          tester.getTopLeft(find.byType(Drawer)).dy - docked.dy,
          greaterThan(60),
        );

        await _lift(tester, stroke);
        await tester.pumpAndSettle();

        expect(find.byType(Drawer), findsOneWidget);
        expect(tester.getTopLeft(find.byType(Drawer)), docked);
        expect(recorder.poppedPopups, 0);
      });

      testWidgets('a quick flick held still before the lift is not a flick', (
        tester,
      ) async {
        final docked = await openDocked(tester, .bottom);

        final stroke = await _pressAndStroke(
          tester,
          tester.getCenter(find.byType(Drawer)),
          const material.Offset(0, 120),
          const Duration(milliseconds: 60),
        );
        await _lift(tester, stroke, hold: const Duration(milliseconds: 200));
        await tester.pumpAndSettle();

        expect(find.byType(Drawer), findsOneWidget);
        expect(tester.getTopLeft(find.byType(Drawer)), docked);
      });

      testWidgets('a lift a moment after the flick is still a flick', (
        tester,
      ) async {
        await openDocked(tester, .bottom);

        final stroke = await _pressAndStroke(
          tester,
          tester.getCenter(find.byType(Drawer)),
          const material.Offset(0, 120),
          const Duration(milliseconds: 60),
        );
        await _lift(tester, stroke, hold: const Duration(milliseconds: 30));
        await tester.pumpAndSettle();

        expect(find.byType(Drawer), findsNothing);
      });

      testWidgets('a long drag dismisses by distance at any speed', (
        tester,
      ) async {
        await openDocked(tester, .bottom);

        await tester.timedDrag(
          find.byType(Drawer),
          const material.Offset(0, 220),
          const Duration(milliseconds: 1600),
        );
        await tester.pumpAndSettle();

        expect(find.byType(Drawer), findsNothing);
      });

      testWidgets('a long drag still dismisses when it is released moving '
          'back', (tester) async {
        await openDocked(tester, .bottom);

        // Far past half in one pull, then a quick pull back up as the finger
        // lifts: four moves a frame apart, about 28 px in 64 ms, so the
        // recogniser reports roughly -440 px/s. The speed points away from
        // the edge, and must not take back the distance already covered.
        final start = tester.getCenter(find.byType(Drawer));
        final gesture = await tester.startGesture(start);
        await gesture.moveTo(
          start + const material.Offset(0, 240),
          timeStamp: const Duration(milliseconds: 400),
        );
        await tester.pump(const Duration(milliseconds: 400));
        var clock = const Duration(milliseconds: 400);
        const back = [236.0, 230.0, 222.0, 212.0];
        for (var i = 0; i < back.length; i++) {
          clock += _kFrame;
          await gesture.moveTo(
            start + material.Offset(0, back[i]),
            timeStamp: clock,
          );
          if (i < back.length - 1) await tester.pump(_kFrame);
        }
        await gesture.up(timeStamp: clock);
        await tester.pumpAndSettle();

        expect(find.byType(Drawer), findsNothing);
      });

      testWidgets('a quick fling back toward the docked edge does nothing', (
        tester,
      ) async {
        final recorder = _RouteRecorder();
        final docked = await openDocked(tester, .bottom, observers: [recorder]);

        await tester.fling(
          find.byType(Drawer),
          const material.Offset(0, -150),
          2500,
        );
        await tester.pumpAndSettle();

        expect(find.byType(Drawer), findsOneWidget);
        expect(tester.getTopLeft(find.byType(Drawer)), docked);
        expect(recorder.poppedPopups, 0);
      });
    });

    group('signed for the edge the panel hides behind', () {
      // A fling toward the edge dismisses, a fling away from it does not.
      // Left and top hide toward smaller coordinates, so these are the sides
      // a velocity taken straight off the screen axis would get backwards.
      final sides = <(CoreDrawerSide, material.Offset)>[
        (.bottom, const material.Offset(0, 120)),
        (.top, const material.Offset(0, -120)),
        (.left, const material.Offset(-120, 0)),
        (.right, const material.Offset(120, 0)),
      ];

      for (final (side, toward) in sides) {
        testWidgets('a quick fling toward the edge dismisses a ${side.name} '
            'drawer', (tester) async {
          await openDocked(tester, side);

          await tester.fling(find.byType(Drawer), toward, 1500);
          await tester.pumpAndSettle();

          expect(find.byType(Drawer), findsNothing);
        });

        testWidgets('a quick fling away from it leaves a ${side.name} drawer '
            'docked', (tester) async {
          final docked = await openDocked(tester, side);

          await tester.fling(find.byType(Drawer), -toward, 1500);
          await tester.pumpAndSettle();

          expect(find.byType(Drawer), findsOneWidget);
          expect(tester.getTopLeft(find.byType(Drawer)), docked);
        });
      }
    });

    group('against the shared gesture table', () {
      test('the table drives a panel of the default threshold', () {
        expect(
          (gestures['threshold']! as num).toDouble(),
          CoreDrawerContract.defaultDragDismissThreshold,
        );
      });

      for (final c
          in (gestures['cases']! as List).cast<Map<String, Object?>>()) {
        testWidgets(c['name']! as String, (tester) async {
          await openDocked(tester, .bottom);

          final travel = (c['travel']! as num).toDouble();
          final durationMs = (c['durationMs']! as num).toInt();
          final holdMs = ((c['holdMs'] as num?) ?? 0).toInt();
          // The stroke at the table's constant speed, then — when the row
          // says so — a rest before the lift.
          final stroke = await _pressAndStroke(
            tester,
            tester.getCenter(find.byType(Drawer)),
            material.Offset(0, travel),
            Duration(milliseconds: durationMs),
          );
          await _lift(tester, stroke, hold: Duration(milliseconds: holdMs));
          await tester.pumpAndSettle();

          expect(
            find.byType(Drawer),
            (c['dismisses']! as bool) ? findsNothing : findsOneWidget,
          );
        });
      }
    });
  });

  group('openDrawer routeSettings', () {
    const named = material.RouteSettings(name: 'filters', arguments: 'a');

    Future<_RouteRecorder> openWith(
      WidgetTester tester, {
      material.RouteSettings? routeSettings,
      material.Widget content = const material.Text('content'),
    }) async {
      final recorder = _RouteRecorder();
      await tester.pumpWidget(
        _fixedExtentDrawerHost(
          .bottom,
          routeSettings: routeSettings,
          observers: [recorder],
          content: content,
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      return recorder;
    }

    material.PopupRoute<dynamic> drawerRoute(_RouteRecorder recorder) =>
        recorder.pushed.whereType<material.PopupRoute<dynamic>>().single;

    testWidgets('the route is pushed under the name it was given', (
      tester,
    ) async {
      final recorder = await openWith(tester, routeSettings: named);

      expect(drawerRoute(recorder).settings.name, 'filters');
      expect(drawerRoute(recorder).settings.arguments, 'a');
    });

    testWidgets('the panel reads that name from its own route', (
      tester,
    ) async {
      await openWith(
        tester,
        routeSettings: named,
        content: material.Builder(
          builder: (context) => material.Text(
            'route:${material.ModalRoute.of(context)?.settings.name}',
          ),
        ),
      );

      expect(find.text('route:filters'), findsOneWidget);
    });

    testWidgets('a drawer opened without settings stays anonymous', (
      tester,
    ) async {
      final recorder = await openWith(tester);

      expect(drawerRoute(recorder).settings.name, isNull);
      expect(drawerRoute(recorder).settings.arguments, isNull);
    });

    testWidgets('the observer sees the same named route leave', (
      tester,
    ) async {
      final recorder = await openWith(tester, routeSettings: named);

      await tester.fling(
        find.byType(Drawer),
        const material.Offset(0, 220),
        1500,
      );
      await tester.pumpAndSettle();

      expect(find.byType(Drawer), findsNothing);
      expect(
        recorder.popped
            .whereType<material.PopupRoute<dynamic>>()
            .single
            .settings
            .name,
        'filters',
      );
    });
  });
}
