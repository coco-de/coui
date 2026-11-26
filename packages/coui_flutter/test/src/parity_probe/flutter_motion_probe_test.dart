// EPIC-004 (#3597) child #3611 — FlutterMotionProbe.
//
// Proves `motion_probe.dart`'s sampling + assertions against the two
// production interactions the issue names: Dialog enter/exit
// (ScaleTransition + FadeTransition) and `CoUIAnimatedTheme` (theme
// brightness crossfade + surface-preset transition). All harnesses build
// their `ThemeData` from `CoreThemePresets` (a genuinely *resolved* palette,
// concrete ARGB `CoreColor`s) rather than the bare `ThemeData()` default
// (`ResolvedColorScheme.tokenized()`) — animating between two tokenized
// schemes runs `CoreColor.lerp` on unresolved token references, which throws
// (`#3381` problem 3). That crash is a pre-existing Flutter theme-lerp bug
// tracked separately; this probe's job is to sample real animations, not to
// exercise that crash path.
import 'dart:async';

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

import 'motion_probe.dart';

/// The [FadeTransition] that actually belongs to the `Dialog`'s own
/// `DialogRoute` — not `find.byType(FadeTransition)`, which also matches the
/// ambient `MaterialApp`/`MaterialPageRoute` page-transition widgets that
/// exist even when no dialog is open (`kAlwaysCompleteAnimation` /
/// `kAlwaysDismissedAnimation` placeholders included). Scoping the finder to
/// an *ancestor of* [Dialog] picks out the one built by
/// `_buildCoUIDialogTransitions`.
Finder _dialogFadeTransition() => find.ancestor(
  of: find.byType(Dialog),
  matching: find.byType(FadeTransition),
);

/// Same reasoning as [_dialogFadeTransition] for the panel's zoom.
Finder _dialogScaleTransition() => find.ancestor(
  of: find.byType(Dialog),
  matching: find.byType(ScaleTransition),
);

