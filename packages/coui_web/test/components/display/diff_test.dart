// The comparison slider on Web — what the markup says and what the resolver
// hands it. `testServer` for DOM shape (only the real SSR binding hands back
// markup), `testComponents` for the resolver's values.
//
// Pointer and key handling can't run here: `dart test` runs this suite on the
// VM, where `universal_web`'s event getters throw outside a real browser. The
// stylesheet rule that gives the handle its hover / held looks is pinned as
// text, and the behaviour the browser gives it is the Chrome probe's.

import 'package:coui_web/coui_web.dart';
import 'package:coui_web/src/components/display/diff/diff_style.dart';
import 'package:html/dom.dart' as html;
import 'package:jaspr_test/jaspr_test.dart';
import 'package:jaspr_test/server_test.dart' as server;

import '../../helpers/pump_with_theme.dart';

class _ContextCapture extends StatelessComponent {
  const _ContextCapture(this.onBuild);

  final void Function(BuildContext context) onBuild;

  @override
  Component build(BuildContext context) {
    onBuild(context);
    return const div([]);
  }
}

ResolvedDiff _resolve(
  ComponentTester tester, {
  CoreDiffStyle? style,
  double? position,
}) {
  late BuildContext context;
  pumpWithTheme(tester, _ContextCapture((c) => context = c));
  return resolveDiff(context, currentPosition: position, diffStyle: style);
}

Component _diff({
  bool interactive = true,
  Component? beforeLabel,
  Component? afterLabel,
  CoreDiffStyle? style,
}) => Diff(
  before: const div([Text('before-content')]),
  after: const div([Text('after-content')]),
  interactive: interactive,
  beforeLabel: beforeLabel,
  afterLabel: afterLabel,
  diffStyle: style,
);

html.Element? _rootOf(html.Document? document) =>
    document?.querySelector('.select-none');

html.Element? _strip(html.Document? document) =>
    document?.querySelector('.coui-diff-handle-strip');

String _style(html.Element? element) => element?.attributes['style'] ?? '';

