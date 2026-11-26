import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final direction in TextDirection.values) {
    for (final allowCellEditing in [false, true]) {
      testWidgets(
        'OTP error alone is live in $direction, editing=$allowCellEditing',
        (tester) async {
          final semantics = tester.ensureSemantics();
          try {
            Future<void> pump(String? error) async {
              await tester.pumpWidget(
                CoUIApp(
                  theme: ThemeData.fromCore(CoreThemePresets.light),
                  home: Directionality(
                    textDirection: direction,
                    child: Center(
                      child: InputOtp(
                        initialValue: '123456'.codeUnits,
                        errorText: error,
                        allowCellEditing: allowCellEditing,
                      ).copyWith(separatorInterval: 0),
                    ),
                  ),
                ),
              );
              await tester.pumpAndSettle();
            }

            List<SemanticsData> nodes() {
              final result = <SemanticsData>[];
              bool visit(SemanticsNode node) {
                result.add(node.getSemanticsData());
                node.visitChildren(visit);
                return true;
              }

              var root = tester.getSemantics(find.byType(InputOtp));
              while (root.parent != null) {
                root = root.parent!;
              }
              visit(root);
              return result;
            }

            await pump(null);
            expect(
              nodes().where((n) => n.flagsCollection.isLiveRegion),
              isEmpty,
            );
            await pump('Invalid code');
            final live = nodes().where((n) => n.flagsCollection.isLiveRegion);
            expect(live, hasLength(1));
            expect(live.single.label, 'Invalid code');
            expect(live.single.value, isEmpty);
            expect(nodes().any((n) => n.value == '123456'), isTrue);
            expect(find.byType(EditableText), findsOneWidget);
            final label = CoUILocalizations.of(
              tester.element(find.byType(InputOtp)),
            ).inputOtpLabel;
            expect(
              nodes().any(
                (n) =>
                    n.label.contains(label) && !n.flagsCollection.isLiveRegion,
              ),
              isTrue,
            );
            await pump('Try again');
            expect(
              nodes().singleWhere((n) => n.flagsCollection.isLiveRegion).label,
              'Try again',
            );
            await pump(null);
            expect(
              nodes().where((n) => n.flagsCollection.isLiveRegion),
              isEmpty,
            );
            expect(nodes().any((n) => n.value == '123456'), isTrue);
          } finally {
            semantics.dispose();
          }
        },
      );
    }
  }
}
