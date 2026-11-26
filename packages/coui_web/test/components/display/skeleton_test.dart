import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

const _kCustomWidth = '200px';
const _kCustomHeight = '20px';
const _kCustomFromOpacity = 0.2;
const _kCustomToOpacity = 0.9;

Iterable<Map<String, String>> _attributes(ComponentTester tester) => find
    .byType(DomComponent)
    .evaluate()
    .map((e) => e.component as DomComponent)
    .map((c) => c.attributes ?? const {});

Iterable<Map<String, String>> _inlineStyles(ComponentTester tester) => find
    .byType(DomComponent)
    .evaluate()
    .map((e) => e.component as DomComponent)
    .map((c) => c.styles?.properties ?? const {});

void main() {
  group('Skeleton', () {
    test('default variant is rectangular', () {
      final skeleton = Skeleton();
      expect(skeleton.variant, equals(CoreSkeletonVariant.rectangular));
    });

    test('circle constructor sets circular variant', () {
      final skeleton = Skeleton.circle(size: '40px');
      expect(skeleton.variant, equals(CoreSkeletonVariant.circular));
    });

    test('text constructor sets text variant', () {
      final skeleton = Skeleton.text();
      expect(skeleton.variant, equals(CoreSkeletonVariant.text));
    });

    test('accepts custom width/height', () {
      final skeleton = Skeleton(width: _kCustomWidth, height: _kCustomHeight);
      expect(skeleton.width, equals(_kCustomWidth));
      expect(skeleton.height, equals(_kCustomHeight));
    });

    testComponents('rectangular variant pumps without errors', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        Skeleton(width: _kCustomWidth, height: _kCustomHeight),
      );
    });

    testComponents('circular variant pumps without errors', (tester) async {
      pumpWithTheme(tester, Skeleton.circle(size: '40px'));
    });

    testComponents('text variant pumps without errors', (tester) async {
      pumpWithTheme(tester, Skeleton.text());
    });

    // A skeleton is a "still loading" message — `role="status"` carries
    // implicit live-region semantics (unlike `role="progressbar"`, which
    // does not), matching the Flutter twin's `Semantics(liveRegion: true)`
    // and the sibling `Loading` component's own role. Silence here reads
    // as a finished but empty screen to a screen-reader user.
    testComponents('announces itself via role="status" (live region)', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        Skeleton(width: _kCustomWidth, height: _kCustomHeight),
      );

      final withStatusRole = _attributes(
        tester,
      ).where((attrs) => attrs['role'] == 'status');
      expect(withStatusRole, isNotEmpty);
    });

    testComponents('carries an aria-label alongside the status role', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        Skeleton(width: _kCustomWidth, height: _kCustomHeight),
      );

      final statusAttrs = _attributes(
        tester,
      ).where((attrs) => attrs['role'] == 'status').first;
      expect(statusAttrs['aria-label'], isNotNull);
      expect(statusAttrs['aria-label'], isNotEmpty);
    });

    group('pulse opacity', () {
      // Tailwind's built-in `animate-pulse` keyframe hardcodes
      // `opacity: 1 → 0.5 → 1` and never reads a CSS variable, so a
      // fromOpacity/toOpacity override used to be silently dropped on
      // Web (Flutter honoured it). The root must point at the custom
      // `co-skeleton-pulse` keyframes (defined once in
      // `ThemeConfig.cssVariables`) instead of relying on Tailwind's
      // class-level keyframe for the animation name.
      testComponents('root points at the custom keyframes by name', (
        tester,
      ) async {
        pumpWithTheme(
          tester,
          Skeleton(width: _kCustomWidth, height: _kCustomHeight),
        );

        // Through the variable the reduced-motion query overrides, falling
        // back to the pulse — an inline literal would outrank the query.
        final withAnimationName = _inlineStyles(tester).where(
          (styles) =>
              styles['animation-name'] ==
              'var($kSkeletonPulseNameVar, $kSkeletonPulseAnimationName)',
        );
        expect(withAnimationName, isNotEmpty);
      });

      testComponents('fromOpacity/toOpacity overrides reach the inline vars', (
        tester,
      ) async {
        pumpWithTheme(
          tester,
          Skeleton(
            width: _kCustomWidth,
            height: _kCustomHeight,
            skeletonStyle: const CoreSkeletonStyle(
              fromOpacity: _kCustomFromOpacity,
              toOpacity: _kCustomToOpacity,
            ),
          ),
        );

        // The two overrides no longer travel as bare numbers. They are composed
        // INTO the pulse colours (`pulseBase.scaleAlpha(fromOpacity)`), because
        // the keyframes animate `background-color` rather than the element's
        // `opacity` — Flutter fades the fill's alpha between the same two ends,
        // and fading the element instead took every descendant with it.
        //
        // Keeping the token inside the composed colour is the other half: a raw
        // rgba would freeze the light-mode value, and dark mode would stop
        // tracking through the animation.
        final rootStyles = _inlineStyles(
          tester,
        ).where((styles) => styles.containsKey('--pulse-from')).first;
        final from = rootStyles['--pulse-from']!;
        final to = rootStyles['--pulse-to']!;
        for (final v in [from, to]) {
          expect(v, contains('var(--coui-'), reason: 'token must survive');
        }
        expect(from, contains('${(_kCustomFromOpacity * 100).round()}%'));
        expect(to, contains('${(_kCustomToOpacity * 100).round()}%'));
        expect(from, isNot(equals(to)));
      });

      // Every variant shares one resolver value, so every pulsing node — the
      // box, the circle, each text line — rests at 70% and peaks at the fill
      // itself (no alpha modifier).
      for (final entry in {
        'rectangular': Skeleton(width: _kCustomWidth, height: _kCustomHeight),
        'circular': Skeleton.circle(size: '40px'),
        'text': Skeleton.text(),
      }.entries) {
        testComponents('${entry.key} rests at 70% and peaks at the fill', (
          tester,
        ) async {
          pumpWithTheme(tester, entry.value);

          final pulsing = _inlineStyles(
            tester,
          ).where((style) => style.containsKey('--pulse-from')).toList();
          expect(pulsing, isNotEmpty);
          for (final style in pulsing) {
            expect(
              style['--pulse-from'],
              'rgb(var(--coui-surface-container-highest) / 70%)',
            );
            expect(
              style['--pulse-to'],
              'rgb(var(--coui-surface-container-highest))',
            );
          }
        });
      }
    });

    // Geometry the designer fixed: a box takes corner 8, a text line is 12
    // high (0.75rem) with 12 between lines, the last line 60% wide.
    group('default geometry', () {
      const corner8 = 'var(--coui-radius-8)';

      testComponents('a rectangular box takes corner 8', (tester) async {
        pumpWithTheme(
          tester,
          Skeleton(width: _kCustomWidth, height: _kCustomHeight),
        );

        final box = _inlineStyles(
          tester,
        ).where((styles) => styles.containsKey('--pulse-from')).first;
        expect(box['border-radius'], '$corner8 $corner8 $corner8 $corner8');
      });

      testComponents('a circle stays full', (tester) async {
        pumpWithTheme(tester, Skeleton.circle(size: '40px'));

        final box = _inlineStyles(
          tester,
        ).where((styles) => styles.containsKey('--pulse-from')).first;
        expect(box['border-radius'], contains('var(--coui-radius-9999)'));
      });

      testComponents('text lines are 12 high with 12 between them', (
        tester,
      ) async {
        pumpWithTheme(tester, Skeleton.text());

        final styles = _inlineStyles(tester).toList();
        final container = styles
            .where((style) => style.containsKey('gap'))
            .single;
        // The 12px step names its spacing variable (`--coui-space-12` is
        // 12 / 16 = 0.75rem in `:root`).
        expect(container['gap'], 'var(--coui-space-12)');

        final lines = styles
            .where((style) => style.containsKey('--pulse-from'))
            .toList();
        expect(lines, hasLength(3));
        for (final line in lines) {
          expect(line['height'], '0.75rem');
          expect(
            line['border-radius'],
            contains('var(--coui-radius-4)'),
            reason: 'a text line keeps corner 4',
          );
        }
        expect(lines[0]['width'], '100%');
        expect(lines[1]['width'], '100%');
        expect(lines.last['width'], '60%');
      });
    });
  });
}
