import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

void main() {
  test(
    'weightFloor bends label roles; an equal-at-baseline overlay defeats it',
    () {
      const floor = CoreSurfaceTypographyConstraint(
        weightFloor: CoreFontWeight.semiBold,
      );
      final bent = floor.apply(CoreTypography.coui);

      // Baseline vs bent role weight.
      expect(CoreTypography.coui.labelLarge.fontWeight, CoreFontWeight.medium);
      expect(bent.labelLarge.fontWeight, CoreFontWeight.semiBold);

      // What core_to_flutter.dart does: slot.merge(overlay).
      final slot = bent.labelLarge;

      const withOverlay = CoreTextStyle(fontWeight: CoreFontWeight.medium);
      const withoutOverlay = CoreTextStyle();

      expect(
        slot.merge(withOverlay).fontWeight,
        CoreFontWeight.medium,
        reason: 'overlay wins -> 500 under neoBrutalism',
      );
      expect(
        slot.merge(withoutOverlay).fontWeight,
        CoreFontWeight.semiBold,
        reason: 'no overlay -> role 600 under neoBrutalism',
      );
    },
  );
}
