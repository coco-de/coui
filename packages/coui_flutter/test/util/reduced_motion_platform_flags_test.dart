// The two flags a platform sets for one request — "reduce motion" — and the
// one place that joins them.
//
// Android reports `MediaQuery.disableAnimations`. iOS reports
// `AccessibilityFeatures.reduceMotion` and, per Flutter's own docs, leaves
// the first flag alone; `MediaQueryData` has no field for the second. A
// component that reads only the first therefore ignores the platform the
// glass material is designed for, and no widget-level test that sets
// `MediaQueryData(disableAnimations: true)` can see it.
//
// So this file drives the **platform dispatcher**, the way the OS does
// (`FakeAccessibilityFeatures(reduceMotion: true)`), and holds:
//   * that no component reads either flag for itself (read from source),
//   * the join (`resolveReducedMotion`) and the policy on top of it,
//   * that a change made while the app runs reaches an already-built
//     dependent (the scope `CoUIApp` mounts), and that outside `CoUIApp`
//     the flag is still honoured when a dependent builds,
//   * that every site that decides on motion for itself, instead of through
//     `resolveMotionDuration`, honours the iOS flag and the Android one.
//
// Mutation check (each was run, and each makes the named tests fail):
//   * `_reduceMotionOf` returns false      -> every iOS test in this file
//   * `_reduceMotionOf` loses its fallback -> the 'outside CoUIApp ...' tests
//     and every iOS test that mounts no `CoUIApp`
//   * the scope ignores accessibility changes, or hears them without
//     publishing -> the 'live' tests
//   * `CoUILayer` stops mounting the scope -> the 'live' tests that use
//     `CoUIApp`
//   * a site goes back to reading `MediaQuery.disableAnimationsOf` itself ->
//     that site's iOS tests, and only that site's
//   * a component reads `MediaQuery.disableAnimationsOf` beside the helper
//     (no behaviour change) -> 'no component reads either flag for itself'

import 'dart:io';

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

/// What the platform reports for the accessibility features under test, put
/// back when the test ends.
///
/// `accessibilityFeaturesTestValue` replaces the dispatcher's answer for
/// every view in the binding and is not cleared by the binding itself, so a
/// test that sets it and forgets to restore it changes the next test.
class _Platform {
  _Platform(this.tester) {
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  }

  final WidgetTester tester;

  /// Reports exactly these features — the dispatcher notifies its listeners,
  /// as it does when the user flips the setting in the OS.
  void report({
    bool reduceMotion = false,
    bool disableAnimations = false,
    bool invertColors = false,
  }) {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        FakeAccessibilityFeatures(
          reduceMotion: reduceMotion,
          disableAnimations: disableAnimations,
          invertColors: invertColors,
        );
  }
}

/// A full app, so the scope `CoUIApp` mounts is in the tree.
Widget _coui(Widget home) => CoUIApp(
  debugShowCheckedModeBanner: false,
  theme: ThemeData.fromCore(CoreThemePresets.light),
  home: home,
);

/// An app that is not CoUI's: it gives CoUI widgets a theme and a
/// `MediaQuery`, and nothing mounts the scope.
Widget _notCoui(Widget home) => material.MaterialApp(
  home: Theme(data: const ThemeData(), child: home),
);

/// A dependent that records every answer it is handed.
Widget _probe(List<bool> answers) => Builder(
  builder: (context) {
    answers.add(resolveReducedMotion(context));
    return const SizedBox.shrink();
  },
);

const _transition = Duration(milliseconds: CoreDuration.normal);
const _ceiling = Duration(milliseconds: CoreDuration.ms500);
const _display = Duration(milliseconds: CoreDuration.ms1000);

