import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

/// The section header's typography role, read back where it lands.
///
/// The section caption's typography role, read back where it lands.
///
/// The role is stated once in `CoreNavigationBarStyle.sectionLabelRole`
/// (`labelSmall`, 12px) and travels through the merge chain into a
/// materialised `TextStyle`. These read the resolver's output so a slide
/// up to `labelLarge` (14) fails here.
void main() {
  group('NavigationBar section label role', () {
    for (final mode in CoreNavigationBarMode.values) {
      testWidgets('${mode.name} resolves the labelSmall role', (tester) async {
        late ResolvedNavigationBar resolved;
        late CoreTypography typography;

        await tester.pumpWidget(
          buildTestApp(
            Builder(
              builder: (context) {
                typography = Theme.of(context).typography;
                resolved = resolveNavigationBar(
                  context,
                  mode: mode,
                  variant: CoreNavigationBarVariant.defaultVariant,
                );
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(
          resolved.sectionLabelTextStyle.fontSize,
          equals(typography.labelSmall.fontSize),
        );
        // Named separately from the positive assertion: the two roles differ
        // by one step, so an equality that silently compared the wrong scale
        // would still pass. This fails if the role slides back up to 14.
        expect(
          resolved.sectionLabelTextStyle.fontSize,
          isNot(equals(typography.labelLarge.fontSize)),
        );
      });
    }

    testWidgets('keeps the semibold weight the role does not carry', (
      tester,
    ) async {
      late ResolvedNavigationBar resolved;

      await tester.pumpWidget(
        buildTestApp(
          Builder(
            builder: (context) {
              resolved = resolveNavigationBar(
                context,
                mode: CoreNavigationBarMode.rail,
                variant: CoreNavigationBarVariant.defaultVariant,
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      // The weight arrives as an overlay on the role token, so it is the half
      // of this default most easily lost when the role moves.
      expect(
        resolved.sectionLabelTextStyle.fontWeight,
        equals(FontWeight.w600),
      );
    });
  });
}
