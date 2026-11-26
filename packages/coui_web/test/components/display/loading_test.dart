import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

const _kCustomSize = 32.0;
const _kCustomDurationMs = 400;

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

int? _delayMs(WebElementChrome? chrome) {
  final raw = chrome?.inlineStyles?.properties['animation-delay'];
  if (raw == null) return null;
  return int.parse(raw.replaceAll('ms', ''));
}

void main() {
  group('Loading', () {
    test('default variant is spinner', () {
      const loading = Loading();
      expect(loading.variant, equals(CoreLoadingVariant.spinner));
    });

    test('accepts dots variant', () {
      const loading = Loading(variant: .dots);
      expect(loading.variant, equals(CoreLoadingVariant.dots));
    });

    test('accepts bar variant', () {
      const loading = Loading(variant: .bar);
      expect(loading.variant, equals(CoreLoadingVariant.bar));
    });

    test('accepts pulse variant', () {
      const loading = Loading(variant: .pulse);
      expect(loading.variant, equals(CoreLoadingVariant.pulse));
    });

    test('accepts custom pixel size via loadingStyle', () {
      const loading = Loading(
        loadingStyle: CoreLoadingStyle(size: _kCustomSize),
      );
      expect(loading.loadingStyle?.size, equals(_kCustomSize));
    });

    test('accepts componentSize token', () {
      const loading = Loading(componentSize: .lg);
      expect(loading.componentSize, equals(CoreComponentSize.lg));
    });

    test('accepts color token via loadingStyle', () {
      const primary = CoreColor.token(CoreColors.primary);
      const loading = Loading(
        loadingStyle: CoreLoadingStyle(color: primary),
      );
      expect(loading.loadingStyle?.color, equals(primary));
    });

    testComponents('spinner variant pumps without errors', (tester) async {
      pumpWithTheme(tester, const Loading());
    });

    testComponents('dots variant pumps without errors', (tester) async {
      pumpWithTheme(tester, const Loading(variant: .dots));
    });

    testComponents('bar variant pumps without errors', (tester) async {
      pumpWithTheme(tester, const Loading(variant: .bar));
    });

    testComponents('pulse variant pumps without errors', (tester) async {
      pumpWithTheme(tester, const Loading(variant: .pulse));
    });
  });

  group('dots wave', () {
    // The stagger is a *ratio* of the resolved duration — the same
    // `CoreLoadingStyle.dotWavePhase` the Flutter twin samples — expressed as
    // a negative delay so every dot starts mid-wave on the first frame.
    int expectedDelay(int index, int durationMs) =>
        -(CoreLoadingStyle.dotWavePhase(index, 0) * durationMs).round();

    testComponents('each dot starts at its wave phase', (tester) async {
      final context = _themedContext(tester);
      final resolved = resolveLoading(context, variant: .dots);
      final durationMs = CoreLoadingStyle
          .defaultsByVariant[CoreLoadingVariant.dots]!
          .duration
          .inMilliseconds;

      expect(_delayMs(resolved.dot0), equals(0));
      expect(_delayMs(resolved.dot1), equals(expectedDelay(1, durationMs)));
      expect(_delayMs(resolved.dot2), equals(expectedDelay(2, durationMs)));
      // A third of the cycle per dot, behind the one before it.
      expect(_delayMs(resolved.dot1), equals(-(durationMs * 2 / 3).round()));
      expect(_delayMs(resolved.dot2), equals(-(durationMs / 3).round()));
    });

    testComponents('scales with a custom duration override', (tester) async {
      final context = _themedContext(tester);
      final resolved = resolveLoading(
        context,
        variant: .dots,
        loadingStyle: const CoreLoadingStyle(
          duration: Duration(milliseconds: _kCustomDurationMs),
        ),
      );

      expect(
        _delayMs(resolved.dot1),
        equals(expectedDelay(1, _kCustomDurationMs)),
      );
    });

    testComponents('dots sit half a dot apart, centred', (tester) async {
      final context = _themedContext(tester);
      final resolved = resolveLoading(
        context,
        variant: .dots,
        componentSize: .md,
      );
      final dot =
          CoreLoadingStyle.defaultsBySize[CoreComponentSize.md]!.dotSize!;

      expect(
        resolved.root.inlineStyles?.properties['gap'],
        equals(
          pinnedLengthCss(dot * CoreLoadingStyle.dotGapRatio),
        ),
      );
      expect(resolved.root.className, contains('justify-center'));
      expect(resolved.root.className, isNot(contains('justify-between')));
    });

    testComponents('keyframes are the Core wave, linear', (tester) async {
      final context = _themedContext(tester);
      final css = resolveLoadingCss(context, variant: .dots, id: 'x');

      for (var k = 0; k <= CoreLoadingStyle.dotCount; k++) {
        final percent = (k / CoreLoadingStyle.dotCount * 100).toStringAsFixed(
          4,
        );
        expect(
          css,
          contains(
            '$percent% { opacity: '
            '${CoreLoadingStyle.dotWaveKeyframeOpacity(k)}; }',
          ),
        );
      }
      expect(css, contains('var(--easing-${CoreEasing.scale.linear})'));
    });
  });
}
