// A list in the editor is laid out as the Web twin lays out its `<ul>`: the
// text sits in by the Core list indent for each level of nesting, and the
// space between blocks is below the list, not between its items.
//
// Each item of a list is a block of its own in the document the editor edits,
// so the block spacing used to come between every pair of items (27 px apart
// against the Web's 21), and the text was set in by a share of the font size
// (about 34 px against the Web's 24) — `super_editor`'s own list indent.

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

Widget _app(String markdown, {CoreRichEditorStyle? style}) =>
    material.MaterialApp(
      home: Theme(
        data: const ThemeData(),
        child: material.Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 480,
              child: RichEditor(
                initialValue: markdown,
                onChanged: (_) {},
                showToolbar: false,
                richEditorStyle: style,
              ),
            ),
          ),
        ),
      ),
    );

Finder _text(String text) => find.textContaining(text, findRichText: true);

double _left(WidgetTester tester, String text) =>
    tester.getTopLeft(_text(text)).dx;

double _top(WidgetTester tester, String text) =>
    tester.getTopLeft(_text(text)).dy;

double _bottom(WidgetTester tester, String text) =>
    tester.getBottomLeft(_text(text)).dy;

void main() {
  group('RichEditor list layout', () {
    testWidgets('the text of a list item is set in by the Core list indent', (
      tester,
    ) async {
      await tester.pumpWidget(_app('paragraph\n\n- one\n- two'));
      await tester.pump();

      expect(
        _left(tester, 'one') - _left(tester, 'paragraph'),
        CoreRichEditorStyle.defaultListIndent,
      );
    });

    testWidgets('a listIndent in the style sets every level in by that much', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          'paragraph\n\n- one\n  - nested',
          style: const CoreRichEditorStyle(listIndent: CoreSpace.space40),
        ),
      );
      await tester.pump();

      expect(
        _left(tester, 'one') - _left(tester, 'paragraph'),
        CoreSpace.space40,
      );
      expect(
        _left(tester, 'nested') - _left(tester, 'one'),
        CoreSpace.space40,
      );
    });

    testWidgets('each level of nesting is set in by one more indent', (
      tester,
    ) async {
      await tester.pumpWidget(_app('- one\n  - nested'));
      await tester.pump();

      expect(
        _left(tester, 'nested') - _left(tester, 'one'),
        CoreRichEditorStyle.defaultListIndent,
      );
    });

    testWidgets('the items of a list touch, and the space is below the list', (
      tester,
    ) async {
      await tester.pumpWidget(_app('- one\n- two\n\nafter'));
      await tester.pump();

      // No block spacing between two items of one list…
      expect(_top(tester, 'two'), _bottom(tester, 'one'));
      // …but the block spacing between the list and what follows it.
      expect(
        _top(tester, 'after') - _bottom(tester, 'two'),
        CoreRichEditorStyle.defaultBlockSpacing,
      );
    });

    testWidgets('a numbered list after a bulleted one is a list of its own', (
      tester,
    ) async {
      await tester.pumpWidget(_app('- bullet\n\n1. first'));
      await tester.pump();

      expect(
        _top(tester, 'first') - _bottom(tester, 'bullet'),
        CoreRichEditorStyle.defaultBlockSpacing,
      );
    });
  });
}
