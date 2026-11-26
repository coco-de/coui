import 'package:coui_flutter/src/util/standoff_border_radius.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StandoffBorderRadius.standoff', () {
    test('grows every round corner by the distance', () {
      expect(
        BorderRadius.circular(8).standoff(4),
        BorderRadius.circular(12),
      );
    });

    test('keeps a square corner square', () {
      // A preset that caps the radius at zero: a CSS spread grows only a
      // round corner, so the Flutter ring must leave this one square too.
      const corners = BorderRadius.only(topLeft: Radius.circular(6));
      expect(
        corners.standoff(2),
        const BorderRadius.only(topLeft: Radius.circular(8)),
      );
      expect(BorderRadius.zero.standoff(2), BorderRadius.zero);
    });
  });
}
