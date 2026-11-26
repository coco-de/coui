import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

const _kFast = Duration(milliseconds: CoreDuration.fast);

void main() {
  group('CoreHiddenStyle.transitionCurve', () {
    test('merge takes the non-null curve from other', () {
      const base = CoreHiddenStyle(transitionDuration: _kFast);
      const patch = CoreHiddenStyle(transitionCurve: CoreEasing.easeOutBack);

      final merged = base.merge(patch);
      expect(merged.transitionCurve, equals(CoreEasing.easeOutBack));
      expect(merged.transitionDuration, equals(_kFast));
    });

    test('merge keeps this curve when other is silent', () {
      const base = CoreHiddenStyle(transitionCurve: CoreEasing.easeOutBack);

      expect(
        base.merge(const CoreHiddenStyle()).transitionCurve,
        equals(CoreEasing.easeOutBack),
      );
    });

    test('copyWith preserves the curve when not specified', () {
      const base = CoreHiddenStyle(transitionCurve: CoreEasing.easeOutBack);

      expect(
        base.copyWith(transitionDuration: _kFast).transitionCurve,
        equals(CoreEasing.easeOutBack),
      );
    });

    test('equality compares the curve', () {
      // Why this matters beyond tidiness: a theme swap builds a new style and
      // the framework decides whether to rebuild by comparing values. A field
      // left out of `==` makes the new style compare equal to the old one, so
      // the curve resolves correctly and the screen never repaints.
      const a = CoreHiddenStyle(transitionCurve: CoreEasing.easeOutBack);
      const b = CoreHiddenStyle(transitionCurve: CoreEasing.easeInQuad);

      expect(a, isNot(equals(b)));
      expect(a.hashCode, isNot(equals(b.hashCode)));
      expect(
        a,
        equals(const CoreHiddenStyle(transitionCurve: CoreEasing.easeOutBack)),
      );
    });

    test('the design-system default is the standard alias', () {
      // Components pick from the alias tier so one global motion vocabulary
      // covers them; `standard` is movement between two on-screen states.
      expect(
        CoreHiddenStyle.defaultTransitionCurve,
        equals(CoreEasing.move),
      );
    });
  });

  group('CoreHiddenTheme.curve', () {
    test('equality compares the curve', () {
      const a = CoreHiddenTheme(curve: CoreEasing.easeOutBack);
      const b = CoreHiddenTheme(curve: CoreEasing.easeInQuad);

      expect(a, isNot(equals(b)));
      expect(a.hashCode, isNot(equals(b.hashCode)));
      expect(a, equals(const CoreHiddenTheme(curve: CoreEasing.easeOutBack)));
    });
  });
}
