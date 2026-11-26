// SwitchField's defaults — the toggle size it composes and the description
// it sets under the label. jaspr_test has no layout, so this reads the
// declarations the browser lays the row out from.
import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

Iterable<DomComponent> _doms() => find
    .byType(DomComponent)
    .evaluate()
    .map((e) => e.component as DomComponent);

/// The toggle's track — the piece marked out of the a11y tree.
DomComponent _track() =>
    _doms().singleWhere((c) => c.attributes?['aria-hidden'] == 'true');

Toggle _toggle() => find.byType(Toggle).evaluate().single.component as Toggle;

/// The element that wears the description role (`labelSmall`) — the label
/// wears `labelLarge`, so this one is the description alone.
DomComponent _description() => _doms().singleWhere(
  (c) => (c.classes ?? '')
      .split(' ')
      .contains(
        'text-${CoreTextStyles.labelSmall.name}',
      ),
);

/// Every typography role class a DOM element in the field wears.
Set<String> _roleClasses() => {
  for (final element in _doms())
    for (final name in (element.classes ?? '').split(' '))
      if (name.startsWith('text-label-') || name.startsWith('text-body-')) name,
};

void main() {
  group('SwitchField toggle size', () {
    testComponents('composes the lg toggle by default — a 40 × 24 track', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        SwitchField(label: 'Alerts', value: true, onChanged: (_) {}),
      );

      final lg = CoreToggleStyle.sizeDefaults(CoreSwitchFieldStyle.defaultSize);
      expect(CoreSwitchFieldStyle.defaultSize, CoreComponentSize.lg);
      final raw = _track().styles?.properties ?? const {};
      expect(raw['width'], '${lg.trackWidth! / kRemDivisor}rem');
      expect(raw['height'], '${lg.trackHeight! / kRemDivisor}rem');
      expect(raw['width'], '2.5rem');
      expect(raw['height'], '1.5rem');
    });

    testComponents('a size the app states wins over the default', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        SwitchField(
          label: 'Alerts',
          value: true,
          onChanged: (_) {},
          switchFieldStyle: const CoreSwitchFieldStyle(
            size: CoreComponentSize.md,
          ),
        ),
      );

      final raw = _track().styles?.properties ?? const {};
      expect(raw['width'], '2.25rem');
      expect(raw['height'], '1.25rem');
    });
  });

  group('SwitchField track colour', () {
    // Read the actual composed child's public slot. CSS may serialize this
    // base through a state property; real computed paint is covered by the
    // composed-control browser regression.

    testComponents('the composed off track is the highest container step', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        SwitchField(label: 'Alerts', onChanged: (_) {}),
      );

      expect(
        _toggle().toggleStyle?.trackInactiveColor,
        const CoreColor.token(CoreColors.surfaceContainerHighest),
      );
      expect(
        _track().styles?.properties['--coui-surface-rgb'],
        'var(--coui-${CoreColors.surfaceContainerHighest.name})',
      );
      // The negative control: the step below, `surfaceContainer`, must not be
      // what matched.
      expect(
        _toggle().toggleStyle?.trackInactiveColor,
        isNot(const CoreColor.token(CoreColors.surfaceContainer)),
      );
      expect(_toggle().value, isFalse);
    });

    testComponents('the composed on track is primary', (tester) async {
      pumpWithTheme(
        tester,
        SwitchField(label: 'Alerts', value: true, onChanged: (_) {}),
      );

      expect(
        _toggle().toggleStyle?.trackActiveColor,
        const CoreColor.token(CoreColors.primary),
      );
      expect(_toggle().value, isTrue);
    });
  });

  group('SwitchField description', () {
    // The label is `labelLarge`; the description is `labelSmall`, not
    // `bodySmall`.
    void expectDescriptionIsLabelSmall() {
      final roles = _roleClasses();
      expect(
        roles,
        containsAll([
          'text-${CoreTextStyles.labelLarge.name}',
          'text-${CoreTextStyles.labelSmall.name}',
        ]),
      );
      expect(roles, isNot(contains('text-${CoreTextStyles.bodySmall.name}')));
    }

    testComponents('reads as labelSmall — enabled', (tester) async {
      pumpWithTheme(
        tester,
        SwitchField(
          label: 'Alerts',
          description: 'Arrival notices',
          onChanged: (_) {},
        ),
      );

      expectDescriptionIsLabelSmall();
    });

    // The description is the subtle ink — one step under the label's own
    // muted tone — resting and disabled alike.
    testComponents('is the subtle ink, enabled and disabled', (tester) async {
      for (final enabled in [true, false]) {
        pumpWithTheme(
          tester,
          SwitchField(
            label: 'Alerts',
            description: 'Arrival notices',
            onChanged: (_) {},
            enabled: enabled,
          ),
        );

        final classes = (_description().classes ?? '').split(' ');
        expect(
          classes,
          contains('text-${CoreColors.onSurfaceSubtle.name}'),
          reason: 'enabled: $enabled',
        );
        // The negative control: the description is not the label's
        // `onSurfaceVariant`.
        expect(
          classes,
          isNot(contains('text-${CoreColors.onSurfaceVariant.name}')),
          reason: 'enabled: $enabled',
        );
      }
    });

    testComponents('reads as labelSmall — disabled', (tester) async {
      pumpWithTheme(
        tester,
        SwitchField(
          label: 'Alerts',
          description: 'Arrival notices',
          enabled: false,
        ),
      );

      expectDescriptionIsLabelSmall();
    });
  });

  group('SwitchField enabled follows the callback', () {
    // The root `Clickable` is the one element that carries the row's state to
    // the browser: `aria-disabled` is what a screen reader reads, and the
    // track's class is what a sighted reader sees.
    DomComponent clickableRoot() => _doms().firstWhere(
      (c) =>
          c.attributes?['role'] == 'button' ||
          c.attributes?['aria-disabled'] != null ||
          c.attributes?['tabindex'] != null,
    );

    testComponents('a field nobody listens to reads as disabled', (
      tester,
    ) async {
      pumpWithTheme(tester, SwitchField(label: 'Alerts', value: true));

      expect(clickableRoot().attributes?['aria-disabled'], 'true');
    });

    testComponents('a field with a callback reads as enabled', (tester) async {
      pumpWithTheme(
        tester,
        SwitchField(label: 'Alerts', value: true, onChanged: (_) {}),
      );

      expect(clickableRoot().attributes?['aria-disabled'], isNot('true'));
    });

    testComponents('what the app states still wins over the callback', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        SwitchField(label: 'Alerts', value: true, enabled: true),
      );

      expect(clickableRoot().attributes?['aria-disabled'], isNot('true'));
    });

    testComponents('and is drawn like a field that was told to be disabled', (
      tester,
    ) async {
      pumpWithTheme(tester, SwitchField(label: 'Alerts', value: true));
      final derived = _track().classes;

      pumpWithTheme(
        tester,
        SwitchField(
          label: 'Alerts',
          value: true,
          onChanged: (_) {},
          enabled: false,
        ),
      );
      final told = _track().classes;

      pumpWithTheme(
        tester,
        SwitchField(label: 'Alerts', value: true, onChanged: (_) {}),
      );
      final live = _track().classes;

      // The third reading is the negative control: a derived field drawn as a
      // live one would equal `live`, not `told`.
      expect(derived, told);
      expect(derived, isNot(live));
    });
  });
}
