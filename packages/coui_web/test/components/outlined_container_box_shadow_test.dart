import 'package:coui_core/coui_core.dart';
import 'package:coui_web/coui_web.dart';
import 'package:test/test.dart';

const List<CoreShadowLayer> _hardOffset = [
  (
    offsetX: 4.0,
    offsetY: 4.0,
    blurRadius: 0.0,
    spreadRadius: 0.0,
    opacity: 1.0,
    inset: false,
  ),
];

const List<CoreShadowLayer> _dual = [
  (
    offsetX: -6.0,
    offsetY: -6.0,
    blurRadius: 12.0,
    spreadRadius: 0.0,
    opacity: 1.0,
    inset: false,
  ),
  (
    offsetX: 6.0,
    offsetY: 6.0,
    blurRadius: 12.0,
    spreadRadius: 0.0,
    opacity: 1.0,
    inset: false,
  ),
];

const List<CoreShadowLayer> _withInset = [
  (
    offsetX: 0.0,
    offsetY: 2.0,
    blurRadius: 6.0,
    spreadRadius: 0.0,
    opacity: 1.0,
    inset: false,
  ),
  (
    offsetX: 0.0,
    offsetY: -2.0,
    blurRadius: 4.0,
    spreadRadius: 0.0,
    opacity: 1.0,
    inset: true,
  ),
];

void main() {
  const base = 'rgb(var(--coui-shadow))';

  group('shadows the elevation enum cannot describe', () {
    test('a hard offset shadow keeps its zero blur', () {
      // Every prepared elevation stack is a soft ambient shadow, so this
      // look was not expressible at all before the slot existed.
      final css = _hardOffset.toValue(base: base);
      expect(css, contains('0.25rem 0.25rem 0.0rem'));
    });

    test('a dual stack keeps both directions and their order', () {
      final css = _dual.toValue(base: base);
      final up = css.indexOf('-0.375rem -0.375rem');
      final down = css.indexOf('0.375rem 0.375rem');
      expect(up, isNonNegative);
      expect(down, greaterThan(up));
    });

    test('an inset layer is marked as such', () {
      expect(_withInset.toValue(base: base), contains('inset '));
    });

    test('a layer without inset is not', () {
      expect(_hardOffset.toValue(base: base), isNot(contains('inset')));
    });
  });

  group('inset layers cannot silently disappear', () {
    test('a stack reports whether it has one', () {
      expect(_withInset.hasInset, isTrue);
      expect(_dual.hasInset, isFalse);
    });

    test('drop-shadow refuses an inset stack instead of skipping it', () {
      // This path used to filter inset layers out. A shadow that is simply
      // not drawn reads as "this preset has no hover", which is much
      // harder to notice than one drawn on the wrong geometry.
      expect(
        () => _withInset.toDropShadowValue(base: base),
        throwsA(isA<AssertionError>()),
      );
    });

    test('it still accepts a stack that has none', () {
      final css = _dual.toDropShadowValue(base: base);
      expect(css, contains('drop-shadow('));
      expect('drop-shadow('.allMatches(css).length, 2);
    });
  });

  group('value equality covers the new field', () {
    test('two stacks that differ compare unequal', () {
      // A field outside equality means the framework sees no change and
      // never rebuilds — the shadow would be computed and never painted.
      const a = CoreOutlinedContainerStyle(boxShadow: _hardOffset);
      const b = CoreOutlinedContainerStyle(boxShadow: _dual);
      expect(a, isNot(equals(b)));
      expect(a.hashCode, isNot(equals(b.hashCode)));
    });

    test('structurally identical stacks compare equal', () {
      // List equality in Dart is identity, so without an element-wise
      // comparison every rebuild would look like a change.
      const a = CoreOutlinedContainerStyle(boxShadow: _hardOffset);
      const b = CoreOutlinedContainerStyle(
        boxShadow: [
          (
            offsetX: 4.0,
            offsetY: 4.0,
            blurRadius: 0.0,
            spreadRadius: 0.0,
            opacity: 1.0,
            inset: false,
          ),
        ],
      );
      expect(a, equals(b));
    });

    test('merge and copyWith carry it', () {
      const empty = CoreOutlinedContainerStyle();
      const withShadow = CoreOutlinedContainerStyle(boxShadow: _dual);
      expect(empty.merge(withShadow).boxShadow, _dual);
      expect(empty.copyWith(boxShadow: _dual).boxShadow, _dual);
    });
  });
}
