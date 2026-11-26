import 'package:coui_web/coui_web.dart';
import 'package:coui_web/src/components/layout/join/join_style.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

void main() {
  for (final vertical in [false, true]) {
    final property = vertical ? 'margin-top' : 'margin-inline-start';

    testComponents('items after the first overlap by one border '
        '(vertical: $vertical)', (tester) async {
      late ResolvedJoin resolved;
      pumpWithTheme(
        tester,
        Builder(
          builder: (context) {
            resolved = resolveJoin(context, vertical: vertical, count: 3);
            return const Component.text('');
          },
        ),
      );

      final raws = [
        for (final item in resolved.items) item.inlineStyles!.properties,
      ];
      expect(raws[0].containsKey(property), isFalse);
      final pull =
          'calc(${strokeWidthCss(CoreJoinStyle.defaultItemOverlap)} * -1)';
      expect(raws[1][property], pull);
      expect(raws[2][property], pull);
    });
  }

  testComponents('itemOverlap 0 leaves the items edge to edge', (
    tester,
  ) async {
    late ResolvedJoin resolved;
    pumpWithTheme(
      tester,
      Builder(
        builder: (context) {
          resolved = resolveJoin(
            context,
            vertical: false,
            count: 3,
            joinStyle: const CoreJoinStyle(itemOverlap: 0),
          );
          return const Component.text('');
        },
      ),
    );

    for (final item in resolved.items) {
      expect(
        item.inlineStyles!.properties.containsKey('margin-inline-start'),
        isFalse,
      );
    }
  });
}
