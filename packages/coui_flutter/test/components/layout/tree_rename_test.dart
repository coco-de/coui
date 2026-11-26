import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _kTreeWidth = 400.0;
const _kTreeHeight = 400.0;

material.Widget _buildApp(material.Widget child) => material.MaterialApp(
  home: material.Scaffold(
    body: material.SizedBox(
      width: _kTreeWidth,
      height: _kTreeHeight,
      child: Theme(data: const ThemeData(), child: child),
    ),
  ),
);

const _nodes = [
  CoreTreeNode(id: 'main', label: 'main.dart'),
  CoreTreeNode(id: 'other', label: 'other.dart'),
  CoreTreeNode(
    id: 'lib',
    label: 'lib',
    children: [CoreTreeNode(id: 'lib/a', label: 'a.dart')],
  ),
];

Finder get _field => find.byType(EditableText);

EditableText _editable(WidgetTester tester) =>
    tester.widget<EditableText>(_field);

/// Two presses inside Clickable's double-tap window — the same path a
/// pointer double-click takes, first press included. A frame is drawn
/// between them, as on a device: whatever the first press changed (a
/// selection, an expansion) is on screen when the second one lands.
Future<void> _doubleTap(WidgetTester tester, String label) async {
  await tester.tap(find.text(label));
  await tester.pump();
  await tester.tap(find.text(label));
  // The field mounts with the next frame; focus lands in a post-frame
  // callback, applied on the frame after.
  await tester.pump();
  await tester.pump();
}

