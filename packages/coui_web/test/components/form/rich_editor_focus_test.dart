// Pins which parts of the Web `RichEditor` keep focus in the writing surface
// when the mouse is pressed on them. The toolbar must — the strip at the top
// of the box, the slot at its far end included: a press that moved focus
// would blur the surface, the blur re-renders the editor before the mouse
// comes up, and the browser drops the click on the icon that was replaced
// under the pointer. The surface itself must not: pressing in the text is how
// the caret gets placed. The focus outline is one ring around both.

import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

Iterable<DomComponent> _doms() => find
    .byType(DomComponent)
    .evaluate()
    .map((element) => element.component as DomComponent);

DomComponent _withRole(String role) =>
    _doms().singleWhere((dom) => dom.attributes?['role'] == role);

Finder _surface() => find.byComponentPredicate(
  (component) =>
      component is DomComponent && component.attributes?['role'] == 'textbox',
);

Finder _toolbar() => find.byComponentPredicate(
  (component) =>
      component is DomComponent && component.attributes?['role'] == 'toolbar',
);

bool _handlesMouseDown(DomComponent dom) =>
    dom.events?.containsKey('mousedown') ?? false;

void main() {
  group('RichEditor — pressing it keeps the surface focused', () {
    testComponents('the toolbar does not take focus', (tester) async {
      pumpWithTheme(tester, const RichEditor());
      expect(_handlesMouseDown(_withRole('toolbar')), isTrue);
    });

    testComponents('the toolbar with an image button does not either', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        RichEditor(
          onImageUpload: (file) async => 'https://example.com/a.png',
          onImageDelete: (url) async {},
        ),
      );
      expect(_handlesMouseDown(_withRole('toolbar')), isTrue);
    });

    testComponents(
      'the writing surface does not, so a press places the caret',
      (
        tester,
      ) async {
        pumpWithTheme(tester, const RichEditor());
        expect(_handlesMouseDown(_withRole('textbox')), isFalse);
      },
    );

    testComponents('the slot at the toolbar’s far end is part of it, so a '
        'press there keeps the focus too', (tester) async {
      pumpWithTheme(
        tester,
        const RichEditor(toolbarTrailing: Text('Show changes')),
      );
      // One toolbar, with the slot inside it — not a second element that
      // would let a press on the slot blur the surface.
      expect(_handlesMouseDown(_withRole('toolbar')), isTrue);
      expect(
        find.descendant(of: _toolbar(), matching: find.text('Show changes')),
        findsOneComponent,
      );
    });
  });
  group('RichEditor — one ring around the toolbar and the surface', () {
    testComponents('the focus outline wraps both', (tester) async {
      pumpWithTheme(tester, const RichEditor());
      final ring = find.byType(FocusOutline);
      expect(ring, findsOneComponent);
      expect(
        find.descendant(of: ring, matching: _toolbar()),
        findsOneComponent,
      );
      expect(
        find.descendant(of: ring, matching: _surface()),
        findsOneComponent,
      );
    });

    testComponents('without a toolbar it wraps the surface alone', (
      tester,
    ) async {
      pumpWithTheme(tester, const RichEditor(showToolbar: false));
      final ring = find.byType(FocusOutline);
      expect(ring, findsOneComponent);
      expect(
        find.descendant(of: ring, matching: _surface()),
        findsOneComponent,
      );
      expect(_toolbar(), findsNothing);
    });
  });
  group('RichEditor — focus changes that change nothing do not re-render', () {
    // A re-render replaces the icons under the pointer, and a click that
    // began with the blur that caused it is dropped by the browser. The
    // surface's event map is built afresh on every build, so an unchanged
    // map is an editor that was not rebuilt.
    testComponents(
      'a blur, with no ring showing, leaves the editor as it was',
      (
        tester,
      ) async {
        pumpWithTheme(tester, const RichEditor());
        final before = _withRole('textbox').events;
        tester.dispatchEvent(_surface(), 'blur');
        await tester.pump();
        expect(identical(_withRole('textbox').events, before), isTrue);
      },
    );
  });
}
