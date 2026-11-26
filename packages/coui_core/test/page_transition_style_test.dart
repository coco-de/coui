import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

const _kFast = Duration(milliseconds: CoreDuration.fast);
const _kSlow = Duration(milliseconds: CoreDuration.slow);

/// One style per field, each stating only that field.
const _kEachField = {
  'enterDuration': CorePageTransitionStyle(enterDuration: _kSlow),
  'exitDuration': CorePageTransitionStyle(exitDuration: _kSlow),
  'enterCurve': CorePageTransitionStyle(enterCurve: CoreEasing.move),
  'exitCurve': CorePageTransitionStyle(exitCurve: CoreEasing.move),
  'slideDistance': CorePageTransitionStyle(slideDistance: CoreSpace.space48),
  'usePlatformDurations': CorePageTransitionStyle(usePlatformDurations: false),
  'animateAppBarTitle': CorePageTransitionStyle(animateAppBarTitle: false),
};

void main() {
  group('CorePageTransitionStyle', () {
    test('the design-system defaults: the arrival is longer than the '
        'departure, each on its own curve', () {
      expect(
        CorePageTransitionStyle.defaultEnterDuration,
        const Duration(milliseconds: CoreDuration.slow),
      );
      expect(
        CorePageTransitionStyle.defaultExitDuration,
        const Duration(milliseconds: CoreDuration.moderate),
      );
      expect(CorePageTransitionStyle.defaultEnterCurve, CoreEasing.enter);
      expect(CorePageTransitionStyle.defaultExitCurve, CoreEasing.exit);
      expect(CorePageTransitionStyle.defaultSlideDistance, CoreSpace.space16);
    });

    test('both defaults stay in the transition tier, so a reduced-motion '
        'request reaches them', () {
      expect(
        CoreReducedMotion.isTransitionMotion(
          CorePageTransitionStyle.defaultEnterDuration,
        ),
        isTrue,
      );
      expect(
        CoreReducedMotion.isTransitionMotion(
          CorePageTransitionStyle.defaultExitDuration,
        ),
        isTrue,
      );
    });

    for (final MapEntry(key: field, value: stated) in _kEachField.entries) {
      test('merge takes $field from other and keeps the rest', () {
        const base = CorePageTransitionStyle(
          enterDuration: _kFast,
          exitDuration: _kFast,
          enterCurve: CoreEasing.linear,
          exitCurve: CoreEasing.linear,
          slideDistance: CoreSpace.space8,
          usePlatformDurations: true,
          animateAppBarTitle: true,
        );
        final merged = base.merge(stated);

        expect(merged, isNot(base));
        expect(merged.merge(base), base);
        expect(base.merge(const CorePageTransitionStyle()), base);
      });

      test('equality and hashCode see $field', () {
        // A field missing from `==` makes a theme swap compare equal to
        // what it replaces, so the new value is computed and nothing
        // repaints.
        expect(stated, isNot(const CorePageTransitionStyle()));
        expect(
          stated.hashCode,
          isNot(const CorePageTransitionStyle().hashCode),
        );
      });
    }

    test('copyWith changes one field and keeps the others', () {
      const base = CorePageTransitionStyle(
        enterDuration: _kFast,
        slideDistance: CoreSpace.space8,
        usePlatformDurations: false,
        animateAppBarTitle: false,
      );
      final copy = base.copyWith(exitDuration: _kSlow);

      expect(copy.exitDuration, _kSlow);
      expect(copy.enterDuration, _kFast);
      expect(copy.slideDistance, CoreSpace.space8);
      expect(copy.usePlatformDurations, isFalse);
      expect(copy.animateAppBarTitle, isFalse);
      expect(base.copyWith(), base);
    });

    test('the component theme compares its style', () {
      expect(
        const CorePageTransitionTheme(
          style: CorePageTransitionStyle(enterDuration: _kSlow),
        ),
        isNot(const CorePageTransitionTheme()),
      );
      expect(
        const CoreComponentTheme(
          pageTransition: CorePageTransitionTheme(
            style: CorePageTransitionStyle(enterDuration: _kSlow),
          ),
        ),
        isNot(const CoreComponentTheme()),
      );
    });
  });
}
