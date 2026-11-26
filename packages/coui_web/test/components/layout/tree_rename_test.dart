// What the Web twin of the Tree rename and folder-press opt-ins can prove on
// the VM: the press wiring, the field the double-click mounts and the policy
// that keeps a row read-only. The field's own keys (Enter · Escape · blur)
// need a browser — `universal_web` throws on `KeyboardEvent.key` here — so
// the decisions they make live in `CoreTreeRenameRules`, pinned in
// coui_core, and the key isolation is pinned on the Flutter twin.
import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

const _nodes = [
  CoreTreeNode(
    id: 'lib',
    label: 'lib',
    children: [CoreTreeNode(id: 'lib/a', label: 'a.dart')],
  ),
  CoreTreeNode(id: 'main', label: 'main.dart'),
];

Finder _row(String id) => find.byComponentPredicate(
  (component) => component is Clickable && component.id == 'tree-node.$id',
  description: 'tree row $id',
);

Clickable _rowClickable(String id) =>
    _row(id).evaluate().single.component as Clickable;

void main() {
  group('Tree toggleFoldersOnSelect', () {
    testComponents('a folder row press selects and toggles when opted in', (
      tester,
    ) async {
      final selected = <String?>[];
      final toggled = <String?>[];
      pumpWithTheme(
        tester,
        Tree(
          nodes: _nodes,
          selectFolders: true,
          toggleFoldersOnSelect: true,
          onNodeSelect: (node) => selected.add(node.id),
          onNodeToggle: (node) => toggled.add(node.id),
        ),
      );
      await tester.pump();
      expect(find.text('a.dart'), findsNothing);

      await tester.click(_row('lib'));

      expect(selected, ['lib']);
      expect(toggled, ['lib']);
      expect(find.text('a.dart'), findsOneComponent);
    });

    testComponents('without the opt-in a folder row press only selects', (
      tester,
    ) async {
      final selected = <String?>[];
      final toggled = <String?>[];
      pumpWithTheme(
        tester,
        Tree(
          nodes: _nodes,
          selectFolders: true,
          onNodeSelect: (node) => selected.add(node.id),
          onNodeToggle: (node) => toggled.add(node.id),
        ),
      );
      await tester.pump();

      await tester.click(_row('lib'));

      expect(selected, ['lib']);
      expect(toggled, isEmpty);
      expect(find.text('a.dart'), findsNothing);
    });
  });

  group('Tree inline rename', () {
    testComponents('a double-click swaps the label for a seeded field', (
      tester,
    ) async {
      pumpWithTheme(tester, Tree(nodes: _nodes, onNodeRename: (_, _) {}));
      await tester.pump();
      expect(find.byType(TextField), findsNothing);

      tester.dispatchEvent(_row('main'), 'dblclick');
      await tester.pump();

      final field =
          find.byType(TextField).evaluate().single.component as TextField;
      expect(field.initialValue, 'main.dart');
      expect(field.onSubmitted, isNotNull);
      expect(field.onTapOutside, isNotNull);
      expect(
        field.textFieldStyle?.baseTextStyle,
        isNotNull,
        reason: 'the field keeps the row label typography',
      );
      // The row stops being a pressable, draggable Clickable while edited.
      expect(_row('main'), findsNothing);
      expect(find.text('main.dart'), findsNothing);
    });

    testComponents('a row the consumer refuses never opens the field', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        Tree(
          nodes: _nodes,
          onNodeRename: (_, _) {},
          canRenameNode: (node) => node.id != 'main',
        ),
      );
      await tester.pump();

      expect(_rowClickable('main').onDoubleTap, isNull);
      expect(_rowClickable('lib').onDoubleTap, isNotNull);
    });

    testComponents('without onNodeRename no row listens for a double-click', (
      tester,
    ) async {
      pumpWithTheme(tester, Tree(nodes: _nodes, onNodeSelect: (_) {}));
      await tester.pump();

      expect(_rowClickable('main').onDoubleTap, isNull);
      expect(_rowClickable('lib').onDoubleTap, isNull);
    });
  });

  // A consumer whose keyboard model lives outside the rows starts the edit
  // through the controller (#5252) — the path F2 on the row takes.
  group('Tree rename from a CoreTreeController', () {
    testComponents('startRename mounts the seeded field on that row', (
      tester,
    ) async {
      final controller = CoreTreeController();
      pumpWithTheme(
        tester,
        Tree(nodes: _nodes, controller: controller, onNodeRename: (_, _) {}),
      );
      await tester.pump();

      controller.startRename('main');
      await tester.pump();

      final field =
          find.byType(TextField).evaluate().single.component as TextField;
      expect(field.initialValue, 'main.dart');
      expect(_row('main'), findsNothing);
    });

    testComponents(
      'an unknown id, a hidden row, a refused row and a tree without '
      'onNodeRename all ignore the request',
      (tester) async {
        final controller = CoreTreeController();
        pumpWithTheme(
          tester,
          Tree(
            nodes: _nodes,
            controller: controller,
            onNodeRename: (_, _) {},
            canRenameNode: (node) => node.id != 'main',
          ),
        );
        await tester.pump();

        // `lib` starts collapsed, so `lib/a` has no visible row.
        for (final id in ['missing', 'lib/a', 'main']) {
          controller.startRename(id);
          await tester.pump();
          expect(find.byType(TextField), findsNothing, reason: id);
        }

        final plain = CoreTreeController();
        pumpWithTheme(tester, Tree(nodes: _nodes, controller: plain));
        await tester.pump();
        plain.startRename('lib');
        await tester.pump();
        expect(find.byType(TextField), findsNothing);
      },
    );

    testComponents('a replaced controller no longer reaches the tree', (
      tester,
    ) async {
      final first = CoreTreeController();
      final second = CoreTreeController();
      late _ControllerHostState host;
      pumpWithTheme(
        tester,
        _ControllerHost(
          initial: first,
          onState: (state) => host = state,
          builder: (controller) => Tree(
            nodes: _nodes,
            controller: controller,
            onNodeRename: (_, _) {},
          ),
        ),
      );
      await tester.pump();

      // The same Tree state is updated with the new controller — a fresh
      // mount would subscribe to it without the update path ever running.
      host.setController(second);
      await tester.pump();

      first.startRename('main');
      await tester.pump();
      expect(find.byType(TextField), findsNothing);

      second.startRename('main');
      await tester.pump();
      expect(find.byType(TextField), findsOneComponent);
    });
  });
}

/// Rebuilds its child with another controller while keeping the child's
/// state, so `didUpdateComponent` is what swaps the subscription.
class _ControllerHost extends StatefulComponent {
  const _ControllerHost({
    required this.initial,
    required this.builder,
    required this.onState,
  });

  final CoreTreeController initial;

  /// Builds the tree from the current controller.
  final Component Function(CoreTreeController controller) builder;

  /// Hands the live state back on every build, since `setState` is
  /// `@protected` and a test sits outside the component tree.
  final void Function(_ControllerHostState state) onState;

  @override
  State<_ControllerHost> createState() => _ControllerHostState();
}

class _ControllerHostState extends State<_ControllerHost> {
  late CoreTreeController controller = component.initial;

  void setController(CoreTreeController next) =>
      setState(() => controller = next);

  @override
  Component build(BuildContext context) {
    component.onState(this);
    return component.builder(controller);
  }
}
