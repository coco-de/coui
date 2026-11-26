// Place at:
//   packages/coui_flutter/test/text_field_focus_semantics_test.dart
//
// Test root, beside `a11y_semantics_test.dart`. `test/components/form/`
// is thirty-one files all named `{component}_test.dart` with no
// exception, and this covers two components on one axis rather than one
// component on every axis — the root is where the repository already
// keeps that shape (`a11y_semantics_test.dart`, and `semantic_role_test`
// / `empty_state_tone_test` a level down).
//
// Why every case here fails before the patch, and what each one pins:
//
//   `EditableText` builds its own `Focus` with semantics excluded, so the
//   node that carries `isTextField` states no enabled state and offers no
//   focus action. Both clauses are therefore absent from an unpatched
//   build and each case fails on the clause the patch supplies — measured
//   against unpatched `main`: the two positive cases report
//   `missing actions: [focus]`, the disabled case reports
//   `missing flags: hasEnabledState`.
//
//   `isEnabled` is the load-bearing one. A web engine renders any text
//   field node that does not state an enabled state as a disabled input,
//   and a disabled input never receives the focus event that activates the
//   semantics editing strategy the engine latches onto once semantics come
//   up — so the field draws, announces itself, and takes no typing.
//   `hasFocusAction` is the handler that event calls.
import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

// Widget test constants.
const _kText = 'abc';
const _kClearLabel = 'Clear';
const _kAreaHeight = 120.0;

Widget _app(Widget child) => material.MaterialApp(
  home: Theme(
    data: const ThemeData(),
    child: material.Scaffold(body: child),
  ),
);

/// The node an assistive technology sees as the text input.
///
/// Read out of the semantics tree directly rather than by walking up from
/// the `EditableText` element. That walk starts at the first render object
/// the element owns and climbs through *ancestors*, so it sails straight
/// past the node `RenderEditable` itself owns and lands on an unrelated
/// route node whose every flag is false — a test written that way reports
/// a pass on a field that announces nothing at all.
SemanticsFinder get _textInput =>
    find.semantics.byFlag(SemanticsFlag.isTextField);

/// What the engine needs before it will let anyone type.
///
/// `isButton: false` beside an empty label is what pins the wiring to the
/// input itself. An annotation lifted above the row absorbs a sibling
/// affordance's flag and label into this same node while still reporting
/// focus and enabled, so without those two clauses the assertion also
/// passes on the one placement that quietly breaks the affordance. Both
/// clauses catch that placement independently, which is why the case
/// below names the clear button rather than leaving it unlabelled — an
/// unnamed affordance contributes no label to absorb, and the label
/// clause would sit there proving nothing.
Matcher _acceptsFocus() => isSemantics(
  label: '',
  isButton: false,
  isTextField: true,
  hasEnabledState: true,
  isEnabled: true,
  hasFocusAction: true,
);

void main() {
  group('a text input tells the engine it can accept focus', () {
    testWidgets('TextField, with an affordance beside it', (tester) async {
      // Text and a named clear affordance together on purpose. The clear
      // button renders only while the field has text, and it is the
      // sibling whose flag and label leak into the input's node when the
      // annotation sits above the row — drop either and the correct
      // placement and the hoisted one become indistinguishable here.
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _app(
          TextField(
            controller: TextEditingController(text: _kText),
            features: const [
              CoreInputFeature.clear(semanticLabel: _kClearLabel),
            ],
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(_textInput, findsOne);
      expect(_textInput, _acceptsFocus());
      handle.dispose();
    });

    testWidgets('TextArea', (tester) async {
      // No affordance here: this component's outer gesture detector
      // aggregates the whole widget into one node, so anything in its
      // `suffix` merges in wherever the annotation goes. Asserting an
      // empty label beside a suffix would demand something no placement
      // can deliver, which is why the placement axis is pinned by the case
      // above instead.
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _app(
          SizedBox(
            height: _kAreaHeight,
            child: TextArea(controller: TextEditingController(text: _kText)),
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(_textInput, findsOne);
      expect(_textInput, _acceptsFocus());
      handle.dispose();
    });

    testWidgets('and a disabled field states that rather than staying silent', (
      tester,
    ) async {
      // A node that states no enabled state at all is the failure being
      // guarded, and the engine reads that absence as disabled — the right
      // announcement here and the wrong one for every other field. Stating
      // it is what makes the two cases distinguishable.
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _app(
          TextField(
            enabled: false,
            controller: TextEditingController(text: _kText),
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(_textInput, isSemantics(hasEnabledState: true, isEnabled: false));
      handle.dispose();
    });
  });
}
