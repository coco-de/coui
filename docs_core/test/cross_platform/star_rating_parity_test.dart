import 'dart:io';

import 'package:test/test.dart';

/// Cross-platform parity for the StarRating preview.
///
/// The Web and Flutter previews delegate to `StarRatingDefaultExample`, which
/// renders the shared `StarRating` component with no per-platform visual
/// overrides. Visual chrome (sharp star points / active + track colours /
/// star size) lives in the single-source `CoreStarRatingStyle` defaults, so
/// parity is guaranteed by *not* re-hardcoding those tokens in either preview.
///
/// (Previously this test asserted literal `starPointRounding: 0`, `0xFFFACC15`,
/// etc. inside the registry preview function. Those tokens moved into the
/// component defaults; the preview now correctly carries none of them.)
void main() {
  late String flutterExample;
  late String webExample;

  setUpAll(() {
    flutterExample = File(
      'lib/previews/examples/flutter/star_rating/'
      'star_rating_default_example.dart',
    ).readAsStringSync();
    webExample = File(
      'lib/previews/examples/web/star_rating/'
      'star_rating_default_example.dart',
    ).readAsStringSync();
  });

  group('StarRating visual parity', () {
    test('both previews render the shared StarRating component', () {
      expect(flutterExample, contains('StarRating('));
      expect(webExample, contains('StarRating('));
    });

    test('both previews use an initial value of 3', () {
      expect(flutterExample, contains('_value = 3'));
      expect(webExample, contains('_value = 3'));
      expect(flutterExample, contains('value: _value'));
      expect(webExample, contains('value: _value'));
    });

    test('neither preview re-hardcodes visual chrome (single-source)', () {
      // Sharp points, colours and size come from CoreStarRatingStyle defaults.
      // A raw hex colour / starSize / starPointRounding in the preview would
      // be a per-platform override that breaks the single-source guarantee.
      for (final source in [flutterExample, webExample]) {
        expect(source, isNot(contains('0xFF')));
        expect(source, isNot(contains('starSize')));
        expect(source, isNot(contains('starPointRounding')));
      }
    });
  });
}
