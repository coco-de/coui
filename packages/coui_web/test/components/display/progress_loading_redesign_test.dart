import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

class _ContextCapture extends StatelessComponent {
  const _ContextCapture(this.onBuild);

  final void Function(BuildContext context) onBuild;

  @override
  Component build(BuildContext context) {
    onBuild(context);
    return const Component.empty();
  }
}

BuildContext _themedContext(ComponentTester tester) {
  late BuildContext context;
  pumpWithTheme(tester, _ContextCapture((c) => context = c));
  return context;
}

String? _prop(WebElementChrome? chrome, String name) =>
    chrome?.inlineStyles?.properties[name];

double _number(String? css) =>
    double.parse(RegExp('[0-9.]+').firstMatch(css!)!.group(0)!);

void main() {
  group('RadialProgress size × tone', () {
    testComponents('the ring grows 32 → 48 → 80 → 128', (tester) async {
      final context = _themedContext(tester);
      final widths = {
        for (final size in CoreProgressSize.values.where(
          CoreRadialProgressStyle.defaultsBySize.containsKey,
        ))
          size: _number(
            _prop(
              resolveRadialProgress(context: context, size: size).root,
              'width',
            ),
          ),
      };
      final base = widths[CoreProgressSize.sm]!;
      expect(widths[CoreProgressSize.md]! / base, closeTo(48 / 32, 1e-6));
      expect(widths[CoreProgressSize.lg]! / base, closeTo(80 / 32, 1e-6));
      expect(widths[CoreProgressSize.xl]! / base, closeTo(128 / 32, 1e-6));
    });

    testComponents('the resting ring is lg', (tester) async {
      final context = _themedContext(tester);
      final resting = _number(
        _prop(resolveRadialProgress(context: context).root, 'width'),
      );
      final small = _number(
        _prop(
          resolveRadialProgress(
            context: context,
            size: CoreProgressSize.sm,
          ).root,
          'width',
        ),
      );
      expect(resting / small, closeTo(80 / 32, 1e-6));
    });

    testComponents('sm draws no figure, md and up do', (tester) async {
      final context = _themedContext(tester);
      expect(
        resolveRadialProgress(
          context: context,
          size: CoreProgressSize.sm,
        ).label,
        isNull,
      );
      for (final size in [
        CoreProgressSize.md,
        CoreProgressSize.lg,
        CoreProgressSize.xl,
      ]) {
        expect(
          resolveRadialProgress(context: context, size: size).label,
          isNotNull,
          reason: size.name,
        );
      }
    });

    testComponents('a tone changes the arc and not the track', (tester) async {
      final context = _themedContext(tester);
      final primary = resolveRadialProgress(context: context);
      final success = resolveRadialProgress(
        context: context,
        tone: CoreProgressTone.success,
      );
      expect(primary.arcCircle.className, isNot(success.arcCircle.className));
      expect(primary.trackCircle.className, success.trackCircle.className);
    });
  });

  group('Progress value label', () {
    testComponents('the cell stacks a hidden reserve under the figure', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final resolved = resolveProgress(
        context: context,
        size: CoreProgressSize.md,
        isIndeterminate: false,
        widthPercent: 50,
        animated: false,
        labelled: true,
      );
      // Both occupy one grid cell: the reserve (invisible, '100%') sizes it,
      // the figure sits at its end.
      expect(_prop(resolved.valueLabelReserve, 'visibility'), 'hidden');
      expect(_prop(resolved.valueLabelReserve, 'grid-area'), '1 / 1');
      expect(_prop(resolved.valueLabelValue, 'grid-area'), '1 / 1');
      expect(_prop(resolved.valueLabelValue, 'justify-self'), 'end');
      // Tabular figures keep the reading from jittering as it ticks.
      expect(
        _prop(resolved.valueLabel, 'font-variant-numeric'),
        'tabular-nums',
      );
    });
  });

  group('Loading tone and ring', () {
    testComponents('primary is the default and reads the accent', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final resolved = resolveLoading(context, variant: .spinner);
      expect(
        resolved.sweep!.className,
        contains(CoreLoadingStyle.defaultColor.toString()),
      );
    });

    testComponents('neutral and inverse read their own ink', (tester) async {
      final context = _themedContext(tester);
      final neutral = resolveLoading(
        context,
        variant: .spinner,
        tone: CoreLoadingTone.neutral,
      );
      expect(
        neutral.sweep!.className,
        contains(const CoreColor.token(CoreColors.onSurfaceVariant).toString()),
      );
      final inverse = resolveLoading(
        context,
        variant: .spinner,
        tone: CoreLoadingTone.inverse,
      );
      expect(
        inverse.sweep!.className,
        contains(const CoreColor.token(CoreColors.onPrimary).toString()),
      );
    });

    testComponents('the tone picks the track', (tester) async {
      final context = _themedContext(tester);
      final primary = resolveLoading(context, variant: .spinner);
      final inverse = resolveLoading(
        context,
        variant: .spinner,
        tone: CoreLoadingTone.inverse,
      );
      expect(
        _prop(primary.track, 'stroke'),
        const CoreColor.token(CoreColors.surfaceContainerHigh).toValue(),
      );
      expect(
        _prop(inverse.track, 'stroke'),
        isNot(_prop(primary.track, 'stroke')),
      );
    });

    testComponents('the arc starts at noon with round caps', (tester) async {
      final sweep = resolveLoading(
        _themedContext(tester),
        variant: .spinner,
      ).sweep;
      expect(_prop(sweep, 'stroke'), 'currentColor');
      expect(_prop(sweep, 'stroke-linecap'), 'round');
      expect(
        _prop(sweep, 'stroke-dasharray'),
        '${CoreLoadingStyle.defaultArcSweepDegrees} 360',
      );
      expect(_prop(sweep, 'transform'), 'rotate(-90deg)');
    });

    testComponents('the ring thickens with the size', (tester) async {
      final context = _themedContext(tester);
      final widths = [
        for (final size in CoreComponentSize.values)
          _prop(
            resolveLoading(
              context,
              variant: .spinner,
              componentSize: size,
            ).track,
            'stroke-width',
          ),
      ];
      expect(widths.toSet().length, 3);
      expect(widths[0], widths[2]);
      expect(widths[3], widths[4]);
      expect(widths[0], isNot(widths[3]));
      expect(widths[3], isNot(widths[5]));
    });
  });

  group('Loading shapes', () {
    testComponents('dots grow with the size: 4 · 4 · 6 · 8 · 10 · 12', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final ratio = _number(
        _prop(
          resolveLoading(
            context,
            variant: .dots,
            componentSize: .xs,
          ).dot0,
          'width',
        ),
      );
      final dots = [
        for (final size in CoreComponentSize.values)
          _number(
                _prop(
                  resolveLoading(
                    context,
                    variant: .dots,
                    componentSize: size,
                  ).dot0,
                  'width',
                ),
              ) /
              ratio *
              4,
      ];
      expect(dots, [4, 4, 6, 8, 10, 12].map((d) => closeTo(d, 1e-6)));
    });

    testComponents('the bar is twice as long as the size is wide', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final bar = resolveLoading(
        context,
        variant: .bar,
        componentSize: .md,
      );
      final spinner = resolveLoading(
        context,
        variant: .spinner,
        componentSize: .md,
      );
      expect(
        _number(_prop(bar.root, 'width')) /
            _number(_prop(spinner.root, 'width')),
        closeTo(2, 1e-6),
      );
    });

    testComponents('the pulse is a halo and a dot, not a solid disc', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final pulse = resolveLoading(context, variant: .pulse);
      expect(pulse.halo, isNotNull);
      expect(pulse.dot, isNotNull);
      expect(_prop(pulse.halo, 'opacity'), isNotNull);
      expect(
        1 - 2 * _number(_prop(pulse.dot, 'clip-path')) / 100,
        closeTo(0.4, 1e-3),
      );
      expect(
        _prop(pulse.dot, 'clip-path'),
        endsWith('round ${_prop(pulse.halo, 'border-radius')})'),
      );
    });
  });
}
