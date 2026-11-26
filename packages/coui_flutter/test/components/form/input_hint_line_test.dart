import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';
import '../../parity/parity_fonts.dart';

void main() {
  setUpAll(loadParityFonts);

  Future<RenderParagraph> hint(
    WidgetTester tester, {
    int maxLines = 1,
    bool custom = false,
  }) async {
    await pumpTestApp(
      tester,
      SizedBox(
        width: 24,
        child: TextField(
          hintText: custom ? null : 'MM',
          placeholder: custom ? const Text('MM') : null,
          maxLines: maxLines,
          size: .lg,
          variant: .plain,
          textFieldStyle: CoreObjectInputStyle.defaultFieldInputStyle,
        ),
      ),
    );
    final finder = find.byWidgetPredicate(
      (widget) => widget is RichText && widget.text.toPlainText() == 'MM',
    );
    return tester.renderObject<RenderParagraph>(finder);
  }

  testWidgets('a one-line hint clips a full run instead of wrapping it away', (
    tester,
  ) async {
    final paragraph = await hint(tester);
    expect(paragraph.size.width, 24);
    expect(paragraph.didExceedMaxLines, isFalse);
  });

  testWidgets('a multiline hint can still wrap', (tester) async {
    final paragraph = await hint(tester, maxLines: 2);
    expect(paragraph.size.height, greaterThan(25));
  });

  testWidgets('a caller placeholder widget retains its wrapping behavior', (
    tester,
  ) async {
    final paragraph = await hint(tester, custom: true);
    expect(paragraph.didExceedMaxLines, isTrue);
  });
}
