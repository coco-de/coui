import 'package:coui_core/coui_core.dart';
import 'package:coui_web/coui_web.dart';
import 'package:html/dom.dart' as html;
import 'package:jaspr/jaspr.dart' hide Text;
import 'package:jaspr_test/jaspr_test.dart';
import 'package:jaspr_test/server_test.dart';

import '../../helpers/pump_with_theme.dart';

// A `<div>` with `overflow: auto` scrolls under a pointer whether or not
// anybody named it, so none of this shows up in a screenshot. What these
// pin is the half only a reader or a Tab key can see — and the `<style>`
// rule that makes the landing visible once Tab can reach it.

Component _viewport({String? semanticLabel, Map<String, String>? attributes}) =>
    ScrollableClient(
      semanticLabel: semanticLabel,
      attributes: attributes,
      builder: (context, offset, viewportSize, child) => const Text('content'),
    );

Map<String, String> _rootAttributes(ComponentTester tester) {
  final root = find
      .byType(DomComponent)
      .evaluate()
      .map((e) => e.component as DomComponent)
      .firstWhere((c) => (c.attributes ?? const {}).containsKey('role'));

  return root.attributes ?? const {};
}

/// The focused ring rule (the `:focus-visible` rule that sets the
/// outline colour) out of a component's scoped `<style>`.
///
/// The stylesheet also carries the scrollbar skin, and the two share
/// colour tokens — so an assertion that reads the whole text can pass on
/// the scrollbar's copy of a value the ring was supposed to carry. The
/// ring itself is three rules (resting colour, the zero-specificity
/// switch that turns the outline on, and the focused values); this picks
/// the last.
String? _focusVisibleRule(String css) {
  for (final rule in css.split('}')) {
    if (rule.contains(':focus-visible') && rule.contains('outline-color')) {
      return '$rule}';
    }
  }

  return null;
}

html.Element? _rootOf(html.Document? document) =>
    document?.querySelector('[role="${CoreSemanticRole.group.ariaRole}"]');

void main() {
  group('the viewport announces itself', () {
    testComponents('it says what it is and what it is called', (tester) async {
      pumpWithTheme(tester, _viewport());
      final attributes = _rootAttributes(tester);

      expect(attributes['role'], CoreSemanticRole.group.ariaRole);
      // Not merely present — a region named '' is read out as nothing,
      // which is the state this component shipped in.
      expect(attributes['aria-label'], isNotEmpty);
      expect(attributes['aria-label'], 'Scrollable region');
    });

    testComponents('an explicit label wins over the fallback', (tester) async {
      pumpWithTheme(tester, _viewport(semanticLabel: 'Order table'));

      expect(_rootAttributes(tester)['aria-label'], 'Order table');
    });

    testComponents('and a caller-supplied attribute still wins over both', (
      tester,
    ) async {
      // Passthrough is the contract every other component honours: a
      // caller who states the role themselves — or takes the viewport out
      // of the tab order because their content owns the keys — keeps
      // their answer.
      pumpWithTheme(
        tester,
        _viewport(attributes: {'tabindex': '-1', 'aria-label': 'Canvas'}),
      );
      final attributes = _rootAttributes(tester);

      expect(attributes['tabindex'], '-1');
      expect(attributes['aria-label'], 'Canvas');
    });
  });

  group('the viewport can be reached by keyboard', () {
    testComponents('it is in the tab order', (tester) async {
      // Browsers disagree about whether a scrollable `<div>` is focusable
      // on its own, and where it is, arrow keys work only because the
      // engine chose to help. Stating it removes the disagreement.
      pumpWithTheme(tester, _viewport());

      expect(_rootAttributes(tester)['tabindex'], '0');
    });

    testServer('landing on it is visible', (tester) async {
      // WCAG 2.4.7 — the ring is keyed on `:focus-visible` so a pointer
      // press does not paint one, matching the Flutter twin's
      // `onShowFocusHighlight`.
      tester.pumpComponent(CoUIWeb(theme: .coui, child: _viewport()));
      final response = await tester.request('/');
      final root = _rootOf(response.document);
      expect(root, isNotNull);

      final style = root!.querySelector('style');
      expect(style, isNotNull);
      expect(style!.text, contains(':focus-visible'));
      expect(
        _focusVisibleRule(style.text),
        contains('outline-color:rgb(var(--coui-focus-ring))'),
        reason:
            'the ring is an outline, as on every other focusable '
            "component here — not clipped by the viewport's own overflow",
      );
      expect(
        style.text,
        isNot(contains('box-shadow')),
        reason: 'the default gap band is transparent and paints nothing',
      );
      // Scoped to this instance — a page with two viewports must not
      // have one of them ring when the other is focused.
      expect(style.text, contains('#${root.attributes['id']}:focus-visible'));
    });

    testServer('the user-agent outline is suppressed so only one ring paints', (
      tester,
    ) async {
      // The root takes `tabindex="0"` unconditionally and paints its own
      // outline ring, so without `outline-none` the browser's default
      // outline would draw instead. Unconditional because it is the
      // ring's resting state: focusing then moves only the colour.
      // Shipped without this once; the scoped `<style>` assertions above
      // all stayed green because they only ever look inside the rule.
      tester.pumpComponent(CoUIWeb(theme: .coui, child: _viewport()));
      final response = await tester.request('/');
      final root = _rootOf(response.document);

      expect(
        root!.classes,
        contains('outline-none'),
        reason:
            'every other focusable component emits this on both the '
            'class-safe and the scoped-rule path (button_style.dart)',
      );
      expect(root.classes, isNot(contains('focus-visible:outline-none')));
    });

    testServer('a per-instance ring override reaches the emitted rule', (
      tester,
    ) async {
      // The ring values arrive through the nested `focusOutlineStyle`
      // slot, so the chaining guard cannot see a flat `merged.ringOpacity`
      // and is told to skip it. That skip is only honest if the override
      // really does reach — this is the check that makes it so.
      tester.pumpComponent(
        CoUIWeb(
          theme: .coui,
          child: Theme(
            data: ThemeData(
              coreComponentTheme: const CoreComponentTheme(
                scrollableClient: CoreScrollableClientTheme(
                  style: CoreScrollableClientStyle(
                    focusOutlineStyle: CoreFocusOutlineStyle(ringOpacity: 0.5),
                  ),
                ),
              ),
            ),
            child: _viewport(),
          ),
        ),
      );
      final response = await tester.request('/');
      final style = _rootOf(response.document)!.querySelector('style');

      // Scoped to the ring rule on purpose. The scrollbar thumb in the
      // same `<style>` is `onSurface` at 50% too, so searching the whole
      // text would pass with the override thrown away.
      final ring = _focusVisibleRule(style!.text);
      expect(ring, isNotNull, reason: 'the ring rule must be emitted');
      expect(ring, contains('50%'));
    });

    testServer('the scrollbar skin is still emitted alongside the ring', (
      tester,
    ) async {
      // Both rules share one `<style>`; appending the ring must not have
      // displaced what was already there.
      tester.pumpComponent(CoUIWeb(theme: .coui, child: _viewport()));
      final response = await tester.request('/');
      final style = _rootOf(response.document)!.querySelector('style');

      expect(style!.text, contains('::-webkit-scrollbar'));
      expect(style.text, contains(':focus-visible'));
    });
  });
}
