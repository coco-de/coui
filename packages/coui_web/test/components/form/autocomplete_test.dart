import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/components/form/autocomplete/autocomplete.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:coui_web/src/components/form/text_field/text_field.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

/// The wrapper that owns the open/close focus listeners.
///
/// Located by the listener it registers rather than by tag or class, so
/// the finder keeps pointing at the right element if the chrome changes.
final _trigger = find.byComponentPredicate(
  (c) =>
      c is DomComponent &&
      c.tag == 'div' &&
      (c.events?.containsKey('focusin') ?? false),
  description: 'autocomplete trigger wrapper (focusin listener)',
);

/// The floating suggestion panel.
///
/// Asserting on this rather than on a suggestion's text is what makes the
/// open/closed distinction real: an emptied or swapped `suggestions` list
/// changes the rendered rows on its own, so a text-only assertion passes
/// whether or not the panel actually closed.
final _panel = find.byComponentPredicate(
  (c) => c is DomComponent && c.attributes?['role'] == 'listbox',
  description: 'suggestion panel (role=listbox)',
);

/// The option row for [label]. Looked up by `data-value` because a label
/// with a match is split into several text nodes.
Finder _option(String label) => find.byComponentPredicate(
  (c) => c is DomComponent && c.attributes?['data-value'] == label,
  description: 'option "$label"',
);

/// The text the matched `<span>` of [label]'s option carries, or `null`
/// when the option has no emphasised part.
String? _matchedText(String label) {
  final option = _option(label).evaluate().single.component as DomComponent;
  String? found;
  void visit(Element element) {
    final c = element.component;
    if (c is DomComponent &&
        c.tag == 'span' &&
        (c.styles?.properties['font-weight'] ?? '').isNotEmpty) {
      final text = StringBuffer();
      void collect(Element e) {
        final cc = e.component;
        if (cc is Text) text.write(cc.text);
        e.visitChildren(collect);
      }

      element.visitChildren(collect);
      found = text.toString();
      return;
    }
    element.visitChildren(visit);
  }

  _option(label).evaluate().single.visitChildren(visit);
  expect(option.attributes?['role'], 'option');
  return found;
}

/// Drains the deferred reconciliation.
///
/// A prop change schedules `_syncPopover` on a microtask; opening then
/// notifies the popover controller, whose listener re-renders the host on
/// the following frame. One pump only reaches the first of those.
Future<void> _settle(ComponentTester tester) async {
  await tester.pump();
  await tester.pump();
}

/// Additionally waits out the popover's exit animation.
///
/// Closing keeps the panel mounted for a fade-out and unmounts it from a
/// real `Timer`, which pumping the event queue does not advance.
Future<void> _settleClose(ComponentTester tester) async {
  await _settle(tester);
  await Future<void>.delayed(const Duration(milliseconds: 250));
  await _settle(tester);
}

/// Handle to the live host state, assigned when the host mounts.
late _HostState _host;

/// A controlled parent that swaps the [Autocomplete]'s props in place.
///
/// Re-pumping the root instead would silently re-attach the tree and
/// discard the child's `State` — the panel would then appear to close
/// simply because focus was thrown away, which is not the behaviour under
/// test. Driving `setState` here keeps the same `State` alive so
/// `didUpdateComponent` is genuinely exercised.
class _Host extends StatefulComponent {
  const _Host();

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  List<String> _suggestions = const [];
  bool _enabled = true;

  @override
  void initState() {
    super.initState();
    _host = this;
  }

  void update({List<String>? suggestions, bool? enabled}) {
    setState(() {
      if (suggestions != null) _suggestions = suggestions;
      if (enabled != null) _enabled = enabled;
    });
  }

  @override
  Component build(BuildContext context) =>
      Autocomplete(suggestions: _suggestions, enabled: _enabled);
}

/// Mounts an [Autocomplete] that already holds [value] and focuses it.
///
/// Seeding through the prop rather than by typing is deliberate: the
/// component test harness runs on the native VM, where a typed
/// `InputEvent` carrying a `target` cannot be constructed, so the field
/// cannot be typed into. Mounting with the text in place puts the caret at
/// its end — the same position typing would leave it — and `focusin` is an
/// untyped event, so the panel can still be opened.
Future<void> _mountWithValue(
  ComponentTester tester, {
  required String value,
  required List<String> suggestions,
  CoreAutocompleteMode mode = CoreAutocompleteMode.defaultMode,
}) async {
  pumpWithTheme(
    tester,
    Autocomplete(suggestions: suggestions, value: value, mode: mode),
  );
  await _settle(tester);
  tester.dispatchEvent(_trigger, 'focusin');
  await _settle(tester);
}

