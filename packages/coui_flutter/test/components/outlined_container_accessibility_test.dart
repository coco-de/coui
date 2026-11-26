import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

void main() {
  for (final style in CoreOutlinedContainerBorderStyle.values) {
    for (final preserve in [false, true]) {
      for (final direction in [TextDirection.ltr, TextDirection.rtl]) {
        for (final contrast in [false, true]) {
          testWidgets(
            '${style.name} preserve=$preserve $direction contrast=$contrast',
            (tester) async {
              final semantics = tester.ensureSemantics();
              final first = FocusNode();
              final second = FocusNode();
              var activations = 0;
              addTearDown(first.dispose);
              addTearDown(second.dispose);
              await tester.pumpWidget(
                material.MaterialApp(
                  home: buildTestApp(
                    MediaQuery(
                      data: MediaQueryData(
                        highContrast: contrast,
                        textScaler: const TextScaler.linear(2),
                      ),
                      child: OutlinedContainer(
                        containerStyle: CoreOutlinedContainerStyle(
                          borderStyle: style,
                          borderColor: CoreColor.transparent,
                          borderWidth: 2,
                          preserveTransparentBorder: preserve,
                        ),
                        child: material.Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            material.TextButton(
                              focusNode: first,
                              onPressed: () {},
                              child: const material.Text('First action'),
                            ),
                            material.TextButton(
                              focusNode: second,
                              onPressed: () => activations++,
                              child: const material.Text('Second action'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    textDirection: direction,
                    highContrast: contrast,
                  ),
                ),
              );
              await tester.pumpAndSettle();
              expect(find.bySemanticsLabel('First action'), findsOneWidget);
              expect(find.bySemanticsLabel('Second action'), findsOneWidget);
              first.requestFocus();
              await tester.pump();
              await tester.sendKeyEvent(LogicalKeyboardKey.tab);
              await tester.pump();
              expect(second.hasFocus, isTrue);
              await tester.sendKeyEvent(LogicalKeyboardKey.enter);
              await tester.pumpAndSettle();
              expect(activations, 1);
              expect(tester.takeException(), isNull);
              semantics.dispose();
            },
          );
        }
      }
    }
  }
}
