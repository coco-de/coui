import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

/// [CoreCastMotion.reverse]'s Web twin of `button_cast_motion_test.dart`
/// (Flutter) — the resolver is theme-free (`core/theme-axis-composition
/// .md`'s Web EMIT rule), so it emits the same `var()` references
/// regardless of which style is active; `control_shadow_reverse_test
/// .dart` covers what those references resolve *to* per style.
class _ContextCapture extends StatelessComponent {
  const _ContextCapture(this.onBuild);

  final void Function(BuildContext context) onBuild;

  @override
  Component build(BuildContext context) {
    onBuild(context);
    return div([]);
  }
}

BuildContext _themedContext(ComponentTester tester) {
  late BuildContext context;
  pumpWithTheme(tester, _ContextCapture((c) => context = c));
  return context;
}

ResolvedButton _resolve(
  BuildContext context, {
  CoreButtonVariant variant = .primary,
  required CoreButtonStyle style,
}) => resolveButton(
  context,
  variant: variant,
  size: .md,
  shape: .rectangle,
  expanded: false,
  buttonStyle: style,
);

void main() {
  group('reverse — injected cast (no authored shadow)', () {
    testComponents(
      'rest is the ghost twin, not the literal none — so the transition '
      'to the full-alpha value at engage stays a pure colour '
      'interpolation',
      (tester) async {
        final context = _themedContext(tester);
        final props = _resolve(
          context,
          style: const CoreButtonStyle(castMotion: .reverse),
        ).root.inlineStyles!.properties;

        expect(props['box-shadow'], kControlShadowGhostVar);
        expect(
          props['box-shadow'],
          isNot('none'),
          reason:
              'a literal none has no shape for the browser to pad the '
              'engage value against — risking the mismatched-layer-count '
              'flash process/verify.md §7-24 records',
        );
      },
    );

    testComponents(
      'engage grows the real cast and travels the negated diagonal — '
      'this element\'s own inline declarations outrank the inherited '
      'style-scoped ones',
      (tester) async {
        final context = _themedContext(tester);
        final props = _resolve(
          context,
          style: const CoreButtonStyle(castMotion: .reverse),
        ).root.inlineStyles!.properties;

        expect(
          props['--coui-control-shadow-press'],
          'var(--coui-control-shadow, none)',
        );
        expect(
          props['--coui-control-shadow-offset-x'],
          'var(--coui-control-shadow-offset-x-reverse, 0px)',
        );
        expect(
          props['--coui-control-shadow-offset-y'],
          'var(--coui-control-shadow-offset-y-reverse, 0px)',
        );
      },
    );

    testComponents(
      'a fill-less variant keeps rest at literal none and states no '
      'engage override — there is no box to grow a cast into either way',
      (tester) async {
        final context = _themedContext(tester);
        final props = _resolve(
          context,
          variant: .ghost,
          style: const CoreButtonStyle(castMotion: .reverse),
        ).root.inlineStyles!.properties;

        expect(props['box-shadow'], 'none');
        expect(props.containsKey('--coui-control-shadow-press'), isFalse);
        expect(props['--coui-control-shadow-offset-x'], '0px');
        expect(props['--coui-control-shadow-offset-y'], '0px');
      },
    );
  });

  group('reverse — a stated shadow outranks the motion axis', () {
    testComponents(
      'an authored boxShadow renders identically whether castMotion asks '
      'for reverse or says nothing — the axis only redirects what the '
      'style injects, never what the caller wrote down',
      (tester) async {
        final context = _themedContext(tester);
        final plain = _resolve(
          context,
          variant: .ghost,
          style: const CoreButtonStyle(boxShadow: CoreShadow.md),
        ).root.inlineStyles!.properties;
        final reversed = _resolve(
          context,
          variant: .ghost,
          style: const CoreButtonStyle(
            boxShadow: CoreShadow.md,
            castMotion: .reverse,
          ),
        ).root.inlineStyles!.properties;

        expect(reversed['box-shadow'], plain['box-shadow']);
        expect(
          reversed.containsKey('--coui-control-shadow-press'),
          isFalse,
          reason: 'reverse never reaches an authored shadow',
        );
      },
    );
  });
}
