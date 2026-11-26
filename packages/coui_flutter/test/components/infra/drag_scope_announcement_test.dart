import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Collects the sentences the scope speaks, as the platform would receive
/// them.
List<String> _announcements() {
  final spoken = <String>[];

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockDecodedMessageHandler<Object?>(
        SystemChannels.accessibility,
        (message) async {
          if (message case {
            'type': 'announce',
            'data': final Map<Object?, Object?> data,
          }) {
            spoken.add(data['message']! as String);
          }

          return null;
        },
      );
  addTearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockDecodedMessageHandler<Object?>(
          SystemChannels.accessibility,
          null,
        ),
  );

  return spoken;
}

/// Wraps [child] in the media query the scope checks before speaking —
/// announcements are skipped on platforms that cannot make them, and the
/// test binding reports that it cannot.
Widget _announcingApp(Widget child) => material.MaterialApp(
  home: Builder(
    builder: (context) => material.MediaQuery(
      data: material.MediaQuery.of(context).copyWith(supportsAnnounce: true),
      child: child,
    ),
  ),
);

Widget _itemAndZone({
  required DragScopeController controller,
  bool announcements = true,
}) => _announcingApp(
  DragScope(
    controller: controller,
    announcements: announcements,
    child: const material.Column(
      children: [
        DragItem(
          id: CoreDragId('item-1'),
          child: SizedBox.square(
            dimension: 48,
            child: material.Text('grab me'),
          ),
        ),
        DropZone(
          id: CoreDragId('zone-1'),
          child: SizedBox.square(
            dimension: 96,
            child: material.Text('drop here'),
          ),
        ),
      ],
    ),
  ),
);

Widget _itemOnly({required DragScopeController controller}) => _announcingApp(
  DragScope(
    controller: controller,
    child: const DragItem(
      id: CoreDragId('item-1'),
      child: SizedBox.square(
        dimension: 48,
        child: material.Text('grab me'),
      ),
    ),
  ),
);

void main() {
  group('DragScope announcements', () {
    testWidgets('speaks pick-up, target entry, and drop in order', (
      tester,
    ) async {
      final spoken = _announcements();
      final controller = DragScopeController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(_itemAndZone(controller: controller));
      await tester.pump();

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('grab me')),
        kind: PointerDeviceKind.mouse,
      );
      await gesture.moveTo(tester.getCenter(find.text('drop here')));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(spoken, ['Picked up.', 'Over a drop target.', 'Dropped.']);
    });

    testWidgets('a cancelled drag speaks cancellation', (tester) async {
      final spoken = _announcements();
      final controller = DragScopeController();
      addTearDown(controller.dispose);
      // No target in this scope, so the only transitions are pick-up and
      // cancellation — a drag that entered a target would announce that
      // entry too, which is its own test.
      await tester.pumpWidget(_itemOnly(controller: controller));
      await tester.pump();

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('grab me')),
        kind: PointerDeviceKind.mouse,
      );
      await gesture.moveBy(const Offset(0, 24));
      await tester.pump();
      controller.runtime.cancel(reason: .dismissed);
      await gesture.up();
      await tester.pumpAndSettle();

      expect(spoken, ['Picked up.', 'Cancelled.']);
    });

    testWidgets('announcements: false stays silent', (tester) async {
      final spoken = _announcements();
      final controller = DragScopeController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _itemAndZone(controller: controller, announcements: false),
      );
      await tester.pump();

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('grab me')),
        kind: PointerDeviceKind.mouse,
      );
      await gesture.moveTo(tester.getCenter(find.text('drop here')));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(spoken, isEmpty);
    });

    testWidgets('a platform that cannot announce is skipped', (tester) async {
      final spoken = _announcements();
      final controller = DragScopeController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        material.MaterialApp(
          home: Builder(
            builder: (context) => material.MediaQuery(
              data: material.MediaQuery.of(
                context,
              ).copyWith(supportsAnnounce: false),
              child: DragScope(
                controller: controller,
                child: const material.Column(
                  children: [
                    DragItem(
                      id: CoreDragId('item-1'),
                      child: SizedBox.square(
                        dimension: 48,
                        child: material.Text('grab me'),
                      ),
                    ),
                    DropZone(
                      id: CoreDragId('zone-1'),
                      child: SizedBox.square(
                        dimension: 96,
                        child: material.Text('drop here'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('grab me')),
        kind: PointerDeviceKind.mouse,
      );
      await gesture.moveTo(tester.getCenter(find.text('drop here')));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(spoken, isEmpty);
    });
  });

  group('DragScope diagnostics', () {
    testWidgets('a second owner on a live id warns once', (tester) async {
      final warnings = <String>[];
      final controller = DragScopeController(
        diagnostics: CoreDragDiagnosticsConfig(onWarning: warnings.add),
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _announcingApp(
          DragScope(
            controller: controller,
            child: const material.Column(
              children: [
                DragItem(
                  id: CoreDragId('dup'),
                  child: SizedBox.square(
                    dimension: 24,
                    child: material.Text('first'),
                  ),
                ),
                DragItem(
                  id: CoreDragId('dup'),
                  child: SizedBox.square(
                    dimension: 24,
                    child: material.Text('second'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      expect(warnings, hasLength(1));
      expect(warnings.single, contains('dup'));
    });

    testWidgets('distinct ids never warn', (tester) async {
      final warnings = <String>[];
      final controller = DragScopeController(
        diagnostics: CoreDragDiagnosticsConfig(onWarning: warnings.add),
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(_itemAndZone(controller: controller));
      await tester.pump();

      expect(warnings, isEmpty);
    });
  });
}
