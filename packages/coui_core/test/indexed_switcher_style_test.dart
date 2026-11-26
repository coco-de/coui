import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

const _kFast = Duration(milliseconds: CoreDuration.fast);
const _kSlow = Duration(milliseconds: CoreDuration.slow);

/// One style per field, each stating only that field.
const _kEachField = {
  'exitDuration': CoreIndexedSwitcherStyle(exitDuration: _kSlow),
  'enterDuration': CoreIndexedSwitcherStyle(enterDuration: _kSlow),
  'exitCurve': CoreIndexedSwitcherStyle(exitCurve: CoreEasing.move),
  'enterCurve': CoreIndexedSwitcherStyle(enterCurve: CoreEasing.move),
};

void main() {
  group('CoreIndexedSwitcherStyle', () {
    test('the design-system defaults: a short fade-out, then the fade-in, '
        'the whole switch one moderate step', () {
      expect(
        CoreIndexedSwitcherStyle.defaultExitDuration,
        const Duration(milliseconds: CoreDuration.instant),
      );
      expect(
        CoreIndexedSwitcherStyle.defaultEnterDuration,
        const Duration(milliseconds: CoreDuration.normal),
      );
      expect(
        CoreIndexedSwitcherStyle.defaultExitDuration +
            CoreIndexedSwitcherStyle.defaultEnterDuration,
        const Duration(milliseconds: CoreDuration.moderate),
      );
      expect(CoreIndexedSwitcherStyle.defaultExitCurve, CoreEasing.exit);
      expect(CoreIndexedSwitcherStyle.defaultEnterCurve, CoreEasing.enter);
    });

    test('both defaults stay in the transition tier, so a reduced-motion '
        'request reaches them', () {
      expect(
        CoreReducedMotion.isTransitionMotion(
          CoreIndexedSwitcherStyle.defaultExitDuration,
        ),
        isTrue,
      );
      expect(
        CoreReducedMotion.isTransitionMotion(
          CoreIndexedSwitcherStyle.defaultEnterDuration,
        ),
        isTrue,
      );
    });

    for (final MapEntry(key: field, value: stated) in _kEachField.entries) {
      test('merge takes $field from other and keeps the rest', () {
        const base = CoreIndexedSwitcherStyle(
          exitDuration: _kFast,
          enterDuration: _kFast,
          exitCurve: CoreEasing.linear,
          enterCurve: CoreEasing.linear,
        );
        final merged = base.merge(stated);

        expect(merged, isNot(base));
        expect(merged.merge(base), base);
        expect(base.merge(const CoreIndexedSwitcherStyle()), base);
      });

      test('equality and hashCode see $field', () {
        // A field missing from `==` makes a theme swap compare equal to
        // what it replaces, so the new value is computed and nothing
        // repaints.
        expect(stated, isNot(const CoreIndexedSwitcherStyle()));
        expect(
          stated.hashCode,
          isNot(const CoreIndexedSwitcherStyle().hashCode),
        );
      });
    }

    test('copyWith changes one field and keeps the others', () {
      const base = CoreIndexedSwitcherStyle(
        exitDuration: _kFast,
        enterCurve: CoreEasing.linear,
      );
      final copy = base.copyWith(enterDuration: _kSlow);

      expect(copy.enterDuration, _kSlow);
      expect(copy.exitDuration, _kFast);
      expect(copy.enterCurve, CoreEasing.linear);
      expect(base.copyWith(), base);
    });

    test('the component theme compares its style', () {
      expect(
        const CoreIndexedSwitcherTheme(
          style: CoreIndexedSwitcherStyle(enterDuration: _kSlow),
        ),
        isNot(const CoreIndexedSwitcherTheme()),
      );
      expect(
        const CoreComponentTheme(
          indexedSwitcher: CoreIndexedSwitcherTheme(
            style: CoreIndexedSwitcherStyle(enterDuration: _kSlow),
          ),
        ),
        isNot(const CoreComponentTheme()),
      );
    });
  });
}
