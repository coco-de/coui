import 'package:test/test.dart';

import '../../src/diff/property_diff.dart';
import '../../src/model/property_snapshot.dart';

BoxShadowLayer _layer({
  bool inset = false,
  String blurStyle = 'normal',
  double blur = 12,
  double offsetY = 4,
}) => BoxShadowLayer(
  offsetX: 0,
  offsetY: offsetY,
  blur: blur,
  spread: 0,
  color: NormalizedColor(r: 0, g: 0, b: 0, a: 0.4),
  inset: inset,
  blurStyle: blurStyle,
);

bool _matches(BoxShadowLayer native, BoxShadowLayer web) {
  PropertySnapshot snapshot(String platform, BoxShadowLayer layer) =>
      PropertySnapshot(
        key: 'paint',
        platform: platform,
        probeRole: 'root',
        boxShadow: [layer],
      );
  return !comparePropertySnapshots(
    flutter: snapshot('flutter', native),
    web: snapshot('web', web),
  ).hasFailures;
}

void main() {
  test('equal visible shadows still match', () {
    expect(_matches(_layer(), _layer()), isTrue);
  });
  test('visible inset and outset never become equivalent', () {
    expect(_matches(_layer(), _layer(inset: true)), isFalse);
  });
  for (final kind in ['inner', 'outer', 'solid']) {
    test('normal and SDK $kind paint remain different', () {
      expect(_matches(_layer(blurStyle: kind), _layer()), isFalse);
    });
  }
  test('visible wrong blur and offset still fail existing tolerances', () {
    expect(_matches(_layer(), _layer(blur: 14)), isFalse);
    expect(_matches(_layer(), _layer(offsetY: 7)), isFalse);
  });
}
