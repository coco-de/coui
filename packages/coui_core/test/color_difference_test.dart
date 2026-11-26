import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

void main() {
  test('public colour distance distinguishes neutral endpoints', () {
    const black = CoreColor(0xff000000);
    const white = CoreColor(0xffffffff);
    expect(CoreColorDifference.ciede2000(black, black), 0);
    expect(CoreColorDifference.ciede2000(white, white), 0);
    // Neutral Lab lightness spans 0 to 100. The rounded D65 sRGB
    // conversion matrix introduces only a tiny residual.
    expect(CoreColorDifference.ciede2000(black, white), closeTo(100, .01));
    expect(CoreColorDifference.ciede2000(white, black), closeTo(100, .01));
  });

  test('public colour distance preserves symmetry and ignores alpha', () {
    const brand = CoreColor(0xff267eff);
    const status = CoreColor(0xff14c37e);
    final distance = CoreColorDifference.ciede2000(brand, status);
    expect(distance, greaterThan(0));
    expect(
      CoreColorDifference.ciede2000(status, brand),
      closeTo(distance, 1e-12),
    );
    expect(
      CoreColorDifference.ciede2000(const CoreColor(0x00267eff), status),
      distance,
    );
  });
}
