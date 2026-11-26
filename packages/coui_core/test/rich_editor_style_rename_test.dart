// `quoteGap` was renamed to `quoteSpacing`: the field is a raw length, and a
// `…Gap` name reads as a `CoreGapStyle` slot. The old name stays until the
// deprecation window closes, so a caller that still states it must keep
// getting the same value.
import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

void main() {
  group('CoreRichEditorStyle quoteGap → quoteSpacing', () {
    test('the old constructor argument lands on quoteSpacing', () {
      const style = CoreRichEditorStyle(quoteGap: 12);
      expect(style.quoteSpacing, 12);
      expect(style.quoteGap, 12);
    });

    test('the new argument wins when both are stated', () {
      const style = CoreRichEditorStyle(quoteSpacing: 8, quoteGap: 12);
      expect(style.quoteSpacing, 8);
    });

    test('merge and equality follow quoteSpacing', () {
      const base = CoreRichEditorStyle(quoteSpacing: 8);
      const over = CoreRichEditorStyle(quoteGap: 12);
      expect(base.merge(over).quoteSpacing, 12);
      expect(over, const CoreRichEditorStyle(quoteSpacing: 12));
    });

    test('the old default name is the same value', () {
      expect(
        CoreRichEditorStyle.defaultQuoteGap,
        CoreRichEditorStyle.defaultQuoteSpacing,
      );
    });
  });
}