void main() {
  group('Diff DOM', () {
    server.testServer('an interactive comparison is a slider on the root', (
      tester,
    ) async {
      tester.pumpComponent(CoUIWeb(theme: .coui, child: _diff()));
      final response = await tester.request('/');
      final root = _rootOf(response.document);

      expect(root?.attributes['role'], 'slider');
      expect(root?.attributes['aria-valuemin'], '0');
      expect(root?.attributes['aria-valuemax'], '100');
      expect(root?.attributes['aria-valuenow'], '50');
      expect(root?.attributes['tabindex'], '0');
      // The browser's own outline is off — the ring belongs to the handle.
      expect(root?.className, contains('outline-none'));
    });

    server.testServer('a non-interactive comparison is a plain group', (
      tester,
    ) async {
      tester.pumpComponent(
        CoUIWeb(theme: .coui, child: _diff(interactive: false)),
      );
      final response = await tester.request('/');
      final root = _rootOf(response.document);

      expect(root?.attributes['role'], 'group');
      expect(root?.attributes.containsKey('tabindex'), isFalse);
      expect(root?.attributes.containsKey('aria-valuenow'), isFalse);
    });

    server.testServer('the handle sits outside the clip, after it', (
      tester,
    ) async {
      tester.pumpComponent(CoUIWeb(theme: .coui, child: _diff()));
      final response = await tester.request('/');
      final root = _rootOf(response.document);

      // Clip layer first, handle strip last — so the disc and its ring are
      // whole at both ends of the frame instead of cut by the rounded clip.
      expect(root?.children, hasLength(2));
      final clip = root!.children.first;
      final strip = root.children.last;
      expect(clip.className, contains('overflow-hidden'));
      expect(_style(clip), contains('border-radius'));
      expect(root.className, isNot(contains('overflow-hidden')));
      expect(strip.className, contains('coui-diff-handle-strip'));
    });

    server.testServer('the handle is a ring host around a round disc', (
      tester,
    ) async {
      tester.pumpComponent(CoUIWeb(theme: .coui, child: _diff()));
      final response = await tester.request('/');
      final strip = _strip(response.document);

      // strip > ring host > disc > glyph.
      final host = strip?.children.single;
      expect(host?.className, contains('coui-diff-handle'));
      // Exactly the disc's box: forty px.
      expect(_style(host), contains('width: 2.5rem'));
      expect(_style(host), contains('height: 2.5rem'));
      final disc = host?.children.single;
      expect(disc?.className, contains('coui-diff-handle-disc'));
      expect(disc?.className, contains('bg-surface-raised'));
      expect(_style(disc), contains('border-radius'));
      expect(_style(disc), contains('border-width'));
      // The cast comes from the shared rule by marker, never inline — an
      // inline `box-shadow` would out-rank the hover and held looks.
      expect(_style(disc), isNot(contains('box-shadow')));
      // The glyph ships in the package, so it is an inline `<svg>` with its
      // strokes — not an `<iconify-icon>`, which draws nothing until a script
      // fetches it and leaves the disc empty in server-rendered markup.
      expect(disc?.querySelector('iconify-icon'), isNull);
      final glyph = disc?.querySelector('svg');
      expect(glyph?.attributes['data-icon'], 'lucide:chevrons-left-right');
      expect(glyph?.querySelectorAll('path'), isNotEmpty);
      // Decorative: the slider on the root carries the meaning.
      expect(glyph?.attributes['aria-hidden'], 'true');
    });

    server.testServer('the strip is the grab area: 44px wide, full height', (
      tester,
    ) async {
      tester.pumpComponent(CoUIWeb(theme: .coui, child: _diff()));
      final response = await tester.request('/');
      final strip = _strip(response.document);

      expect(strip?.className, contains('top-0'));
      expect(strip?.className, contains('bottom-0'));
      expect(strip?.className, contains('cursor-col-resize'));
      // A size, not a gap: a literal, so no density moves it. Flutter keeps
      // the strip at 44 under every density, and so must this.
      expect(_style(strip), contains('width: 2.75rem'));
      // A vertical swipe stays the page's.
      expect(_style(strip), contains('touch-action: pan-y'));
      expect(_style(strip), contains('left: var(--co-diff-pos)'));
    });

    server.testServer('the strip publishes the three casts, scale and clock', (
      tester,
    ) async {
      tester.pumpComponent(CoUIWeb(theme: .coui, child: _diff()));
      final response = await tester.request('/');
      final style = _style(_strip(response.document));

      expect(style, contains('--coui-diff-handle-shadow: var(--shadow-sm)'));
      expect(
        style,
        contains('--coui-diff-handle-shadow-hover: var(--shadow-md)'),
      );
      expect(
        style,
        contains('--coui-diff-handle-shadow-pressed: var(--shadow-xs)'),
      );
      expect(style, contains('--coui-diff-handle-pressed-scale: 0.94'));
      expect(
        style,
        contains('--coui-diff-handle-duration: var(--coui-duration-150)'),
      );
    });

    server.testServer('a non-interactive comparison draws no handle', (
      tester,
    ) async {
      tester.pumpComponent(
        CoUIWeb(theme: .coui, child: _diff(interactive: false)),
      );
      final response = await tester.request('/');

      expect(_strip(response.document), isNull);
      expect(response.document?.querySelector('iconify-icon'), isNull);
      // The line is still drawn, with its cast.
      final line = response.document?.querySelector('.pointer-events-none');
      expect(line, isNotNull);
    });

    server.testServer('the line is raised: surface-raised with the sm cast', (
      tester,
    ) async {
      tester.pumpComponent(CoUIWeb(theme: .coui, child: _diff()));
      final response = await tester.request('/');
      final line = response.document
          ?.querySelectorAll('.bg-surface-raised')
          .first;

      expect(line?.className, contains('pointer-events-none'));
      expect(_style(line), contains('box-shadow: var(--shadow-sm)'));
      expect(_style(line), contains('width: 0.125rem'));
    });

    server.testServer('labels are drawn only when given, in the top corners', (
      tester,
    ) async {
      tester.pumpComponent(CoUIWeb(theme: .coui, child: _diff()));
      var response = await tester.request('/');
      expect(response.document?.body?.text, isNot(contains('Before')));
      expect(response.document?.body?.text, isNot(contains('After')));

      tester.pumpComponent(
        CoUIWeb(
          theme: .coui,
          child: _diff(
            beforeLabel: const Text('Before'),
            afterLabel: const Text('After'),
          ),
        ),
      );
      response = await tester.request('/');
      final hosts = response.document
          ?.querySelectorAll('.pointer-events-none.absolute')
          .where((e) => e.text.contains('Before') || e.text.contains('After'))
          .toList();

      expect(hosts, hasLength(2));
      final before = hosts!.firstWhere((e) => e.text.contains('Before'));
      final after = hosts.firstWhere((e) => e.text.contains('After'));
      // Twelve in from the corner, density-routed.
      expect(_style(before), contains('top: var(--coui-space-12)'));
      expect(_style(before), contains('left: var(--coui-space-12)'));
      expect(_style(after), contains('top: var(--coui-space-12)'));
      expect(_style(after), contains('right: var(--coui-space-12)'));
      // The twelve above only lands there if the host lays the badge out as a
      // box. In a block host the inline badge sits on the text baseline, lower.
      // Whole class names: a badge-like `inline-flex` must not satisfy this.
      expect(before.className.split(' '), contains('flex'));
      expect(after.className.split(' '), contains('flex'));
    });

    server.testServer('only the label that is given is drawn', (tester) async {
      tester.pumpComponent(
        CoUIWeb(
          theme: .coui,
          child: _diff(beforeLabel: const Text('Before')),
        ),
      );
      final response = await tester.request('/');
      final text = response.document?.body?.text ?? '';

      expect(text, contains('Before'));
      expect(text, isNot(contains('After')));
    });

    server.testServer('the frame edge is an inset overlay, not layout', (
      tester,
    ) async {
      tester.pumpComponent(CoUIWeb(theme: .coui, child: _diff()));
      final response = await tester.request('/');
      final clip = _rootOf(response.document)!.children.first;
      final edge = clip.children.last;

      expect(edge.className, contains('inset-0'));
      expect(edge.className, contains('pointer-events-none'));
      expect(edge.className, contains('border-outline-subtle'));
      expect(_style(edge), contains('box-sizing: border-box'));
      expect(_style(edge), contains('border-style: solid'));
      expect(_style(edge), contains('border-width'));
    });

    server.testServer('a zero edge width draws no edge', (tester) async {
      tester.pumpComponent(
        CoUIWeb(
          theme: .coui,
          child: _diff(style: const CoreDiffStyle(borderWidth: 0)),
        ),
      );
      final response = await tester.request('/');
      final clip = _rootOf(response.document)!.children.first;

      expect(
        clip.children.where(
          (e) => e.className.contains('border-outline-subtle'),
        ),
        isEmpty,
      );
    });
  });

  group('resolveDiff', () {
    testComponents('the split position seeds from the style', (tester) async {
      final resolved = _resolve(tester);
      expect(resolved.root.inlineStyles?.properties['--co-diff-pos'], '50.0%');

      final moved = _resolve(tester, position: 0.25);
      expect(moved.root.inlineStyles?.properties['--co-diff-pos'], '25.0%');

      final clamped = _resolve(tester, position: 7);
      expect(clamped.root.inlineStyles?.properties['--co-diff-pos'], '100.0%');
    });

    testComponents('the edge slot is null at zero width only', (tester) async {
      expect(_resolve(tester).edge, isNotNull);
      expect(
        _resolve(tester, style: const CoreDiffStyle(borderWidth: 0)).edge,
        isNull,
      );
    });

    testComponents('handle values follow the style', (tester) async {
      final resolved = _resolve(
        tester,
        style: const CoreDiffStyle(
          handleSize: 48,
          handleHitSize: 64,
          handlePressedScale: 0.9,
          handleShadow: CoreShadow.lg,
        ),
      );

      expect(resolved.handleHost.inlineStyles?.properties['width'], '3.0rem');
      final strip = resolved.handleStrip.inlineStyles?.properties;
      expect(strip?['width'], '4.0rem');
      expect(strip?['--coui-diff-handle-pressed-scale'], '0.9');
      expect(strip?['--coui-diff-handle-shadow'], 'var(--shadow-lg)');
    });

    testComponents('an empty cast reads as none', (tester) async {
      final resolved = _resolve(
        tester,
        style: const CoreDiffStyle(
          handleShadow: CoreShadow.none,
          resizerShadow: CoreShadow.none,
        ),
      );

      expect(
        resolved
            .handleStrip
            .inlineStyles
            ?.properties['--coui-diff-handle-shadow'],
        'none',
      );
      expect(resolved.resizer.inlineStyles?.properties['box-shadow'], 'none');
    });

    testComponents('a raw colour goes inline and drops its class', (
      tester,
    ) async {
      final resolved = _resolve(
        tester,
        style: const CoreDiffStyle(resizerColor: CoreColor(0xFFFF0000)),
      );

      expect(resolved.resizer.className, isNot(contains('bg-')));
      expect(
        resolved.resizer.inlineStyles?.properties['background-color'],
        isNotNull,
      );
    });

    testComponents('the nested slots are raw-forwarded over their defaults', (
      tester,
    ) async {
      final resolved = _resolve(
        tester,
        style: const CoreDiffStyle(
          handleIconStyle: CoreIconStyle(size: 20),
          labelBadgeStyle: CoreBadgeStyle(borderWidth: 2),
          focusOutlineStyle: CoreFocusOutlineStyle(borderWidth: 3),
        ),
      );

      expect(resolved.handleIconStyle.size, 20);
      expect(
        resolved.handleIconStyle.color,
        CoreDiffStyle.defaultHandleIconStyle.color,
      );
      expect(resolved.labelBadgeStyle.borderWidth, 2);
      expect(
        resolved.labelBadgeStyle.backgroundColor,
        CoreDiffStyle.defaultLabelBadgeStyle.backgroundColor,
      );
      expect(resolved.focusOutlineStyle.borderWidth, 3);
      expect(
        resolved.focusOutlineStyle.offsetColor,
        CoreFocusRing.opaqueOffsetColor,
      );
    });

    testComponents('the tuning reads the keyboard steps from the chain', (
      tester,
    ) async {
      late BuildContext context;
      pumpWithTheme(tester, _ContextCapture((c) => context = c));

      final defaults = resolveDiffTuning(context);
      expect(defaults.initialPosition, 0.5);
      expect(defaults.keyboardStep, 0.05);
      expect(defaults.keyboardPageStep, 0.1);

      final custom = resolveDiffTuning(
        context,
        diffStyle: const CoreDiffStyle(
          keyboardStep: 0.01,
          keyboardPageStep: 0.2,
          initialPosition: 3,
        ),
      );
      expect(custom.keyboardStep, 0.01);
      expect(custom.keyboardPageStep, 0.2);
      expect(custom.initialPosition, 1);
    });
  });

  group('the shared stylesheet', () {
    test('states the handle at rest, hovered and held', () {
      final css = ThemeConfig.defaults().cssVariables;

      // At rest: the disc's cast and the ring host's scale transition.
      expect(
        css,
        contains(
          '.coui-diff-handle-disc{'
          'box-shadow:var(--coui-diff-handle-shadow,none);',
        ),
      );
      // Hovered: the strip, not just the disc — and only where hover exists.
      expect(
        css,
        contains(
          '@media (hover:hover){ .coui-diff-handle-strip:hover '
          '.coui-diff-handle-disc{',
        ),
      );
      expect(
        css,
        contains('box-shadow:var(--coui-diff-handle-shadow-hover,none);'),
      );
      // Held: the root's attribute, with the strip marker twice so it out-
      // ranks the hover rule wherever the stylesheet order lands.
      expect(
        css,
        contains(
          '[data-coui-dragging] '
          '.coui-diff-handle-strip.coui-diff-handle-strip '
          '.coui-diff-handle-disc{',
        ),
      );
      expect(
        css,
        contains('box-shadow:var(--coui-diff-handle-shadow-pressed,none);'),
      );
      expect(
        css,
        contains('scale:var(--coui-diff-handle-pressed-scale,1);'),
      );
    });
  });
}
