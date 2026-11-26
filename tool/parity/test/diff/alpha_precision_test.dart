// Current-observation comparison fixture, separate from legacy A8 original21.
// Typed float inputs use the actual Color.a precision witnessed by Native8.
// Synthetic calls test the public comparator, not rendered component output.
import 'package:test/test.dart';

import '../../src/diff/property_diff.dart';
import '../../src/model/property_snapshot.dart';
import '../../src/normalize/css_value_parsers.dart';
import '../../src/normalize/flutter_property_normalizer.dart';

NormalizedColor _nativeByte(int alpha) =>
    normalizeFlutterArgbColor((alpha << 24) | 0x010203);

NormalizedColor _floatColor(double alpha) =>
    NormalizedColor(r: 1, g: 2, b: 3, a: alpha);

NormalizedColor _css(double alpha) => parseCssColor('rgba(1, 2, 3, $alpha)');

PropertySnapshot _snapshot(
  String platform,
  String field,
  NormalizedColor color,
) => PropertySnapshot(
  key: 'alpha-source-contract',
  platform: platform,
  probeRole: 'root',
  color: field == 'color' ? color : null,
  backgroundColor: field == 'backgroundColor' ? color : null,
  borderWidthPx: field == 'borderColor' ? 1 : null,
  borderColor: field == 'borderColor' ? color : null,
  boxShadow: field == 'boxShadow'
      ? [
          BoxShadowLayer(
            offsetX: 0,
            offsetY: 1,
            blur: 2,
            spread: 0,
            color: color,
          ),
        ]
      : null,
);

PropertySnapshot _opacity(String platform, double? value) => PropertySnapshot(
  key: 'alpha-source-contract',
  platform: platform,
  probeRole: 'root',
  opacity: value == null ? null : roundAlpha(value),
);

FieldDivergence _field(PropertyDiffResult result, String field) =>
    result.fields.singleWhere((entry) => entry.field == field);