Future<void> _pumpDialogHarness(
  WidgetTester tester, {
  required ThemeData theme,
  bool disableAnimations = false,
}) async {
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(disableAnimations: disableAnimations),
      child: Theme(
        data: theme,
        child: material.MaterialApp(
          home: material.Scaffold(
            body: material.Center(
              child: material.Builder(
                builder: (context) => material.ElevatedButton(
                  onPressed: () => unawaited(
                    showDialog(
                      context: context,
                      builder: (_) => const Dialog(
                        title: Text('Probe Title'),
                        content: Text('Probe content'),
                      ),
                    ),
                  ),
                  child: const material.Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('FlutterMotionProbe — Dialog enter/exit (#3611)', () {
    testWidgets(
      '진입: opacity 가 단조 증가하고 즉시 최종값으로 점프하지 않는다',
      (tester) async {
        await _pumpDialogHarness(
          tester,
          theme: ThemeData.fromCore(CoreThemePresets.light),
        );
        await tester.tap(find.text('open'));
        // One bare pump materializes the pushed route's transition widgets
        // at t≈0 — the sample this function's own header comment requires
        // callers to take responsibility for.
        await tester.pump();

        final duration = resolveDialog(
          tester.element(find.byType(Dialog)),
        ).transitionDuration;
        expectDurationWithinTransitionTierTokens(
          duration,
          reason: 'Dialog.transitionDuration',
        );

        final samples = await sampleAnimationValues(
          tester,
          read: () => tester
              .widget<FadeTransition>(_dialogFadeTransition())
              .opacity
              .value,
          totalDuration: duration,
        );
        expectNoImmediateFinalValueJump(
          samples,
          reason: 'Dialog enter opacity',
        );
        expectMonotonicProgression(samples, reason: 'Dialog enter opacity');
      },
    );

    testWidgets(
      '진입: scale 도 단조 증가하고 즉시 최종값으로 점프하지 않는다',
      (tester) async {
        await _pumpDialogHarness(
          tester,
          theme: ThemeData.fromCore(CoreThemePresets.light),
        );
        await tester.tap(find.text('open'));
        await tester.pump();

        final duration = resolveDialog(
          tester.element(find.byType(Dialog)),
        ).transitionDuration;

        final samples = await sampleAnimationValues(
          tester,
          read: () => tester
              .widget<ScaleTransition>(_dialogScaleTransition())
              .scale
              .value,
          totalDuration: duration,
        );
        expectNoImmediateFinalValueJump(samples, reason: 'Dialog enter scale');
        expectMonotonicProgression(samples, reason: 'Dialog enter scale');
      },
    );

    testWidgets(
      '퇴장: opacity 가 단조 감소하고 컴포넌트가 퇴장 구간 동안 트리에 존속한다',
      (tester) async {
        await _pumpDialogHarness(
          tester,
          theme: ThemeData.fromCore(CoreThemePresets.light),
        );
        await tester.tap(find.text('open'));
        // Steady, fully-open state before triggering the reverse transition
        // — sampling only the *exit* half of the lifecycle.
        await tester.pumpAndSettle();
        expect(_dialogFadeTransition(), findsOneWidget);

        final duration = resolveDialog(
          tester.element(find.byType(Dialog)),
        ).transitionDuration;

        Navigator.of(
          tester.element(find.byType(Dialog)),
          rootNavigator: true,
        ).pop();
        await tester.pump();

        final samples = await sampleAnimationValues(
          tester,
          read: () => tester
              .widget<FadeTransition>(_dialogFadeTransition())
              .opacity
              .value,
          totalDuration: duration,
        );
        expectNoImmediateFinalValueJump(samples, reason: 'Dialog exit opacity');
        expectMonotonicProgression(samples, reason: 'Dialog exit opacity');

        // Confirmed present at every sampled point except possibly the very
        // last (which may coincide with the frame the route finishes
        // popping) — this is the Flutter-side half of the
        // "does the component survive its own exit transition instead of
        // vanishing instantly" question #3613's WebLifecycleProbe asks on
        // the Web side.
        final interiorSampleCount = samples.length - 2;
        expect(
          interiorSampleCount,
          greaterThan(0),
          reason:
              'no interior samples were even taken — Dialog vanished before '
              'the exit transition had a chance to run.',
        );
      },
    );
  });

  group('FlutterMotionProbe — CoUIAnimatedTheme 전환 (#3611)', () {
    testWidgets(
      'light → dark: colorScheme.surface 명도가 단조 변화하고 즉시 점프하지 않는다',
      (tester) async {
        final light = ThemeData.fromCore(CoreThemePresets.light);
        final dark = ThemeData.fromCore(CoreThemePresets.dark);
        late BuildContext probeContext;

        Widget harness(ThemeData data) => Directionality(
          textDirection: .ltr,
          child: CoUIAnimatedTheme(
            data: data,
            duration: kDefaultDuration,
            child: material.Builder(
              builder: (context) {
                probeContext = context;
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        await tester.pumpWidget(harness(light));
        // Rebuilding with a different `data` is the trigger — this is what
        // `CoUILayer` does on every theme/surfaceStyle change (`coui_app.dart`).
        await tester.pumpWidget(harness(dark));

        final samples = await sampleAnimationValues(
          tester,
          read: () => Theme.of(
            probeContext,
          ).colorScheme.surface.toValue().computeLuminance(),
          totalDuration: kDefaultDuration,
        );
        expectNoImmediateFinalValueJump(
          samples,
          reason: 'Theme brightness transition surface luminance',
        );
        expectMonotonicProgression(
          samples,
          reason: 'Theme brightness transition surface luminance',
        );
      },
    );

    testWidgets(
      '서페이스 프리셋 전환 (default → neoBrutalism): outline 명도가 단조 변화하고 즉시 점프하지 않는다',
      (tester) async {
        final base = ThemeData.fromCore(CoreThemePresets.light);
        final defaultStyled = applySurfaceStyle(
          base,
          surfaceStyle: .defaultId,
          highContrast: false,
        );
        final brutalistStyled = applySurfaceStyle(
          base,
          surfaceStyle: .neoBrutalism,
          highContrast: false,
        );
        // A style whose colorConstraint is not identity must actually
        // change the colour it emphasises — otherwise this test would
        // "pass" by having nothing to distinguish, exactly the trap
        // `expectMonotonicProgression` refuses to silently allow (it fails
        // loudly instead when start == end).
        expect(
          defaultStyled.colorScheme.outline,
          isNot(equals(brutalistStyled.colorScheme.outline)),
          reason:
              'neoBrutalism declares outlineEmphasis:1 — its outline colour '
              'should differ from the default preset, or this test is '
              'sampling a property the preset does not actually touch.',
        );

        late BuildContext probeContext;
        Widget harness(ThemeData data) => Directionality(
          textDirection: .ltr,
          child: CoUIAnimatedTheme(
            data: data,
            duration: kDefaultDuration,
            child: material.Builder(
              builder: (context) {
                probeContext = context;
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        await tester.pumpWidget(harness(defaultStyled));
        await tester.pumpWidget(harness(brutalistStyled));

        final samples = await sampleAnimationValues(
          tester,
          read: () => Theme.of(
            probeContext,
          ).colorScheme.outline.toValue().computeLuminance(),
          totalDuration: kDefaultDuration,
        );
        expectNoImmediateFinalValueJump(
          samples,
          reason: 'Surface preset transition outline luminance',
        );
        expectMonotonicProgression(
          samples,
          reason: 'Surface preset transition outline luminance',
        );
      },
    );
  });

  group('FlutterMotionProbe — reduced-motion (전환 tier, #3611)', () {
    testWidgets(
      'MediaQuery.disableAnimations 하에서 Dialog 전환 duration 이 0 으로 억제된다',
      (tester) async {
        await _pumpDialogHarness(
          tester,
          theme: ThemeData.fromCore(CoreThemePresets.light),
          disableAnimations: true,
        );
        await tester.tap(find.text('open'));
        await tester.pump();

        final duration = resolveDialog(
          tester.element(find.byType(Dialog)),
        ).transitionDuration;
        expect(
          duration,
          Duration.zero,
          reason:
              'transition-tier motion must collapse to zero under reduced '
              'motion (core/design-tokens.md — resolveMotionDuration).',
        );
      },
    );
  });
}
