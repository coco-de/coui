import 'dart:io';

import 'package:coui_web/coui_web.dart';
import 'package:test/test.dart';

/// `theme_config.dart` used to emit zero `screens` keys — Tailwind's
/// `sm:`/`md:`/`lg:`/`xl:`/`2xl:` variants resolved against Tailwind's own
/// built-in scale, not `CoreBreakpoint`. The two scales carry the same five
/// numbers today, so nothing looked broken; moving `CoreBreakpoint` would
/// have moved Flutter and left Web's Tailwind variants unchanged, with no
/// diff showing the divergence (#3776).
void main() {
  final config = ThemeConfig.defaults();
  final tw = config.tailwindConfig;

  group('ThemeConfig — Tailwind screens scale', () {
    test('wires screens under theme.extend', () {
      expect(tw, contains('screens:{'));
    });

    test('every screen key resolves to the matching CoreBreakpoint width', () {
      expect(tw, contains('sm:"${CoreBreakpoint.sm.minWidth.toInt()}px"'));
      expect(tw, contains('md:"${CoreBreakpoint.md.minWidth.toInt()}px"'));
      expect(tw, contains('lg:"${CoreBreakpoint.lg.minWidth.toInt()}px"'));
      expect(tw, contains('xl:"${CoreBreakpoint.xl.minWidth.toInt()}px"'));
      // Digit-first key must be quoted to stay valid JS.
      expect(
        tw,
        contains('"2xl":"${CoreBreakpoint.xxl.minWidth.toInt()}px"'),
      );
    });

    test('does not emit an xs screen — no Tailwind default counterpart', () {
      // `xs:` never had a Tailwind default variant, and a
      // `(min-width:0px)` media query would always match, so wiring it
      // would add a new capability rather than fix the missing wiring.
      expect(tw, isNot(contains('xs:"0px"')));
    });

    test('screens precede colors — extend key order does not hide it', () {
      final screensIndex = tw.indexOf('screens:{');
      final colorsIndex = tw.indexOf('colors:{');
      expect(screensIndex, greaterThanOrEqualTo(0));
      expect(colorsIndex, greaterThan(screensIndex));
    });
  });

  group('ThemeConfig — screens value parity (no value drift)', () {
    // This ticket is wiring only — pinning the literal pixel values keeps
    // a future edit to `CoreBreakpoint` from silently also changing what
    // ships here without a visible diff in this test.
    test('CoreBreakpoint still matches Tailwind defaults numerically', () {
      expect(CoreBreakpoint.sm.minWidth, equals(640));
      expect(CoreBreakpoint.md.minWidth, equals(768));
      expect(CoreBreakpoint.lg.minWidth, equals(1024));
      expect(CoreBreakpoint.xl.minWidth, equals(1280));
      expect(CoreBreakpoint.xxl.minWidth, equals(1536));
    });
  });

  group('ThemeConfig — screens is source-wired to CoreBreakpoint (#3776)', () {
    // `CoreBreakpoint` members are compile-time enum constants — nothing
    // can flip `CoreBreakpoint.md.minWidth` at test runtime to observe
    // whether Web "follows". What is checkable is the wiring itself: the
    // generator source has to *read* the member rather than restate its
    // number. If a future edit reverted to a bare `'md:"768px"'` literal,
    // `CoreBreakpoint` could move again without this file's output moving
    // with it — the exact divergence #3776 reported, and a value-only
    // assertion (both sides pinned to "768") would not catch a revert
    // back to that literal.
    final source = File('lib/src/base/theme_config.dart').readAsStringSync();

    test('the screens config reads CoreBreakpoint members, not literals', () {
      for (final member in ['sm', 'md', 'lg', 'xl', 'xxl']) {
        expect(
          source,
          contains('CoreBreakpoint.$member.minWidth'),
          reason:
              '_screensConfig has to read CoreBreakpoint.$member.minWidth — '
              'a hardcoded literal here is exactly the "looks right by '
              'coincidence, not by wiring" bug this ticket exists to close',
        );
      }
    });
  });
}
