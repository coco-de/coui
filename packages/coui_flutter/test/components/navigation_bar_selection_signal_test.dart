import 'package:coui_core/coui_core.dart';
import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Future<ResolvedNavigationBar> _resolved(WidgetTester tester) async {
  late ResolvedNavigationBar seen;

  await tester.pumpWidget(
    CoUIApp(
      theme: ThemeData.fromCore(CoreThemePresets.light),
      home: Builder(
        builder: (context) {
          seen = resolveNavigationBar(
            context,
            mode: CoreNavigationBarMode.bar,
            variant: CoreNavigationBarVariant.defaultVariant,
          );

          return const SizedBox.shrink();
        },
      ),
    ),
  );

  return seen;
}

void main() {
  group('selection is legible without colour', () {
    testWidgets('the selected label carries a different weight', (
      tester,
    ) async {
      // Selection was signalled twice and both signals were colour — the
      // pill behind the item and the label's own colour. A mode that forces
      // the palette lands both on the same value at once and the selected
      // item stops looking selected. Weight is not forced.
      //
      // Assistive technology was never the gap: the item already reports a
      // selected semantics flag. This is for the people looking at it.
      final resolved = await _resolved(tester);

      expect(resolved.selectedLabelTextStyle.fontWeight, isNotNull);
      expect(
        resolved.selectedLabelTextStyle.fontWeight,
        isNot(resolved.labelTextStyle.fontWeight),
      );
    });

    testWidgets('the colour signals are still there', (tester) async {
      // The weight is an addition, not a replacement — removing either
      // colour would be trading one single-signal state for another.
      final resolved = await _resolved(tester);

      expect(
        resolved.selectedLabelTextStyle.color,
        isNot(resolved.labelTextStyle.color),
      );
      expect(
        resolved.selectedBackgroundColor,
        isNot(resolved.backgroundColor),
      );
    });
  });
}