/// Mounts the host with [suggestions] already in place and focuses the
/// field, leaving the panel open when the list is non-empty.
Future<void> _mountAndFocus(
  ComponentTester tester, {
  required List<String> suggestions,
}) async {
  pumpWithTheme(tester, const _Host());
  await _settle(tester);
  _host.update(suggestions: suggestions);
  await _settle(tester);
  tester.dispatchEvent(_trigger, 'focusin');
  await _settle(tester);
}

void main() {
  group('Autocomplete panel reconciles with props', () {
    // The panel used to react only to focus and input events, so anything
    // the parent changed underneath it (suggestions arriving, the field
    // going disabled) left a stale — or permanently closed — panel behind.

    testComponents('closes when suggestions are emptied underneath it', (
      tester,
    ) async {
      await _mountAndFocus(tester, suggestions: const ['Apple', 'Apricot']);
      expect(_panel, findsOneComponent);

      _host.update(suggestions: const []);
      await _settleClose(tester);

      expect(_panel, findsNothing);
    });

    testComponents('swaps contents when suggestions are replaced', (
      tester,
    ) async {
      await _mountAndFocus(tester, suggestions: const ['Apple', 'Apricot']);
      expect(find.text('Apricot'), findsOneComponent);

      _host.update(suggestions: const ['Banana', 'Cherry']);
      await _settle(tester);

      expect(_panel, findsOneComponent);
      expect(find.text('Apricot'), findsNothing);
      expect(find.text('Banana'), findsOneComponent);
    });

    testComponents('closes when the field goes disabled underneath it', (
      tester,
    ) async {
      // The one case where the rows do not change on their own, so only a
      // genuine close can satisfy it.
      await _mountAndFocus(tester, suggestions: const ['Apple', 'Apricot']);
      expect(_panel, findsOneComponent);

      _host.update(enabled: false);
      await _settleClose(tester);

      expect(_panel, findsNothing);
      expect(find.text('Apricot'), findsNothing);
    });

    testComponents('opens when async suggestions arrive while focused', (
      tester,
    ) async {
      // The sharpest form of the bug: the list is empty while a fetch is
      // in flight, so the panel never opens; the results then land as new
      // props that nothing was watching, leaving it shut forever.
      await _mountAndFocus(tester, suggestions: const []);
      expect(_panel, findsNothing);

      _host.update(suggestions: const ['Apple', 'Apricot']);
      await _settle(tester);

      expect(_panel, findsOneComponent);
      expect(find.text('Apricot'), findsOneComponent);
    });

    testComponents('a blurred field stays closed when suggestions arrive', (
      tester,
    ) async {
      // Reconciling on props must not override the focus rule — results
      // landing for a field the user already left must not pop a panel
      // open under their cursor.
      await _mountAndFocus(tester, suggestions: const []);
      tester.dispatchEvent(_trigger, 'focusout');
      await _settleClose(tester);

      _host.update(suggestions: const ['Apple', 'Apricot']);
      await _settle(tester);

      expect(_panel, findsNothing);
    });
  });

  group('Autocomplete replaceWord completes the word under the caret', () {
    // `replaceWord` is the default mode, and it was an alias of
    // `replaceAll`: it matched the whole field, so nothing was offered the
    // moment the field held more than one word.

    testComponents('offers suggestions for the word under the caret', (
      tester,
    ) async {
      await _mountWithValue(
        tester,
        value: 'I like App',
        suggestions: const ['Apple', 'Apricot'],
      );

      expect(_panel, findsOneComponent);
      expect(_option('Apple'), findsOneComponent);
      // 'Apricot' does not contain 'App', so its absence shows the filter
      // ran against the caret word rather than letting everything through.
      expect(_option('Apricot'), findsNothing);
    });

    testComponents('replaceAll still matches on the whole field', (
      tester,
    ) async {
      // The contrast that proves the two modes are no longer aliases:
      // given the same field, whole-field matching offers nothing, so the
      // panel never opens.
      await _mountWithValue(
        tester,
        value: 'I like App',
        suggestions: const ['Apple', 'Apricot'],
        mode: CoreAutocompleteMode.replaceAll,
      );

      expect(_panel, findsNothing);
    });

    testComponents('the caret capability is wired, not merely declared', (
      tester,
    ) async {
      // Typing cannot be simulated here, so this asserts the one thing
      // that is observable: supplying only `onCaretChanged` is enough to
      // register the field's `input` listener. A callback the field never
      // subscribed for would be a declared-but-dead capability.
      pumpWithTheme(tester, TextField(onCaretChanged: (_) {}));
      await tester.pump();

      final input = find
          .byComponentPredicate(
            (c) => c is DomComponent && c.tag == 'input',
          )
          .evaluate()
          .single
          .component;
      expect((input as DomComponent).events?.keys, contains('input'));
    });
  });

  group('Autocomplete emphasises the matched part of each label', () {
    testComponents('at the start, in the middle and at the end', (
      tester,
    ) async {
      await _mountWithValue(
        tester,
        value: 'ap',
        suggestions: const ['Apple', 'Grape', 'Wrap'],
        mode: CoreAutocompleteMode.replaceAll,
      );

      expect(_matchedText('Apple'), 'Ap');
      expect(_matchedText('Grape'), 'ap');
      expect(_matchedText('Wrap'), 'ap');
    });

    testComponents('an empty query emphasises nothing', (tester) async {
      await _mountWithValue(
        tester,
        value: '',
        suggestions: const ['Apple'],
      );

      expect(_matchedText('Apple'), isNull);
    });
  });

  group('Autocomplete exposes combobox semantics', () {
    // Web's half of the a11y fix. The panel is portaled outside the
    // trigger's subtree, so Tab leaves the field and closes it — the only
    // way a keyboard user reaches the list is for focus to stay on the
    // input while `aria-activedescendant` points into the panel.

    testComponents('the input is a combobox that controls the panel', (
      tester,
    ) async {
      await _mountWithValue(
        tester,
        value: '',
        suggestions: const ['Apple', 'Apricot'],
      );

      final input = _inputAttributes();
      expect(input['role'], equals('combobox'));
      expect(input['aria-autocomplete'], equals('list'));
      expect(input['aria-expanded'], equals('true'));

      // `aria-controls` must name an element that exists, or it points at
      // nothing and the relationship is not announced.
      final panelId = input['aria-controls'];
      expect(panelId, isNotNull);
      expect(
        find.byComponentPredicate(
          (c) => c is DomComponent && c.id == panelId,
        ),
        findsOneComponent,
      );
    });

    testComponents('aria-expanded reports the closed panel too', (
      tester,
    ) async {
      // A combobox that always claims to be expanded tells the reader
      // nothing.
      pumpWithTheme(
        tester,
        Autocomplete(suggestions: const ['Apple'], value: ''),
      );
      await _settle(tester);

      expect(_inputAttributes()['aria-expanded'], equals('false'));
    });

    testComponents('each option has a stable id and a selected state', (
      tester,
    ) async {
      await _mountWithValue(
        tester,
        value: '',
        suggestions: const ['Apple', 'Apricot'],
      );

      final options = find
          .byComponentPredicate(
            (c) => c is DomComponent && c.attributes?['role'] == 'option',
          )
          .evaluate()
          .map((e) => e.component as DomComponent)
          .toList();

      expect(options.length, equals(2));
      // Ids must be distinct — `aria-activedescendant` names exactly one.
      expect(options.map((o) => o.id).toSet().length, equals(2));
      for (final option in options) {
        expect(option.id, isNotNull);
        expect(option.attributes?['aria-selected'], equals('false'));
      }
    });

    testComponents('an option row reads the ItemPicker row', (tester) async {
      await _mountWithValue(
        tester,
        value: '',
        suggestions: const ['Apple', 'Apricot'],
      );

      final option =
          find
                  .byComponentPredicate(
                    (c) =>
                        c is DomComponent && c.attributes?['role'] == 'option',
                  )
                  .evaluate()
                  .first
                  .component
              as DomComponent;
      final raw = option.styles?.properties ?? const <String, String>{};

      // Padding 8 on every side and the control radius — the inset and
      // corner an ItemPicker row takes — and the 14px body role.
      expect(
        raw['padding'],
        equals(const CoreEdgeInsets.all(CoreSpace.space8).toValue()),
      );
      expect(
        raw['border-radius'],
        equals(
          const CoreBorderRadius.all(CoreRadiusRole.control).toValue(),
        ),
      );
      expect(option.classes, contains('body-medium'));
      expect(option.classes, isNot(contains('body-small')));
    });
  });
}

/// Attributes of the single `<input>` the autocomplete renders.
Map<String, String> _inputAttributes() {
  final input =
      find
              .byComponentPredicate(
                (c) => c is DomComponent && c.tag == 'input',
              )
              .evaluate()
              .single
              .component
          as DomComponent;
  return input.attributes ?? const {};
}
