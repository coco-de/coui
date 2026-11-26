// #4204 — the oscillation probe's verdict and spec table, held without a
// browser.
//
// The browser half (`tool/parity/oscillation_probe.dart`) runs nightly
// against the hydrated docs site. What can be pinned here is pinned here,
// so a mistake fails in the PR that makes it rather than the next night:
//   * a run in which nothing happened — the panel never opened — is a
//     failure, not a pass (the whole point of the probe's first stage);
//   * any state change under a resting pointer fails;
//   * every spec points at a docs page that renders its pane — the page's
//     playground, server rendered, holds the live component — and at a
//     trigger and panel the component actually emits.
import 'dart:io';

import 'package:docs_core/internal/preview/scenes.dart';
import 'package:docs_core/internal/preview/web_scene.dart';
import 'package:docs_core/shared/component_catalog.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../src/web/oscillation_probe.dart';
import '../../src/web/ssr_render.dart';

/// The elements [spec] would resolve on its page: the page's own
/// `<Playground>` tags, read by the parser the docs site uses, server
/// rendered the way the site renders them, then searched for the live
/// component inside the playground. `problem` says why there is nothing to
/// search.
Future<({String? problem, List<dom.Element> live})> _renderedLive(
  String repoRoot,
  OscillationProbeSpec spec,
) async {
  final page = File(
    p.join(
      repoRoot,
      'docs_core',
      'content',
      'components',
      '${spec.component}.md',
    ),
  );
  if (!page.existsSync()) {
    return (problem: 'no ${page.path}', live: <dom.Element>[]);
  }
  final playgrounds = [
    for (final scene in visibleDocsScenes(
      page.readAsStringSync(),
      sourcePath: page.path,
    ))
      if (scene.tag == 'Playground' &&
          scene.attributes['component'] == spec.component)
        scene,
  ];
  if (playgrounds.isEmpty) {
    return (
      problem: 'no <Playground component="${spec.component}" /> on the page',
      live: <dom.Element>[],
    );
  }
  final live = <dom.Element>[];
  for (final scene in playgrounds) {
    final document = html_parser.parse(
      await renderComponentToDocumentHtml(renderWebScene(scene)),
    );
    for (final pane in document.querySelectorAll('.docs-playground')) {
      live.addAll(pane.querySelectorAll(spec.liveSelector));
    }
  }

  return (problem: null, live: live);
}

