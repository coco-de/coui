// Synthetic snapshots/PNGs only — no capture, no browser (same convention
// as comparator_test.dart/pixel_diff_test.dart).
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:test/test.dart';

import '../../src/diff/pruned_pair_verifier.dart';
import '../../src/model/property_snapshot.dart';

Uint8List _solidPng(int r, int g, int b) {
  final image = img.Image(width: 4, height: 4, numChannels: 4);
  for (final pixel in image) {
    pixel
      ..r = r
      ..g = g
      ..b = b
      ..a = 255;
  }
  return Uint8List.fromList(img.encodePng(image));
}

PropertySnapshot _snapshot({
  required String key,
  NormalizedColor? backgroundColor,
}) => PropertySnapshot(
  key: key,
  platform: 'web',
  probeRole: 'root',
  backgroundColor: backgroundColor,
);

void main() {
  group('verifyPrunedPair — pixel-only regression (existing behaviour)', () {
    test('identical PNGs, no property snapshots supplied: passes', () {
      final png = _solidPng(252, 252, 253);
      final result = verifyPrunedPair(
        prunedKey: 'card-default-light-liquidGlass',
        baselineKey: 'card-default-light-defaultStyle',
        platform: 'web',
        prunedPng: png,
        baselinePng: png,
      );
      expect(result.passed, isTrue);
      expect(result.propertyDiff, isNull);
    });

    test('differing PNGs, no property snapshots supplied: fails', () {
      final result = verifyPrunedPair(
        prunedKey: 'k-pruned',
        baselineKey: 'k-baseline',
        platform: 'web',
        prunedPng: _solidPng(255, 0, 0),
        baselinePng: _solidPng(0, 0, 0),
      );
      expect(result.passed, isFalse);
      expect(result.describeFailures(), isNotEmpty);
      expect(result.describeFailures().first, startsWith('pixel:'));
    });
  });

  group('verifyPrunedPair — the card liquidGlass case (#3663 item 1)', () {
    // This is the exact empirical case that motivated adding PropertyDiff
    // here: a liquidGlass surface style on a same-colour flat backdrop
    // moves zero pixels (opaque rgb(252,252,253) vs a 70%-alpha
    // rgba(252,252,253,0.7) composite onto the same-coloured page
    // background render byte-identically) but the underlying
    // backgroundColor property genuinely differs. Before this file
    // existed, pruned_verify.dart only ran PixelDiff and would report this
    // pair as "matched" — a wrong pruning rule sailing through green.
    test(
      'pixel-identical PNGs + differing backgroundColor: PixelDiff alone '
      'would pass, but verifyPrunedPair fails on the property signal',
      () {
        final identicalPng = _solidPng(252, 252, 253);
        final prunedProperty = _snapshot(
          key: 'card-default-light-liquidGlass',
          backgroundColor: NormalizedColor(r: 252, g: 252, b: 253, a: 0.7),
        );
        final baselineProperty = _snapshot(
          key: 'card-default-light-defaultStyle',
          backgroundColor: NormalizedColor(r: 252, g: 252, b: 253, a: 1),
        );

        // Sanity-check the premise: pixel comparison alone genuinely
        // cannot see this — if this assertion ever fails, the fixture no
        // longer reproduces the case and the test below is testing
        // nothing.
        final pixelOnly = verifyPrunedPair(
          prunedKey: prunedProperty.key,
          baselineKey: baselineProperty.key,
          platform: 'web',
          prunedPng: identicalPng,
          baselinePng: identicalPng,
        );
        expect(
          pixelOnly.passed,
          isTrue,
          reason:
              'fixture premise: identical PNG bytes must pixel-match so '
              'the property signal below is what catches the mismatch',
        );

        final result = verifyPrunedPair(
          prunedKey: prunedProperty.key,
          baselineKey: baselineProperty.key,
          platform: 'web',
          prunedPng: identicalPng,
          baselinePng: identicalPng,
          prunedProperty: prunedProperty,
          baselineProperty: baselineProperty,
        );

        expect(result.passed, isFalse);
        expect(result.pixelDiff!.passed, isTrue);
        expect(result.propertyDiff!.hasFailures, isTrue);

        final failures = result.describeFailures();
        expect(failures, isNotEmpty);
        // Labelled pruned/baseline, not flutter/web — this comparison's
        // two sides are the same platform's pruned vs baseline capture,
        // not cross-platform.
        expect(
          failures.any(
            (line) =>
                line.contains('backgroundColor') &&
                line.contains('pruned=') &&
                line.contains('baseline='),
          ),
          isTrue,
          reason:
              'describeFailures() must label sides pruned/baseline: '
              '$failures',
        );
      },
    );

    test('identical backgroundColor: property signal also passes', () {
      final identicalPng = _solidPng(252, 252, 253);
      final snapshot = NormalizedColor(r: 252, g: 252, b: 253, a: 1);
      final result = verifyPrunedPair(
        prunedKey: 'card-default-light-defaultStyle-dup',
        baselineKey: 'card-default-light-defaultStyle',
        platform: 'web',
        prunedPng: identicalPng,
        baselinePng: identicalPng,
        prunedProperty: _snapshot(
          key: 'card-default-light-defaultStyle-dup',
          backgroundColor: snapshot,
        ),
        baselineProperty: _snapshot(
          key: 'card-default-light-defaultStyle',
          backgroundColor: snapshot,
        ),
      );
      expect(result.passed, isTrue);
    });
  });

  group('verifyPrunedPair — a bordered component that did not move', () {
    // The snapshots come from one platform. Their captured padding must
    // stay unchanged when the common comparator is reused for pruning.
    PropertySnapshot bordered(String key) => PropertySnapshot(
      key: key,
      platform: 'web',
      probeRole: 'root',
      borderWidthPx: 1,
      paddingPx: const FourSidePx(16, 16, 16, 16),
    );

    test('identical bordered snapshots pass the property signal', () {
      final result = verifyPrunedPair(
        prunedKey: 'frame-default-light-liquidGlass',
        baselineKey: 'frame-default-light-defaultStyle',
        platform: 'web',
        prunedProperty: bordered('frame-default-light-liquidGlass'),
        baselineProperty: bordered('frame-default-light-defaultStyle'),
      );

      expect(result.propertyDiff!.failures, isEmpty);
      expect(result.passed, isTrue);
    });

    test('a real padding change on a bordered component still fails', () {
      final result = verifyPrunedPair(
        prunedKey: 'frame-default-light-liquidGlass',
        baselineKey: 'frame-default-light-defaultStyle',
        platform: 'web',
        prunedProperty: const PropertySnapshot(
          key: 'frame-default-light-liquidGlass',
          platform: 'web',
          probeRole: 'root',
          borderWidthPx: 1,
          paddingPx: FourSidePx(20, 16, 20, 16),
        ),
        baselineProperty: bordered('frame-default-light-defaultStyle'),
      );

      expect(
        result.propertyDiff!.failures.map((f) => f.field),
        contains('paddingPx'),
      );
    });
  });
}
