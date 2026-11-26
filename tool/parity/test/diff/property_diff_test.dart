// This file's entire purpose is checking specific numeric/token
// combinations against specific expected verdicts — naming each literal
// would add noise, not clarity (same convention as
// `test/model/property_snapshot_test.dart`).
import 'package:test/test.dart';

import '../../src/diff/property_diff.dart';
import '../../src/model/property_snapshot.dart';

PropertySnapshot _snapshot({
  required String platform,
  int? fontWeight,
  NormalizedColor? color,
  double? borderWidthPx,
  FourSidePx? borderRadiusPx,
  double? outlineWidthPx,
  double? outlineOffsetPx,
  double? widthPx,
  double? heightPx,
  NormalizedColor? borderColor,
  FourSidePx? paddingPx,
  double? opacity,
  NormalizedColor? backgroundColor,
  List<BoxShadowLayer>? boxShadow,
}) => .new(
  key: 'k',
  platform: platform,
  probeRole: 'root',
  fontWeight: fontWeight,
  color: color,
  borderWidthPx: borderWidthPx,
  borderRadiusPx: borderRadiusPx,
  outlineWidthPx: outlineWidthPx,
  outlineOffsetPx: outlineOffsetPx,
  widthPx: widthPx,
  heightPx: heightPx,
  borderColor: borderColor,
  paddingPx: paddingPx,
  opacity: opacity,
  backgroundColor: backgroundColor,
  boxShadow: boxShadow,
);