void main() {
  group('the request has one seat', () {
    test('no component reads either flag for itself', () {
      // Read from source because the failure is invisible at run time: a
      // site that asks `MediaQuery` alone behaves correctly on Android and
      // only shows on a device with iOS's setting on. Every behavioural test
      // below sets the flag through the platform, but only for the sites it
      // knows about — this is what catches the next one.
      final reads = RegExp(
        r'\bmaybeDisableAnimationsOf\b|\bdisableAnimationsOf\b|'
        r'\.disableAnimations\b|\baccessibilityFeatures\b',
      );
      final offenders = <String>[];
      for (final file in Directory('lib').listSync(recursive: true)) {
        final path = file.path.replaceAll(r'\', '/');
        if (file is! File || !path.endsWith('.dart')) continue;
        if (path.endsWith('lib/src/util/motion.dart')) continue;

        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          // Comments may say what they like; only code reads.
          if (reads.hasMatch(lines[i].split('//').first)) {
            offenders.add('$path:${i + 1}');
          }
        }
      }

      expect(
        offenders,
        isEmpty,
        reason:
            'route the request through resolveReducedMotion '
            "(lib/src/util/motion.dart) — it joins Android's "
            "MediaQuery.disableAnimations with iOS's "
            'AccessibilityFeatures.reduceMotion; reading one flag honours '
            'one platform.',
      );
    });
  });

  group('resolveReducedMotion joins the two flags', () {
    // [disableAnimations] is `MediaQuery`'s; [reduceMotion] is the platform's.
    final cases = <({bool android, bool ios, bool expected})>[
      (android: false, ios: false, expected: false),
      (android: true, ios: false, expected: true),
      (android: false, ios: true, expected: true),
      (android: true, ios: true, expected: true),
    ];

    for (final c in cases) {
      testWidgets(
        'MediaQuery.disableAnimations=${c.android} '
        'reduceMotion=${c.ios} -> ${c.expected}',
        (tester) async {
          _Platform(tester).report(reduceMotion: c.ios);
          final answers = <bool>[];
          await tester.pumpWidget(
            MediaQuery(
              data: MediaQueryData(disableAnimations: c.android),
              child: _probe(answers),
            ),
          );

          expect(answers.last, c.expected);
        },
      );
    }

    testWidgets('the platform disableAnimations flag counts on its own', (
      tester,
    ) async {
      // No `MediaQuery` override: the value comes the way it does in a real
      // app, from the view's dispatcher through `MediaQuery.fromView`.
      _Platform(tester).report(disableAnimations: true);
      final answers = <bool>[];
      await tester.pumpWidget(_notCoui(_probe(answers)));

      expect(answers.last, isTrue);
    });

    testWidgets('a MediaQuery override cannot hide the iOS flag', (
      tester,
    ) async {
      // `MediaQueryData` does not carry `reduceMotion`, so an ancestor that
      // says `disableAnimations` is off (its default) is not speaking
      // about it.
      _Platform(tester).report(reduceMotion: true);
      final answers = <bool>[];
      await tester.pumpWidget(
        MediaQuery(data: const MediaQueryData(), child: _probe(answers)),
      );

      expect(answers.last, isTrue);
    });
  });

  group('the policy on top of the join', () {
    late Duration Function(Duration) resolveIn;

    Future<void> pumpResolver(
      WidgetTester tester,
      Widget Function(Widget) host,
    ) {
      return tester.pumpWidget(
        host(
          Builder(
            builder: (context) {
              resolveIn = (d) => resolveMotionDuration(context, d);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
    }

    testWidgets('transition-tier motion is instant under iOS Reduce Motion', (
      tester,
    ) async {
      _Platform(tester).report(reduceMotion: true);
      await pumpResolver(tester, _notCoui);

      expect(resolveIn(_transition), Duration.zero);
      expect(
        resolveIn(_ceiling),
        Duration.zero,
        reason: 'the ceiling itself is still transition tier',
      );
    });

    testWidgets('display-tier timing is left alone under iOS Reduce Motion', (
      tester,
    ) async {
      _Platform(tester).report(reduceMotion: true);
      await pumpResolver(tester, _notCoui);

      expect(resolveIn(_display), _display);
      expect(
        resolveIn(const Duration(milliseconds: CoreDuration.indeterminate)),
        const Duration(milliseconds: CoreDuration.indeterminate),
      );
    });

    testWidgets('nothing changes while the setting is off', (tester) async {
      _Platform(tester).report();
      await pumpResolver(tester, _notCoui);

      expect(resolveIn(_transition), _transition);
      expect(resolveIn(_display), _display);
    });

    testWidgets('the Android flag still collapses transition-tier motion', (
      tester,
    ) async {
      _Platform(tester).report();
      await pumpResolver(
        tester,
        (child) => MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: child,
        ),
      );

      expect(resolveIn(_transition), Duration.zero);
      expect(resolveIn(_display), _display);
    });

    testWidgets('a loading placeholder stops pulsing under iOS Reduce Motion', (
      tester,
    ) async {
      final platform = _Platform(tester)..report();
      late bool Function() pulses;
      await tester.pumpWidget(
        _notCoui(
          Builder(
            builder: (context) {
              pulses = () => resolvePlaceholderPulse(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(pulses(), isTrue, reason: 'baseline: it pulses');

      platform.report(reduceMotion: true);
      await tester.pumpWidget(
        _notCoui(
          Builder(
            builder: (context) {
              pulses = () => resolvePlaceholderPulse(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(pulses(), isFalse);
    });
  });

  group('outside CoUIApp the flag is read when a dependent builds', () {
    testWidgets('a tree with no scope still honours iOS Reduce Motion', (
      tester,
    ) async {
      _Platform(tester).report(reduceMotion: true);
      final answers = <bool>[];
      await tester.pumpWidget(_notCoui(_probe(answers)));

      expect(answers.last, isTrue);
    });

    testWidgets('and with no MediaQuery ancestor either', (tester) async {
      // The view is the only thing the lookup needs. A resolver used with
      // neither ancestor must not behave as if the user asked for less.
      final platform = _Platform(tester)..report(reduceMotion: true);
      final answers = <bool>[];
      await tester.pumpWidget(_probe(answers));
      expect(answers.last, isTrue);

      platform.report();
      final quiet = <bool>[];
      await tester.pumpWidget(_probe(quiet));
      expect(quiet.last, isFalse);
    });

    testWidgets('a later build reads the new value', (tester) async {
      final platform = _Platform(tester)..report();
      final answers = <bool>[];
      await tester.pumpWidget(_notCoui(_probe(answers)));
      expect(answers.last, isFalse);

      platform.report(reduceMotion: true);
      await tester.pumpWidget(_notCoui(_probe(answers)));
      expect(answers.last, isTrue);
    });
  });

  group('a change made while the app runs reaches what already built', () {
    testWidgets('CoUIApp mounts a scope that rebuilds its dependents', (
      tester,
    ) async {
      final platform = _Platform(tester)..report();
      final answers = <bool>[];
      await tester.pumpWidget(_coui(_probe(answers)));
      expect(answers.last, isFalse);
      final built = answers.length;

      platform.report(reduceMotion: true);
      await tester.pump();
      expect(answers.last, isTrue, reason: 'turned on while the app runs');
      expect(answers.length, built + 1, reason: 'one rebuild, not a storm');

      platform.report();
      await tester.pump();
      expect(answers.last, isFalse, reason: 'and back off again');
      expect(answers.length, built + 2);
    });

    testWidgets('an unrelated accessibility feature rebuilds nothing', (
      tester,
    ) async {
      final platform = _Platform(tester)..report();
      final answers = <bool>[];
      await tester.pumpWidget(_coui(_probe(answers)));
      final built = answers.length;

      platform.report(invertColors: true);
      await tester.pump();

      expect(answers.length, built);
    });

    testWidgets('the Android flag keeps working through MediaQuery', (
      tester,
    ) async {
      final platform = _Platform(tester)..report();
      final answers = <bool>[];
      await tester.pumpWidget(_coui(_probe(answers)));
      expect(answers.last, isFalse);

      platform.report(disableAnimations: true);
      await tester.pump();

      expect(answers.last, isTrue);
    });

    testWidgets('a scope an app mounts itself behaves the same', (
      tester,
    ) async {
      // For an app that hosts CoUI widgets without `CoUIApp`.
      final platform = _Platform(tester)..report();
      final answers = <bool>[];
      await tester.pumpWidget(
        _notCoui(ReducedMotionScope(child: _probe(answers))),
      );
      expect(answers.last, isFalse);

      platform.report(reduceMotion: true);
      await tester.pump();

      expect(answers.last, isTrue);
    });

    testWidgets('an animation already in flight ends when it is turned on', (
      tester,
    ) async {
      // `AnimatedValueBuilder` resolves its duration in
      // `didChangeDependencies`, so it only learns of the change if the
      // scope reaches it.
      final platform = _Platform(tester)..report();
      var observed = -1.0;
      await tester.pumpWidget(
        _coui(
          AnimatedValueBuilder<double>(
            initialValue: 0,
            value: 1,
            duration: const Duration(milliseconds: 300),
            builder: (context, value, child) {
              observed = value;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(observed, inExclusiveRange(0, 1), reason: 'baseline: mid-flight');

      platform.report(reduceMotion: true);
      await tester.pump();

      expect(observed, 1);
      expect(tester.hasRunningAnimations, isFalse);
    });
  });

  group('sites that decide on motion for themselves', () {
    group('LiquidMorphClip', () {
      const anchor = CoreMorphBlob(
        centerX: 168,
        centerY: 218,
        halfWidth: 48,
        halfHeight: 18,
        radius: 8,
      );
      const panel = CoreMorphBlob(
        centerX: 170,
        centerY: 110,
        halfWidth: 110,
        halfHeight: 70,
        radius: 16,
      );

      Widget clip({bool disableAnimations = false}) => MediaQuery(
        data: MediaQueryData(disableAnimations: disableAnimations),
        child: const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SizedBox(
              width: 320,
              height: 260,
              child: LiquidMorphClip(
                anchor: anchor,
                panel: panel,
                child: ColoredBox(color: Color(0xFF203040)),
              ),
            ),
          ),
        ),
      );

      bool isClipping(WidgetTester tester) =>
          tester.widget<ClipPath>(find.byType(ClipPath)).clipper != null;

      testWidgets('carves while no one asked for less', (tester) async {
        _Platform(tester).report();
        await tester.pumpWidget(clip());

        expect(isClipping(tester), isTrue);
      });

      testWidgets('does not morph under iOS Reduce Motion', (tester) async {
        _Platform(tester).report(reduceMotion: true);
        await tester.pumpWidget(clip());

        expect(isClipping(tester), isFalse);
      });

      testWidgets('does not morph under the Android flag', (tester) async {
        _Platform(tester).report();
        await tester.pumpWidget(clip(disableAnimations: true));

        expect(isClipping(tester), isFalse);
      });

      testWidgets('stops carving when the setting is turned on mid-morph', (
        tester,
      ) async {
        final platform = _Platform(tester)..report();
        await tester.pumpWidget(_notCoui(ReducedMotionScope(child: clip())));
        await tester.pump(const Duration(milliseconds: 40));
        expect(isClipping(tester), isTrue, reason: 'baseline: mid-morph');

        platform.report(reduceMotion: true);
        await tester.pump();

        expect(isClipping(tester), isFalse);
      });
    });

    group('Dock', () {
      Dock dock(int active) => Dock(
        items: [
          for (var i = 0; i < 3; i++)
            CoreDockItemData<Widget>(
              icon: const Icon(LucideIcons.house),
              label: 'Item $i',
              isActive: i == active,
              onPressed: () {},
            ),
        ],
      );

      Future<void> moveActive(
        WidgetTester tester, {
        bool disableAnimations = false,
      }) async {
        Widget app(int active) => _coui(
          MediaQuery(
            data: MediaQueryData(disableAnimations: disableAnimations),
            child: dock(active),
          ),
        );
        await tester.pumpWidget(app(0));
        await tester.pumpWidget(app(2));
        await tester.pump();
      }

      testWidgets('flies the pill when no one asked for less', (tester) async {
        _Platform(tester).report();
        await moveActive(tester);

        expect(find.byType(LiquidMorphClip), findsOneWidget);
      });

      testWidgets('skips the flight under iOS Reduce Motion', (tester) async {
        _Platform(tester).report(reduceMotion: true);
        await moveActive(tester);

        expect(find.byType(LiquidMorphClip), findsNothing);
      });

      testWidgets('skips the flight under the Android flag', (tester) async {
        _Platform(tester).report();
        await moveActive(tester, disableAnimations: true);

        expect(find.byType(LiquidMorphClip), findsNothing);
      });
    });

    group('Status', () {
      bool pulses(WidgetTester tester) => find
          .descendant(
            of: find.byType(Status),
            matching: find.byType(FadeTransition),
          )
          .evaluate()
          .isNotEmpty;

      testWidgets('pulses when no one asked for less', (tester) async {
        _Platform(tester).report();
        await tester.pumpWidget(
          _notCoui(const Status(animated: true, semanticLabel: 'Busy')),
        );

        expect(pulses(tester), isTrue);
      });

      testWidgets('holds still under iOS Reduce Motion', (tester) async {
        _Platform(tester).report(reduceMotion: true);
        await tester.pumpWidget(
          _notCoui(const Status(animated: true, semanticLabel: 'Busy')),
        );

        expect(pulses(tester), isFalse);
      });

      testWidgets('holds still under the Android flag', (tester) async {
        _Platform(tester).report();
        await tester.pumpWidget(
          _notCoui(
            const MediaQuery(
              data: MediaQueryData(disableAnimations: true),
              child: Status(animated: true, semanticLabel: 'Busy'),
            ),
          ),
        );

        expect(pulses(tester), isFalse);
      });

      testWidgets('follows the setting while the app runs', (tester) async {
        final platform = _Platform(tester)..report();
        await tester.pumpWidget(
          _coui(const Status(animated: true, semanticLabel: 'Busy')),
        );
        expect(pulses(tester), isTrue);

        platform.report(reduceMotion: true);
        await tester.pump();
        expect(pulses(tester), isFalse);

        platform.report();
        await tester.pump();
        expect(pulses(tester), isTrue);
      });
    });

    group('NavigationBar', () {
      const glass = CoreNavigationBarStyle(surfaceStyle: .liquidGlass);

      // The bar's selection duration is a spring's settling tail — longer
      // than the transition ceiling — so the duration policy alone would
      // leave it running. The bar asks the join directly for exactly that.
      Future<ResolvedNavigationBar> resolve(
        WidgetTester tester, {
        bool disableAnimations = false,
      }) async {
        late ResolvedNavigationBar resolved;
        await tester.pumpWidget(
          MediaQuery(
            data: MediaQueryData(disableAnimations: disableAnimations),
            child: Theme(
              data: ThemeData.fromCore(CoreThemePresets.light),
              child: Builder(
                builder: (context) {
                  resolved = resolveNavigationBar(
                    context,
                    mode: .bar,
                    variant: .standard,
                    navigationBarStyle: glass,
                  );
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        );

        return resolved;
      }

      testWidgets('keeps the spring and the lens while no one asked', (
        tester,
      ) async {
        _Platform(tester).report();
        final resolved = await resolve(tester);

        expect(
          resolved.duration,
          greaterThan(_ceiling),
          reason: 'the premise: only a direct check can zero this duration',
        );
        expect(resolved.selectionRefraction, isNotNull);
      });

      testWidgets(
        'selects at once and drops the lens under iOS Reduce Motion',
        (
          tester,
        ) async {
          _Platform(tester).report(reduceMotion: true);
          final resolved = await resolve(tester);

          expect(resolved.duration, Duration.zero);
          expect(resolved.selectionRefraction, isNull);
          expect(
            resolved.refraction,
            CoreNavigationBarStyle.glassRestingRefraction,
            reason: 'the resting glass stays; only the optical lens goes',
          );
        },
      );

      testWidgets('selects at once and drops the lens under the Android flag', (
        tester,
      ) async {
        _Platform(tester).report();
        final resolved = await resolve(tester, disableAnimations: true);

        expect(resolved.duration, Duration.zero);
        expect(resolved.selectionRefraction, isNull);
      });
    });
  });
}
