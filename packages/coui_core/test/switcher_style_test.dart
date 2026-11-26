import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

const _kFast = Duration(milliseconds: CoreDuration.fast);

void main() {
  group('CoreSwitcherStyle.curve', () {
    test('merge takes the non-null curve from other', () {
      const base = CoreSwitcherStyle(duration: _kFast);
      const patch = CoreSwitcherStyle(curve: CoreEasing.easeOutBack);

      final merged = base.merge(patch);
      expect(merged.curve, equals(CoreEasing.easeOutBack));
      expect(merged.duration, equals(_kFast));
    });

    test('merge keeps this curve when other is silent', () {
      const base = CoreSwitcherStyle(curve: CoreEasing.easeOutBack);

      expect(
        base.merge(const CoreSwitcherStyle()).curve,
        equals(CoreEasing.easeOutBack),
      );
    });

    test('copyWith preserves the curve when not specified', () {
      const base = CoreSwitcherStyle(curve: CoreEasing.easeOutBack);

      expect(
        base.copyWith(duration: _kFast).curve,
        equals(CoreEasing.easeOutBack),
      );
    });

    test('equality compares the curve', () {
      // A field missing from `==` makes a theme swap compare equal to what it
      // replaces, so the new curve is computed and nothing repaints.
      const a = CoreSwitcherStyle(curve: CoreEasing.easeOutBack);
      const b = CoreSwitcherStyle(curve: CoreEasing.easeInQuad);

      expect(a, isNot(equals(b)));
      expect(a.hashCode, isNot(equals(b.hashCode)));
      expect(
        a,
        equals(const CoreSwitcherStyle(curve: CoreEasing.easeOutBack)),
      );
    });

    test('the design-system default is the standard alias', () {
      expect(CoreSwitcherStyle.defaultCurve, equals(CoreEasing.move));
    });
  });
}
