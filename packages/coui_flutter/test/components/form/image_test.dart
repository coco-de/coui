import 'package:coui_core/coui_core.dart';
import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

const _kRotationZero = 0.0;
const _kRotation90 = 90.0;
const _kRotationNeg90 = -90.0;
const _kCropX = 10.0;
const _kCropY = 20.0;
const _kCropWidth = 90.0;
const _kCropHeight = 180.0;

void main() {
  group('CoreImageType', () {
    test('has all expected values', () {
      expect(
        CoreImageType.values,
        containsAll([
          CoreImageType.bmp,
          CoreImageType.gif,
          CoreImageType.ico,
          CoreImageType.jpg,
          CoreImageType.png,
          CoreImageType.pvr,
          CoreImageType.tga,
          CoreImageType.tiff,
        ]),
      );
    });

    test('has correct count of values', () {
      const expectedCount = 8;

      expect(CoreImageType.values.length, equals(expectedCount));
    });
  });

  group('ImageProperties', () {
    group('constructor', () {
      test('creates with default values', () {
        const props = ImageProperties();

        expect(props.cropX, equals(0));
        expect(props.cropY, equals(0));
        expect(props.cropWidth, equals(0));
        expect(props.cropHeight, equals(0));
        expect(props.rotation, equals(_kRotationZero));
        expect(props.flipHorizontal, isFalse);
        expect(props.flipVertical, isFalse);
      });

      test('creates with custom crop region', () {
        const props = ImageProperties(
          cropX: _kCropX,
          cropY: _kCropY,
          cropWidth: _kCropWidth,
          cropHeight: _kCropHeight,
        );

        expect(props.cropX, equals(_kCropX));
        expect(props.cropY, equals(_kCropY));
        expect(props.cropWidth, equals(_kCropWidth));
        expect(props.cropHeight, equals(_kCropHeight));
      });

      test('creates with custom rotation', () {
        const props = ImageProperties(rotation: _kRotation90);

        expect(props.rotation, equals(_kRotation90));
      });

      test('creates with flipHorizontal true', () {
        const props = ImageProperties(flipHorizontal: true);

        expect(props.flipHorizontal, isTrue);
      });

      test('creates with flipVertical true', () {
        const props = ImageProperties(flipVertical: true);

        expect(props.flipVertical, isTrue);
      });

      test('creates with all custom values', () {
        const props = ImageProperties(
          cropX: _kCropX,
          cropY: _kCropY,
          cropWidth: _kCropWidth,
          cropHeight: _kCropHeight,
          flipHorizontal: true,
          flipVertical: true,
          rotation: _kRotationNeg90,
        );

        expect(props.cropX, equals(_kCropX));
        expect(props.cropHeight, equals(_kCropHeight));
        expect(props.flipHorizontal, isTrue);
        expect(props.flipVertical, isTrue);
        expect(props.rotation, equals(_kRotationNeg90));
      });
    });

    group('equality', () {
      test('two identical instances are equal', () {
        const propsA = ImageProperties(rotation: _kRotation90);
        const propsB = ImageProperties(rotation: _kRotation90);

        expect(propsA, equals(propsB));
      });

      test('instances with different rotation are not equal', () {
        const propsA = ImageProperties(rotation: _kRotation90);
        const propsB = ImageProperties(rotation: _kRotationNeg90);

        expect(propsA, isNot(equals(propsB)));
      });

      test('instances with different crop region are not equal', () {
        const propsA = ImageProperties(cropX: _kCropX);
        const propsB = ImageProperties();

        expect(propsA, isNot(equals(propsB)));
      });

      test('instances with different flipHorizontal are not equal', () {
        const propsA = ImageProperties(flipHorizontal: true);
        const propsB = ImageProperties();

        expect(propsA, isNot(equals(propsB)));
      });

      test('instances with different flipVertical are not equal', () {
        const propsA = ImageProperties(flipVertical: true);
        const propsB = ImageProperties();

        expect(propsA, isNot(equals(propsB)));
      });

      test('not equal to non-ImageProperties object', () {
        const props = ImageProperties();

        // ignore: unrelated_type_equality_checks
        expect(props == 'not an ImageProperties', isFalse);
      });
    });

    group('hashCode', () {
      test('equal instances have same hashCode', () {
        const propsA = ImageProperties(rotation: _kRotation90);
        const propsB = ImageProperties(rotation: _kRotation90);

        expect(propsA.hashCode, equals(propsB.hashCode));
      });

      test('default instance hashCode is consistent', () {
        const propsA = ImageProperties();
        const propsB = ImageProperties();

        expect(propsA.hashCode, equals(propsB.hashCode));
      });
    });

    group('toString', () {
      test('includes class name', () {
        const props = ImageProperties();

        expect(props.toString(), contains('ImageProperties'));
      });

      test('includes cropX', () {
        const props = ImageProperties();

        expect(props.toString(), contains('cropX'));
      });

      test('includes rotation', () {
        const props = ImageProperties();

        expect(props.toString(), contains('rotation'));
      });

      test('includes flipHorizontal', () {
        const props = ImageProperties();

        expect(props.toString(), contains('flipHorizontal'));
      });

      test('includes flipVertical', () {
        const props = ImageProperties();

        expect(props.toString(), contains('flipVertical'));
      });
    });
  });
}
