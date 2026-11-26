import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

void main() {
  for (final preserve in [false, true]) {
    testWidgets('zero token alpha preserves only when requested: $preserve', (
      tester,
    ) async {
      ResolvedOutlinedContainer? result;
      await tester.pumpWidget(
        buildTestApp(
          Builder(
            builder: (context) {
              result = resolveOutlinedContainer(
                context,
                containerStyle: CoreOutlinedContainerStyle(
                  borderColor: const CoreColor.token(
                    CoreColors.primary,
                    opacity: 0,
                  ),
                  borderWidth: 2,
                  preserveTransparentBorder: preserve,
                ),
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(result!.borderWidth, preserve ? 2 : 0);
    });
  }
  for (final (opacity, width) in [(0.0, 0.0), (0.5, 2.0), (1.0, 2.0)]) {
    testWidgets('token opacity $opacity resolves width $width', (tester) async {
      ResolvedOutlinedContainer? result;
      await tester.pumpWidget(
        buildTestApp(
          Builder(
            builder: (context) {
              result = resolveOutlinedContainer(
                context,
                containerStyle: CoreOutlinedContainerStyle(
                  borderColor: CoreColor.token(
                    CoreColors.primary,
                    opacity: opacity,
                  ),
                  borderWidth: 2,
                ),
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(result!.borderWidth, width);
    });
  }
}
