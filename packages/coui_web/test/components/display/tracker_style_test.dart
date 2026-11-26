import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

class _ContextCapture extends StatelessComponent {
  const _ContextCapture(this.onBuild);

  final void Function(BuildContext context) onBuild;

  @override
  Component build(BuildContext context) {
    onBuild(context);
    return const div([]);
  }
}

BuildContext _themedContext(ComponentTester tester) {
  late BuildContext context;
  pumpWithTheme(tester, _ContextCapture((c) => context = c));
  return context;
}

const _kSegments = [
  CoreTrackerSegment(status: CoreTrackerStatus.fine),
  CoreTrackerSegment(status: CoreTrackerStatus.warning),
];

void main() {
  group(
    'Tracker endRadius reaches the radiusCap CSS-variable seat (#3771)',
    () {
      testComponents(
        'the default endRadius emits the "var(--coui-radius-2)" token '
        'variable, not a raw literal rem computation',
        (tester) async {
          final context = _themedContext(tester);
          final resolved = resolveTracker(
            context,
            segments: _kSegments,
            rounded: true,
          );

          // Before the fix `endRadiusRem` was computed as
          // `'${endRadius / kRemDivisor}rem'` — a raw literal that never
          // touches `var(--coui-radius-2)`, so a `radiusCap` surface style
          // (whose CSS override targets exactly that variable) had no
          // effect on this component at all.
          final first = resolved.segments[0].inlineStyles?.properties;
          expect(first?['border-top-left-radius'], 'var(--coui-radius-2)');
          expect(first?['border-bottom-left-radius'], 'var(--coui-radius-2)');

          final last = resolved.segments[1].inlineStyles?.properties;
          expect(last?['border-top-right-radius'], 'var(--coui-radius-2)');
          expect(last?['border-bottom-right-radius'], 'var(--coui-radius-2)');
        },
      );

      testComponents(
        'an arbitrary endRadius override still renders as a literal px '
        'value (no token step to route through a CSS variable)',
        (tester) async {
          final context = _themedContext(tester);
          // 13 is off the radius scale. This case used to pass `10`,
          // which reads as arbitrary and is not: `CoreRadius.radius10`
          // is a step, and it only emitted a literal because the
          // emitter's step list was missing ten of the nineteen. So the
          // value was testing the gap rather than the rule. The rule —
          // a value with no token step stays a literal — is unchanged
          // and is what this now asks with a value that really has none.
          const style = CoreTrackerStyle(endRadius: 13);
          final resolved = resolveTracker(
            context,
            segments: _kSegments,
            rounded: true,
            trackerStyle: style,
          );

          final first = resolved.segments[0].inlineStyles?.properties;
          expect(first?['border-top-left-radius'], '13.0px');
        },
      );

      testComponents(
        'a token endRadius override routes through its variable',
        (tester) async {
          // The other half, and the half that was missing: an override
          // that names a step must reach that step's variable, or a
          // surface style cannot move it. `radius10` is one of the ten
          // that silently emitted literals.
          final context = _themedContext(tester);
          const style = CoreTrackerStyle(endRadius: CoreRadius.radius10);
          final resolved = resolveTracker(
            context,
            segments: _kSegments,
            rounded: true,
            trackerStyle: style,
          );

          final first = resolved.segments[0].inlineStyles?.properties;
          expect(first?['border-top-left-radius'], 'var(--coui-radius-10)');
        },
      );
    },
  );

  group('Tracker redesign (#6467)', () {
    testComponents('fine is success at 40 %, warning at full colour', (
      tester,
    ) async {
      final resolved = resolveTracker(
        _themedContext(tester),
        segments: _kSegments,
        rounded: true,
      );
      expect(
        resolved.segments[0].className.split(' '),
        contains('bg-success/40'),
      );
      expect(resolved.segments[1].className.split(' '), contains('bg-warning'));
    });

    testComponents('segments sit 4 apart', (tester) async {
      final resolved = resolveTracker(
        _themedContext(tester),
        segments: _kSegments,
        rounded: true,
      );
      expect(
        resolved.root.inlineStyles?.properties['gap'],
        spaceCss(CoreSpace.space4),
      );
    });
  });
}
