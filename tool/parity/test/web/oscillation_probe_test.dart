// #4204 — the oscillation probe's verdict and spec table, held without a
// browser.
//
// The browser half (`tool/parity/oscillation_probe.dart`) runs nightly
// against the hydrated docs site. What can be pinned here is pinned here,
// so a mistake fails in the PR that makes it rather than the next night:
//   * a run in which nothing happened — the panel never opened — is a
//     failure, not a pass (the whole point of the probe's first stage);
//   * any state change under a resting pointer fails;
//   * every spec points at a docs page that renders its pane, and at a
//     trigger and panel the component actually emits.
import 'dart:io';

import 'package:docs_core/shared/component_catalog.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../src/web/oscillation_probe.dart';

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
        problem: 'no `#web-x-default` on /components/x/',
      );
      expect(
        oscillationFailures(observation),
        ['no `#web-x-default` on /components/x/'],
      );
    });
  });

  group('oscillation probe self-test fixtures', () {
    test('every fixture renders the pane and trigger the spec looks for', () {
      for (final fixture in OscillationFixture.values) {
        final html = oscillationFixtureHtml(fixture);
        expect(
          html,
          contains('id="${kOscillationFixtureSpec.paneId}"'),
          reason: fixture.name,
        );
        expect(html, contains('aria-expanded="false"'), reason: fixture.name);
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

    test('every spec points at a docs page that renders its pane', () {
      final slugs = {for (final entry in kDocsComponentEntries) entry.slug};
      final problems = <String>[];
      for (final spec in kOscillationProbeSpecs) {
        if (!slugs.contains(spec.component)) {
          problems.add('${spec.component}: not in the docs catalog');
          continue;
        }
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
          problems.add('${spec.component}: no ${page.path}');
          continue;
        }
        final rendersPane =
            RegExp(
              '<LivePreview component="${RegExp.escape(spec.component)}"'
              '([^>]*)/>',
            ).allMatches(page.readAsStringSync()).any((match) {
              final attributes = match.group(1)!;
              final variants = RegExp(
                'variants="([^"]*)"',
              ).firstMatch(attributes)?.group(1);
              if (variants != null) {
                return variants
                    .split(',')
                    .map((v) => v.trim())
                    .contains(
                      spec.variant,
                    );
              }
              final variant = RegExp(
                'variant="([^"]*)"',
              ).firstMatch(attributes)?.group(1);
              return (variant ?? 'default') == spec.variant;
            });
        if (!rendersPane) {
          problems.add('${spec.component}: no pane #${spec.paneId}');
        }
      }
      expect(problems, isEmpty, reason: problems.join('\n'));
    });

    test('the navigation-menu spec matches what the component emits', () {
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
    });
  });
}
