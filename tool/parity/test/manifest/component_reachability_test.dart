// Every catalog component must be SELECTABLE from a diff that touches it.
//
// The gate's empty-manifest path prints "no component in this diff". That
// sentence is only true if a changed component would in fact have been
// found. When it would not, the same green check and the same warning
// appear — and they now say something false, which is worse than saying
// nothing: the run looks considered.
//
// Two ways a component becomes unselectable, both real here:
//
//   1. Its files sit at a depth `changedComponentsFor` does not read.
//      The rule wants `components/<category>/<component>/…`; a component
//      parked one level up (`components/icon/icon.dart`) matches nothing,
//      falls through every branch, and is reported as "not this
//      pipeline's concern".
//
//   2. Its directory name maps to a DIFFERENT catalog slug. This is the
//      worse one, because the manifest is not empty — it is confidently
//      wrong. Flutter's `FormField` lived at `form/form/form_field.dart`,
//      so the rule read `form`, and `form` is itself a catalog slug:
//      every FormField change captured and compared **Form** instead,
//      and passed.
//
// So the test does not re-implement the path rule — a second copy would
// drift from the one that runs. It walks the real source trees, feeds
// every real path through `changedComponentsFor` itself, and asks which
// catalog slugs no file on disk can produce.
import 'dart:io';

import 'package:docs_core/shared/component_catalog.dart';
import 'package:test/test.dart';

import '../../src/manifest/changed_components.dart';

const _kPlatformRoots = <String>[
  'packages/coui_flutter/lib/src/components',
  'packages/coui_web/lib/src/components',
];

/// Slugs that no file under [_kPlatformRoots] can select today.
///
/// Ratchet, not a permanent exemption: each entry is a component whose
/// own changes cannot trigger its own parity check. Removing one means
/// moving its files to `components/<category>/<slug_with_underscores>/`
/// — the same move that made `FormField` selectable again.
///
/// `icon` and `text` are the costly two: both are composed by most of
/// the catalog, so a change to either can alter many components'
/// rendering while selecting none of them.
const _kUnreachableBaseline = <String>{
  'drag',
  'icon',
  'mockup',
  'selectable-text',
  'stack-layout',
  'tab-pane',
  'text',
};

Iterable<String> _dartFilesUnder(String root) sync* {
  final dir = Directory(root);
  if (!dir.existsSync()) return;
  for (final entity in dir.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      yield entity.path;
    }
  }
}

/// The catalog slugs any file under [root] can select, via the manifest's
/// own rule rather than a second copy of it.
Set<String> _selectableUnder(String root) {
  final found = <String>{};
  for (final path in _dartFilesUnder(root)) {
    final result = changedComponentsFor([path]);
    if (result is ChangedComponentSet) found.addAll(result.slugs);
  }
  return found;
}

void main() {
  group('every catalog component is selectable from its own diff', () {
    // Resolved once — the walk is the expensive part, and both tests
    // below ask a different question of the same answer.
    late final Set<String> selectable;
    late final Set<String> catalogSlugs;
    late final Map<String, Set<String>> byPlatform;

    setUpAll(() {
      catalogSlugs = kDocsComponentEntries.map((e) => e.slug).toSet();
      byPlatform = {
        for (final root in _kPlatformRoots) root: _selectableUnder(root),
      };
      selectable = byPlatform.values.fold(
        <String>{},
        (acc, s) => acc..addAll(s),
      );
    });

    test('the source trees are actually on disk', () {
      // Without this the walk finds nothing, every slug looks
      // unreachable, and the ratchet below would still pass if someone
      // widened the baseline to match. A test that cannot fail for the
      // right reason has to fail for the wrong one loudly.
      for (final root in _kPlatformRoots) {
        expect(
          Directory(root).existsSync(),
          isTrue,
          reason:
              '$root not found — run from the repo root. Every slug would '
              'read as unreachable and this gate would be measuring '
              'nothing.',
        );
      }
      expect(selectable, isNotEmpty);
    });

    test('no NEW component is unreachable', () {
      final unreachable = catalogSlugs.difference(selectable);
      final regressions = unreachable.difference(_kUnreachableBaseline);

      expect(
        regressions,
        isEmpty,
        reason:
            'These components cannot be selected by the parity manifest, '
            'so a change to one of them produces an empty matrix and a '
            'green check that says "no component in this diff": '
            '${(regressions.toList()..sort()).join(', ')}.\n'
            'Put the files under '
            'components/<category>/<slug_with_underscores>/ so the '
            "manifest's own path rule can see them.",
      );
    });

    test('the two platforms agree on what is selectable', () {
      // The union test above cannot see the failure that actually
      // happened: Web's `form_field/` kept `form-field` in the union
      // while Flutter's copy sat at `form/form/` and selected `form`
      // instead. Every FormField diff then captured Form on both sides
      // and passed. Comparing the two platforms to each other is what
      // makes that visible — a component present on both but selectable
      // on only one is misfiled, not single-platform.
      final flutter = byPlatform[_kPlatformRoots[0]]!.intersection(
        catalogSlugs,
      );
      final web = byPlatform[_kPlatformRoots[1]]!.intersection(catalogSlugs);

      expect(
        (web.difference(flutter).toList()..sort()),
        isEmpty,
        reason:
            'Selectable from the Web tree but not the Flutter one — the '
            'Flutter files are under a directory that maps to some other '
            "slug (or to none). That is the shape that made FormField's "
            'diffs verify Form.',
      );
      expect(
        (flutter.difference(web).toList()..sort()),
        isEmpty,
        reason: 'Selectable from the Flutter tree but not the Web one.',
      );
    });

    test('the baseline does not outlive what it excuses', () {
      // A baseline entry that became reachable has to leave, or the
      // number stops meaning "still broken" and starts meaning "was
      // broken once".
      final stale = _kUnreachableBaseline.intersection(selectable);
      expect(
        stale,
        isEmpty,
        reason:
            'Now selectable — delete from _kUnreachableBaseline: '
            '${(stale.toList()..sort()).join(', ')}',
      );

      final unknown = _kUnreachableBaseline.difference(catalogSlugs);
      expect(
        unknown,
        isEmpty,
        reason:
            'Not catalog slugs at all — delete from _kUnreachableBaseline: '
            '${(unknown.toList()..sort()).join(', ')}',
      );
    });
  });
}
