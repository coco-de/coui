// The tint of an OutlinedContainer's cast, and the two ways it can be stated.
//
// A token follows the mode: the browser resolves `--coui-shadow`, which is
// white in dark mode, and the stack goes out as the `--shadow-*` variable a
// surface style can bend. A raw colour pins the cast, so there is no variable
// to point at: the stack goes out as literal layers in that colour.
import 'package:coui_web/coui_web.dart';
import 'package:coui_web/src/components/infra/outlined_container/outlined_container_style.dart';
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

String _boxShadow(
  ComponentTester tester,
  CoreOutlinedContainerStyle containerStyle,
) {
  final r = resolveOutlinedContainer(
    context: _themedContext(tester),
    containerStyle: containerStyle,
  );
  return r.root.inlineStyles!.properties['box-shadow']!;
}

void main() {
  const pinned = CoreColor(0xFF000000);

  group('OutlinedContainer — the shadow base colour', () {
    testComponents('the default points at the shadow variable', (
      tester,
    ) async {
      final explicit = _boxShadow(
        tester,
        const CoreOutlinedContainerStyle(boxShadow: CoreShadow.xl),
      );
      expect(explicit, startsWith('var(--shadow-xl)'));

      final preset = _boxShadow(
        tester,
        const CoreOutlinedContainerStyle(elevation: .medium),
      );
      expect(preset, startsWith('var(--shadow-md)'));
    });

    testComponents('a raw colour pins an explicit stack as literal layers', (
      tester,
    ) async {
      final css = _boxShadow(
        tester,
        const CoreOutlinedContainerStyle(
          boxShadow: CoreShadow.xl,
          shadowBaseColor: pinned,
        ),
      );

      // No variable: nothing a mode (or a style) turns over is in the value
      // — only the dark scope's strength, which every cast takes.
      expect(css, isNot(contains('--shadow-')));
      expect(css, isNot(contains('var(--coui-shadow)')));
      // The stack's one layer, tinted by the stated colour at its alpha.
      expect(
        css,
        contains(
          '0.0rem 1.5rem 4.0rem 0.0rem '
          'color-mix(in srgb, ${pinned.toRgba()} '
          'calc(12.5% * var(--coui-shadow-strength, 1)), transparent)',
        ),
      );
    });

    testComponents('an unstrengthened stack leaves the dark strength out', (
      tester,
    ) async {
      // A raw base: the literal layers, at the alpha they state.
      final raw = _boxShadow(
        tester,
        const CoreOutlinedContainerStyle(
          boxShadow: CoreShadow.xl,
          shadowBaseColor: pinned,
          shadowStrengthens: false,
        ),
      );
      expect(raw, isNot(contains('--coui-shadow-strength')));
      expect(
        raw,
        startsWith(
          '0.0rem 1.5rem 4.0rem 0.0rem '
          'color-mix(in srgb, ${pinned.toRgba()} 12.5%, transparent)',
        ),
      );

      // The token base: `--shadow-*` carries the strength inside it, so a
      // pinned stack goes out as literal layers rather than the variable —
      // the explicit stack and the elevation preset alike.
      for (final style in const [
        CoreOutlinedContainerStyle(
          boxShadow: CoreShadow.xl,
          shadowStrengthens: false,
        ),
        CoreOutlinedContainerStyle(
          elevation: .medium,
          shadowStrengthens: false,
        ),
      ]) {
        final css = _boxShadow(tester, style);
        expect(css, isNot(contains('--shadow-')), reason: '$style');
        expect(css, isNot(contains('--coui-shadow-strength')));
        expect(css, contains('color-mix(in srgb, rgb(var(--coui-shadow))'));
      }
    });

    testComponents('it tints the elevation preset the same way', (
      tester,
    ) async {
      final css = _boxShadow(
        tester,
        const CoreOutlinedContainerStyle(
          elevation: .medium,
          shadowBaseColor: pinned,
        ),
      );
      expect(css, isNot(contains('--shadow-')));
      expect(css, contains('color-mix(in srgb, ${pinned.toRgba()}'));
    });

    testComponents('an empty stack stays empty whatever the base', (
      tester,
    ) async {
      final css = _boxShadow(
        tester,
        const CoreOutlinedContainerStyle(
          boxShadow: [],
          shadowBaseColor: pinned,
        ),
      );
      expect(css, isNot(contains('color-mix')));
    });
  });
}
