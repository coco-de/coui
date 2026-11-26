// Tests for CoreScrollbarThumbGeometry — the arithmetic Flutter and Web both
// run to keep a bar's footprint fixed while its thumb grows.

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

void main() {
  group('CoreScrollbarThumbGeometry', () {
    test('footprint is the thumb plus its inset on both sides', () {
      const geometry = CoreScrollbarThumbGeometry(
        thickness: CoreSize.size6,
        hoverThickness: CoreSize.size8,
        inset: CoreSpace.space2,
      );

      expect(geometry.footprint, 10);
    });

    test('growing the thumb takes the growth out of the inset', () {
      const geometry = CoreScrollbarThumbGeometry(
        thickness: CoreSize.size6,
        hoverThickness: CoreSize.size8,
        inset: CoreSpace.space2,
      );

      expect(geometry.activeThickness, 8);
      expect(geometry.activeInset, 1);
      // The footprint does not move: thumb + inset on both sides is the same
      // before and after, so content beside the bar is never pushed.
      expect(
        geometry.activeThickness + 2 * geometry.activeInset,
        geometry.footprint,
      );
    });

    test('the thumb never outgrows the space reserved for it', () {
      const geometry = CoreScrollbarThumbGeometry(
        thickness: CoreSize.size6,
        hoverThickness: 14,
        inset: CoreSpace.space2,
      );

      expect(geometry.activeThickness, geometry.footprint);
      expect(geometry.activeInset, 0);
    });

    test('a hover thickness below the resting one is honoured', () {
      const geometry = CoreScrollbarThumbGeometry(
        thickness: CoreSize.size6,
        hoverThickness: 4,
        inset: CoreSpace.space2,
      );

      expect(geometry.activeThickness, 4);
      expect(geometry.activeInset, 3);
      expect(
        geometry.activeThickness + 2 * geometry.activeInset,
        geometry.footprint,
      );
    });

    test('thin scales every thickness by the factor and keeps the inset', () {
      // What the platform resolvers do for `CoreScrollbarVisibility.thin`:
      // each thickness is halved, the inset is not.
      const factor = CoreScrollbarStyle.thinThicknessFactor;
      const geometry = CoreScrollbarThumbGeometry(
        thickness: CoreScrollbarStyle.defaultThickness * factor,
        hoverThickness: CoreScrollbarStyle.defaultHoverThickness * factor,
        inset: CoreScrollbarStyle.defaultThumbInset,
      );

      expect(geometry.footprint, 7);
      expect(geometry.activeThickness, 4);
      expect(geometry.activeInset, 1.5);
    });

    test('equality compares every part', () {
      const a = CoreScrollbarThumbGeometry(
        thickness: 6,
        hoverThickness: 8,
        inset: 2,
      );
      const b = CoreScrollbarThumbGeometry(
        thickness: 6,
        hoverThickness: 8,
        inset: 2,
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(
        a,
        isNot(
          equals(
            const CoreScrollbarThumbGeometry(
              thickness: 6,
              hoverThickness: 8,
              inset: 3,
            ),
          ),
        ),
      );
    });
  });
}
