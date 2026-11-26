import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

/// The trigger-to-panel distance a popover keeps (#5967): 4 by default — the
/// same as every other floating panel — and a stated offset still wins.
Future<ResolvedPopover> _resolve(
  WidgetTester tester, {
  CorePopoverStyle? popoverStyle,
}) async {
  late ResolvedPopover resolved;
  await tester.pumpWidget(
    CoUIApp(
      theme: ThemeData.fromCore(CoreThemePresets.light),
      home: Builder(
        builder: (context) {
          resolved = resolvePopover(context, popoverStyle: popoverStyle);

          return const SizedBox.shrink();
        },
      ),
    ),
  );

  return resolved;
}

void main() {
  group('Popover trigger-to-panel offset', () {
    testWidgets('defaults to 4 at the standard scaling', (tester) async {
      final resolved = await _resolve(tester);

      expect(resolved.placementOffset, CoreSpace.space4);
      expect(resolved.placementOffset, 4);
    });

    testWidgets('a stated offset wins over the default', (tester) async {
      final resolved = await _resolve(
        tester,
        popoverStyle: const CorePopoverStyle(placementOffset: 12),
      );

      expect(resolved.placementOffset, 12);
    });
  });
}
