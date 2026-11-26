// The empty editor's placeholder wraps over as many lines as it takes, as a
// `TextArea`'s does (the editor's box is the `TextArea`'s) and as the design
// draws it.
//
// `super_editor` draws the hint with an ellipsis and no line limit, and a
// paragraph that is to be ellipsized with no line limit ends at the first
// line that overflows: a placeholder wider than the box ended in "…" on its
// first line, and the rest of it was never shown.

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_test/flutter_test.dart';

/// Longer than a line of a narrow editor — a feedback form's placeholder,
/// two lines in its design.
const _long =
    '응급 환자나 재진 환자를 먼저 보내야 할 때 순서를 바꿀 방법이 없어요. '
    '목록에서 끌어서 옮길 수 있으면 좋겠어요.';

Widget _app(String placeholder, {required double width}) =>
    material.MaterialApp(
      home: Theme(
        data: const ThemeData(),
        child: material.Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: width,
              child: RichEditor(placeholder: placeholder),
            ),
          ),
        ),
      ),
    );

RenderParagraph _hint(WidgetTester tester, String placeholder) =>
    tester.renderObject<RenderParagraph>(
      find.text(placeholder, findRichText: true),
    );

/// The lines [hint] lays [text] out on: one per distinct top among the boxes
/// of its characters (a character an ellipsis took the place of has none).
int _lines(RenderParagraph hint, String text) => {
  for (final box in hint.getBoxesForSelection(
    TextSelection(baseOffset: 0, extentOffset: text.length),
  ))
    box.top.round(),
}.length;

/// Whether the last character of [text] is laid out in [hint].
bool _endsLaidOut(RenderParagraph hint, String text) => hint
    .getBoxesForSelection(
      TextSelection(baseOffset: text.length - 1, extentOffset: text.length),
    )
    .isNotEmpty;

void main() {
  group('RichEditor placeholder', () {
    testWidgets('a placeholder wider than the box wraps onto more lines', (
      tester,
    ) async {
      await tester.pumpWidget(_app(_long, width: 240));
      await tester.pump();

      final hint = _hint(tester, _long);
      expect(_lines(hint, _long), greaterThanOrEqualTo(2));
      expect(hint.didExceedMaxLines, isFalse);
      expect(_endsLaidOut(hint, _long), isTrue, reason: 'no ellipsis');
    });

    testWidgets('a placeholder that fits stays on one line', (tester) async {
      const short = '댓글을 입력해 주세요';
      await tester.pumpWidget(_app(short, width: 480));
      await tester.pump();

      final hint = _hint(tester, short);
      expect(_lines(hint, short), 1);
      expect(_endsLaidOut(hint, short), isTrue);
    });
  });
}
