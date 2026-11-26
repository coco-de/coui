import 'package:test/test.dart';

import '../../src/diff/property_diff.dart';
import '../../src/report/property_diff_codec.dart';

void main() {
  group('propertyDiffResultToJson/fromJson — round trip', () {
    test('preserves key/probeRole/every field, matching and failing alike', () {
      const result = PropertyDiffResult(
        key: 'card-outlined-light-neoBrutalism',
        probeRole: 'root',
        fields: const [
          FieldDivergence(
            field: 'fontWeight',
            matches: false,
            flutterDescription: '600',
            webDescription: '400',
            tokenDescription: '400',
            tokenDivergence: TokenDivergence.flutterDiverges,
          ),
          FieldDivergence(
            field: 'color',
            matches: true,
            flutterDescription: 'NormalizedColor(r:1, g:2, b:3, a:1.0)',
            webDescription: 'NormalizedColor(r:1, g:2, b:3, a:1.0)',
          ),
        ],
      );

      final decoded = propertyDiffResultFromJson(
        propertyDiffResultToJson(result),
      );

      expect(decoded.key, result.key);
      expect(decoded.probeRole, result.probeRole);
      expect(decoded.fields, hasLength(2));
      expect(decoded.failures, hasLength(1));
      expect(decoded.failures.single.field, 'fontWeight');
      expect(
        decoded.failures.single.tokenDivergence,
        TokenDivergence.flutterDiverges,
      );
      expect(decoded.fields.last.matches, isTrue);
      expect(decoded.fields.last.tokenDescription, isNull);
      expect(decoded.fields.last.tokenDivergence, TokenDivergence.notChecked);
    });

    test('round-trips a field with no token supplied', () {
      const field = FieldDivergence(
        field: 'borderWidthPx',
        matches: false,
        flutterDescription: '1.0',
        webDescription: '2.0',
      );

      final decoded = fieldDivergenceFromJson(fieldDivergenceToJson(field));

      expect(decoded.field, 'borderWidthPx');
      expect(decoded.matches, isFalse);
      expect(decoded.tokenDescription, isNull);
      expect(decoded.tokenDivergence, TokenDivergence.notChecked);
    });
  });
}
