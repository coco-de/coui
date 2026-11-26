import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

void main() {
  const width = 120;
  const height = 80;
  const profile = CoreSurfaceRefraction(bezel: .2, lens: .2);

  test('the band pulls inward, leaves the face neutral and stays opaque', () {
    final pixels = surfaceRefractionDisplacementMap(
      width: width,
      height: height,
      radius: 16,
      refraction: profile,
    );
    int channel(int x, int y, int index) => pixels[(y * width + x) * 4 + index];
    expect(channel(1, 40, 0), greaterThan(128));
    expect(channel(118, 40, 0), lessThan(128));
    expect(channel(60, 1, 1), greaterThan(128));
    expect(channel(60, 78, 1), lessThan(128));
    expect(channel(60, 40, 0), 128);
    expect(channel(60, 40, 1), 128);
    // Corners need both axes; a rectangular per-axis edge approximation
    // would bend the straight edges correctly and fail this measurement.
    expect(channel(5, 5, 0), greaterThan(128));
    expect(channel(5, 5, 1), greaterThan(128));
    for (var at = 3; at < pixels.length; at += 4) {
      expect(pixels[at], 255);
    }
  });

  test('the dome magnifies the full face without a centre seam', () {
    final pixels = surfaceRefractionDisplacementMap(
      width: width,
      height: height,
      radius: 16,
      refraction: profile,
      lens: true,
    );
    int red(int x) => pixels[(40 * width + x) * 4];
    expect(red(20), greaterThan(red(40)));
    expect(red(40), greaterThan(red(59)));
    expect(red(59), closeTo(red(60), 2));
    expect(red(80), lessThan(128));
  });
}
