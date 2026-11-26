import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

void main() {
  group('resolveDrawerBackdropRuntime', () {
    testComponents(
      'asymmetric backdropCornerRadius survives to all 4 corners',
      (tester) async {
        late ResolvedDrawerBackdropRuntime runtime;
        pumpWithTheme(
          tester,
          Builder(
            builder: (context) {
              runtime = resolveDrawerBackdropRuntime(
                context,
                drawerStyle: const CoreDrawerStyle(
                  // Deliberately avoid the CoreRadius scale values
                  // (0/4/8/16/9999) `_radiusCss` special-cases as
                  // `var(--coui-radius-N)` tokens — this test wants
                  // plain `px` output so the 4 corners are trivially
                  // distinguishable in the CSS shorthand string.
                  backdropCornerRadius: CoreBorderRadius.only(
                    topLeft: 3,
                    topRight: 39,
                    bottomLeft: 11,
                    bottomRight: 27,
                  ),
                ),
              );
              return const Text('probe');
            },
          ),
        );

        expect(runtime.cornerRadiusTopLeftPx, equals(3));
        expect(runtime.cornerRadiusTopRightPx, equals(39));
        expect(runtime.cornerRadiusBottomLeftPx, equals(11));
        expect(runtime.cornerRadiusBottomRightPx, equals(27));
        // Settled-state CSS shorthand must carry all 4 distinct values
        // in `topLeft topRight bottomRight bottomLeft` order — proof
        // the fix doesn't collapse to one representative corner.
        expect(runtime.cornerRadiusCss, equals('3.0px 39.0px 27.0px 11.0px'));
      },
    );
  });
}
