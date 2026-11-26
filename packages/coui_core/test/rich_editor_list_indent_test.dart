// `listIndent` is the one document length of the rich editor's list that a
// style can state: both platforms read it as `merged.listIndent ?? default`,
// so the field has to survive `merge`, take part in equality and hashing, and
// leave the Core default alone when nothing is stated.

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

void main() {
  group('CoreRichEditorStyle.listIndent', () {
    test(
      'is unstated by default, and the Core default is the marker width',
      () {
        expect(const CoreRichEditorStyle().listIndent, isNull);
        expect(CoreRichEditorStyle.defaultListIndent, CoreSpace.space24);
      },
    );

    test(
      'merge takes the later statement and keeps the earlier one otherwise',
      () {
        const base = CoreRichEditorStyle(listIndent: CoreSpace.space16);

        expect(
          base
              .merge(const CoreRichEditorStyle(listIndent: CoreSpace.space40))
              .listIndent,
          CoreSpace.space40,
        );
        expect(
          base.merge(const CoreRichEditorStyle()).listIndent,
          CoreSpace.space16,
        );
        expect(base.merge(null).listIndent, CoreSpace.space16);
      },
    );

    test('takes part in equality and in the hash', () {
      const a = CoreRichEditorStyle(listIndent: CoreSpace.space16);
      const same = CoreRichEditorStyle(listIndent: CoreSpace.space16);
      const other = CoreRichEditorStyle(listIndent: CoreSpace.space40);

      expect(a, same);
      expect(a.hashCode, same.hashCode);
      expect(a, isNot(other));
      expect(a, isNot(const CoreRichEditorStyle()));
    });
  });
}
