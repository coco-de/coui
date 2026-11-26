import 'dart:ui' show SemanticsAction;

import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:flutter/rendering.dart' show RenderEditable;
import 'package:flutter/semantics.dart' show SemanticsNode;
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter/widgets.dart' as widgets;
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

enum _Kind { select, autocomplete, numberInput }

enum _Pose { groupDisabled, groupEnabled, ownDisabled }

widgets.Widget _inputFor(
  _Kind kind, {
  required List<String> changes,
  required List<String> selected,
  required List<double> numbers,
  widgets.Key? key,
  bool enabled = true,
  bool updated = false,
  bool controlledNumber = false,
}) => switch (kind) {
  _Kind.select => coui.Select<String>(
    key: key,
    value: updated ? 'banana' : 'apple',
    enabled: enabled,
    items: const [
      coui.CoreSelectItem(value: 'apple', label: 'Apple'),
      coui.CoreSelectItem(value: 'banana', label: 'Banana'),
    ],
    onChanged: changes.add,
  ),
  _Kind.autocomplete => coui.Autocomplete(
    key: key,
    value: updated ? 'Next' : '',
    enabled: enabled,
    suggestions: const ['Apple', 'Banana'],
    onChanged: changes.add,
    onSelected: selected.add,
  ),
  _Kind.numberInput => coui.NumberInput(
    key: key,
    initialValue: 2,
    value: controlledNumber ? (updated ? 7 : 2) : null,
    enabled: enabled,
    onChanged: numbers.add,
  ),
};

widgets.Widget _scoped(
  widgets.Widget child,
  _Pose pose,
  widgets.Widget Function(widgets.Widget)? wrapper,
) => wrapper != null
    ? wrapper(child)
    : coui.Fieldset(enabled: pose != _Pose.groupDisabled, children: [child]);

widgets.Widget _host(widgets.Widget child) => widgets.WidgetsApp(
  color: const widgets.Color(0xff000000),
  builder: (_, _) => buildTestApp(
    widgets.SizedBox(width: 360, child: child),
    theme: coui.ThemeData.fromCore(coui.CoreThemePresets.light),
  ),
);

