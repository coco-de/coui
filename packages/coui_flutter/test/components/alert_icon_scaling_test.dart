import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

Widget _buildApp(Widget child, {required double scaling}) =>
    material.MaterialApp(
      home: Theme(
        data: ThemeData(scaling: scaling),
        child: material.Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(width: 400, child: child),
          ),
        ),
      ),
    );

/// The box the first `Icon` under the alert draws in.
Size _iconBox(WidgetTester tester) => tester.getSize(
  find.descendant(of: find.byType(Alert), matching: find.byType(Icon)).first,
);

void main() {
  // `Icon` multiplies its own box by the theme scaling, so the alert hands it
  // the token size. A size multiplied here as well was multiplied twice: on a
  // 1.25× screen the stacked alert's 18 glyph was drawn 28.125 and the inline
  // strip's 16 one 25.
  group('Alert icon follows the theme scaling once', () {
    final stacked = CoreAlertStyle.defaultIconStyle.size!;
    final inline = CoreAlertStyle
        .defaultsByLayout[CoreAlertLayout.inline]!
        .iconStyle!
        .size!;

    for (final scaling in [1.0, 1.25, 1.5]) {
      testWidgets('stacked variant icon is $stacked × $scaling', (
        tester,
      ) async {
        await tester.pumpWidget(
          _buildApp(const Alert.info(title: 'Heads up'), scaling: scaling),
        );
        expect(_iconBox(tester), Size.square(stacked * scaling));
      });

      testWidgets('inline variant icon is $inline × $scaling', (tester) async {
        await tester.pumpWidget(
          _buildApp(
            const Alert.info(
              title: 'Heads up',
              layout: CoreAlertLayout.inline,
            ),
            scaling: scaling,
          ),
        );
        expect(_iconBox(tester), Size.square(inline * scaling));
      });
    }

    testWidgets('a CoUI icon given as leading draws at the same size', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          const Alert.info(
            title: 'Heads up',
            leading: Icon(LucideIcons.bell),
          ),
          scaling: 1.25,
        ),
      );
      expect(_iconBox(tester), Size.square(stacked * 1.25));
    });

    testWidgets('an icon size stated on the alert is a token size too', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          const Alert.info(
            title: 'Heads up',
            alertStyle: CoreAlertStyle(iconStyle: CoreIconStyle(size: 20)),
          ),
          scaling: 1.25,
        ),
      );
      expect(_iconBox(tester), const Size.square(25));
    });
  });
}
