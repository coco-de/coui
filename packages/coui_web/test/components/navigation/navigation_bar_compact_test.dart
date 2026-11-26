import 'dart:convert';
import 'dart:io';

import 'package:coui_web/coui_web.dart';
// The resolver, the names it shares with the runtimes and the DOM-free
// tracker are internal — imported directly for resolver-level assertions.
import 'package:coui_web/src/components/navigation/navigation_bar/navigation_bar_style.dart';
import 'package:coui_web/src/components/navigation/navigation_bar/navigation_bar_vars.dart';
import 'package:coui_web/src/components/navigation/navigation_bar/navigation_compact_tracker.dart';
import 'package:jaspr_test/jaspr_test.dart';
import 'package:jaspr_test/server_test.dart' show testServer;

import '../../helpers/pump_with_theme.dart';

/// The Web twin of the Flutter `navigation_bar_compact_test`: the bar's
/// compact form (`NavigationBar.compact`) read back off the resolver and the
/// server markup, and the rule that follows the content replayed on the
/// DOM-free tracker from the table every package shares
/// (`coui_core/test/fixtures/navigation_scroll_compaction_vectors.json`).
/// What the browser then does — the listener, the computed transform, the
/// lens under a compact bar — is the Chrome probe's
/// (`tool/parity/test/web/navigation_compact_probe_test.dart`).
const String _kVectorsPath =
    '../coui_core/test/fixtures/navigation_scroll_compaction_vectors.json';

class _ContextCapture extends StatelessComponent {
  const _ContextCapture(this.onBuild);

  final void Function(BuildContext context) onBuild;

  @override
  Component build(BuildContext context) {
    onBuild(context);
    return const div([]);
  }
}

const _glass = CoreNavigationBarStyle(
  surfaceStyle: CoreSurfaceStyleId.liquidGlass,
);

ResolvedNavigationBar _resolve(
  ComponentTester tester, {
  CoreNavigationBarMode mode = .bar,
  CoreNavigationCompact? compact,
  CoreNavigationBarStyle? style = _glass,
  CoreNavigationLabelPosition? labelPosition,
}) {
  late BuildContext context;
  pumpWithTheme(tester, _ContextCapture((c) => context = c));
  return compact == null
      ? resolveNavigationBar(
          context,
          mode: mode,
          variant: CoreNavigationBarVariant.defaultVariant,
          overflow: CoreNavigationOverflow.ellipsis,
          labelPosition: labelPosition ?? mode.defaultLabelPosition,
          navigationBarStyle: style,
        )
      : resolveNavigationBar(
          context,
          mode: mode,
          variant: CoreNavigationBarVariant.defaultVariant,
          overflow: CoreNavigationOverflow.ellipsis,
          labelPosition: labelPosition ?? mode.defaultLabelPosition,
          compact: compact,
          navigationBarStyle: style,
        );
}

Map<String, String> _inline(WebElementChrome chrome) =>
    chrome.inlineStyles?.properties ?? const {};

/// The declarations the compact form adds to the bar's root.
const Set<String> _compactKeys = {
  kNavigationCompactScaleVar,
  'transform',
  'translate',
  'transition',
};

Component _host(Component child) => CoUIWeb(theme: .coui, child: child);

NavigationBar _bar({
  CoreNavigationCompact compact = CoreNavigationCompact.defaultCompact,
  CoreNavigationBarStyle? style = _glass,
}) => NavigationBar(
  id: 'nav',
  selectedIndex: 0,
  onSelected: (_) {},
  compact: compact,
  navigationBarStyle: style,
  items: const [
    CoreNavigationBarItem.destination(
      icon: Icon(LucideIcons.house),
      label: 'Home',
    ),
    CoreNavigationBarItem.destination(
      icon: Icon(LucideIcons.search),
      label: 'Search',
    ),
  ],
);

List<Map<String, Object?>> _list(Object? value) =>
    (value! as List).cast<Map<String, Object?>>();

