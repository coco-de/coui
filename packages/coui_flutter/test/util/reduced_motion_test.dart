import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

/// Pumps [child] with `MediaQuery.disableAnimations` set to [reduce].
Widget _app({required bool reduce, required Widget child}) =>
    material.MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduce),
        child: Theme(data: const ThemeData(), child: child),
      ),
    );

/// Captures a resolver's output from inside the pumped tree.
Widget _capture(void Function(BuildContext context) onBuild) => Builder(
  builder: (context) {
    onBuild(context);
    return const SizedBox.shrink();
  },
);

void main() {
  group('resolveMotionDuration', () {
    testWidgets('passes durations through when the preference is off', (
      tester,
    ) async {
      late Duration transition;
      await tester.pumpWidget(
        _app(
          reduce: false,
          child: _capture((context) {
            transition = resolveMotionDuration(
              context,
              const Duration(milliseconds: CoreDuration.normal),
            );
          }),
        ),
      );
      expect(
        transition,
        equals(const Duration(milliseconds: CoreDuration.normal)),
      );
    });

    testWidgets('collapses transition motion when the preference is on', (
      tester,
    ) async {
      late Duration transition;
      await tester.pumpWidget(
        _app(
          reduce: true,
          child: _capture((context) {
            transition = resolveMotionDuration(
              context,
              const Duration(milliseconds: CoreDuration.normal),
            );
          }),
        ),
      );
      expect(transition, equals(Duration.zero));
    });

    testWidgets('leaves display timing alone when the preference is on', (
      tester,
    ) async {
      late Duration display;
      await tester.pumpWidget(
        _app(
          reduce: true,
          child: _capture((context) {
            display = resolveMotionDuration(
              context,
              const Duration(milliseconds: CoreDuration.indeterminate),
            );
          }),
        ),
      );
      expect(
        display,
        equals(const Duration(milliseconds: CoreDuration.indeterminate)),
      );
    });

    testWidgets('treats a missing MediaQuery as "not requested"', (
      tester,
    ) async {
      // A resolver used outside a MediaQuery ancestor must animate normally
      // rather than silently behave as if the user asked for reduced motion.
      late Duration transition;
      await tester.pumpWidget(
        _capture((context) {
          transition = resolveMotionDuration(
            context,
            const Duration(milliseconds: CoreDuration.normal),
          );
        }),
      );
      expect(
        transition,
        equals(const Duration(milliseconds: CoreDuration.normal)),
      );
    });
  });

  group('resolvers honour the preference', () {
    testWidgets('Progress suppresses its transition but keeps its cycle', (
      tester,
    ) async {
      // One resolver holds both kinds: `duration` animates a value change,
      // `indeterminateDuration` is the "still working" cycle. They must come
      // out of the same call differently — that is the whole policy in one
      // assertion.
      late ResolvedProgress reduced;
      late ResolvedProgress normal;

      await tester.pumpWidget(
        _app(
          reduce: true,
          child: _capture((context) {
            reduced = resolveProgress(
              context,
              size: CoreProgressSize.defaultSize,
            );
          }),
        ),
      );
      await tester.pumpWidget(
        _app(
          reduce: false,
          child: _capture((context) {
            normal = resolveProgress(
              context,
              size: CoreProgressSize.defaultSize,
            );
          }),
        ),
      );

      expect(
        normal.duration,
        isNot(equals(Duration.zero)),
        reason: 'baseline: the transition normally animates.',
      );
      expect(reduced.duration, equals(Duration.zero));
      expect(
        reduced.indeterminateDuration,
        equals(normal.indeterminateDuration),
        reason:
            'A frozen indeterminate bar reads as a hang — display timing is '
            'information, not decoration.',
      );
    });

    testWidgets('FocusOutline suppresses its transition', (tester) async {
      late ResolvedFocusOutline reduced;
      late ResolvedFocusOutline normal;

      await tester.pumpWidget(
        _app(
          reduce: true,
          child: _capture((context) {
            reduced = resolveFocusOutline(context);
          }),
        ),
      );
      await tester.pumpWidget(
        _app(
          reduce: false,
          child: _capture((context) {
            normal = resolveFocusOutline(context);
          }),
        ),
      );

      expect(normal.duration, isNot(equals(Duration.zero)));
      expect(reduced.duration, equals(Duration.zero));
    });

    testWidgets(
      'Clickable suppresses its press-feedback duration (#4407)',
      (tester) async {
        // The Web twin of this gap was `ThemeConfig._controlShadowPressRule`
        // writing a bare `50ms` literal instead of routing through
        // `--coui-duration-50` — `resolveClickable` had the same bug on
        // the Flutter side: `pressDuration` never reached
        // `resolveMotionDuration`.
        late ResolvedClickable reduced;
        late ResolvedClickable normal;

        await tester.pumpWidget(
          _app(
            reduce: true,
            child: _capture((context) {
              reduced = resolveClickable(context);
            }),
          ),
        );
        await tester.pumpWidget(
          _app(
            reduce: false,
            child: _capture((context) {
              normal = resolveClickable(context);
            }),
          ),
        );

        expect(
          normal.pressDuration,
          isNot(equals(Duration.zero)),
          reason: 'baseline: press feedback normally animates',
        );
        expect(reduced.pressDuration, equals(Duration.zero));
      },
    );

    testWidgets(
      'Clickable applies the preference to a caller-supplied pressDuration '
      'override too, not just the design default',
      (tester) async {
        // `Button` overrides `pressDuration` explicitly (rather than
        // relying on `CoreClickableStyle.defaultPressDuration`) — the fix
        // has to wrap whatever `merged.pressDuration` resolves to, not
        // just the literal default, or Button's own override would have
        // stayed a live regression even after this file's other cases
        // went green.
        const override = Duration(milliseconds: CoreDuration.ms50);
        late ResolvedClickable reduced;

        await tester.pumpWidget(
          _app(
            reduce: true,
            child: _capture((context) {
              reduced = resolveClickable(
                context,
                clickableStyle: const CoreClickableStyle(
                  pressDuration: override,
                ),
              );
            }),
          ),
        );

        expect(reduced.pressDuration, equals(Duration.zero));
      },
    );

    testWidgets(
      'Button suppresses its cast-hide duration, the shared clock for the '
      'shadow-hide and the travel (#4407)',
      (tester) async {
        late ResolvedButton reduced;
        late ResolvedButton normal;

        ResolvedButton resolve(BuildContext context) => resolveButton(
          context,
          variant: .primary,
          size: .md,
          shape: .rectangle,
        );

        await tester.pumpWidget(
          _app(reduce: true, child: _capture((c) => reduced = resolve(c))),
        );
        await tester.pumpWidget(
          _app(reduce: false, child: _capture((c) => normal = resolve(c))),
        );

        expect(
          normal.castHideDuration,
          equals(const Duration(milliseconds: CoreDuration.ms50)),
          reason: 'baseline: unchanged 50ms clock outside the preference',
        );
        expect(reduced.castHideDuration, equals(Duration.zero));
      },
    );

    testWidgets(
      'Chip suppresses its cast-hide duration, independently of '
      'transitionDuration (#4407)',
      (tester) async {
        late ResolvedChip reduced;
        late ResolvedChip normal;

        ResolvedChip resolve(BuildContext context) => resolveChip(
          context,
          variant: CoreChipVariant.outlined,
          chipColor: .defaultColor,
          size: .md,
          selected: false,
          emphasis: .defaultEmphasis,
          enabled: true,
        );

        await tester.pumpWidget(
          _app(reduce: true, child: _capture((c) => reduced = resolve(c))),
        );
        await tester.pumpWidget(
          _app(reduce: false, child: _capture((c) => normal = resolve(c))),
        );

        expect(
          normal.castHideDuration,
          equals(const Duration(milliseconds: CoreDuration.ms50)),
        );
        expect(reduced.castHideDuration, equals(Duration.zero));
        // The chip's chrome transition (hover/selected speed) is a
        // different clock from the press pair's — both must independently
        // honour the preference, not just whichever one this file already
        // asserted on elsewhere.
        expect(reduced.transitionDuration, equals(Duration.zero));
      },
    );

    testWidgets(
      'Skeleton stops its pulse under reduced motion but keeps its period',
      (tester) async {
        // The placeholder pulse is a display-tier loop reduced motion stops
        // (`CoreReducedMotion.runsPlaceholderPulse`). It stops through
        // `pulses`, never by zeroing the period: a transition-tier override
        // must still come back unchanged, or `repeat()` asserts on a zero
        // period the moment the setting is turned off again.
        const shortOverride = Duration(milliseconds: CoreDuration.ms200);
        late ResolvedSkeleton reduced;
        late ResolvedSkeleton normal;

        await tester.pumpWidget(
          _app(
            reduce: true,
            child: _capture((context) {
              reduced = resolveSkeleton(
                context,
                variant: .rectangular,
                skeletonStyle: const CoreSkeletonStyle(
                  duration: shortOverride,
                ),
              );
            }),
          ),
        );
        await tester.pumpWidget(
          _app(
            reduce: false,
            child: _capture((context) {
              normal = resolveSkeleton(
                context,
                variant: .rectangular,
                skeletonStyle: const CoreSkeletonStyle(
                  duration: shortOverride,
                ),
              );
            }),
          ),
        );

        expect(normal.duration, equals(shortOverride));
        expect(
          reduced.duration,
          equals(shortOverride),
          reason: 'reduced motion must not zero a repeating pulse duration',
        );
        expect(normal.pulses, isTrue);
        expect(reduced.pulses, isFalse);
      },
    );

    testWidgets(
      'Skeleton with a short duration override does not crash under '
      'reduced motion',
      (tester) async {
        // Regression: a transition-tier duration override used to collapse
        // to Duration.zero under reduced motion, and
        // AnimationController.repeat() asserts on a zero period
        // (_RepeatingSimulation._periodInSeconds > 0.0) — the skeleton threw
        // instead of rendering.
        await tester.pumpWidget(
          _app(
            reduce: true,
            child: const Skeleton(
              width: 200,
              height: 20,
              skeletonStyle: CoreSkeletonStyle(
                duration: Duration(milliseconds: CoreDuration.ms200),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        expect(tester.takeException(), isNull);
        expect(find.byType(Skeleton), findsOneWidget);
      },
    );
  });
}