void main() {
  final repoRoot = Directory.current.path;

  group('oscillation probe verdict (#4204)', () {
    test('a panel that opened and held still passes', () {
      const observation = OscillationObservation(
        opened: true,
        openAttempts: 1,
        panelPresentAtEnd: true,
      );
      expect(oscillationFailures(observation), isEmpty);
    });

    test('a panel that never opened fails stage 1 — not a quiet pass', () {
      // Nothing changed while "resting" because nothing was ever open.
      // Counting alone would call this a pass; it is the unhydrated page.
      const observation = OscillationObservation(
        opened: false,
        openAttempts: 15,
      );
      final failures = oscillationFailures(observation);
      expect(failures, hasLength(1));
      expect(failures.single, startsWith('stage 1:'));
    });

    test('one change under a resting pointer fails stage 2', () {
      const observation = OscillationObservation(
        opened: true,
        openAttempts: 1,
        changes: [
          OscillationChange(
            atMs: 200,
            subject: 'aria-expanded',
            value: 'false',
          ),
        ],
        panelPresentAtEnd: true,
      );
      final failures = oscillationFailures(observation);
      expect(failures, hasLength(1));
      expect(failures.single, startsWith('stage 2: 1 state changes'));
    });

    test('a loop that ends where it started still fails', () {
      // Closed and reopened inside the window: the panel is present at the
      // end, exactly as in a pass — only the recorded changes tell.
      const observation = OscillationObservation(
        opened: true,
        openAttempts: 1,
        changes: [
          OscillationChange(atMs: 304, subject: 'panel', value: 'absent'),
          OscillationChange(atMs: 327, subject: 'panel', value: 'present'),
        ],
        panelPresentAtEnd: true,
      );
      expect(oscillationFailures(observation), hasLength(1));
    });

    test('a panel gone with no recorded change is reported, not passed', () {
      const observation = OscillationObservation(
        opened: true,
        openAttempts: 1,
      );
      expect(oscillationFailures(observation), hasLength(1));
    });

    test('a structural problem is reported as itself', () {
      const observation = OscillationObservation(
        opened: false,
        problem: 'no playground with a live `x` on /components/x/',
      );
      expect(
        oscillationFailures(observation),
        ['no playground with a live `x` on /components/x/'],
      );
    });
  });

  group('oscillation probe self-test fixtures', () {
    test('every fixture renders the pane and trigger the spec looks for', () {
      for (final fixture in OscillationFixture.values) {
        final document = html_parser.parse(oscillationFixtureHtml(fixture));
        final live = document.querySelectorAll(
          '.docs-playground ${kOscillationFixtureSpec.liveSelector}',
        );
        expect(live, hasLength(1), reason: fixture.name);
        final trigger = live.single.querySelector(
          kOscillationFixtureSpec.triggerSelector,
        );
        expect(
          trigger?.attributes['aria-expanded'],
          'false',
          reason: fixture.name,
        );
        // As on the docs page, a picture with a trigger of its own sits
        // outside the live element — the self-test fails a probe that
        // reaches it.
        expect(
          document.querySelectorAll('.docs-playground button[aria-expanded]'),
          hasLength(2),
          reason: fixture.name,
        );
      }
    });

    test('only the inert fixture has no handlers', () {
      expect(
        oscillationFixtureHtml(OscillationFixture.inert),
        isNot(contains('<script>')),
      );
      expect(
        oscillationFixtureHtml(OscillationFixture.steady),
        isNot(contains('setInterval')),
      );
      expect(
        oscillationFixtureHtml(OscillationFixture.oscillating),
        contains('setInterval'),
      );
    });
  });

  group('oscillation probe spec table', () {
    test('every spec names a distinct component', () {
      final names = [for (final spec in kOscillationProbeSpecs) spec.component];
      expect(names.toSet(), hasLength(names.length), reason: '$names');
    });

    test('every spec points at a docs page that renders its pane', () async {
      final slugs = {for (final entry in kDocsComponentEntries) entry.slug};
      final problems = <String>[];
      for (final spec in kOscillationProbeSpecs) {
        if (!slugs.contains(spec.component)) {
          problems.add('${spec.component}: not in the docs catalog');
          continue;
        }
        final rendered = await _renderedLive(repoRoot, spec);
        final problem = rendered.problem;
        if (problem != null) {
          problems.add('${spec.component}: $problem');
          continue;
        }
        // Exactly one: the probe takes the first match, so a second would
        // make that choice without saying so.
        if (rendered.live.length != 1) {
          problems.add(
            '${spec.component}: ${rendered.live.length} elements match '
            '${spec.liveSelector} in the page playground',
          );
          continue;
        }
        if (rendered.live.single.querySelector(spec.triggerSelector) == null) {
          problems.add(
            '${spec.component}: no ${spec.triggerSelector} in the live '
            '${spec.liveSelector}',
          );
        }
      }
      expect(problems, isEmpty, reason: problems.join('\n'));
    });

    test('the navigation-menu spec matches what the component emits', () async {
      // The selectors are strings the browser resolves at night; a rename
      // in the component would otherwise surface as a stage-1 failure a day
      // later instead of here.
      final spec = kOscillationProbeSpecs.singleWhere(
        (s) => s.component == 'navigation-menu',
      );
      final source = File(
        p.join(
          repoRoot,
          'packages',
          'coui_web',
          'lib',
          'src',
          'components',
          'menu',
          'navigation_menu',
          'navigation_menu.dart',
        ),
      ).readAsStringSync();
      final panelPrefix = RegExp(
        r'\[id\^="([^"]+)"\]',
      ).firstMatch(spec.panelSelector)!.group(1)!;
      expect(source, contains("_panelId = '$panelPrefix"));
      expect(spec.triggerSelector, contains('aria-expanded'));
      expect(source, contains("'aria-expanded': isOpen ?"));

      // The mark is on the component itself, not on the picture of its open
      // state: the live element is the component's own `<nav>`.
      final rendered = await _renderedLive(repoRoot, spec);
      expect(rendered.live, hasLength(1), reason: rendered.problem);
      final live = rendered.live.single;
      expect(live.localName, 'nav');
      expect(live.id, startsWith('co-navigation-menu-'));
    });
  });
}
