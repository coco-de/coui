import 'dart:math' as math;

import 'package:coui_web/coui_web.dart';
import 'package:html/dom.dart' as html;
import 'package:jaspr_test/server_test.dart';

// DOM shape of the redesigned rating: size steps, the three star states,
// the optional value / count text and the single ring around the group.

Component _rating({
  double value = 3.5,
  CoreComponentSize size = CoreStarRatingStyle.defaultSize,
  bool showValue = false,
  bool showCount = false,
  int? count,
  bool enabled = true,
}) => StarRating(
  value: value,
  size: size,
  showValue: showValue,
  showCount: showCount,
  count: count,
  enabled: enabled,
  onChanged: (_) {},
);

html.Element? _rootOf(html.Document? document) =>
    document?.querySelector('[role="slider"]');

List<html.Element> _starsOf(html.Document? document) =>
    document?.querySelectorAll('[data-coui-star-state]') ?? const [];

/// The `R G B` triplet `--coui-<name>` holds in the rule for [selector].
List<int> _tripletOf(String css, String selector, String name) {
  final match = RegExp(
    '${RegExp.escape(selector)}\\s*\\{[^}]*--coui-$name:\\s*(\\d+) (\\d+) (\\d+);',
  ).firstMatch(css);
  expect(match, isNotNull, reason: '--coui-$name under $selector');
  return [for (var i = 1; i <= 3; i++) int.parse(match!.group(i)!)];
}

/// WCAG relative luminance of an sRGB triplet.
double _luminance(List<int> rgb) {
  double channel(int v) {
    final c = v / 255;
    return c <= 0.03928
        ? c / 12.92
        : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
  }

  return 0.2126 * channel(rgb[0]) +
      0.7152 * channel(rgb[1]) +
      0.0722 * channel(rgb[2]);
}

/// WCAG contrast ratio between two sRGB triplets.
double _contrast(List<int> a, List<int> b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  group('StarRating DOM', () {
    for (final entry in {
      CoreComponentSize.sm: '1.0rem',
      CoreComponentSize.md: '1.25rem',
      CoreComponentSize.lg: '1.5rem',
      CoreComponentSize.xl: '2.0rem',
    }.entries) {
      testServer('${entry.key.name} draws ${entry.value} stars', (
        tester,
      ) async {
        tester.pumpComponent(
          CoUIWeb(
            theme: .coui,
            child: _rating(size: entry.key),
          ),
        );
        final response = await tester.request('/');

        expect(
          _starsOf(response.document).first.attributes['style'],
          contains('width: ${entry.value}'),
        );
      });
    }

    testServer('3.5 draws 3 filled, 1 half, 1 empty', (tester) async {
      tester.pumpComponent(CoUIWeb(theme: .coui, child: _rating()));
      final response = await tester.request('/');

      expect(
        _starsOf(
          response.document,
        ).map((s) => s.attributes['data-coui-star-state']).toList(),
        ['filled', 'filled', 'filled', 'half', 'empty'],
      );
    });

    testServer('4.3 draws 4 filled, 1 half but still reads "4.3"', (
      tester,
    ) async {
      tester.pumpComponent(
        CoUIWeb(theme: .coui, child: _rating(value: 4.3, showValue: true)),
      );
      final response = await tester.request('/');

      expect(
        _starsOf(
          response.document,
        ).map((s) => s.attributes['data-coui-star-state']).toList(),
        ['filled', 'filled', 'filled', 'filled', 'half'],
      );
      expect(_rootOf(response.document)?.text, contains('4.3'));
      expect(_rootOf(response.document)?.attributes['aria-valuenow'], '4.3');
    });

    testServer('filled is primary, empty is outline-variant', (tester) async {
      tester.pumpComponent(CoUIWeb(theme: .coui, child: _rating()));
      final response = await tester.request('/');
      final style = _starsOf(response.document).first.attributes['style'];

      expect(style, contains('--coui-star-active: rgb(var(--coui-primary))'));
      expect(
        style,
        contains('--coui-star-inactive: rgb(var(--coui-outline-variant))'),
      );
    });

    test('the colours the stars read tell filled from empty in both '
        'brightnesses', () {
      final css = ThemeConfig.defaults().cssVariables;
      for (final (mode, selector) in [
        ('light', ':root'),
        ('dark', '[data-theme="dark"]:not(:root)'),
      ]) {
        final filled = _tripletOf(css, selector, 'primary');
        final empty = _tripletOf(css, selector, 'outline-variant');

        expect(
          _contrast(filled, empty),
          greaterThanOrEqualTo(3),
          reason: '$mode: $filled against $empty',
        );
      }
    });

    testServer('disabled uses disabled-content and disabled-container', (
      tester,
    ) async {
      tester.pumpComponent(
        CoUIWeb(theme: .coui, child: _rating(enabled: false)),
      );
      final response = await tester.request('/');
      final style = _starsOf(response.document).first.attributes['style'];

      expect(
        style,
        contains('--coui-star-active: rgb(var(--coui-disabled-content))'),
      );
      expect(
        style,
        contains('--coui-star-inactive: rgb(var(--coui-disabled-container))'),
      );
    });

    testServer('draws neither value nor count by default', (tester) async {
      tester.pumpComponent(
        CoUIWeb(theme: .coui, child: _rating(value: 4.5, count: 128)),
      );
      final response = await tester.request('/');
      final text = _rootOf(response.document)?.text ?? '';

      expect(text, isNot(contains('4.5')));
      expect(text, isNot(contains('(128)')));
    });

    testServer('showValue / showCount draw "4.5" and "(128)"', (tester) async {
      tester.pumpComponent(
        CoUIWeb(
          theme: .coui,
          child: _rating(
            value: 4.5,
            showValue: true,
            showCount: true,
            count: 128,
          ),
        ),
      );
      final response = await tester.request('/');
      final text = _rootOf(response.document)?.text ?? '';

      expect(text, contains('4.5'));
      expect(text, contains('(128)'));
    });

    testServer('the root carries no per-star ring, one FocusOutline wraps '
        'the group', (tester) async {
      tester.pumpComponent(CoUIWeb(theme: .coui, child: _rating()));
      final response = await tester.request('/');
      final root = _rootOf(response.document);

      expect(root?.className, isNot(contains('focus-visible:outline')));
      expect(root?.className, contains('outline-none'));
      expect(root?.parent?.className, contains('inline-flex'));
    });
  });
}
