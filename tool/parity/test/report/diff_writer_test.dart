import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:test/test.dart';

import '../../src/diff/comparator.dart';
import '../../src/model/property_snapshot.dart';
import '../../src/report/diff_writer.dart';

Uint8List _solidPng(int r, int g, int b) {
  final image = img.Image(width: 8, height: 8, numChannels: 4);
  for (final pixel in image) {
    pixel
      ..r = r
      ..g = g
      ..b = b
      ..a = 255;
  }
  return Uint8List.fromList(img.encodePng(image));
}

void main() {
  group('writePropertyDiffJson', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('coui-diff-writer-');
    });

    tearDown(() {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    test('writes structured field breakdown when property failed', () {
      final result = compareEntry(
        key: 'command-default-light-neoBrutalism',
        probeRole: 'root',
        signal: .property,
        flutterProperty: .new(
          key: 'k',
          platform: 'flutter',
          probeRole: 'root',
          fontWeight: 600,
        ),
        webProperty: .new(
          key: 'k',
          platform: 'web',
          probeRole: 'root',
          fontWeight: 400,
        ),
      );

      writePropertyDiffJson(result, tempDir);

      final file = File(
        '${tempDir.path}/command-default-light-neoBrutalism.root.property.diff.json',
      );
      expect(file.existsSync(), isTrue);

      final decoded =
          jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
      final failures = decoded['failures']! as List;
      expect(
        failures,
        contains(
          predicate<Object?>(
            (f) =>
                f is Map &&
                f['field'] == 'fontWeight' &&
                f['flutter'] == '600' &&
                f['web'] == '400',
          ),
        ),
      );
    });

    test('writes nothing when property passed', () {
      final result = compareEntry(
        key: 'k',
        probeRole: 'root',
        signal: .property,
        flutterProperty: .new(
          key: 'k',
          platform: 'flutter',
          probeRole: 'root',
        ),
        webProperty: .new(key: 'k', platform: 'web', probeRole: 'root'),
      );

      writePropertyDiffJson(result, tempDir);

      expect(tempDir.listSync(), isEmpty);
    });
  });

  group('writeComparisonDiffImages', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('coui-diff-writer-');
    });

    tearDown(() {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    test('writes a PNG per failing pixel check, named by label', () {
      final result = compareEntry(
        key: 'k',
        probeRole: 'root',
        signal: .pixel,
        flutterPng: _solidPng(255, 0, 0),
        flutterBaselinePng: _solidPng(0, 0, 255),
        webPng: _solidPng(255, 0, 0),
        pixelModes: {.regression},
      );

      writeComparisonDiffImages(result, tempDir);

      expect(
        File('${tempDir.path}/k.root.flutter-regression.diff.png').existsSync(),
        isTrue,
      );
    });

    test('writes nothing when nothing failed', () {
      final result = compareEntry(
        key: 'k',
        probeRole: 'root',
        signal: .pixel,
        flutterPng: _solidPng(255, 0, 0),
        webPng: _solidPng(255, 0, 0),
        pixelModes: {.regression},
      );

      writeComparisonDiffImages(result, tempDir);

      expect(tempDir.listSync(), isEmpty);
    });
  });
}
