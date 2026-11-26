import 'package:test/test.dart';

import '../../src/model/probe_spec.dart';
import '../../src/model/property_field.dart';

void main() {
  group('ProbeSpec', () {
    test('rootProbeSpec scopes the selector to the matrix key', () {
      final spec = rootProbeSpec(
        key: 'card-default-light-defaultStyle',
        flutterClassName: 'Card',
      );
      expect(spec.role, 'root');
      expect(
        spec.webSelector,
        '[data-parity-key="card-default-light-defaultStyle"] > *',
      );
      expect(spec.flutterFinder, 'byType:Card');
      expect(spec.fields, PropertyField.all);
    });

    test('round-trips through JSON', () {
      final spec = rootProbeSpec(key: 'k', flutterClassName: 'Button');
      final decoded = ProbeSpec.fromJson(spec.toJson());
      expect(decoded, spec);
    });

    test('historical JSON does not invent a Native source contract', () {
      final json = rootProbeSpec(key: 'k', flutterClassName: 'Button').toJson()
        ..remove('nativeBoxSource');
      final decoded = ProbeSpec.fromJson(json);
      expect(decoded.nativeBoxSource, isNull);
      expect(decoded.toJson().containsKey('nativeBoxSource'), isFalse);
      expect(decoded.fields, PropertyField.all);
    });

    test('different source contracts remain distinct probe declarations', () {
      final json = rootProbeSpec(key: 'k', flutterClassName: 'Button').toJson();
      final original = ProbeSpec.fromJson(json);
      final different = ProbeSpec.fromJson({
        ...json,
        'nativeBoxSource': 'unsupported-future-version',
      });
      expect(different, isNot(original));
      expect(different.fields, original.fields);
      expect(different.flutterFinder, original.flutterFinder);
    });

    test('toJson emits field names sorted (stable diffs)', () {
      final json = rootProbeSpec(key: 'k', flutterClassName: 'Button').toJson();
      final fields = (json['fields']! as List).cast<String>();
      expect(fields, List.of(fields)..sort());
    });
  });
}
