// A dialog names itself.
//
// The route already scopes the screen reader's context; what it announces on
// arrival is the node marked as naming that route. Without one a dialog opens
// as an unnamed region, and the person hears the first control instead of
// what they were asked. The readings here are the rendered semantics tree —
// flags and roles on the nodes a screen reader walks — not what the widget
// declares.
import 'dart:async';
import 'dart:ui' show Tristate;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _openDialog(
  WidgetTester tester, {
  String? title,
  List<Widget> actions = const [material.Text('Cancel')],
}) async {
  await tester.pumpWidget(
    Theme(
      data: const ThemeData(),
      child: material.MaterialApp(
        home: material.Builder(
          builder: (context) => material.GestureDetector(
            onTap: () => unawaited(
              showDialog<void>(
                context: context,
                builder: (_) => Dialog(
                  title: title == null ? null : material.Text(title),
                  content: const material.Text('This cannot be undone.'),
                  actions: actions,
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
}

SemanticsData _of(WidgetTester tester, Finder finder) =>
    tester.getSemantics(finder).getSemanticsData();

/// Whether [node] or an ancestor satisfies [test] — the tree is read the way
/// a screen reader reads it: a name sits under the scope that contains it.
bool _underneath(
  SemanticsNode node,
  bool Function(SemanticsData data) test,
) {
  for (
    SemanticsNode? current = node;
    current != null;
    current = current.parent
  ) {
    if (test(current.getSemanticsData())) return true;
  }

  return false;
}

void main() {
  group('a dialog names itself', () {
    testWidgets('by its title', (tester) async {
      await _openDialog(tester, title: 'Delete item');

      final title = _of(tester, find.text('Delete item'));
      expect(title.flagsCollection.namesRoute, isTrue);
      expect(title.label, contains('Delete item'));
    });

    testWidgets('inside the route scope that announces it', (tester) async {
      await _openDialog(tester, title: 'Delete item');

      final node = tester.getSemantics(find.text('Delete item'));
      expect(
        _underneath(node, (data) => data.flagsCollection.scopesRoute),
        isTrue,
      );
    });

    testWidgets('and says what it is', (tester) async {
      await _openDialog(tester, title: 'Delete item');

      final node = tester.getSemantics(find.text('Delete item'));
      expect(
        _underneath(node, (data) => data.role == SemanticsRole.dialog),
        isTrue,
      );
    });

    testWidgets('the body is not the name', (tester) async {
      await _openDialog(tester, title: 'Delete item');

      // The negative control: only the title carries the flag, so a body that
      // had been swept into the name would fail here.
      expect(
        _of(
          tester,
          find.text('This cannot be undone.'),
        ).flagsCollection.namesRoute,
        isFalse,
      );
    });

    testWidgets('a dialog with no title names nothing it was not given', (
      tester,
    ) async {
      await _openDialog(tester);

      expect(
        _of(
          tester,
          find.text('This cannot be undone.'),
        ).flagsCollection.namesRoute,
        isFalse,
      );
    });
  });

  group('a dialog action with no handler', () {
    // Measured against upstream's disabled dialog actions: the action keeps
    // its place and tells a screen reader it is not available.
    testWidgets('stays in place and announces as disabled', (tester) async {
      await _openDialog(
        tester,
        title: 'Delete item',
        actions: const [
          Button(child: material.Text('Delete')),
        ],
      );

      expect(find.text('Delete'), findsOneWidget);
      expect(
        tester
            .getSemantics(find.text('Delete'))
            .getSemanticsData()
            .flagsCollection
            .isEnabled,
        Tristate.isFalse,
      );
    });

    testWidgets('a live action announces as enabled', (tester) async {
      await _openDialog(
        tester,
        title: 'Delete item',
        actions: [
          Button(onPressed: () {}, child: const material.Text('Delete')),
        ],
      );

      expect(
        tester
            .getSemantics(find.text('Delete'))
            .getSemanticsData()
            .flagsCollection
            .isEnabled,
        Tristate.isTrue,
      );
    });
  });
}