void main() {
  for (final field in [
    'color',
    'backgroundColor',
    'borderColor',
    'boxShadow',
  ]) {
    test('one alpha byte remains a difference in $field', () {
      final result = comparePropertySnapshots(
        flutter: _snapshot('flutter', field, _nativeByte(6)),
        web: _snapshot('web', field, _css(7 / 255)),
      );
      expect(_field(result, field).matches, isFalse);
    });
  }

  test('same Native platform does not absorb adjacent alpha bytes', () {
    final result = comparePropertySnapshots(
      flutter: _snapshot('flutter', 'color', _nativeByte(6)),
      web: _snapshot('flutter', 'color', _nativeByte(7)),
      reconcilePlatforms: false,
    );
    expect(_field(result, 'color').matches, isFalse);
  });

  test('same Web platform does not absorb a rounded colour difference', () {
    final result = comparePropertySnapshots(
      flutter: _snapshot('web', 'color', _css(6 / 255)),
      web: _snapshot('web', 'color', _css(7 / 255)),
      reconcilePlatforms: false,
    );
    expect(_field(result, 'color').matches, isFalse);
  });

  test('continuous opacity .300 and .303 remain different', () {
    final result = comparePropertySnapshots(
      flutter: _opacity('flutter', .300),
      web: _opacity('web', .303),
    );
    expect(_field(result, 'opacity').matches, isFalse);
  });

  test('continuous same-platform opacity does not get colour allowance', () {
    final result = comparePropertySnapshots(
      flutter: _opacity('flutter', .300),
      web: _opacity('flutter', .303),
      reconcilePlatforms: false,
    );
    expect(_field(result, 'opacity').matches, isFalse);
  });

  test('expected continuous opacity attributes the different Web value', () {
    final result = comparePropertySnapshots(
      flutter: _opacity('flutter', .300),
      web: _opacity('web', .303),
      expected: _opacity('token', .300),
    );
    expect(
      _field(result, 'opacity').tokenDivergence,
      TokenDivergence.webDiverges,
    );
  });

  test('expected authored colour attributes the adjacent Web byte', () {
    final result = comparePropertySnapshots(
      flutter: _snapshot('flutter', 'color', _nativeByte(6)),
      web: _snapshot('web', 'color', _css(7 / 255)),
      expected: _snapshot('token', 'color', _css(6 / 255)),
    );
    expect(
      _field(result, 'color').tokenDivergence,
      TokenDivergence.webDiverges,
    );
  });

  test('current typed .3 alpha matches the Web observation', () {
    final result = comparePropertySnapshots(
      flutter: _snapshot('flutter', 'color', _floatColor(.3)),
      web: _snapshot('web', 'color', _css(.3)),
    );
    expect(_field(result, 'color').matches, isTrue);
  });

  test('current typed .7 alpha matches the Web observation', () {
    final result = comparePropertySnapshots(
      flutter: _snapshot('flutter', 'color', _floatColor(.7)),
      web: _snapshot('web', 'color', _css(.7)),
    );
    expect(_field(result, 'color').matches, isTrue);
  });

  for (final alpha in [0, 255]) {
    test('matching endpoint byte$alpha is preserved', () {
      final result = comparePropertySnapshots(
        flutter: _snapshot('flutter', 'color', _nativeByte(alpha)),
        web: _snapshot('web', 'color', _css(alpha / 255)),
      );
      expect(_field(result, 'color').matches, isTrue);
    });
  }

  test('zero and first positive alpha byte remain different', () {
    final result = comparePropertySnapshots(
      flutter: _snapshot('flutter', 'color', _nativeByte(0)),
      web: _snapshot('web', 'color', _css(1 / 255)),
    );
    expect(_field(result, 'color').matches, isFalse);
  });

  test('nearby decimal outside the Native byte cell is not equivalent', () {
    final result = comparePropertySnapshots(
      flutter: _snapshot('flutter', 'color', _nativeByte(6)),
      web: _snapshot('web', 'color', _css(.026)),
    );
    expect(_field(result, 'color').matches, isFalse);
  });

  test('stored alpha values are not inferred as a byte cell', () {
    final result = comparePropertySnapshots(
      flutter: _snapshot('flutter', 'color', _nativeByte(6)),
      web: _snapshot('web', 'color', _css(.025)),
    );
    expect(_field(result, 'color').matches, isFalse);
  });

  test('the existing shared rounding absorbs finer arithmetic noise', () {
    final result = comparePropertySnapshots(
      flutter: _opacity('flutter', .3),
      web: _opacity('web', .30000000000000004),
    );
    expect(_field(result, 'opacity').matches, isTrue);
  });

  test('same Native byte remains identical in same-platform comparison', () {
    final result = comparePropertySnapshots(
      flutter: _snapshot('flutter', 'color', _nativeByte(6)),
      web: _snapshot('flutter', 'color', _nativeByte(6)),
      reconcilePlatforms: false,
    );
    expect(_field(result, 'color').matches, isTrue);
  });

  test('unmeasured opacity is not a measured zero', () {
    final result = comparePropertySnapshots(
      flutter: _opacity('flutter', null),
      web: _opacity('web', 0),
    );
    expect(_field(result, 'opacity').matches, isFalse);
  });

  test('two unmeasured opacity values preserve their existing status', () {
    final result = comparePropertySnapshots(
      flutter: _opacity('flutter', null),
      web: _opacity('web', null),
    );
    expect(_field(result, 'opacity').matches, isTrue);
  });
  test('stored float differences are not inferred as old byte losses', () {
    for (final pair in [(.302, .3), (.702, .7)]) {
      final result = comparePropertySnapshots(
        flutter: _snapshot('flutter', 'color', _floatColor(pair.$1)),
        web: _snapshot('web', 'color', _css(pair.$2)),
      );
      expect(_field(result, 'color').matches, isFalse);
    }
  });

  test('all distinct adjacent shared-round3 opacity values differ', () {
    final scale = BigInt.from(10).pow(kAlphaRoundingDecimals).toInt();
    for (var index = 0; index < scale; index++) {
      final result = comparePropertySnapshots(
        flutter: _opacity('flutter', index / scale),
        web: _opacity('web', (index + 1) / scale),
      );
      expect(_field(result, 'opacity').matches, isFalse);
    }
  });

  test('off-grid stored JSON is not coerced into an alpha byte', () {
    final value = NormalizedColor.fromJson(const {
      'r': 1,
      'g': 2,
      'b': 3,
      'a': .3016,
    });
    final result = comparePropertySnapshots(
      flutter: _snapshot('flutter', 'color', value),
      web: _snapshot('web', 'color', _css(.3)),
    );
    expect(value.a, .3016);
    expect(_field(result, 'color').matches, isFalse);
    expect(_field(result, 'color').flutterDescription, contains('0.3016'));
  });

  test('a stored float point3 is valid without byte provenance', () {
    final value = NormalizedColor.fromJson(const {
      'r': 1,
      'g': 2,
      'b': 3,
      'a': .3,
    });
    final result = comparePropertySnapshots(
      flutter: _snapshot('flutter', 'color', value),
      web: _snapshot('web', 'color', _css(.3)),
    );
    expect(value.a, .3);
    expect(_field(result, 'color').matches, isTrue);
  });

  test('expected target exposes a different actual Native float', () {
    final result = comparePropertySnapshots(
      flutter: _snapshot('flutter', 'color', _floatColor(.302)),
      web: _snapshot('web', 'color', _css(.3)),
      expected: _snapshot('token', 'color', _floatColor(.3)),
    );
    expect(
      _field(result, 'color').tokenDivergence,
      TokenDivergence.flutterDiverges,
    );
  });

  test('RGB comparison remains exact with an equal alpha', () {
    final result = comparePropertySnapshots(
      flutter: _snapshot('flutter', 'color', _floatColor(.3)),
      web: _snapshot(
        'web',
        'color',
        NormalizedColor(r: 2, g: 2, b: 3, a: .3),
      ),
    );
    expect(_field(result, 'color').matches, isFalse);
  });
}
