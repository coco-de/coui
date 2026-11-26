import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/components/overlay/tooltip/tooltip.dart';
import 'package:coui_web/src/components/overlay/tooltip/tooltip_style.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

/// Captures the ambient themed [BuildContext] so [resolveTooltip] can be
/// called directly.
class _ContextCapture extends StatelessComponent {
  const _ContextCapture(this.onBuild);

  final void Function(BuildContext context) onBuild;

  @override
  Component build(BuildContext context) {
    onBuild(context);
    return const div([]);
  }
}

ResolvedTooltip _resolve(
  ComponentTester tester, {
  CoreTooltipStyle? tooltipStyle,
}) {
  late ResolvedTooltip resolved;
  pumpWithTheme(
    tester,
    _ContextCapture(
      (context) => resolved = resolveTooltip(
        context,
        didEnter: true,
        activeDurationMs: 0,
        placement: CorePopoverPlacement.top,
        tooltipStyle: tooltipStyle,
      ),
    ),
  );
  return resolved;
}

void main() {
  group('Tooltip', () {
    testComponents('renders its child by default (message hidden until '
        'hover)', (tester) async {
      pumpWithTheme(
        tester,
        const Tooltip(message: 'Hint', child: Component.text('Anchor')),
      );

      expect(find.text('Anchor'), findsOneComponent);
    });

    testComponents('renders a custom tooltipChild instead of message', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const Tooltip(
          tooltipChild: Component.text('Rich hint'),
          child: Component.text('Anchor'),
        ),
      );

      expect(find.text('Anchor'), findsOneComponent);
    });

    test('accepts custom id', () {
      const tooltip = Tooltip(
        message: 'Hint',
        child: Component.text('Anchor'),
        id: 'tooltip-1',
      );
      expect(tooltip.id, equals('tooltip-1'));
    });

    test('copyWith preserves properties', () {
      const original = Tooltip(
        message: 'Hint',
        child: Component.text('Anchor'),
        position: CoreTooltipPosition.bottom,
        id: 'tooltip-orig',
      );

      final copy = original.copyWith(id: 'tooltip-new');

      expect(copy.id, equals('tooltip-new'));
      expect(copy.message, equals('Hint'));
      expect(copy.position, equals(CoreTooltipPosition.bottom));
    });

    test('implements CoreTooltipContract', () {
      const tooltip = Tooltip(
        message: 'Hint',
        child: Component.text('Anchor'),
        position: CoreTooltipPosition.left,
      );

      expect(tooltip.message, equals('Hint'));
      expect(tooltip.position, equals(CoreTooltipPosition.left));
    });

    // Hover timings are the Flutter twin's `waitDuration` / `showDuration`
    // / `minDuration`. The values must arrive from the shared
    // `CoreTooltipContract` constants — a Web-local copy is exactly the
    // divergence that leaves one platform behind when a default moves.
    test('hover timings default to the shared contract constants', () {
      const tooltip = Tooltip(
        message: 'Hint',
        child: Component.text('Anchor'),
      );

      expect(
        tooltip.waitDuration,
        equals(CoreTooltipContract.defaultWaitDuration),
      );
      expect(
        tooltip.showDuration,
        equals(CoreTooltipContract.defaultShowDuration),
      );
      expect(tooltip.minDuration, isNull);
    });

    test('copyWith carries the hover timings', () {
      const original = Tooltip(
        message: 'Hint',
        waitDuration: Duration(milliseconds: CoreDuration.ms450),
        showDuration: Duration(milliseconds: CoreDuration.ms250),
        minDuration: Duration(milliseconds: CoreDuration.ms350),
        child: Component.text('Anchor'),
      );

      final copy = original.copyWith(id: 'tooltip-new');

      expect(
        copy.waitDuration,
        equals(const Duration(milliseconds: CoreDuration.ms450)),
      );
      expect(
        copy.showDuration,
        equals(const Duration(milliseconds: CoreDuration.ms250)),
      );
      expect(
        copy.minDuration,
        equals(const Duration(milliseconds: CoreDuration.ms350)),
      );
    });
  });

  group('resolveTooltip tail', () {
    testComponents('the default states no tail, so no tail node is resolved', (
      tester,
    ) async {
      final resolved = _resolve(tester);

      expect(CoreTooltipStyle.defaultTailWidth, 0);
      expect(CoreTooltipStyle.defaultTailHeight, 0);
      expect(resolved.tail, isNull);
    });

    testComponents('a stated tail resolves a clip-path triangle', (
      tester,
    ) async {
      final resolved = _resolve(
        tester,
        tooltipStyle: const CoreTooltipStyle(tailWidth: 12, tailHeight: 6),
      );

      expect(resolved.tail, isNotNull);
      expect(resolved.tail!.inlineStyles?.properties['clip-path'], isNotNull);
    });

    testComponents('a zero on either axis drops the tail again', (
      tester,
    ) async {
      final noWidth = _resolve(
        tester,
        tooltipStyle: const CoreTooltipStyle(tailWidth: 0, tailHeight: 6),
      );
      final noHeight = _resolve(
        tester,
        tooltipStyle: const CoreTooltipStyle(tailWidth: 12, tailHeight: 0),
      );

      expect(noWidth.tail, isNull);
      expect(noHeight.tail, isNull);
    });
  });

  group('resolveTooltip redesign (#5967)', () {
    testComponents('the bubble takes no contributed border marker', (
      tester,
    ) async {
      final resolved = _resolve(tester);

      // A reversed-fill surface draws no visible line — the style's
      // contributed control border is not forwarded to it.
      expect(resolved.bubble.className, isNot(contains(kControlBorderMarker)));
    });

    testComponents('the label states the labelSmall role and no weight', (
      tester,
    ) async {
      final resolved = _resolve(tester);

      // 12 Medium comes from the role class; no SemiBold overlay is emitted
      // inline or as a class on the bubble.
      expect(resolved.bubble.className, contains('text-label-small'));
      expect(
        resolved.bubble.inlineStyles?.properties['font-weight'],
        isNull,
      );
      expect(resolved.bubble.className, isNot(contains('font-semibold')));
    });
  });

  group('resolveTooltipTiming', () {
    test('fills every timing from the contract defaults when unset', () {
      final timing = resolveTooltipTiming();

      expect(
        timing.waitDurationMs,
        equals(CoreTooltipContract.defaultWaitDuration.inMilliseconds),
      );
      expect(
        timing.showDurationMs,
        equals(CoreTooltipContract.defaultShowDuration.inMilliseconds),
      );
      expect(
        timing.minDurationMs,
        equals(CoreTooltipContract.defaultMinDuration.inMilliseconds),
      );
    });

    test('honours per-instance overrides', () {
      final timing = resolveTooltipTiming(
        waitDuration: const Duration(milliseconds: CoreDuration.ms450),
        showDuration: const Duration(milliseconds: CoreDuration.ms250),
        minDuration: const Duration(milliseconds: CoreDuration.ms350),
      );

      expect(timing.waitDurationMs, equals(CoreDuration.ms450));
      expect(timing.showDurationMs, equals(CoreDuration.ms250));
      expect(timing.minDurationMs, equals(CoreDuration.ms350));
    });
  });
}
