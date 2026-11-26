import 'package:coui_core/coui_core.dart';
import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Whether any semantics node in the tree states an expansion state.
///
/// Read off the widgets rather than a single node: the trigger that
/// carries it is not the one a text finder lands on.
Iterable<bool?> _expandedFlags(WidgetTester tester) => tester
    .widgetList<Semantics>(find.byType(Semantics))
    .map((w) => w.properties.expanded);

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    CoUIApp(
      theme: ThemeData.fromCore(CoreThemePresets.light),
      home: Align(child: SizedBox(width: 320, child: child)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('a trigger says whether the thing it controls is showing', () {
    testWidgets('an accordion header states it, and it follows the panel', (
      tester,
    ) async {
      // Web has put `aria-expanded` on this control all along. Without
      // the Flutter half a reader announces "button" and the user has no
      // way to know whether activating opens or closes — nor that it
      // opened afterwards.
      await _pump(
        tester,
        Accordion(
          items: [
            AccordionItem(title: 'Shipping', content: const Text('c')),
          ],
        ),
      );

      expect(_expandedFlags(tester), contains(false));

      await tester.tap(find.text('Shipping'));
      await tester.pumpAndSettle();

      expect(
        _expandedFlags(tester),
        contains(true),
        reason: 'the header still says collapsed after opening',
      );
    });

    testWidgets('a tree node with children states it, and it follows', (
      tester,
    ) async {
      await _pump(
        tester,
        Tree(
          onNodeSelect: (_) {},
          nodes: const [
            CoreTreeNode(
              label: 'Parent',
              children: [CoreTreeNode(label: 'Child')],
            ),
          ],
        ),
      );

      expect(_expandedFlags(tester), contains(false));

      await tester.tap(find.text('Parent'));
      await tester.pumpAndSettle();

      expect(_expandedFlags(tester), contains(true));
    });

    testWidgets('and a leaf states nothing', (tester) async {
      // Null, not `false`. A leaf that said "collapsed, activate to
      // open" would be describing something it cannot do.
      //
      // `onNodeSelect` is what makes this the right test: a leaf without
      // a handler renders bare — no interactive wrapper at all — so it
      // would report nothing no matter how the wiring behaved. The row
      // that could get this wrong is the one that *is* a control.
      await _pump(
        tester,
        Tree(
          onNodeSelect: (_) {},
          nodes: const [CoreTreeNode(label: 'Leaf')],
        ),
      );

      expect(_expandedFlags(tester).whereType<bool>(), isEmpty);
    });
  });

  group('a control that expands nothing says nothing', () {
    testWidgets('a plain action button states no expansion', (tester) async {
      // The same distinction as the tree leaf, on the component where it
      // is easiest to get wrong: a FAB with no actions is an ordinary
      // button, and `false` would promise a menu that does not exist.
      await _pump(tester, Fab(onPressed: () {}, trigger: const Text('+')));

      expect(_expandedFlags(tester).whereType<bool>(), isEmpty);
    });

    testWidgets('and one with actions states it', (tester) async {
      await _pump(
        tester,
        Fab(
          onPressed: () {},
          actions: const [CoreFabAction<Widget>(icon: Text('a'))],
          trigger: const Text('+'),
        ),
      );

      expect(_expandedFlags(tester), contains(false));
    });
  });
}
