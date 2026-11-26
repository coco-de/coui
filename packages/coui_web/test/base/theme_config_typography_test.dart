// Tests for the Web typography theme wiring (#2624). The Tailwind fontSize
// config references per-role CSS variables, and the SSR `cssVariables` block
// emits the default per-role values from CoreTypography — so a project's
// `theme.typography` overrides the role composition on Web (parity with
// Flutter).
import 'package:coui_web/coui_web.dart';
import 'package:test/test.dart';

/// The rendering expression lives beside the current typography values,
/// so replacing that block does not need to rebuild Tailwind's classes.
String _roleLineBox(String role) =>
    'var(--coui-text-$role-rendered-line-height)';

void main() {
  final config = ThemeConfig.defaults();

  group('ThemeConfig.cssVariables — default per-role typography', () {
    final css = config.cssVariables;

    test(
      'body-medium default matches the scale (14px / 1.5 / 400 / -0.01em)',
      () {
        // Below 20px the role tracks at CoreLetterSpacing.tight10.
        expect(css, contains('--coui-text-body-medium-size:0.875rem;'));
        expect(css, contains('--coui-text-body-medium-line-height:1.5;'));
        expect(css, contains('--coui-text-body-medium-weight:400;'));
        expect(css, contains('--coui-text-body-medium-tracking:-0.01em;'));
      },
    );

    test('display-large default matches (52px / 1.4 / 700 / -0.02em)', () {
      expect(css, contains('--coui-text-display-large-size:3.25rem;'));
      expect(css, contains('--coui-text-display-large-line-height:1.4;'));
      expect(css, contains('--coui-text-display-large-weight:700;'));
      expect(css, contains('--coui-text-display-large-tracking:-0.02em;'));
    });

    test('headline is bold (700), one step above title (600)', () {
      expect(css, contains('--coui-text-title-medium-weight:600;'));
      expect(css, contains('--coui-text-headline-medium-weight:700;'));
    });

    test('body-xs and label-xs are the small rungs (12 / 1.5, 11 / 1.4)', () {
      expect(css, contains('--coui-text-body-xs-size:0.75rem;'));
      expect(css, contains('--coui-text-body-xs-line-height:1.5;'));
      expect(css, contains('--coui-text-body-xs-weight:400;'));
      expect(css, contains('--coui-text-label-xs-size:0.6875rem;'));
      expect(css, contains('--coui-text-label-xs-line-height:1.4;'));
      expect(css, contains('--coui-text-label-xs-weight:500;'));
    });

    test('the code roles sit on one fixed line box, written in rem', () {
      // 21 / 16 — a rem length rather than a multiplier, so 11 · 12 · 13px
      // code shares one line grid and the box follows the browser's text
      // size the way the glyphs do. A `px` box would stay put while the
      // glyphs inside it grew.
      for (final (role, size) in [
        ('code-xs', '0.6875rem'),
        ('code-sm', '0.75rem'),
        ('code-md', '0.8125rem'),
      ]) {
        expect(css, contains('--coui-text-$role-size:$size;'));
        expect(css, contains('--coui-text-$role-line-height:1.3125rem;'));
        expect(css, contains('--coui-text-$role-weight:400;'));
        expect(css, contains('--coui-text-$role-tracking:0.0em;'));
        // Never a bare multiplier as well.
        expect(
          RegExp('--coui-text-$role-line-height:[0-9.]+;').hasMatch(css),
          isFalse,
        );
      }
    });
  });

  group('ThemeConfig.cssVariables — primitives the roles stand on', () {
    final css = config.cssVariables;

    test('font sizes 11 · 13 · 15 and line height 1.5 have variables', () {
      expect(css, contains('--coui-font-size-11:0.6875rem;'));
      expect(css, contains('--coui-font-size-13:0.8125rem;'));
      expect(css, contains('--coui-font-size-15:0.9375rem;'));
      expect(css, contains('--coui-line-height-150:1.5;'));
    });

    test('the mono stack is Geist Mono, then Pretendard for Hangul', () {
      expect(
        css,
        contains(
          '--coui-font-family-mono:'
          '"${CoreFontFamily.mono}", "${CoreFontFamily.sans}", monospace;',
        ),
      );
      expect(
        css,
        contains('--coui-font-family-mono:"Geist Mono", "Pretendard", '),
      );
    });
  });

  group('ThemeConfig.tailwindConfig — role → per-role var references', () {
    final tw = config.tailwindConfig;

    test('body-medium fontSize entry references the per-role variables', () {
      expect(
        tw,
        contains(
          '"body-medium":["var(--coui-text-body-medium-size)",'
          '{lineHeight:"${_roleLineBox('body-medium')}",'
          'fontWeight:"var(--coui-text-body-medium-weight)",'
          'letterSpacing:"var(--coui-text-body-medium-tracking)"}]',
        ),
      );
    });

    test('the code-sm entry reads its box from the line-height variable', () {
      expect(
        tw,
        contains(
          '"code-sm":["var(--coui-text-code-sm-size)",'
          '{lineHeight:"${_roleLineBox('code-sm')}",'
          'fontWeight:"var(--coui-text-code-sm-weight)",'
          'letterSpacing:"var(--coui-text-code-sm-tracking)"}]',
        ),
      );
    });

    test('the primitive keys 11 · 13 · 15 and h150 reach their variables', () {
      for (final (key, variable) in [
        (CoreFontSize.scale.s11, '--coui-font-size-11'),
        (CoreFontSize.scale.s13, '--coui-font-size-13'),
        (CoreFontSize.scale.s15, '--coui-font-size-15'),
        (CoreLineHeight.scale.h150, '--coui-line-height-150'),
      ]) {
        expect(tw, contains('$key:"var($variable)"'));
      }
    });

    test('runtime type changes do not need a new Tailwind config', () {
      final changed = ThemeConfig.from(
        CouiColorPresets.source,
        typography: CoreTypography.coui.copyWith(
          labelLarge: const CoreTextStyle(fontSize: 14, lineHeightPx: 28),
          codeSm: const CoreTextStyle(fontSize: 12, lineHeight: 1.4),
        ),
      );
      expect(changed.tailwindConfig, tw);
    });

    test('every role has a fontSize entry', () {
      for (final token in CoreTextStyles.values) {
        expect(
          tw,
          contains('"${token.name}":["var(--coui-text-${token.name}-size)"'),
          reason: 'missing role ${token.name}',
        );
      }
    });
  });
}
