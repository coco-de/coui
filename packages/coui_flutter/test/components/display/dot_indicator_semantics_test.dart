import 'dart:ui' show Tristate;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget child) => material.MaterialApp(
  home: Theme(data: const ThemeData(), child: child),
);

List<SemanticsNode> _nodes(WidgetTester tester) {
  final result = <SemanticsNode>[];
  void visit(SemanticsNode node) {
    if (!node.isMergedIntoParent) result.add(node);
    node.visitChildren((child) {
      visit(child);
      return true;
    });
  }

  final root =
      tester.binding.renderViews.first.owner!.semanticsOwner!.rootSemanticsNode;
  if (root != null) visit(root);
  return result;
}

void main() {
  testWidgets('interactive dots expose one named actionable node each', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    int? tapped;
    final events = <Object?>[];
    tester.binding.defaultBinaryMessenger.setMockDecodedMessageHandler<Object?>(
      SystemChannels.accessibility,
      (message) async {
        events.add(message);
        return null;
      },
    );
    await tester.pumpWidget(
      _app(DotIndicator(index: 1, length: 3, onChanged: (i) => tapped = i)),
    );
    final nodes = _nodes(tester);
    final controls = nodes.where((node) {
      final data = node.getSemanticsData();
      return data.flagsCollection.isButton ||
          data.hasAction(SemanticsAction.tap);
    }).toList();
    expect(controls, hasLength(3));
    expect(controls.map((node) => node.getSemanticsData().label), [
      'Go to item 1',
      'Go to item 2',
      'Go to item 3',
    ]);
    expect(
      controls[1].getSemanticsData().flagsCollection.isSelected,
      Tristate.isTrue,
    );
    expect(
      controls.every(
        (node) => node.getSemanticsData().hasAction(SemanticsAction.tap),
      ),
      isTrue,
    );
    tester.binding.renderViews.first.owner!.semanticsOwner!.performAction(
      controls[2].id,
      SemanticsAction.tap,
    );
    await tester.pump();
    expect(tapped, 2);
    expect(
      events.whereType<Map<Object?, Object?>>().any(
        (event) => event['type'] == 'tap',
      ),
      isTrue,
    );
    tester.binding.defaultBinaryMessenger.setMockDecodedMessageHandler<Object?>(
      SystemChannels.accessibility,
      null,
    );
    handle.dispose();
  });

  testWidgets('passive dots do not expose actions or buttons', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_app(const DotIndicator(index: 1, length: 3)));
    final nodes = _nodes(tester);
    expect(
      nodes.where((node) {
        final data = node.getSemanticsData();
        return data.flagsCollection.isButton ||
            data.hasAction(SemanticsAction.tap);
      }),
      isEmpty,
    );
    expect(
      nodes.map((node) => node.getSemanticsData().label),
      contains('Item 2 of 3'),
    );
    handle.dispose();
  });
  testWidgets('semantics track switching between interactive and passive', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    var interactive = true;
    var selected = 0;
    late void Function(void Function()) update;
    await tester.pumpWidget(
      _app(
        material.StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return DotIndicator(
              index: selected,
              length: 3,
              onChanged: interactive
                  ? (i) => setState(() => selected = i)
                  : null,
            );
          },
        ),
      ),
    );
    update(() => interactive = false);
    await tester.pump();
    expect(
      _nodes(tester).map((n) => n.getSemanticsData().label),
      contains('Item 1 of 3'),
    );
    expect(
      _nodes(
        tester,
      ).where((n) => n.getSemanticsData().hasAction(SemanticsAction.tap)),
      isEmpty,
    );
    update(() => interactive = true);
    await tester.pump();
    final target = _nodes(
      tester,
    ).singleWhere((n) => n.getSemanticsData().label == 'Go to item 3');
    tester.binding.renderViews.first.owner!.semanticsOwner!.performAction(
      target.id,
      SemanticsAction.tap,
    );
    await tester.pump();
    expect(selected, 2);
    final current = _nodes(
      tester,
    ).singleWhere((n) => n.getSemanticsData().label == 'Go to item 3');
    expect(
      current.getSemanticsData().flagsCollection.isSelected,
      Tristate.isTrue,
    );
    handle.dispose();
  });

  for (final variant in CoreCarouselVariant.values) {
    testWidgets(
      'carousel $variant preserves indicator semantics and selection',
      (tester) async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(
          _app(
            Carousel(
              items: const [Text('one'), Text('two'), Text('three')],
              transition: const CarouselTransition.sliding(),
              variant: variant,
              wrap: false,
              showNavigation: false,
            ),
          ),
        );
        await tester.pumpAndSettle();
        final targets = _nodes(tester)
            .where((n) => n.getSemanticsData().label.startsWith('Go to item '))
            .toList();
        expect(targets, hasLength(3));
        expect(
          targets.every(
            (n) => n.getSemanticsData().hasAction(SemanticsAction.tap),
          ),
          isTrue,
        );
        tester.binding.renderViews.first.owner!.semanticsOwner!.performAction(
          targets[1].id,
          SemanticsAction.tap,
        );
        await tester.pumpAndSettle();
        final selected = _nodes(
          tester,
        ).singleWhere((n) => n.getSemanticsData().label == 'Go to item 2');
        expect(
          selected.getSemanticsData().flagsCollection.isSelected,
          Tristate.isTrue,
        );
        handle.dispose();
      },
    );
  }
  for (final direction in CoreAxis.values) {
    testWidgets('keyboard selects along the $direction axis', (tester) async {
      int? selected;
      await tester.pumpWidget(
        _app(
          DotIndicator(
            index: 0,
            length: 3,
            direction: direction,
            onChanged: (i) => selected = i,
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(
        direction == CoreAxis.horizontal
            ? LogicalKeyboardKey.arrowRight
            : LogicalKeyboardKey.arrowDown,
      );
      await tester.pump();
      expect(selected, 1);
    });
  }
  testWidgets('empty interactive indicator has no actions', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _app(DotIndicator(index: 0, length: 0, onChanged: (_) {})),
    );
    expect(
      _nodes(
        tester,
      ).where((node) => node.getSemanticsData().hasAction(SemanticsAction.tap)),
      isEmpty,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    expect(tester.takeException(), isNull);
    handle.dispose();
  });
  testWidgets('passive position is localized in Korean', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      CoUIApp(
        home: const DotIndicator(index: 1, length: 3),
        locale: const Locale('ko'),
        supportedLocales: const [Locale('en', 'US'), Locale('ko')],
        theme: ThemeData.fromCore(CoreThemePresets.light),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      _nodes(tester).map((node) => node.getSemanticsData().label),
      contains('전체 3개 항목 중 2번째'),
    );
    handle.dispose();
  });
}