void main() {
  group('Tree inline rename', () {
    testWidgets(
      'a double-tap opens the field on the stem; Enter reports the trimmed '
      'name and closes it',
      (tester) async {
        final selected = <String?>[];
        final renamed = <(String?, String)>[];

        await tester.pumpWidget(
          _buildApp(
            Tree(
              nodes: _nodes,
              onNodeSelect: (node) => selected.add(node.id),
              onNodeRename: (node, label) => renamed.add((node.id, label)),
            ),
          ),
        );

        await _doubleTap(tester, 'main.dart');

        expect(_field, findsOneWidget);
        final editable = _editable(tester);
        expect(editable.controller.text, 'main.dart');
        expect(
          editable.controller.selection,
          const TextSelection(baseOffset: 0, extentOffset: 4),
          reason: 'a leaf keeps its extension out of the selection',
        );
        expect(editable.focusNode.hasFocus, isTrue);
        // The first press of the pair is a normal press — never delayed.
        expect(selected, ['main']);

        await tester.enterText(_field, '  app.dart ');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pump();

        expect(renamed, [('main', 'app.dart')]);
        expect(_field, findsNothing);
      },
    );

    testWidgets(
      'a double-tap opens the field when its first press moves a controlled '
      'selection onto the row',
      (tester) async {
        // The consumer owns selection: the first press selects, the parent
        // rebuilds with the new selectedId, and the second press must still
        // reach the same Clickable's tap count.
        String? selectedId;

        await tester.pumpWidget(
          _buildApp(
            StatefulBuilder(
              builder: (context, setState) => Tree(
                nodes: _nodes,
                selectedId: selectedId,
                onNodeSelect: (node) => setState(() => selectedId = node.id),
                onNodeRename: (_, _) {},
              ),
            ),
          ),
        );

        await _doubleTap(tester, 'main.dart');

        expect(selectedId, 'main');
        expect(_field, findsOneWidget);
      },
    );

    testWidgets(
      'the stem selection survives the desktop select-all on focus',
      (tester) async {
        // EditableText selects everything when focus arrives on desktop and
        // web (its platform default) — the field must put the stem back.
        await tester.pumpWidget(
          _buildApp(Tree(nodes: _nodes, onNodeRename: (_, _) {})),
        );

        await _doubleTap(tester, 'main.dart');

        expect(_editable(tester).focusNode.hasFocus, isTrue);
        expect(
          _editable(tester).controller.selection,
          const TextSelection(baseOffset: 0, extentOffset: 4),
        );
      },
      variant: TargetPlatformVariant.desktop(),
    );

    testWidgets('a branch opens with its whole name selected', (tester) async {
      await tester.pumpWidget(
        _buildApp(Tree(nodes: _nodes, onNodeRename: (_, _) {})),
      );

      await _doubleTap(tester, 'lib');

      expect(
        _editable(tester).controller.selection,
        const TextSelection(baseOffset: 0, extentOffset: 3),
      );
    });

    testWidgets(
      'the second press of a double-tap does not toggle a folder again',
      (tester) async {
        final toggled = <String?>[];

        await tester.pumpWidget(
          _buildApp(
            Tree(
              nodes: _nodes,
              selectFolders: true,
              toggleFoldersOnSelect: true,
              onNodeSelect: (_) {},
              onNodeToggle: (node) => toggled.add(node.id),
              onNodeRename: (_, _) {},
            ),
          ),
        );

        await _doubleTap(tester, 'lib');

        expect(toggled, ['lib']);
        expect(_field, findsOneWidget);
      },
    );

    testWidgets('Escape closes the field and reports nothing', (tester) async {
      final renamed = <String>[];

      await tester.pumpWidget(
        _buildApp(
          Tree(
            nodes: _nodes,
            onNodeRename: (_, label) => renamed.add(label),
          ),
        ),
      );

      await _doubleTap(tester, 'main.dart');
      await tester.enterText(_field, 'changed.dart');
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();

      expect(renamed, isEmpty);
      expect(_field, findsNothing);
      expect(find.text('main.dart'), findsOneWidget);
    });

    testWidgets(
      "macOS's Escape — the cancelOperation: selector — closes the field too",
      (tester) async {
        final renamed = <String>[];

        await tester.pumpWidget(
          _buildApp(
            Tree(
              nodes: _nodes,
              onNodeRename: (_, label) => renamed.add(label),
            ),
          ),
        );

        await _doubleTap(tester, 'main.dart');
        await tester.enterText(_field, 'changed.dart');
        // The text-editing shortcuts hand Escape to the platform; macOS
        // answers with this selector instead of a key event.
        tester
            .state<EditableTextState>(_field)
            .performSelector(
              'cancelOperation:',
            );
        await tester.pump();

        expect(renamed, isEmpty);
        expect(_field, findsNothing);
        expect(find.text('main.dart'), findsOneWidget);
      },
      variant: TargetPlatformVariant.only(TargetPlatform.macOS),
    );

    testWidgets('an empty or unchanged name reports nothing', (tester) async {
      final renamed = <String>[];

      await tester.pumpWidget(
        _buildApp(
          Tree(
            nodes: _nodes,
            onNodeRename: (_, label) => renamed.add(label),
          ),
        ),
      );

      await _doubleTap(tester, 'main.dart');
      await tester.enterText(_field, '   ');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      await _doubleTap(tester, 'main.dart');
      await tester.enterText(_field, 'main.dart');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(renamed, isEmpty);
      expect(_field, findsNothing);
    });

    testWidgets('pressing elsewhere commits what was typed', (tester) async {
      final renamed = <(String?, String)>[];

      await tester.pumpWidget(
        _buildApp(
          Tree(
            nodes: _nodes,
            onNodeSelect: (_) {},
            onNodeRename: (node, label) => renamed.add((node.id, label)),
          ),
        ),
      );

      await _doubleTap(tester, 'main.dart');
      await tester.enterText(_field, 'app.dart');
      await tester.tap(find.text('other.dart'));
      await tester.pump();

      expect(renamed, [('main', 'app.dart')]);
      expect(_field, findsNothing);
    });

    testWidgets('keys typed into the field never reach an ancestor handler', (
      tester,
    ) async {
      final seen = <LogicalKeyboardKey>[];

      await tester.pumpWidget(
        _buildApp(
          Focus(
            onKeyEvent: (_, event) {
              seen.add(event.logicalKey);

              return KeyEventResult.handled;
            },
            child: Tree(nodes: _nodes, onNodeRename: (_, _) {}),
          ),
        ),
      );

      await _doubleTap(tester, 'main.dart');
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();

      expect(seen, isEmpty);
      expect(_field, findsOneWidget);
    });

    testWidgets('F2 on a focused row opens the field', (tester) async {
      await tester.pumpWidget(
        _buildApp(Tree(nodes: _nodes, onNodeRename: (_, _) {})),
      );

      // Tab lands on the first row — the keyboard path to a row's focus.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.f2);
      await tester.pump();
      await tester.pump();

      expect(_field, findsOneWidget);
      expect(_editable(tester).controller.text, 'main.dart');
    });

    testWidgets('a row the consumer refuses stays read-only', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          Tree(
            nodes: _nodes,
            onNodeSelect: (_) {},
            onNodeRename: (_, _) {},
            canRenameNode: (node) => node.id != 'main',
          ),
        ),
      );

      await _doubleTap(tester, 'main.dart');
      expect(_field, findsNothing);

      await _doubleTap(tester, 'other.dart');
      expect(_field, findsOneWidget);
    });

    testWidgets('without onNodeRename a double-tap is two plain presses', (
      tester,
    ) async {
      final selected = <String?>[];

      await tester.pumpWidget(
        _buildApp(
          Tree(nodes: _nodes, onNodeSelect: (node) => selected.add(node.id)),
        ),
      );

      await _doubleTap(tester, 'main.dart');

      expect(_field, findsNothing);
      expect(selected, ['main', 'main']);
    });
  });

  // A consumer whose keyboard model lives outside the rows (an IDE explorer
  // moving its own cursor) starts the edit through the controller (#5252).
  group('Tree rename from a CoreTreeController', () {
    testWidgets(
      'startRename opens the field on the stem, and Enter hands focus back '
      'to the outer focus that asked',
      (tester) async {
        final controller = CoreTreeController();
        addTearDown(controller.dispose);
        final outer = FocusNode(debugLabel: 'explorer');
        addTearDown(outer.dispose);
        final renamed = <(String?, String)>[];

        await tester.pumpWidget(
          _buildApp(
            Focus(
              focusNode: outer,
              autofocus: true,
              child: Tree(
                nodes: _nodes,
                controller: controller,
                onNodeRename: (node, label) => renamed.add((node.id, label)),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(outer.hasFocus, isTrue);

        controller.startRename('main');
        await tester.pump();
        await tester.pump();

        expect(_field, findsOneWidget);
        expect(
          _editable(tester).controller.selection,
          const TextSelection(baseOffset: 0, extentOffset: 4),
        );
        expect(_editable(tester).focusNode.hasFocus, isTrue);

        await tester.enterText(_field, 'app.dart');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pump();

        expect(renamed, [('main', 'app.dart')]);
        expect(_field, findsNothing);
        expect(outer.hasFocus, isTrue, reason: 'the cursor keys resume');
      },
      variant: TargetPlatformVariant.desktop(),
    );

    testWidgets('Escape cancels and also hands focus back', (tester) async {
      final controller = CoreTreeController();
      addTearDown(controller.dispose);
      final outer = FocusNode(debugLabel: 'explorer');
      addTearDown(outer.dispose);
      final renamed = <String>[];

      await tester.pumpWidget(
        _buildApp(
          Focus(
            focusNode: outer,
            autofocus: true,
            child: Tree(
              nodes: _nodes,
              controller: controller,
              onNodeRename: (_, label) => renamed.add(label),
            ),
          ),
        ),
      );
      await tester.pump();

      controller.startRename('other');
      await tester.pump();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();

      expect(renamed, isEmpty);
      expect(_field, findsNothing);
      expect(outer.hasFocus, isTrue);
    });

    testWidgets('a branch opens with its whole name selected', (tester) async {
      final controller = CoreTreeController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _buildApp(
          Tree(
            nodes: _nodes,
            controller: controller,
            onNodeRename: (_, _) {},
          ),
        ),
      );

      controller.startRename('lib');
      await tester.pump();
      await tester.pump();

      expect(
        _editable(tester).controller.selection,
        const TextSelection(baseOffset: 0, extentOffset: 3),
      );
    });

    testWidgets(
      'an unknown id, a hidden row, a refused row and a tree without '
      'onNodeRename all ignore the request',
      (tester) async {
        final controller = CoreTreeController();
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          _buildApp(
            Tree(
              nodes: _nodes,
              controller: controller,
              onNodeRename: (_, _) {},
              canRenameNode: (node) => node.id != 'other',
            ),
          ),
        );

        // `lib` starts collapsed, so `lib/a` has no visible row.
        for (final id in ['missing', 'lib/a', 'other']) {
          controller.startRename(id);
          await tester.pump();
          await tester.pump();
          expect(_field, findsNothing, reason: id);
        }

        await tester.pumpWidget(
          _buildApp(Tree(nodes: _nodes, controller: controller)),
        );
        controller.startRename('main');
        await tester.pump();
        await tester.pump();
        expect(_field, findsNothing, reason: 'rename is not enabled');
      },
    );

    testWidgets(
      'a replaced controller no longer reaches the tree, nor does any '
      'controller once the tree is gone',
      (tester) async {
        final first = CoreTreeController();
        final second = CoreTreeController();
        addTearDown(first.dispose);
        addTearDown(second.dispose);

        material.Widget tree(CoreTreeController controller) => _buildApp(
          Tree(nodes: _nodes, controller: controller, onNodeRename: (_, _) {}),
        );

        await tester.pumpWidget(tree(first));
        await tester.pumpWidget(tree(second));

        first.startRename('main');
        await tester.pump();
        await tester.pump();
        expect(_field, findsNothing);

        second.startRename('main');
        await tester.pump();
        await tester.pump();
        expect(_field, findsOneWidget);

        await tester.pumpWidget(_buildApp(const material.SizedBox()));
        second.startRename('main');
        await tester.pump();
        expect(tester.takeException(), isNull);
      },
    );
  });
}