void main() {
  group('comparePropertySnapshots — field tolerance', () {
    test('identical snapshots produce no failures', () {
      final snapshot = _snapshot(platform: 'flutter', fontWeight: 400);
      final result = comparePropertySnapshots(
        flutter: snapshot,
        web: _snapshot(platform: 'web', fontWeight: 400),
      );
      expect(result.hasFailures, isFalse);
    });

    test('fontWeight has zero tolerance — 1 unit off still fails', () {
      final result = comparePropertySnapshots(
        flutter: _snapshot(platform: 'flutter', fontWeight: 401),
        web: _snapshot(platform: 'web', fontWeight: 400),
      );
      expect(result.hasFailures, isTrue);
      expect(result.failures.single.field, 'fontWeight');
    });

    test('px fields within kPxTolerance pass', () {
      final result = comparePropertySnapshots(
        flutter: _snapshot(platform: 'flutter', borderWidthPx: 1),
        web: _snapshot(platform: 'web', borderWidthPx: 1 + kPxTolerance),
      );
      expect(result.hasFailures, isFalse);
    });

    test('px fields beyond kPxTolerance fail', () {
      final result = comparePropertySnapshots(
        flutter: _snapshot(platform: 'flutter', borderWidthPx: 1),
        web: _snapshot(
          platform: 'web',
          borderWidthPx: 1 + kPxTolerance + 0.01,
        ),
      );
      final failure = result.failures.singleWhere(
        (f) => f.field == 'borderWidthPx',
      );
      expect(failure.matches, isFalse);
    });

    test('color channels have zero tolerance', () {
      final result = comparePropertySnapshots(
        flutter: _snapshot(
          platform: 'flutter',
          color: NormalizedColor(r: 29, g: 29, b: 31, a: 1),
        ),
        web: _snapshot(
          platform: 'web',
          color: NormalizedColor(r: 30, g: 29, b: 31, a: 1),
        ),
      );
      expect(
        result.failures.any((f) => f.field == 'color'),
        isTrue,
        reason: 'a single r-channel unit off should still fail',
      );
    });

    test('a null on one side and a value on the other is a failure', () {
      final result = comparePropertySnapshots(
        flutter: _snapshot(platform: 'flutter', fontWeight: 400),
        web: _snapshot(platform: 'web'),
      );
      expect(
        result.failures.any((f) => f.field == 'fontWeight'),
        isTrue,
      );
    });

    test('borderRadiusPx compares all four corners independently', () {
      final result = comparePropertySnapshots(
        flutter: _snapshot(
          platform: 'flutter',
          borderRadiusPx: const FourSidePx(8, 8, 8, 8),
        ),
        web: _snapshot(
          platform: 'web',
          // Only the bottom-right corner differs, beyond tolerance.
          borderRadiusPx: const FourSidePx(8, 8, 2, 8),
        ),
      );
      expect(
        result.failures.any((f) => f.field == 'borderRadiusPx'),
        isTrue,
      );
    });
  });

  group('comparePropertySnapshots — 3-way token verdict', () {
    test(
      'both platforms matching the token reports neitherDiverges',
      () {
        final result = comparePropertySnapshots(
          flutter: _snapshot(platform: 'flutter', fontWeight: 400),
          web: _snapshot(platform: 'web', fontWeight: 400),
          expected: _snapshot(platform: 'token', fontWeight: 400),
        );
        expect(
          result.fields
              .singleWhere((f) => f.field == 'fontWeight')
              .tokenDivergence,
          TokenDivergence.neitherDiverges,
        );
      },
    );

    test('no expected value supplied reports notChecked', () {
      final result = comparePropertySnapshots(
        flutter: _snapshot(platform: 'flutter', fontWeight: 400),
        web: _snapshot(platform: 'web', fontWeight: 400),
      );
      expect(
        result.fields
            .singleWhere((f) => f.field == 'fontWeight')
            .tokenDivergence,
        TokenDivergence.notChecked,
      );
    });
  });

  group('confirmed defect #1 — Command label font-weight (RED)', () {
    // PRD (`.bmad/prd-*.md`): both platforms reference the identical Core
    // token (`CoreFontWeight.regular` == 400), so this defect is
    // invisible to any token-source comparison — it only shows up by
    // comparing what each platform actually *rendered*. Flutter rendered
    // semibold-weight text despite the regular token; Web rendered
    // correctly. This fixture reproduces exactly that shape.
    test(
      'flutter renders bold despite both platforms sharing the regular '
      'token — PropertyDiff catches it, and correctly blames flutter',
      () {
        final result = comparePropertySnapshots(
          flutter: _snapshot(platform: 'flutter', fontWeight: 600),
          web: _snapshot(platform: 'web', fontWeight: 400),
          expected: _snapshot(platform: 'token', fontWeight: 400),
        );

        expect(result.hasFailures, isTrue);
        final fontWeightFailure = result.failures.singleWhere(
          (f) => f.field == 'fontWeight',
        );
        expect(
          fontWeightFailure.tokenDivergence,
          TokenDivergence.flutterDiverges,
        );
        expect(
          fontWeightFailure.describe(),
          'fontWeight: flutter=600 web=400 (token=400 — flutter diverges)',
        );
      },
    );
  });

  group(
    'confirmed defect #2 — DatePicker focus-ring geometry (RED)',
    () {
      // PRD/architecture (`.bmad/prd-*.md`, `.bmad/architecture-*.md`):
      // Web renders the trigger's focus ring sharp and tight, Flutter
      // renders it rounder and more generous — a border-radius/width
      // geometry mismatch, screenshot-confirmed. No token comparison is
      // claimed for this one (no PRD evidence either platform matches a
      // token), so this fixture only exercises the Flutter-vs-Web half.
      test(
        'flutter and web focus-ring geometry differ beyond tolerance on '
        'both borderRadiusPx and outlineWidthPx',
        () {
          final result = comparePropertySnapshots(
            flutter: _snapshot(
              platform: 'flutter',
              borderRadiusPx: const FourSidePx(8, 8, 8, 8),
              outlineWidthPx: 3,
              outlineOffsetPx: 3,
            ),
            web: _snapshot(
              platform: 'web',
              borderRadiusPx: const FourSidePx(2, 2, 2, 2),
              outlineWidthPx: 1,
              outlineOffsetPx: 1,
            ),
          );

          expect(result.hasFailures, isTrue);
          expect(
            result.failures.map((f) => f.field),
            containsAll([
              'borderRadiusPx',
              'outlineWidthPx',
              'outlineOffsetPx',
            ]),
          );
        },
      );
    },
  );

  group('geometry — the box that layout actually produced', () {
    // The defect this field was added for: a size token one platform
    // applies as an exact height and the other as a minimum. Every
    // painted field agrees; only the rendered box disagrees. Measured on
    // Button `sm`, whose token is 32 — Flutter renders 34 because the
    // token is a `minHeight` with `maxHeight: infinity`, Web renders 32
    // because it is a fixed `h-size32`.
    test('a height the two platforms resolve differently is a failure', () {
      final result = comparePropertySnapshots(
        flutter: _snapshot(platform: 'flutter', heightPx: 34),
        web: _snapshot(platform: 'web', heightPx: 32),
      );

      expect(result.hasFailures, isTrue);
      expect(result.failures.map((f) => f.field), contains('heightPx'));
    });

    test('the same height on both platforms is not', () {
      final result = comparePropertySnapshots(
        flutter: _snapshot(platform: 'flutter', heightPx: 32),
        web: _snapshot(platform: 'web', heightPx: 32),
      );

      expect(result.failures.map((f) => f.field), isNot(contains('heightPx')));
    });

    test('width diverges on its own axis', () {
      final result = comparePropertySnapshots(
        flutter: _snapshot(platform: 'flutter', widthPx: 120),
        web: _snapshot(platform: 'web', widthPx: 96),
      );

      expect(result.failures.map((f) => f.field), contains('widthPx'));
    });

    test('sub-pixel geometry noise is absorbed, not reported', () {
      // Layout arithmetic differs in the last decimal between a Skia
      // rasterizer and a browser one. A gate that reported those would
      // be turned off within a week, which is the failure mode that
      // matters more than the one it would catch.
      final result = comparePropertySnapshots(
        flutter: _snapshot(platform: 'flutter', heightPx: 32.2, widthPx: 96.1),
        web: _snapshot(platform: 'web', heightPx: 32, widthPx: 96),
      );

      expect(result.hasFailures, isFalse);
    });

    test('a snapshot captured before geometry existed still compares', () {
      // Both sides null — an older `<key>.flutter.json` on disk has no
      // `widthPx` key at all. That has to read as "not probed", the same
      // as every other optional field, rather than as a divergence
      // against a freshly captured Web side.
      final result = comparePropertySnapshots(
        flutter: _snapshot(platform: 'flutter'),
        web: _snapshot(platform: 'web'),
      );

      expect(result.hasFailures, isFalse);
    });
  });

  group('measurement artifacts are not divergences', () {
    // The capture pages mount a reset that sets a border colour on every
    // element (`border: 0px solid rgb(229,231,235)`), so Chrome computes
    // that grey whether or not a border is painted while Flutter reports
    // null. At width 0 neither reaches a pixel. This was 78% of the
    // corpus.
    test('a zero-width border has no colour to disagree about', () {
      final result = comparePropertySnapshots(
        flutter: _snapshot(platform: 'flutter', borderWidthPx: 0),
        web: _snapshot(
          platform: 'web',
          borderWidthPx: 0,
          borderColor: NormalizedColor(r: 229, g: 231, b: 235, a: 1),
        ),
      );

      expect(result.hasFailures, isFalse);
      // Still reported, so the reader can see what each side measured.
      expect(result.fields.map((f) => f.field), contains('borderColor'));
    });

    test('null width and 0.0 width are the same absent border', () {
      final result = comparePropertySnapshots(
        flutter: _snapshot(platform: 'flutter'),
        web: _snapshot(platform: 'web', borderWidthPx: 0),
      );

      expect(result.hasFailures, isFalse);
    });

    // `outline-width` initialises to `medium`, which Chrome computes to 3px
    // on EVERY element — a bare `<div>` reports `3px` / `outline-style:
    // none`. The normalizer zeroes it once it can see the style; this gate
    // is what makes that zero mean the same thing as Flutter's null, which
    // it otherwise would not (`_withinTolerance` short-circuits a null pair
    // to `null == 0.0`). 160 of the corpus.
    test('an outline nobody draws is not held against anything', () {
      final result = comparePropertySnapshots(
        flutter: _snapshot(platform: 'flutter'),
        web: _snapshot(platform: 'web', outlineWidthPx: 0, outlineOffsetPx: 2),
      );

      expect(result.hasFailures, isFalse);
      // Still reported, so the reader can see what each side measured.
      expect(result.fields.map((f) => f.field), contains('outlineWidthPx'));
      expect(result.fields.map((f) => f.field), contains('outlineOffsetPx'));
    });

    test('an outline that IS drawn is still compared', () {
      final result = comparePropertySnapshots(
        flutter: _snapshot(platform: 'flutter', outlineWidthPx: 2),
        web: _snapshot(platform: 'web', outlineWidthPx: 4),
      );

      expect(result.hasFailures, isTrue);
      expect(
        result.failures.map((f) => f.field),
        contains('outlineWidthPx'),
      );
    });

    test('one side drawing an outline and the other not is a real failure', () {
      final result = comparePropertySnapshots(
        flutter: _snapshot(platform: 'flutter'),
        web: _snapshot(platform: 'web', outlineWidthPx: 3),
      );

      expect(result.hasFailures, isTrue);
    });

    test('a border that IS painted still has its colour held to account', () {
      // The gate above must not become a way to stop checking borders.
      final result = comparePropertySnapshots(
        flutter: _snapshot(
          platform: 'flutter',
          borderWidthPx: 1,
          borderColor: NormalizedColor(r: 0, g: 0, b: 0, a: 1),
        ),
        web: _snapshot(
          platform: 'web',
          borderWidthPx: 1,
          borderColor: NormalizedColor(r: 255, g: 0, b: 0, a: 1),
        ),
      );

      expect(result.failures.map((f) => f.field), contains('borderColor'));
    });

    // The former A8-loss allowance hid different observations. Typed
    // Flutter Color.a and computed CSS alpha now share round3 precision;
    // historical .702/.7 remains an explicit difference, not a guessed
    // common authored value.
    test('distinct observed alpha is not inferred as a byte loss', () {
      final result = comparePropertySnapshots(
        flutter: _snapshot(
          platform: 'flutter',
          color: NormalizedColor(r: 24, g: 25, b: 27, a: 0.702),
        ),
        web: _snapshot(
          platform: 'web',
          color: NormalizedColor(r: 24, g: 25, b: 27, a: 0.7),
        ),
      );

      expect(result.hasFailures, isTrue);
    });

    test('a whole alpha byte still fails', () {
      // The tolerance sits under 1/255, so it can never swallow a real
      // one-step difference — the property that makes it a tolerance
      // rather than a blindfold.
      final result = comparePropertySnapshots(
        flutter: _snapshot(
          platform: 'flutter',
          color: NormalizedColor(r: 0, g: 0, b: 0, a: 0.7),
        ),
        web: _snapshot(
          platform: 'web',
          color: NormalizedColor(r: 0, g: 0, b: 0, a: 0.694),
        ),
      );

      expect(result.failures.map((f) => f.field), contains('color'));
    });

    test('the smallest opacity step the palette can say still fails', () {
      // `CoreOpacity` opacity3 → opacity5 is 0.02 apart. If the tolerance
      // ever grew past a step the design system can express, it would be
      // hiding authored differences rather than measurement noise.
      final result = comparePropertySnapshots(
        flutter: _snapshot(platform: 'flutter', opacity: 0.03),
        web: _snapshot(platform: 'web', opacity: 0.05),
      );

      expect(result.failures.map((f) => f.field), contains('opacity'));
    });

    // Pixel agreement does not make two different captured insets equal.
    // The snapshot has no provenance to reconstruct authored padding.
    test(
      'different captured vertical padding is reported despite a border',
      () {
        final result = comparePropertySnapshots(
          flutter: _snapshot(
            platform: 'flutter',
            borderWidthPx: 1,
            paddingPx: const FourSidePx(7, 16, 7, 16),
            borderColor: NormalizedColor(r: 0, g: 0, b: 0, a: 1),
          ),
          web: _snapshot(
            platform: 'web',
            borderWidthPx: 1,
            paddingPx: const FourSidePx(8, 16, 8, 16),
            borderColor: NormalizedColor(r: 0, g: 0, b: 0, a: 1),
          ),
        );

        expect(result.failures.map((f) => f.field), contains('paddingPx'));
      },
    );

    test('a real horizontal padding difference still fails', () {
      final result = comparePropertySnapshots(
        flutter: _snapshot(
          platform: 'flutter',
          borderWidthPx: 1,
          paddingPx: const FourSidePx(7, 12, 7, 12),
          borderColor: NormalizedColor(r: 0, g: 0, b: 0, a: 1),
        ),
        web: _snapshot(
          platform: 'web',
          borderWidthPx: 1,
          paddingPx: const FourSidePx(8, 16, 8, 16),
          borderColor: NormalizedColor(r: 0, g: 0, b: 0, a: 1),
        ),
      );

      expect(result.failures.map((f) => f.field), contains('paddingPx'));
    });

    test('a real vertical padding difference still fails', () {
      final result = comparePropertySnapshots(
        flutter: _snapshot(
          platform: 'flutter',
          borderWidthPx: 1,
          paddingPx: const FourSidePx(3, 16, 3, 16),
          borderColor: NormalizedColor(r: 0, g: 0, b: 0, a: 1),
        ),
        web: _snapshot(
          platform: 'web',
          borderWidthPx: 1,
          paddingPx: const FourSidePx(8, 16, 8, 16),
          borderColor: NormalizedColor(r: 0, g: 0, b: 0, a: 1),
        ),
      );

      expect(result.failures.map((f) => f.field), contains('paddingPx'));
    });
  });

  // 야간 스윕이 열흘 넘게 `0 passed` 를 보고한 이유. 두 플랫폼은 "없음" 을
  // 다르게 적는다 — Flutter 는 필드를 비우고, Chrome 은 모든 요소가 갖는
  // 초기값(투명 배경 · `box-shadow: none` · 0 패딩)을 계산해 돌려준다.
  // 어느 쪽도 픽셀에 닿지 않으므로 이것을 차이로 세면 눈으로 찾을 수 없는
  // 차이를 보고하게 된다. 실측: 262 실패 중 138 이 이 형태였다.
  group('없음은 없음과 같다 — 철자가 달라도', () {
    test('배경: Flutter 의 null 과 Web 의 투명은 같은 없음이다', () {
      final result = comparePropertySnapshots(
        flutter: _snapshot(platform: 'flutter'),
        web: _snapshot(
          platform: 'web',
          backgroundColor: NormalizedColor(r: 0, g: 0, b: 0, a: 0),
        ),
      );

      expect(
        result.failures.map((f) => f.field),
        isNot(contains('backgroundColor')),
      );
    });

    test('배경: 한쪽이 실제로 칠하면 여전히 다르다', () {
      final result = comparePropertySnapshots(
        flutter: _snapshot(
          platform: 'flutter',
          backgroundColor: NormalizedColor(r: 195, g: 196, b: 198, a: 1),
        ),
        web: _snapshot(
          platform: 'web',
          backgroundColor: NormalizedColor(r: 0, g: 0, b: 0, a: 0),
        ),
      );

      expect(result.failures.map((f) => f.field), contains('backgroundColor'));
    });

    test('그림자: null 과 빈 목록은 같은 없음이다', () {
      final result = comparePropertySnapshots(
        flutter: _snapshot(platform: 'flutter'),
        web: _snapshot(platform: 'web', boxShadow: const []),
      );

      expect(result.failures.map((f) => f.field), isNot(contains('boxShadow')));
    });

    test('패딩: null 과 사방 0 은 같은 없음이다', () {
      final result = comparePropertySnapshots(
        flutter: _snapshot(platform: 'flutter'),
        web: _snapshot(
          platform: 'web',
          paddingPx: const FourSidePx(0, 0, 0, 0),
        ),
      );

      expect(result.failures.map((f) => f.field), isNot(contains('paddingPx')));
    });

    test('패딩: 한쪽이 실제로 밀면 여전히 다르다', () {
      final result = comparePropertySnapshots(
        flutter: _snapshot(
          platform: 'flutter',
          paddingPx: const FourSidePx(1, 0, 1, 0),
        ),
        web: _snapshot(
          platform: 'web',
          paddingPx: const FourSidePx(0, 0, 0, 0),
        ),
      );

      expect(result.failures.map((f) => f.field), contains('paddingPx'));
    });
  });
}
