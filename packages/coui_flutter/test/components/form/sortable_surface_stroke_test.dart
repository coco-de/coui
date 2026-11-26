// A material that draws its own edge (liquid glass) is the row's boundary,
// so the row's own border steps aside — the same suppression every surface
// that resolves its own stroke goes through (`resolveSurfaceStroke`).
import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

Future<ResolvedSortable> _resolveUnder(
  WidgetTester tester,
  CoreSurfaceStyleId style,
) async {
  late ResolvedSortable resolved;
  await tester.pumpWidget(
    CoUIApp(
      theme: ThemeData.fromCore(CoreThemePresets.light),
      surfaceStyle: style,
      home: Builder(
        builder: (context) {
          resolved = resolveSortable(context);
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  return resolved;
}

void main() {
  group('Sortable row border under a surface style', () {
    testWidgets('a style that draws its own edge drops the row border', (
      tester,
    ) async {
      final resolved = await _resolveUnder(
        tester,
        CoreSurfaceStyleId.liquidGlass,
      );
      expect(resolved.itemBorderColor.a, 0);
      expect(resolved.disabledItemBorderColor.a, 0);
    });

    testWidgets('the default style keeps it', (tester) async {
      final resolved = await _resolveUnder(
        tester,
        CoreSurfaceStyleId.defaultStyle,
      );
      expect(resolved.itemBorderColor.a, greaterThan(0));
      expect(resolved.disabledItemBorderColor.a, greaterThan(0));
    });
  });
}
