import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';
import '../parity/parity_fonts.dart';

void main() {
  setUpAll(loadParityFonts);
  for (final dark in [false, true]) {
    for (final (width, enabled, selected) in [
      (600.0, true, false),
      (240.0, true, false),
      (480.0, false, false),
      (360.0, true, true),
    ]) {
      testWidgets('drop border follows width $width, dark=$dark', (
        tester,
      ) async {
        await pumpTestApp(
          tester,
          SizedBox(
            width: width,
            child: FileInput(
              enabled: enabled,
              selectedFiles: selected ? const ['report.pdf'] : null,
            ),
          ),
          theme: ThemeData.fromCore(
            dark ? CoreThemePresets.dark : CoreThemePresets.light,
          ),
        );
        await tester.pumpAndSettle();
        final border = find
            .descendant(
              of: find.byType(FileInput),
              matching: find.byWidgetPredicate(
                (widget) => widget is CustomPaint && widget.painter != null,
              ),
            )
            .first;
        expect(tester.getSize(border).width, width);
        expect(tester.getRect(border), tester.getRect(find.byType(FileInput)));
      });
    }
  }
}
