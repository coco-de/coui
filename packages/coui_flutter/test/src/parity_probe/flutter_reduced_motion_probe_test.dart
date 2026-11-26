// EPIC-004 (#3597) child #3614 — ReducedMotionProbe (Flutter half).
//
// FR-019: under `MediaQuery.disableAnimations`, transition-tier motion
// (0–`CoreDuration.ms500`) collapses to zero while display-tier motion
// (spinners, indeterminate progress) keeps running — a frozen spinner is
// itself an accessibility failure (`core/design-tokens.md`).
//
// NFR-005 role separation: the existing `check_motion_alias_tier.sh` guard
// already answers "does the source reference a token" — this probe answers
// "does the rendered/resolved behaviour honour the policy", so it does not
// re-check token usage at the source level.
//
// Deliberately does not restate #3611's Dialog-specific
// `expectDurationWithinTransitionTierTokens` assertion — this file checks
// the shared `CoreReducedMotion`/`resolveMotionDuration` *policy* directly
// across several inputs (unit-level), plus the one thing #3611 didn't cover:
// that a display-tier animation is *not* suppressed by the same setting.
import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReducedMotionProbe — Flutter 전환 tier 억제 (#3614)', () {
    testWidgets(
      'MediaQuery.disableAnimations 하에서 resolveMotionDuration 이 모든 '
      '전환-tier 값을 0 으로 억제한다',
      (tester) async {
        late BuildContext probeContext;
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: material.Builder(
              builder: (context) {
                probeContext = context;
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        for (final ms in const [
          CoreDuration.ms50,
          CoreDuration.ms150,
          CoreDuration.ms200,
          CoreDuration.ms500,
        ]) {
          final resolved = resolveMotionDuration(
            probeContext,
            Duration(milliseconds: ms),
          );
          expect(
            resolved,
            Duration.zero,
            reason: 'transition-tier duration ${ms}ms must collapse to zero',
          );
        }
      },
    );

    testWidgets(
      'MediaQuery.disableAnimations 하에서도 표시-tier 값(CoreDuration.ms1000+)은 '
      '그대로 보존된다',
      (tester) async {
        late BuildContext probeContext;
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: material.Builder(
              builder: (context) {
                probeContext = context;
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        for (final ms in const [
          CoreDuration.ms1000,
          CoreDuration.indeterminate,
          CoreDuration.ms3000,
        ]) {
          final resolved = resolveMotionDuration(
            probeContext,
            Duration(milliseconds: ms),
          );
          expect(
            resolved,
            Duration(milliseconds: ms),
            reason: 'display-tier duration ${ms}ms must be left untouched',
          );
        }
      },
    );

    testWidgets(
      'MediaQuery.disableAnimations 하에서도 Loading(spinner) 은 계속 순환한다 — '
      '멈춘 스피너는 그 자체로 접근성 실패다',
      (tester) async {
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Directionality(
              textDirection: .ltr,
              child: Theme(
                data: ThemeData.fromCore(CoreThemePresets.light),
                child: const Loading(),
              ),
            ),
          ),
        );
        await tester.pump();

        // `Loading`'s spinner ticker keeps a transient callback scheduled
        // for as long as it repeats forever (`AnimationController..repeat()`)
        // — the standard Flutter-test signal that an infinite animation is
        // still running (see `WidgetTester.hasRunningAnimations`). Do NOT
        // use `pumpAndSettle()` here: it loops until no frame is scheduled
        // and throws on a genuinely infinite animation.
        await tester.pump(const Duration(milliseconds: 100));
        expect(
          tester.hasRunningAnimations,
          isTrue,
          reason:
              'Loading spinner has a transient ticker scheduled a full '
              '100ms after being pumped under disableAnimations — a frozen '
              'display-tier animation would have none.',
        );
      },
    );
  });
}
