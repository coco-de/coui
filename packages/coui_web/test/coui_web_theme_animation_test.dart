import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

CoUIWeb _app({bool? enableThemeAnimation}) => .new(
  theme: .coui,
  enableThemeAnimation: enableThemeAnimation ?? true,
  child: div([]),
);

void main() {
  testComponents('glass contrast preferences apply without theme animation', (
    tester,
  ) async {
    tester.pumpComponent(_app(enableThemeAnimation: false));
    final css = find
        .byType(RawText)
        .evaluate()
        .map((e) => (e.component as RawText).text)
        .join();
    expect(css, contains('(prefers-reduced-transparency:reduce)'));
    expect(css, contains('(prefers-contrast:more)'));
    expect(css, contains('[data-coui-app-bar-edge]{opacity:1!important;'));
    expect(css, contains('background:rgb(var(--coui-surface))!important;'));
  });

  group('CoUIWeb.enableThemeAnimation', () {
    test('defaults to true (Flutter CoUIApp parity), settable to false', () {
      expect(_app().enableThemeAnimation, isTrue);
      expect(_app(enableThemeAnimation: false).enableThemeAnimation, isFalse);
    });

    // The app root always mounts a couple of global `<style>` blocks that
    // are independent of the theme cross-fade (the `OverlayHost` portal
    // stylesheet + the `Clickable` press-shrink rule), so this asserts the
    // *delta* — enabling the animation adds exactly one more `<style>`
    // (the theme-transition rule) — rather than an absolute count that
    // would silently break whenever another global stylesheet is added.
    testComponents('theme cross-fade adds exactly one <style> when enabled', (
      tester,
    ) async {
      tester.pumpComponent(_app(enableThemeAnimation: false));
      final withoutAnim = find.tag('style').evaluate().length;

      tester.pumpComponent(_app());
      final withAnim = find.tag('style').evaluate().length;

      expect(withAnim, withoutAnim + 1);
    });

    // Regression for #3468: the crossfade rule used to bake a literal
    // `150ms` (`'transition-duration:${CoreDuration.fast}ms;'`) instead of
    // referencing the `--coui-duration-150` CSS variable. Since the rule is
    // scoped to `.coui-theme-anim *` — every descendant of a
    // `CoUIWeb.enableThemeAnimation` root, 139/139 docs pages — that meant
    // `@media (prefers-reduced-motion:reduce)` (which zeroes
    // `--coui-duration-150`) could never reach it: a reduced-motion user
    // still got a full-speed theme crossfade site-wide.
    testComponents(
      'crossfade duration is token-routed, not a literal ms (#3468)',
      (tester) async {
        tester.pumpComponent(_app());
        final crossfadeCss = find
            .byType(RawText)
            .evaluate()
            .map((e) => (e.component as RawText).text)
            .firstWhere((t) => t.contains('coui-theme-anim'));

        expect(
          crossfadeCss,
          contains('transition-duration:var(--coui-duration-150);'),
        );
        expect(crossfadeCss, isNot(contains('transition-duration:150ms;')));
      },
    );

    // Regression for #3622: switching the surface *preset*
    // (`[data-coui-style]`) snapped border-width / border-radius
    // instantly even with the theme cross-fade enabled, because the
    // existing crossfade rule only ever transitioned colour properties
    // (a light/dark swap never touches geometry) — a preset swap does.
    group('surface geometry cross-fade (#3622)', () {
      testComponents(
        'transitions border-width and border-radius on surface-marked elements',
        (tester) async {
          tester.pumpComponent(_app());
          final css = find
              .byType(RawText)
              .evaluate()
              .map((e) => (e.component as RawText).text)
              .firstWhere((t) => t.contains('.coui-surface{'));

          expect(css, contains('.coui-surface{'));
          expect(css, contains('border-width'));
          expect(css, contains('border-radius'));
          // The colour set must be restated here too — a longhand
          // `transition-property` from this (later, same-specificity)
          // rule fully replaces the broad crossfade rule's list for any
          // element both match, so dropping colour here would silently
          // undo it for every surface-marked element.
          expect(css, contains('background-color'));
        },
      );

      testComponents('token-routed duration, not a literal ms', (tester) async {
        tester.pumpComponent(_app());
        final css = find
            .byType(RawText)
            .evaluate()
            .map((e) => (e.component as RawText).text)
            .firstWhere((t) => t.contains('.coui-surface{'));

        // `firstWhere` above returns the same combined RawText as the
        // #3468 test (both rules are concatenated into one <style>
        // node), so re-scope to just the surface-geometry rule text
        // before asserting on its duration to avoid matching the other
        // rule's (already-covered) duration declaration instead.
        final surfaceRuleStart = css.indexOf('.coui-surface{');
        final surfaceRule = css.substring(surfaceRuleStart);

        expect(
          surfaceRule,
          contains('transition-duration:var(--coui-duration-150);'),
        );
        expect(surfaceRule, isNot(contains('transition-duration:150ms;')));
      });

      testComponents('absent when enableThemeAnimation is false', (
        tester,
      ) async {
        tester.pumpComponent(_app(enableThemeAnimation: false));
        final hasSurfaceGeometryRule = find
            .byType(RawText)
            .evaluate()
            .map((e) => (e.component as RawText).text)
            .any((t) => t.contains('.coui-surface{'));

        expect(hasSurfaceGeometryRule, isFalse);
      });
    });
  });
}
