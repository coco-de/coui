/// The drawings of a `MockupFoldable`'s status island.
library;

import 'package:coui_core/src/shape/vector_glyph.dart';

/// The status indicator a folding device shows under its clock: a ring, open
/// at the bottom, around the wifi glyph, with four dots closing the ring.
///
/// Sample content, like the status bar drawings of `MockupDevice`: a mockup
/// draws an operating system caught at one moment, so the drawing is stated
/// once here and read by both platforms. It is two drawings because it is two
/// colours — the ring and the glyph in the island's icon colour, the dots in
/// its quieter one — laid in the same box, so a platform draws one over the
/// other.
///
/// Both are drawn in a 42 × 42 box (iOS points) around its centre. The ring's
/// middle line is 19.05 from the centre and the ring 3.3 thick, with round
/// ends; it stops 61° either side of straight down. The dots are 4 across and
/// sit on that middle line, 10.6° and 32° either side of straight down. The
/// glyph inside is the phone's wifi glyph of `CoreMockupStatusBarGlyphs`,
/// drawn 18.1 wide and centred 0.4 above the ring's centre.
abstract final class CoreMockupFoldableGlyphs {
  /// The side of the box both drawings are drawn in (iOS points).
  static const double statusBox = 42;

  /// The ring and the wifi glyph inside it.
  static const CoreVectorGlyph statusRing = CoreVectorGlyph(
    path:
        'M 39.1046 31.0356 C 43.9308 22.3289 41.8761 11.4201 34.2132 '
        '5.0657 C 26.5503 -1.2886 15.4497 -1.2886 7.7868 5.0657 C 0.1239 '
        '11.4201 -1.9308 22.3289 2.8954 31.0356 C 3.3372 31.8326 4.3414 '
        '32.1205 5.1384 31.6787 C 5.9354 31.237 6.2234 30.2327 5.7816 '
        '29.4357 C 1.7248 22.1171 3.452 12.9473 9.8932 7.606 C 16.3345 '
        '2.2647 25.6655 2.2647 32.1068 7.606 C 38.548 12.9473 40.2752 '
        '22.1171 36.2184 29.4357 C 35.7766 30.2327 36.0646 31.237 36.8616 '
        '31.6787 C 37.6586 32.1205 38.6628 31.8326 39.1046 31.0356 Z M '
        '21.0005 16.6954 C 23.6266 16.6955 26.1523 17.6692 28.0556 19.415 '
        'C 28.199 19.5499 28.428 19.5482 28.5692 19.4112 L 29.9392 '
        '18.0772 C 30.0107 18.0077 30.0505 17.9136 30.05 17.8158 C '
        '30.0494 17.718 30.0084 17.6243 29.9361 17.5557 C 24.9406 12.9364 '
        '17.0596 12.9364 12.0641 17.5557 C 11.9917 17.6243 11.9506 '
        '17.7179 11.95 17.8157 C 11.9494 17.9136 11.9891 18.0077 12.0606 '
        '18.0772 L 13.431 19.4112 C 13.5721 19.5484 13.8013 19.5501 '
        '13.9445 19.415 C 15.8481 17.6691 18.374 16.6954 21.0005 16.6954 '
        'Z M 20.9969 21.1517 C 22.4302 21.1516 23.8121 21.6919 24.8746 '
        '22.6676 C 25.0182 22.8062 25.2446 22.8032 25.3847 22.6609 L '
        '26.7439 21.2678 C 26.8154 21.1947 26.8553 21.0956 26.8542 '
        '20.9926 C 26.8531 20.8896 26.8114 20.7914 26.7384 20.7198 C '
        '23.5033 17.6673 18.4933 17.6673 15.2581 20.7198 C 15.1851 '
        '20.7914 15.1435 20.8897 15.1424 20.9927 C 15.1415 21.0958 '
        '15.1814 21.1948 15.2531 21.2678 L 16.6119 22.6609 C 16.752 '
        '22.8032 16.9783 22.8062 17.122 22.6676 C 18.1837 21.6925 19.5647 '
        '21.1522 20.9969 21.1517 Z M 23.6625 24.1013 C 23.6645 24.2126 '
        '23.6253 24.3198 23.5543 24.3977 L 21.256 26.9898 C 21.1886 '
        '27.0659 21.0968 27.1088 21.0009 27.1088 C 20.905 27.1088 20.8132 '
        '27.0659 20.7458 26.9898 L 18.4471 24.3977 C 18.3761 24.3198 '
        '18.3371 24.2125 18.3392 24.1012 C 18.3412 23.99 18.3844 23.8847 '
        '18.4582 23.8101 C 19.926 22.4228 22.0758 22.4228 23.5436 23.8101 '
        'C 23.6174 23.8848 23.6604 23.9901 23.6625 24.1013 Z',
    width: statusBox,
    height: statusBox,
    fillRule: CoreVectorFillRule.evenOdd,
  );

  /// The four dots in the ring's opening.
  static const CoreVectorGlyph statusDots = CoreVectorGlyph(
    path:
        'M 10.905 39.1553 C 12.0096 39.1553 12.905 38.2599 12.905 37.1553 '
        'C 12.905 36.0507 12.0096 35.1553 10.905 35.1553 C 9.8005 35.1553 '
        '8.905 36.0507 8.905 37.1553 C 8.905 38.2599 9.8005 39.1553 '
        '10.905 39.1553 Z M 17.4957 41.7249 C 18.6003 41.7249 19.4957 '
        '40.8295 19.4957 39.7249 C 19.4957 38.6203 18.6003 37.7249 '
        '17.4957 37.7249 C 16.3912 37.7249 15.4957 38.6203 15.4957 '
        '39.7249 C 15.4957 40.8295 16.3912 41.7249 17.4957 41.7249 Z M '
        '24.5043 41.7249 C 25.6088 41.7249 26.5043 40.8295 26.5043 '
        '39.7249 C 26.5043 38.6203 25.6088 37.7249 24.5043 37.7249 C '
        '23.3997 37.7249 22.5043 38.6203 22.5043 39.7249 C 22.5043 '
        '40.8295 23.3997 41.7249 24.5043 41.7249 Z M 31.095 39.1553 C '
        '32.1995 39.1553 33.095 38.2599 33.095 37.1553 C 33.095 36.0507 '
        '32.1995 35.1553 31.095 35.1553 C 29.9904 35.1553 29.095 36.0507 '
        '29.095 37.1553 C 29.095 38.2599 29.9904 39.1553 31.095 39.1553 Z',
    width: statusBox,
    height: statusBox,
    fillRule: CoreVectorFillRule.nonZero,
  );
}