void main() {
  group('the resolver', () {
    testComponents('a bar that never asks emits none of it', (tester) {
      // Stated or left to the default, `never` leaves the root exactly as
      // it was before the form existed.
      final defaulted = _inline(_resolve(tester).root);
      final never = _inline(_resolve(tester, compact: .never).root);

      expect(never, defaulted);
      expect(defaulted.keys.toSet().intersection(_compactKeys), isEmpty);
    });

    testComponents('the floating glass bar states its compact form', (tester) {
      final resolved = _resolve(tester, compact: .always);
      final root = _inline(resolved.root);

      expect(
        root[kNavigationCompactScaleVar],
        '${CoreNavigationBarStyle.glassCompactScale}',
      );
      // About the middle of the bottom edge: half a bar down for what the
      // scale takes off.
      expect(
        root['transform'],
        'translate(0,calc((1 - var(--coui-navigation-compact,1)) * 50%)) '
        'scale(var(--coui-navigation-compact,1))',
      );
      // Nothing at rest; while the swell has the origin off the middle and
      // the bar drawn larger, what that moves the form's point by.
      expect(
        root['translate'],
        'calc((1 - var(--coui-navigation-compact,1)) * '
        '(50% - var(--coui-navigation-swell-origin,50%))) '
        'calc((1 - var(--coui-navigation-compact,1)) * '
        '(1 - var(--coui-navigation-swell,1)) * 50%)',
      );
      expect(
        root['transition'],
        'transform ${durationMsCss(CoreDuration.moderate)} '
        '${CoreEasing.move.toVarCss()}',
      );
      // The capsule the runtime takes up is drawn through the same form.
      final glassRoot = _inline(resolved.glassRoot);
      for (final key in _compactKeys) {
        expect(glassRoot[key], root[key], reason: key);
      }
    });

    testComponents('following the content states the same form up front', (
      tester,
    ) {
      // The size is on the root before the content has moved; whether the
      // bar is at it is the marker's.
      final following = _inline(_resolve(tester, compact: .onScroll).root);
      final always = _inline(_resolve(tester, compact: .always).root);

      expect(following, always);
    });

    testComponents('a docked bar has no compact form', (tester) {
      final docked = _inline(
        _resolve(
          tester,
          compact: .always,
          style: const CoreNavigationBarStyle(),
        ).root,
      );

      expect(docked.keys.toSet().intersection(_compactKeys), isEmpty);
    });

    testComponents('a style states the compact size and the time it takes', (
      tester,
    ) {
      final root = _inline(
        _resolve(
          tester,
          compact: .always,
          style: const CoreNavigationBarStyle(
            compactScale: .5,
            compactDuration: Duration(milliseconds: CoreDuration.fast),
          ),
        ).root,
      );

      expect(root[kNavigationCompactScaleVar], '0.5');
      expect(
        root['transition'],
        'transform ${durationMsCss(CoreDuration.fast)} '
        '${CoreEasing.move.toVarCss()}',
      );
    });

    testComponents('a column shrinks about its centre', (tester) {
      final root = _inline(
        _resolve(
          tester,
          mode: .rail,
          compact: .always,
          style: _glass.copyWith(compactScale: .8),
        ).root,
      );

      // The scale alone is about the centre already; along the column only
      // the swell's origin being off the middle moves it.
      expect(root['transform'], 'scale(var(--coui-navigation-compact,1))');
      expect(
        root['translate'],
        '0 calc((1 - var(--coui-navigation-compact,1)) * '
        '(50% - var(--coui-navigation-swell-origin,50%)))',
      );
    });

    testComponents('a bar with a compact form keeps its captions in a fold '
        'that carries the gap to the icon', (tester) {
      final gap = spaceCss(CoreNavigationBarStyle.defaultLabelSpacing);
      // Whatever `compact` says: the fold is there before the bar turns
      // compact, so turning compact closes it.
      for (final compact in CoreNavigationCompact.values) {
        final resolved = _resolve(tester, compact: compact);
        final open = _inline(resolved.captionFold!);
        final folded = _inline(resolved.captionFoldFolded!);

        expect(open['grid-template-rows'], '$gap 1fr', reason: '$compact');
        expect(open['opacity'], '1');
        expect(folded['grid-template-rows'], '0px 0fr', reason: '$compact');
        expect(folded['opacity'], '0');
        // Only the tracks and the opacity differ, and both move on the
        // compact form's clock.
        expect(
          {...open}..removeWhere((key, _) => folded[key] == open[key]),
          {'grid-template-rows': '$gap 1fr', 'opacity': '1'},
        );
        final clock =
            '${CoreNavigationBarStyle.defaultCompactDuration.inMilliseconds}';
        expect(
          open['transition'],
          allOf(
            contains('grid-template-rows'),
            contains('opacity'),
            contains(clock),
          ),
        );
        // The caption sits in the second track and may close to nothing.
        final body = _inline(resolved.captionFoldBody!);
        expect(body['grid-row'], '2');
        expect(body['min-height'], '0');
        expect(
          resolved.captionFoldBody!.className,
          contains('overflow-hidden'),
        );
        // The fold has the gap, so the stack has none.
        expect(_inline(resolved.inner), isNot(contains('gap')));
      }
    });

    testComponents('the fold closes toward the icon wherever the caption '
        'sits', (tester) {
      final gap = spaceCss(CoreNavigationBarStyle.defaultLabelSpacing);
      const tracks = <CoreNavigationLabelPosition, (String, String, String)>{
        .bottom: ('grid-template-rows', 'grid-row', '2'),
        .top: ('grid-template-rows', 'grid-row', '1'),
        .end: ('grid-template-columns', 'grid-column', '2'),
        .start: ('grid-template-columns', 'grid-column', '1'),
      };
      for (final MapEntry(key: position, value: (track, place, at))
          in tracks.entries) {
        final resolved = _resolve(tester, labelPosition: position);
        final captionLast = at == '2';

        expect(
          _inline(resolved.captionFold!)[track],
          captionLast ? '$gap 1fr' : '1fr $gap',
          reason: '$position',
        );
        expect(
          _inline(resolved.captionFoldFolded!)[track],
          captionLast ? '0px 0fr' : '0fr 0px',
          reason: '$position',
        );
        expect(
          _inline(resolved.captionFoldBody!)[place],
          at,
          reason: '$position',
        );
      }
    });

    testComponents('a bar with no compact form has no fold', (tester) {
      for (final compact in CoreNavigationCompact.values) {
        final resolved = _resolve(
          tester,
          compact: compact,
          style: const CoreNavigationBarStyle(),
        );

        expect(resolved.captionFold, isNull);
        expect(resolved.captionFoldFolded, isNull);
        expect(resolved.captionFoldBody, isNull);
        expect(
          _inline(resolved.inner)['gap'],
          spaceCss(CoreNavigationBarStyle.defaultLabelSpacing),
        );
      }
    });

    test('the names the transform reads are the ones the runtimes write', () {
      for (final vertical in [false, true]) {
        final form = navigationCompactTransformCss(vertical: vertical);
        expect(form.transform, contains('var($kNavigationCompactVar,1)'));
        expect(form.translate, contains('var($kNavigationCompactVar,1)'));
        expect(
          form.translate,
          contains('var($kNavigationSwellOriginVar,50%)'),
        );
        // What the form animates depends on the factor alone, so the swell
        // moving frame by frame never restarts its transition.
        expect(form.transform, isNot(contains(kNavigationSwellVar)));
      }
      expect(
        navigationCompactTransformCss(vertical: false).translate,
        contains('var($kNavigationSwellVar,1)'),
      );
      expect(
        kNavigationCompactCss,
        '[$kNavigationCompactAttribute]'
        '{$kNavigationCompactVar:var($kNavigationCompactScaleVar,1);}',
      );
    });
  });

  group('the server markup', () {
    testServer('a bar that never asks carries neither marker nor rule', (
      tester,
    ) async {
      tester.pumpComponent(_host(_bar()));
      final document = (await tester.request('/')).document!;
      final nav = document.querySelector('#nav')!;

      expect(nav.attributes.containsKey(kNavigationCompactAttribute), isFalse);
      expect(nav.outerHtml, isNot(contains(kNavigationCompactVar)));
    });

    testServer('`always` is rendered compact', (tester) async {
      tester.pumpComponent(_host(_bar(compact: .always)));
      final document = (await tester.request('/')).document!;
      final nav = document.querySelector('#nav')!;

      expect(nav.attributes[kNavigationCompactAttribute], '');
      expect(
        nav.querySelectorAll('style').map((style) => style.text),
        contains(kNavigationCompactCss),
      );
      expect(
        nav.attributes['style'],
        contains(
          '$kNavigationCompactScaleVar: '
          '${CoreNavigationBarStyle.glassCompactScale}',
        ),
      );
    });

    testServer('a compact bar folds every caption and keeps the '
        'destination', (tester) async {
      // What one destination renders: its fold's declarations, its caption,
      // what names it, and the chrome around all of it.
      final rendered = <CoreNavigationCompact, List<Map<String, Object?>>>{};
      for (final compact in [
        CoreNavigationCompact.never,
        CoreNavigationCompact.always,
      ]) {
        tester.pumpComponent(_host(_bar(compact: compact)));
        final nav = (await tester.request('/')).document!.querySelector(
          '#nav',
        )!;
        rendered[compact] = [
          for (final index in [0, 1])
            () {
              final destination = nav.querySelector(
                '[data-coui-nav-index="$index"]',
              )!;
              final label = nav.querySelector('#nav-item-$index-label')!;
              final chrome = destination.querySelector(
                '[data-coui-nav-chrome]',
              )!;
              return {
                'fold': label.parent!.parent!.attributes['style'],
                'caption': label.text,
                'named by': destination.attributes['aria-labelledby'],
                'chrome': {...chrome.attributes},
                'html': chrome.outerHtml,
              };
            }(),
        ];
      }

      for (final index in [0, 1]) {
        final resting = rendered[CoreNavigationCompact.never]![index];
        final compact = rendered[CoreNavigationCompact.always]![index];
        final open = resting['fold']! as String;
        final folded = compact['fold']! as String;

        expect(open, allOf(contains('1fr'), contains('opacity: 1')));
        expect(
          folded,
          allOf(
            contains('grid-template-rows: 0px 0fr'),
            contains('opacity: 0'),
          ),
        );
        // The caption is still there to name the destination…
        expect(compact['caption'], resting['caption']);
        expect(compact['named by'], 'nav-item-$index-label');
        // …and the destination around it is the one it was: the same
        // chrome, and nothing but the fold changed inside it.
        expect(compact['chrome'], resting['chrome']);
        expect(
          (compact['html']! as String).replaceAll(folded, open),
          resting['html'],
        );
      }
    });

    testServer('a docked bar marked compact keeps its captions out of a '
        'fold', (tester) async {
      tester.pumpComponent(
        _host(_bar(compact: .always, style: const CoreNavigationBarStyle())),
      );
      final document = (await tester.request('/')).document!;
      final label = document.querySelector('#nav-item-0-label')!;

      // The caption is the stack's own child, beside the icon's box.
      expect(label.parent!.attributes['style'], contains('flex-direction'));
      expect(document.outerHtml, isNot(contains('0fr')));
    });

    testServer('a bar that follows the content is rendered in full', (
      tester,
    ) async {
      // Nothing has scrolled on the server; the rule and the size are in
      // place for when it does.
      tester.pumpComponent(_host(_bar(compact: .onScroll)));
      final document = (await tester.request('/')).document!;
      final nav = document.querySelector('#nav')!;

      expect(nav.attributes.containsKey(kNavigationCompactAttribute), isFalse);
      expect(
        nav.querySelectorAll('style').map((style) => style.text),
        contains(kNavigationCompactCss),
      );
      expect(nav.attributes['style'], contains(kNavigationCompactScaleVar));
    });

    testServer('a docked bar marked compact is drawn as it was', (
      tester,
    ) async {
      tester.pumpComponent(
        _host(_bar(compact: .always, style: const CoreNavigationBarStyle())),
      );
      final document = (await tester.request('/')).document!;
      final style = document.querySelector('#nav')!.attributes['style']!;

      expect(style, isNot(contains('transform')));
      expect(style, isNot(contains(kNavigationCompactScaleVar)));
    });
  });

  group('following the content', () {
    final vectors =
        jsonDecode(File(_kVectorsPath).readAsStringSync())
            as Map<String, Object?>;

    for (final trace in _list(vectors['traces'])) {
      test('the shared table: ${trace['name']}', () {
        final tracker = NavigationCompactTracker();
        final maxExtent = (trace['maxExtent']! as num).toDouble();
        for (final step in _list(trace['steps'])) {
          if (step['event'] == 'reset') {
            tracker.reset();
          } else {
            // Only where the scroller is — the tracker works the distance
            // out, as it must from a scroll event.
            tracker.scrolled(
              'content',
              offset: (step['offset']! as num).toDouble(),
              maxExtent: maxExtent,
            );
          }
          expect(tracker.compact, step['compact'], reason: '$step');
        }
      });
    }

    test('a scroller it has only just met does not move the bar', () {
      // A page restored part-way down: the first position heard is where it
      // already was, not a distance travelled.
      final tracker = NavigationCompactTracker();

      expect(tracker.scrolled('page', offset: 900, maxExtent: 4000), isFalse);
      expect(tracker.scrolled('page', offset: 912, maxExtent: 4000), isTrue);
    });

    test('each scroller is measured from where it was itself', () {
      // Two lists under one bar: the second starting where the first is not
      // is no travel.
      final tracker = NavigationCompactTracker()
        ..scrolled('first', offset: 0, maxExtent: 4000)
        ..scrolled('first', offset: 5, maxExtent: 4000);

      expect(tracker.scrolled('second', offset: 600, maxExtent: 4000), isFalse);
      expect(tracker.scrolled('second', offset: 606, maxExtent: 4000), isFalse);
      expect(tracker.scrolled('second', offset: 612, maxExtent: 4000), isTrue);
    });

    test('a reset keeps where the scroller is', () {
      final tracker = NavigationCompactTracker()
        ..scrolled('page', offset: 0, maxExtent: 4000)
        ..scrolled('page', offset: 300, maxExtent: 4000);
      expect(tracker.compact, isTrue);

      tracker.reset();
      expect(tracker.compact, isFalse);
      // Measured from 300, not from nothing: 12 on is the travel.
      expect(tracker.scrolled('page', offset: 312, maxExtent: 4000), isTrue);
    });
  });
}
