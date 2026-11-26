// Sortable's only job is reordering, and a pointer drag was the only way to
// do it (WCAG 2.1.1 / 2.5.7). These tests press real keys on the handle and
// read back the order the list actually committed, the sentences a screen
// reader would hear, and where focus ends up — the three things a keyboard
// user relies on and cannot see from the pointer path.
import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Collects the sentences spoken through the platform announcement channel.
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

/// A list that applies its own reorders, so a test reads the order the
/// widget committed rather than the callback arguments alone.
class _Harness extends StatefulWidget {
  const _Harness({required this.onReorder});

  final void Function(int oldIndex, int newIndex) onReorder;

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  final List<String> items = ['Alpha', 'Bravo', 'Charlie'];

  @override
  Widget build(BuildContext context) => Sortable(
    itemCount: items.length,
    onReorder: (oldIndex, newIndex) {
      widget.onReorder(oldIndex, newIndex);
      setState(() => items.insert(newIndex, items.removeAt(oldIndex)));
    },
    itemBuilder: (context, index, dragHandle, removeButton) => material.Row(
      children: [dragHandle, material.Text(items[index])],
    ),
  );
}

Future<void> _pump(
  WidgetTester tester, {
  required void Function(int oldIndex, int newIndex) onReorder,
}) async {
  await tester.pumpWidget(
    material.MaterialApp(
      home: Builder(
        builder: (context) => material.MediaQuery(
          data: material.MediaQuery.of(
            context,
          ).copyWith(supportsAnnounce: true),
          child: material.Scaffold(
            body: material.SizedBox(
              width: 300,
              child: Theme(
                data: const ThemeData(),
                child: _Harness(onReorder: onReorder),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  // Rows measure themselves post-frame; the keyboard path needs the rects.
  await tester.pump();
}

List<String> _order(WidgetTester tester) =>
    tester.state<_HarnessState>(find.byType(_Harness)).items.toList();

Future<void> _press(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyEvent(key);
  await tester.pump();
}

String? _focusedLabel() => FocusManager.instance.primaryFocus?.debugLabel;

void main() {
  testWidgets('the handle is the first tab stop, not the row around it', (
    tester,
  ) async {
    await _pump(tester, onReorder: (_, _) {});

    await _press(tester, LogicalKeyboardKey.tab);

    expect(_focusedLabel(), 'Sortable handle 0');
  });

  testWidgets('the handle is named with its position', (tester) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester, onReorder: (_, _) {});

    expect(find.bySemanticsLabel('Reorder item 1 of 3'), findsOneWidget);
    expect(find.bySemanticsLabel('Reorder item 3 of 3'), findsOneWidget);

    semantics.dispose();
  });

  testWidgets('Space, two arrows, Space moves the item two places', (
    tester,
  ) async {
    final calls = <(int, int)>[];
    await _pump(tester, onReorder: (from, to) => calls.add((from, to)));

    await _press(tester, LogicalKeyboardKey.tab);
    await _press(tester, LogicalKeyboardKey.space);
    await _press(tester, LogicalKeyboardKey.arrowDown);
    await _press(tester, LogicalKeyboardKey.arrowDown);
    await _press(tester, LogicalKeyboardKey.space);
    await tester.pumpAndSettle();

    // The same `(oldIndex, newIndex)` signature a pointer drop reports.
    expect(calls, [(0, 2)]);
    expect(_order(tester), ['Bravo', 'Charlie', 'Alpha']);
    // Focus follows the item to where it landed, so the next arrow moves
    // the same item rather than whichever one now sits under the old handle.
    expect(_focusedLabel(), 'Sortable handle 2');
  });

  testWidgets('every step is announced with the position', (tester) async {
    final spoken = _announcements();
    await _pump(tester, onReorder: (_, _) {});

    await _press(tester, LogicalKeyboardKey.tab);
    await _press(tester, LogicalKeyboardKey.space);
    await _press(tester, LogicalKeyboardKey.arrowDown);
    await _press(tester, LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    // One sentence per step — the scope's generic "Picked up." / "Dropped."
    // is replaced, not followed, by the positional one.
    expect(spoken, [
      'Picked up item 1 of 3. Use the arrow keys to move it.',
      'Moved to position 2 of 3.',
      'Dropped at position 2 of 3.',
    ]);
  });

  testWidgets('Escape puts the item back where it started', (tester) async {
    final spoken = _announcements();
    final calls = <(int, int)>[];
    await _pump(tester, onReorder: (from, to) => calls.add((from, to)));

    await _press(tester, LogicalKeyboardKey.tab);
    await _press(tester, LogicalKeyboardKey.space);
    await _press(tester, LogicalKeyboardKey.arrowDown);
    await _press(tester, LogicalKeyboardKey.arrowDown);
    await _press(tester, LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(calls, isEmpty);
    expect(_order(tester), ['Alpha', 'Bravo', 'Charlie']);
    expect(spoken.last, 'Cancelled. Returned to position 1 of 3.');
    expect(_focusedLabel(), 'Sortable handle 0');
  });

  testWidgets('focus leaving the handle abandons the move', (tester) async {
    final calls = <(int, int)>[];
    await _pump(tester, onReorder: (from, to) => calls.add((from, to)));

    await _press(tester, LogicalKeyboardKey.tab);
    await _press(tester, LogicalKeyboardKey.space);
    await _press(tester, LogicalKeyboardKey.arrowDown);
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    // A drop key after the move was abandoned drops nothing.
    await _press(tester, LogicalKeyboardKey.space);
    await tester.pumpAndSettle();

    expect(calls, isEmpty);
    expect(_order(tester), ['Alpha', 'Bravo', 'Charlie']);
  });

  testWidgets('Home and End jump to either end', (tester) async {
    final calls = <(int, int)>[];
    await _pump(tester, onReorder: (from, to) => calls.add((from, to)));

    await _press(tester, LogicalKeyboardKey.tab);
    await _press(tester, LogicalKeyboardKey.space);
    await _press(tester, LogicalKeyboardKey.end);
    await _press(tester, LogicalKeyboardKey.space);
    await tester.pumpAndSettle();

    expect(calls, [(0, 2)]);
    expect(_order(tester), ['Bravo', 'Charlie', 'Alpha']);
  });

  testWidgets('arrows do nothing until the item is picked up', (
    tester,
  ) async {
    final calls = <(int, int)>[];
    await _pump(tester, onReorder: (from, to) => calls.add((from, to)));

    await _press(tester, LogicalKeyboardKey.tab);
    await _press(tester, LogicalKeyboardKey.arrowDown);
    await _press(tester, LogicalKeyboardKey.enter);
    await _press(tester, LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(calls, isEmpty);
    expect(_order(tester), ['Alpha', 'Bravo', 'Charlie']);
  });

  testWidgets('a non-reorderable list offers no keyboard handle', (
    tester,
  ) async {
    await tester.pumpWidget(
      material.MaterialApp(
        home: Theme(
          data: const ThemeData(),
          child: Sortable(
            itemCount: 2,
            itemBuilder: (context, index, dragHandle, removeButton) =>
                material.Row(children: [dragHandle, material.Text('$index')]),
          ),
        ),
      ),
    );

    await _press(tester, LogicalKeyboardKey.tab);

    expect(_focusedLabel(), isNot(startsWith('Sortable handle')));
  });
}
