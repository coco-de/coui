import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

void main() {
  for (final reduced in [false, true]) {
    for (final ms in [137, 150, 730]) {
      testWidgets('duration $ms reduced=$reduced follows Core policy', (
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
                    duration: Duration(milliseconds: ms),
                  ),
                );
                return const SizedBox.shrink();
              },
            ),
            disableAnimations: reduced,
          ),
        );
        expect(
          result!.duration,
          reduced && ms <= 500 ? Duration.zero : Duration(milliseconds: ms),
        );
      });
    }
  }
}
