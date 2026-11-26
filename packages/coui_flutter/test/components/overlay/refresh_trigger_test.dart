import 'dart:async';

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

material.Widget _buildApp(material.Widget child) => material.MaterialApp(
  home: Theme(
    data: const ThemeData(),
    child: child,
  ),
);

const _kRefreshStageCount = 4;

void main() {
  group('CoreRefreshStage', () {
    test('has all expected values', () {
      expect(
        CoreRefreshStage.values,
        containsAll([
          CoreRefreshStage.idle,
          CoreRefreshStage.pulling,
          CoreRefreshStage.refreshing,
          CoreRefreshStage.completed,
        ]),
      );
    });

    test('has the expected count of values', () {
      expect(CoreRefreshStage.values.length, _kRefreshStageCount);
    });

    test('values are unique', () {
      final values = CoreRefreshStage.values.toSet();
      expect(values.length, equals(CoreRefreshStage.values.length));
    });
  });

  group('RefreshTrigger', () {
    testWidgets('renders with child widget', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          RefreshTrigger(
            child: material.ListView(
              children: const [material.Text('item')],
            ),
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.text('item'), findsOneWidget);
    });

    testWidgets('renders with direction vertical (default)', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          RefreshTrigger(
            direction: .vertical,
            child: material.ListView(
              children: const [material.Text('vertical-child')],
            ),
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.byType(RefreshTrigger), findsOneWidget);
    });

    testWidgets('renders with direction horizontal', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          RefreshTrigger(
            direction: .horizontal,
            child: material.ListView(
              scrollDirection: .horizontal,
              children: const [material.Text('horizontal-child')],
            ),
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.byType(RefreshTrigger), findsOneWidget);
    });

    testWidgets('accepts onRefresh callback and renders', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          RefreshTrigger(
            onRefresh: () async {},
            child: material.ListView(
              children: const [material.Text('item')],
            ),
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.byType(RefreshTrigger), findsOneWidget);
    });

    testWidgets('renders without onRefresh callback', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          RefreshTrigger(
            child: material.ListView(
              children: const [material.Text('item')],
            ),
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.byType(RefreshTrigger), findsOneWidget);
    });
  });

  group('RefreshTrigger pull gesture', () {
    material.Widget buildPullApp({
      required Future<void> Function() onRefresh,
      material.Key? triggerKey,
    }) {
      // Center loosens the tight `home` constraints so the SizedBox
      // height holds — the viewport must stay smaller than the content
      // for the scrollable (and thus the pull) to engage.
      return _buildApp(
        material.Center(
          child: material.SizedBox(
            height: CoreSpace.space256,
            child: RefreshTrigger(
              key: triggerKey,
              onRefresh: onRefresh,
              child: ScrollArea(
                child: material.Container(
                  height: CoreSpace.space256 * 2,
                  alignment: material.Alignment.topCenter,
                  child: const material.Text('Pull Me'),
                ),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('mouse pull past minExtent triggers onRefresh', (
      tester,
    ) async {
      var refreshed = false;

      await tester.pumpWidget(
        buildPullApp(onRefresh: () async => refreshed = true),
      );
      final _ = await tester.pumpAndSettle();

      // Drag past minExtent with a MOUSE pointer — the component itself
      // must arm mouse dragging (built-in ScrollConfiguration).
      // Not a design token — raw simulated drag distance; it must stay
      // inside the test viewport (moves past the screen edge stall).
      const kDragDistance = 250.0;
      await tester.drag(
        find.byType(ScrollArea),
        const material.Offset(0, kDragDistance),
        kind: PointerDeviceKind.mouse,
      );
      final __ = await tester.pumpAndSettle();

      expect(refreshed, isTrue);
    });

    testWidgets('threshold sits at minExtent of raw travel and the '
        'content follows the pull', (tester) async {
      var refreshed = false;

      await tester.pumpWidget(
        buildPullApp(onRefresh: () async => refreshed = true),
      );
      final _ = await tester.pumpAndSettle();

      final contentTop = tester.getTopLeft(find.text('Pull Me')).dy;

      // Hold a pull short of the threshold — the content must follow
      // the drag (clamped physics + shared translate — the Web engine
      // model), not stay pinned under an overlay indicator. Stepped
      // moves with pumps let the drag engage past the touch slop.
      // Not a design token — raw simulated drag distances around the
      // 75px default threshold (slop eats ~18px of the first move).
      const kPullStep = 30.0;
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(ScrollArea)),
        kind: PointerDeviceKind.mouse,
      );
      await gesture.moveBy(const material.Offset(0, kPullStep));
      final __ = await tester.pump();
      await gesture.moveBy(const material.Offset(0, kPullStep));
      final ___ = await tester.pump();
      final pulledTop = tester.getTopLeft(find.text('Pull Me')).dy;
      expect(pulledTop - contentTop, greaterThanOrEqualTo(kPullStep));

      // Short of minExtent → releasing must NOT refresh.
      await gesture.up();
      final ____ = await tester.pumpAndSettle();
      expect(refreshed, isFalse);

      // Past minExtent (+ slop margin) → refresh triggers — far less
      // raw travel than the previous frictioned engine needed.
      const kPastThreshold = 120.0;
      await tester.drag(
        find.byType(ScrollArea),
        const material.Offset(0, kPastThreshold),
        kind: PointerDeviceKind.mouse,
      );
      final _____ = await tester.pumpAndSettle();
      expect(refreshed, isTrue);
    });

    testWidgets('programmatic refresh() runs onRefresh', (tester) async {
      var refreshed = false;
      final key = material.GlobalKey<RefreshTriggerState>();

      await tester.pumpWidget(
        buildPullApp(
          onRefresh: () async => refreshed = true,
          triggerKey: key,
        ),
      );
      final _ = await tester.pumpAndSettle();

      unawaited(key.currentState!.refresh());
      final __ = await tester.pumpAndSettle();

      expect(refreshed, isTrue);
    });
  });
}
