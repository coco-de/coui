// #4154 — the keyboard probe's spec table, held to the arithmetic and to the
// repository it describes.
//
// The browser half (`tool/parity/keyboard_probe.dart`) runs nightly against
// the hydrated docs site; what can be pinned without a browser is pinned
// here, so a spec mistake fails in the PR that makes it rather than the
// next night:
//   * every arrow / Home / End step agrees with `rovingTargetIndex`, the
//     helper the collections themselves call;
//   * every spec names a component that has an `/embed` route and a Web
//     preview for it to render;
//   * every Web component that promises a roving tab stop or an
//     `aria-activedescendant` has a spec — a new collection cannot ship
//     without the probe walking it.
import 'dart:io';

import 'package:docs_core/previews/web_registry.dart';
import 'package:docs_core/shared/component_catalog.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../src/web/keyboard_probe_spec.dart';

/// Source markers of a keyboard-owning collection: it hands out roving
/// tab stops, or it announces a highlight through `aria-activedescendant`.
final _kCollectionMarker = RegExp(
  r"rovingItemAttributes\(|'aria-activedescendant':",
);

void main() {
  final repoRoot = Directory.current.path;

  group('keyboard probe spec table (#4154)', () {
    test('every spec names a distinct component', () {
      final names = [for (final spec in kKeyboardProbeSpecs) spec.component];
      expect(names.toSet(), hasLength(names.length), reason: '$names');
    });

    test('arrow / Home / End steps agree with rovingTargetIndex', () {
      final mismatches = [
        for (final spec in kKeyboardProbeSpecs)
          ...keyboardProbeModelMismatches(spec),
      ];
      expect(mismatches, isEmpty, reason: mismatches.join('\n'));
    });

    test('a spec that disagrees with the arithmetic is caught', () {
      // The replay has to be able to fail, or the test above proves nothing.
      const wrong = KeyboardProbeSpec(
        component: 'tabs',
        mode: .roving,
        startIndex: 0,
        model: KeyboardProbeModel(count: 2, vertical: false),
        steps: [
          KeyboardProbeStep('ArrowRight', index: 1),
          // Wraps back to 0 — stating 1 is wrong.
          KeyboardProbeStep('ArrowRight', index: 1),
        ],
      );
      expect(keyboardProbeModelMismatches(wrong), hasLength(1));
    });

    test('a structural step resets the count the replay uses', () {
      // A tree row expanding from three visible rows to five: End after it
      // is row 4, which only a replay that took the new count gets right.
      const spec = KeyboardProbeSpec(
        component: 'tree',
        mode: .roving,
        startIndex: 1,
        model: KeyboardProbeModel(count: 3, vertical: true, wrap: false),
        steps: [
          KeyboardProbeStep('ArrowRight', index: 1, structural: true, count: 5),
          KeyboardProbeStep('End', index: 4),
        ],
      );
      expect(keyboardProbeModelMismatches(spec), isEmpty);
    });

    test('every spec has an embed route that renders its pane', () {
      // `/embed/<slug>` is emitted for every catalogued component and mounts
      // that component's entry in the Web preview registry. Either one
      // missing leaves the probe with no pane to drive.
      final slugs = {for (final entry in kDocsComponentEntries) entry.slug};
      final problems = <String>[];
      for (final spec in kKeyboardProbeSpecs) {
        if (!slugs.contains(spec.component)) {
          problems.add(
            '${spec.component}: not in the docs catalog, so no '
            '/embed/${spec.component} route',
          );
        } else if (!kWebPreviewRegistry.containsKey(spec.component)) {
          problems.add(
            '${spec.component}: no Web preview registered '
            '(pane #${spec.paneId})',
          );
        }
      }
      expect(problems, isEmpty, reason: problems.join('\n'));
    });

    test('every Web collection that owns keys has a spec', () {
      final components = Directory(
        p.join(
          repoRoot,
          'packages',
          'coui_web',
          'lib',
          'src',
          'components',
        ),
      );
      final covered = {for (final spec in kKeyboardProbeSpecs) spec.component};
      final missing = <String>[];
      for (final file in components.listSync(recursive: true)) {
        if (file is! File) continue;
        final name = p.basename(file.path);
        if (!name.endsWith('.dart') || name.endsWith('_style.dart')) continue;
        if (!_kCollectionMarker.hasMatch(file.readAsStringSync())) continue;
        final slug = p.basenameWithoutExtension(name).replaceAll('_', '-');
        if (!covered.contains(slug)) {
          missing.add('$slug (${p.relative(file.path, from: repoRoot)})');
        }
      }
      expect(
        missing,
        isEmpty,
        reason:
            'These Web components hand out roving tab stops or an '
            'aria-activedescendant but the keyboard probe does not walk '
            'them — add a KeyboardProbeSpec for each:\n${missing.join('\n')}',
      );
    });
  });
}
