import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_test/flutter_test.dart';

Widget _buildApp(Widget child) => material.MaterialApp(
  home: Theme(data: const ThemeData(), child: child),
);

void main() {
  group('CoreAutocompleteMode', () {
    test('has append, replaceAll, replaceWord values', () {
      expect(
        CoreAutocompleteMode.values,
        containsAll([
          CoreAutocompleteMode.append,
          CoreAutocompleteMode.replaceAll,
          CoreAutocompleteMode.replaceWord,
        ]),
      );
    });

    test('values are distinct', () {
      expect(
        CoreAutocompleteMode.append,
        isNot(equals(CoreAutocompleteMode.replaceAll)),
      );
      expect(
        CoreAutocompleteMode.append,
        isNot(equals(CoreAutocompleteMode.replaceWord)),
      );
    });
  });

  group('Autocomplete widget', () {
    testWidgets('fills the available width (field-trigger convention)', (
      tester,
    ) async {
      const parentWidth = 300.0;
      await tester.pumpWidget(
        _buildApp(
          material.Center(
            child: material.SizedBox(
              width: parentWidth,
              child: const Autocomplete(suggestions: ['Apple', 'Banana']),
            ),
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      // `CoreAutocompleteStyle.defaultPopoverStyle` carries
      // `triggerSizing: .expand`, so the inner TextField stretches to
      // the parent's inline axis instead of shrink-wrapping.
      expect(tester.getSize(find.byType(TextField)).width, parentWidth);
    });

    testWidgets('renders the widget in the tree', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const Autocomplete(
            key: Key('autocomplete'),
            suggestions: [],
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.byKey(const Key('autocomplete')), findsOneWidget);
      expect(find.byType(Autocomplete), findsOneWidget);
    });

    testWidgets('renders with placeholder', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const Autocomplete(
            placeholder: 'Search...',
            suggestions: [],
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.byType(Autocomplete), findsOneWidget);
    });

    testWidgets('renders with mode set', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const Autocomplete(
            mode: .append,
            suggestions: [],
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.byType(Autocomplete), findsOneWidget);
    });

    testWidgets('renders with suggestions', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const Autocomplete(
            suggestions: ['Apple', 'Banana'],
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.byType(Autocomplete), findsOneWidget);
    });
  });

  group('Autocomplete panel reconciles with props', () {
    // The panel used to react only to text edits, so anything the parent
    // changed underneath it (suggestions arriving, the field going
    // disabled) left a stale — or permanently closed — panel behind.

    testWidgets('closes when suggestions are emptied underneath it', (
      tester,
    ) async {
      await _pumpAutocomplete(tester, suggestions: _fruit);
      await _openPanel(tester);
      expect(find.text('Apricot'), findsOneWidget);

      await _pumpAutocomplete(tester, suggestions: const []);
      await _settle(tester);

      expect(find.text('Apricot'), findsNothing);
    });

    testWidgets('swaps contents when suggestions are replaced', (
      tester,
    ) async {
      await _pumpAutocomplete(tester, suggestions: _fruit);
      await _openPanel(tester);
      expect(find.text('Apricot'), findsOneWidget);

      await _pumpAutocomplete(
        tester,
        suggestions: const ['Banana', 'Cherry'],
      );
      await _settle(tester);

      expect(find.text('Apricot'), findsNothing);
      expect(find.text('Banana'), findsOneWidget);
    });

    testWidgets('closes when the field goes disabled underneath it', (
      tester,
    ) async {
      await _pumpAutocomplete(tester, suggestions: _fruit);
      await _openPanel(tester);
      expect(find.text('Apricot'), findsOneWidget);

      await _pumpAutocomplete(tester, suggestions: _fruit, enabled: false);
      await _settle(tester);

      expect(find.text('Apricot'), findsNothing);
    });

    testWidgets('opens when async suggestions arrive after the query', (
      tester,
    ) async {
      // The sharpest form of the bug: the list is empty while a fetch is
      // in flight, so the panel never opens; the results then land as new
      // props that nothing was watching, leaving it shut forever.
      await _pumpAutocomplete(tester, suggestions: const []);
      await _openPanel(tester);
      await tester.enterText(find.byType(TextField), 'Ap');
      await _settle(tester);
      expect(find.text('Apricot'), findsNothing);

      await _pumpAutocomplete(tester, suggestions: _fruit);
      await _settle(tester);

      expect(find.text('Apricot'), findsOneWidget);
    });
  });

  group('Autocomplete does not reopen after a selection', () {
    testWidgets('a controlled parent rebuilding on onChanged keeps it shut', (
      tester,
    ) async {
      // Selecting fires `onChanged`; a controlled parent rebuilds with a
      // new `value`, and the field is still focused with text that matches
      // the suggestion just chosen. Reconciling on props without
      // suppressing the reopen makes the panel spring straight back.
      await tester.pumpWidget(_buildApp(const _ControlledHost()));
      await _settle(tester);

      await _openPanel(tester);
      // 'Apple pie' is the probe: it survives the post-selection filter
      // (query 'Apple' still matches it), so it is visible whenever the
      // panel is open and absent only when the panel is truly closed.
      expect(find.text('Apple pie'), findsOneWidget);

      await tester.tap(find.text('Apple').last);
      await _settle(tester);

      expect(find.text('Apple pie'), findsNothing);
    });

    testWidgets('typing again after a selection reopens it', (tester) async {
      // The suppression must lift, or the field is dead after one pick.
      await tester.pumpWidget(_buildApp(const _ControlledHost()));
      await _settle(tester);

      await _openPanel(tester);
      await tester.tap(find.text('Apple').last);
      await _settle(tester);
      expect(find.text('Apple pie'), findsNothing);

      // A real edit — re-entering the identical text fires no change event
      // at all, so it would prove nothing about the suppression lifting.
      await tester.enterText(find.byType(TextField), 'Appl');
      await _settle(tester);

      expect(find.text('Apple pie'), findsOneWidget);
    });
  });

  group('Autocomplete replaceWord completes the word under the caret', () {
    // `replaceWord` is the default mode, and it was an alias of
    // `replaceAll`: it matched the whole field, so the dropdown emptied the
    // moment a second word was typed, and picking a suggestion threw the
    // rest of the sentence away.

    testWidgets('offers suggestions for the word being typed', (tester) async {
      await _pumpAutocomplete(tester, suggestions: _fruit);
      await _openPanel(tester);
      await tester.enterText(find.byType(TextField), 'I like App');
      await _settle(tester);

      expect(find.text('Apple'), findsOneWidget);
    });

    testWidgets('splices that word and keeps the rest of the field', (
      tester,
    ) async {
      await _pumpAutocomplete(tester, suggestions: _fruit);
      await _openPanel(tester);
      await tester.enterText(find.byType(TextField), 'I like App');
      await _settle(tester);

      await tester.tap(find.text('Apple').last);
      await _settle(tester);

      final controller = _controllerOf(tester);
      expect(controller.text, 'I like Apple');
      // The caret sits just past what was inserted, not wherever a bare
      // `.text =` assignment would have dropped it.
      expect(controller.selection.baseOffset, 'I like Apple'.length);
    });

    testWidgets('replaceAll still matches on the whole field', (tester) async {
      // The contrast that proves the two modes are no longer aliases:
      // given the same input, `replaceAll` offers nothing.
      await _pumpAutocomplete(
        tester,
        suggestions: _fruit,
        mode: CoreAutocompleteMode.replaceAll,
      );
      await _openPanel(tester);
      await tester.enterText(find.byType(TextField), 'I like App');
      await _settle(tester);

      expect(find.text('Apple'), findsNothing);
    });

    testWidgets('replaceAll swaps the whole field on selection', (
      tester,
    ) async {
      await _pumpAutocomplete(
        tester,
        suggestions: _fruit,
        mode: CoreAutocompleteMode.replaceAll,
      );
      await _openPanel(tester);
      await tester.enterText(find.byType(TextField), 'App');
      await _settle(tester);

      await tester.tap(find.text('Apple').last);
      await _settle(tester);

      expect(_controllerOf(tester).text, 'Apple');
    });

    testWidgets('append leaves the existing text in front', (tester) async {
      await _pumpAutocomplete(
        tester,
        suggestions: _fruit,
        mode: CoreAutocompleteMode.append,
      );
      await _openPanel(tester);
      await tester.enterText(find.byType(TextField), 'App');
      await _settle(tester);

      await tester.tap(find.text('Apple').last);
      await _settle(tester);

      expect(_controllerOf(tester).text, 'AppApple');
    });
  });

  group('Autocomplete keyboard navigation', () {
    // There was none: the list could only be reached with a pointer, which
    // on Web made the suggestions unreachable outright.

    testWidgets('ArrowDown highlights the first row and Enter accepts it', (
      tester,
    ) async {
      await _pumpAutocomplete(tester, suggestions: _fruit);
      await _openPanel(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await _settle(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await _settle(tester);

      expect(_controllerOf(tester).text, 'Apple');
    });

    testWidgets('ArrowUp from nothing highlights the last row', (
      tester,
    ) async {
      await _pumpAutocomplete(tester, suggestions: _fruit);
      await _openPanel(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await _settle(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await _settle(tester);

      expect(_controllerOf(tester).text, 'Apricot');
    });

    testWidgets('the highlight wraps at the end of the list', (tester) async {
      await _pumpAutocomplete(tester, suggestions: _fruit);
      await _openPanel(tester);

      // Two rows, three steps down: 0 -> 1 -> back to 0.
      for (var i = 0; i < 3; i += 1) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await _settle(tester);
      }
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await _settle(tester);

      expect(_controllerOf(tester).text, 'Apple');
    });

    testWidgets('Escape closes the panel', (tester) async {
      // Flutter-only: this popover is non-modal, so the shared dismiss
      // path never sees the key. The Web twin already closes on Escape.
      await _pumpAutocomplete(tester, suggestions: _fruit);
      await _openPanel(tester);
      expect(find.text('Apricot'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await _settle(tester);

      expect(find.text('Apricot'), findsNothing);
    });

    testWidgets('the highlight resets when the list refilters', (
      tester,
    ) async {
      // Index 1 of the old list is a different suggestion in the new one,
      // so a surviving highlight would accept something never chosen.
      await _pumpAutocomplete(tester, suggestions: _fruit);
      await _openPanel(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await _settle(tester);

      await tester.enterText(find.byType(TextField), 'Ap');
      await _settle(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await _settle(tester);

      // Enter with nothing highlighted leaves the typed text alone.
      expect(_controllerOf(tester).text, 'Ap');
    });

    testWidgets('the highlighted row is exposed as selected to semantics', (
      tester,
    ) async {
      // Web says this with `aria-selected`; the Flutter mechanism is
      // `Semantics(selected:)`, and the a11y guard wants both sides.
      final handle = tester.ensureSemantics();
      await _pumpAutocomplete(tester, suggestions: _fruit);
      await _openPanel(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await _settle(tester);

      expect(
        find.byWidgetPredicate(
          (w) => w is Semantics && (w.properties.selected ?? false),
        ),
        findsOneWidget,
      );
      handle.dispose();
    });
  });
}

const _fruit = ['Apple', 'Apricot'];

/// Pumps a bare [Autocomplete] at a stable position so that re-pumping
/// with different props exercises `didUpdateWidget` on the same State.
Future<void> _pumpAutocomplete(
  WidgetTester tester, {
  required List<String> suggestions,
  bool enabled = true,
  CoreAutocompleteMode mode = CoreAutocompleteMode.defaultMode,
}) async {
  await tester.pumpWidget(
    _buildApp(
      material.Center(
        child: material.SizedBox(
          width: 300,
          child: Autocomplete(
            key: const Key('ac'),
            suggestions: suggestions,
            enabled: enabled,
            mode: mode,
          ),
        ),
      ),
    ),
  );
}

/// The controller backing the field, for reading text and caret back out.
TextEditingController _controllerOf(WidgetTester tester) => tester
    .widget<material.EditableText>(
      find.byType(material.EditableText),
    )
    .controller;

/// Advances past the popover transition.
///
/// `pumpAndSettle` cannot be used once the field holds focus — the caret
/// blink is a perpetual animation, so settling never terminates.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

/// Focuses the field, which is what drives the panel open.
Future<void> _openPanel(WidgetTester tester) async {
  await tester.tap(find.byType(TextField));
  await _settle(tester);
}

/// A controlled parent: it rebuilds the [Autocomplete] with a fresh
/// `value` from within `onChanged`, exactly as a form-bound caller does.
class _ControlledHost extends material.StatefulWidget {
  const _ControlledHost();

  @override
  material.State<_ControlledHost> createState() => _ControlledHostState();
}

class _ControlledHostState extends material.State<_ControlledHost> {
  String _value = '';

  @override
  Widget build(BuildContext context) {
    return material.Center(
      child: material.SizedBox(
        width: 300,
        child: Autocomplete(
          onChanged: (next) => setState(() => _value = next),
          suggestions: const ['Apple', 'Apple pie'],
          value: _value,
        ),
      ),
    );
  }
}