Future<void> _frames(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _finishPanelExit(WidgetTester tester) async {
  // The post-frame close first rebuilds the overlay, then its exit tween
  // removes the entry at onEnd. The editor's caret keeps scheduling frames,
  // so wait for this public panel content with a finite frame bound.
  for (
    var frame = 0;
    frame < 20 && find.text('Banana').evaluate().isNotEmpty;
    frame++
  ) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

widgets.EditableText _editor(WidgetTester tester) =>
    tester.widget<widgets.EditableText>(find.byType(widgets.EditableText));

String _renderedValue(WidgetTester tester) {
  final paintedEditor = find.descendant(
    of: find.byType(widgets.EditableText),
    matching: find.byElementPredicate(
      (element) =>
          element is widgets.RenderObjectElement &&
          element.renderObject is RenderEditable,
    ),
  );
  expect(paintedEditor, findsOneWidget);
  return tester.renderObject<RenderEditable>(paintedEditor).text!.toPlainText();
}

Future<void> _exercise(
  WidgetTester tester, {
  required _Kind kind,
  required _Pose pose,
  widgets.Widget Function(widgets.Widget)? scopeWrapper,
}) async {
  final sentinel = widgets.FocusNode(debugLabel: 'before-input');
  addTearDown(sentinel.dispose);
  final changes = <String>[];
  final selected = <String>[];
  final numbers = <double>[];
  final ownEnabled = pose != _Pose.ownDisabled;
  final effectiveDisabled = pose != _Pose.groupEnabled;
  coui.CoreFormFieldScope? actualScope;
  final input = _inputFor(
    kind,
    enabled: ownEnabled,
    changes: changes,
    selected: selected,
    numbers: numbers,
  );
  await tester.pumpWidget(
    _host(
      widgets.FocusTraversalGroup(
        policy: widgets.OrderedTraversalPolicy(),
        child: widgets.Column(
          mainAxisSize: widgets.MainAxisSize.min,
          children: [
            widgets.FocusTraversalOrder(
              order: const widgets.NumericFocusOrder(0),
              child: widgets.Focus(
                focusNode: sentinel,
                child: const widgets.Text('Before input'),
              ),
            ),
            widgets.FocusTraversalOrder(
              order: const widgets.NumericFocusOrder(1),
              child: _scoped(
                widgets.Builder(
                  builder: (context) {
                    actualScope = coui.FormFieldScope.maybeOf(context);
                    return input;
                  },
                ),
                pose,
                scopeWrapper,
              ),
            ),
          ],
        ),
      ),
    ),
  );
  await _frames(tester);
  expect(actualScope, isNotNull);
  expect(actualScope!.disabled, pose == _Pose.groupDisabled);
  expect(
    _editor(tester).readOnly,
    kind == _Kind.select || effectiveDisabled,
  );
  final initial = _renderedValue(tester);
  expect(initial, switch (kind) {
    _Kind.select => 'Apple',
    _Kind.autocomplete => '',
    _Kind.numberInput => '2',
  });

  // Only the caller-owned sentinel is positioned directly. Reaching the
  // actual editor must use real Tab traversal, including any step buttons.
  sentinel.requestFocus();
  await tester.pump();
  expect(sentinel.hasPrimaryFocus, isTrue);
  for (
    var attempt = 0;
    attempt < 6 && !_editor(tester).focusNode.hasFocus;
    attempt++
  ) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await _frames(tester);
  }
  expect(
    _editor(tester).focusNode.hasFocus,
    isTrue,
    reason: 'The real Tab route must reach the input before testing its keys',
  );
  expect(tester.takeException(), isNull);

  await tester.sendKeyEvent(
    kind == _Kind.numberInput
        ? LogicalKeyboardKey.arrowUp
        : LogicalKeyboardKey.arrowDown,
  );
  await _frames(tester);
  if (kind == _Kind.autocomplete) {
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await _frames(tester);
  }
  expect(tester.takeException(), isNull);
  final renderedAfter = _renderedValue(tester);

  if (effectiveDisabled) {
    expect(
      changes,
      isEmpty,
      reason:
          'Disabled input must not emit a user value change; '
          'rendered=$renderedAfter; selected=$selected',
    );
    expect(selected, isEmpty);
    expect(
      numbers,
      isEmpty,
      reason:
          'Disabled number input must not step from a real key; '
          'rendered=$renderedAfter',
    );
    expect(renderedAfter, initial);
  } else {
    switch (kind) {
      case _Kind.select:
        expect(changes, ['banana']);
        expect(renderedAfter, 'Banana');
      case _Kind.autocomplete:
        expect(changes, ['Apple']);
        expect(selected, ['Apple']);
        expect(renderedAfter, 'Apple');
      case _Kind.numberInput:
        expect(numbers, [3.0]);
        expect(renderedAfter, '3');
    }
  }
}

Future<void> _ancestorOnlyChange(WidgetTester tester, _Kind kind) async {
  final enabled = widgets.ValueNotifier<bool>(true);
  final sentinel = widgets.FocusNode(debugLabel: 'before-current-input');
  addTearDown(enabled.dispose);
  addTearDown(sentinel.dispose);
  final key = widgets.ValueKey<String>('current-${kind.name}');
  final changes = <String>[];
  final selected = <String>[];
  final numbers = <double>[];
  final input = _inputFor(
    kind,
    key: key,
    changes: changes,
    selected: selected,
    numbers: numbers,
  );
  coui.CoreFormFieldScope? actualScope;
  await tester.pumpWidget(
    _host(
      widgets.Column(
        mainAxisSize: widgets.MainAxisSize.min,
        children: [
          widgets.Focus(
            focusNode: sentinel,
            child: const widgets.Text('Before current input'),
          ),
          widgets.ValueListenableBuilder<bool>(
            valueListenable: enabled,
            child: input,
            builder: (_, value, heldInput) => coui.Fieldset(
              enabled: value,
              children: [
                widgets.Builder(
                  builder: (context) {
                    actualScope = coui.FormFieldScope.maybeOf(context);
                    return heldInput!;
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
  await _frames(tester);
  sentinel.requestFocus();
  await tester.pump();
  for (
    var attempt = 0;
    attempt < 6 && !_editor(tester).focusNode.hasFocus;
    attempt++
  ) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await _frames(tester);
  }
  expect(_editor(tester).focusNode.hasFocus, isTrue);
  expect(actualScope!.disabled, isFalse);
  if (kind == _Kind.select) {
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await _frames(tester);
  }
  if (kind != _Kind.numberInput) {
    expect(find.text('Banana'), findsOneWidget);
  }
  final element = tester.element(find.byKey(key));
  final focus = _editor(tester).focusNode;
  final initial = _renderedValue(tester);

  enabled.value = false;
  await _frames(tester);
  if (kind != _Kind.numberInput) {
    await _finishPanelExit(tester);
  }
  expect(tester.element(find.byKey(key)), same(element));
  expect(_editor(tester).focusNode, same(focus));
  expect(focus.hasFocus, isTrue);
  expect(_editor(tester).readOnly, isTrue);
  expect(actualScope!.disabled, isTrue);
  if (kind != _Kind.numberInput) {
    expect(find.text('Banana'), findsNothing);
  }
  await tester.sendKeyEvent(
    kind == _Kind.numberInput
        ? LogicalKeyboardKey.arrowUp
        : LogicalKeyboardKey.arrowDown,
  );
  await _frames(tester);
  if (kind != _Kind.numberInput) {
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await _frames(tester);
  }
  expect(changes, isEmpty);
  expect(selected, isEmpty);
  expect(numbers, isEmpty);
  expect(_renderedValue(tester), initial);
  expect(tester.takeException(), isNull);

  enabled.value = true;
  await _frames(tester);
  expect(tester.element(find.byKey(key)), same(element));
  expect(_editor(tester).focusNode, same(focus));
  expect(actualScope!.disabled, isFalse);
  await tester.sendKeyEvent(
    kind == _Kind.numberInput
        ? LogicalKeyboardKey.arrowUp
        : LogicalKeyboardKey.arrowDown,
  );
  await _frames(tester);
  if (kind == _Kind.autocomplete) {
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await _frames(tester);
  }
  switch (kind) {
    case _Kind.select:
      expect(changes, ['banana']);
      expect(_renderedValue(tester), 'Banana');
    case _Kind.autocomplete:
      expect(changes, ['Apple']);
      expect(selected, ['Apple']);
      expect(_renderedValue(tester), 'Apple');
    case _Kind.numberInput:
      expect(numbers, [3.0]);
      expect(_renderedValue(tester), '3');
  }
}

Future<void> _controlledWhileDisabled(
  WidgetTester tester,
  _Kind kind,
) async {
  final updated = widgets.ValueNotifier<bool>(false);
  addTearDown(updated.dispose);
  final key = widgets.ValueKey<String>('controlled-${kind.name}');
  final changes = <String>[];
  final selected = <String>[];
  final numbers = <double>[];
  await tester.pumpWidget(
    _host(
      coui.Fieldset(
        enabled: false,
        children: [
          widgets.ValueListenableBuilder<bool>(
            valueListenable: updated,
            builder: (_, value, _) => _inputFor(
              kind,
              key: key,
              updated: value,
              controlledNumber: true,
              changes: changes,
              selected: selected,
              numbers: numbers,
            ),
          ),
        ],
      ),
    ),
  );
  await _frames(tester);
  final element = tester.element(find.byKey(key));
  expect(_editor(tester).readOnly, isTrue);
  expect(_renderedValue(tester), switch (kind) {
    _Kind.select => 'Apple',
    _Kind.autocomplete => '',
    _Kind.numberInput => '2',
  });
  updated.value = true;
  await _frames(tester);
  expect(tester.element(find.byKey(key)), same(element));
  expect(_editor(tester).readOnly, isTrue);
  expect(_renderedValue(tester), switch (kind) {
    _Kind.select => 'Banana',
    _Kind.autocomplete => 'Next',
    _Kind.numberInput => '7',
  });
  expect(changes, isEmpty);
  expect(selected, isEmpty);
  expect(numbers, isEmpty);
  expect(tester.takeException(), isNull);
}

List<SemanticsNode> _numberSemantics(WidgetTester tester) {
  final nodes = <SemanticsNode>[];
  void visit(SemanticsNode node) {
    nodes.add(node);
    node.visitChildren((child) {
      visit(child);
      return true;
    });
  }

  visit(tester.getSemantics(find.byType(coui.NumberInput)));
  return nodes;
}

void main() {
  testWidgets('normal host Tab visits both ordinary visible inputs', (
    tester,
  ) async {
    final first = widgets.FocusNode(debugLabel: 'first-visible-input');
    final second = widgets.FocusNode(debugLabel: 'second-visible-input');
    addTearDown(first.dispose);
    addTearDown(second.dispose);
    await tester.pumpWidget(
      _host(
        widgets.Column(
          mainAxisSize: widgets.MainAxisSize.min,
          children: [
            coui.TextField(focusNode: first),
            coui.TextField(focusNode: second),
          ],
        ),
      ),
    );
    await _frames(tester);
    first.requestFocus();
    await tester.pump();
    expect(first.hasPrimaryFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await _frames(tester);
    expect(first.hasFocus, isFalse);
    expect(second.hasPrimaryFocus, isTrue);
    expect(tester.takeException(), isNull);
  });

  for (final kind in _Kind.values) {
    for (final pose in _Pose.values) {
      testWidgets('${kind.name} ${pose.name} real keyboard value action', (
        tester,
      ) async {
        await _exercise(tester, kind: kind, pose: pose);
      });
    }
    testWidgets('${kind.name} respects a disabled FormField', (tester) async {
      await _exercise(
        tester,
        kind: kind,
        pose: _Pose.groupDisabled,
        scopeWrapper: (child) => coui.FormField(enabled: false, child: child),
      );
    });
    testWidgets('${kind.name} nested enabled wrappers cannot re-enable', (
      tester,
    ) async {
      await _exercise(
        tester,
        kind: kind,
        pose: _Pose.groupDisabled,
        scopeWrapper: (child) => coui.Fieldset(
          enabled: false,
          children: [
            coui.Fieldset(
              children: [coui.FormField(child: child)],
            ),
          ],
        ),
      );
    });
    testWidgets('${kind.name} reacts to an ancestor-only disabled change', (
      tester,
    ) async {
      await _ancestorOnlyChange(tester, kind);
    });
    testWidgets('${kind.name} keeps controlled updates while disabled', (
      tester,
    ) async {
      await _controlledWhileDisabled(tester, kind);
    });
  }

  testWidgets('ambient disable removes NumberInput semantic step actions', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    try {
      final enabled = widgets.ValueNotifier<bool>(true);
      addTearDown(enabled.dispose);
      final numbers = <double>[];
      await tester.pumpWidget(
        _host(
          widgets.ValueListenableBuilder<bool>(
            valueListenable: enabled,
            child: coui.NumberInput(initialValue: 2, onChanged: numbers.add),
            builder: (_, value, child) =>
                coui.Fieldset(enabled: value, children: [child!]),
          ),
        ),
      );
      await _frames(tester);
      final increase = _numberSemantics(tester).singleWhere(
        (node) => node.getSemanticsData().hasAction(SemanticsAction.increase),
      );
      expect(
        _numberSemantics(tester).any(
          (node) => node.getSemanticsData().hasAction(SemanticsAction.decrease),
        ),
        isTrue,
      );
      increase.owner!.performAction(increase.id, SemanticsAction.increase);
      await _frames(tester);
      expect(numbers, [3.0]);
      expect(_renderedValue(tester), '3');
      enabled.value = false;
      await _frames(tester);
      expect(
        _numberSemantics(tester).any(
          (node) =>
              node.getSemanticsData().hasAction(SemanticsAction.increase) ||
              node.getSemanticsData().hasAction(SemanticsAction.decrease),
        ),
        isFalse,
      );
      expect(numbers, [3.0]);
      expect(_renderedValue(tester), '3');
    } finally {
      handle.dispose();
    }
  });
}
