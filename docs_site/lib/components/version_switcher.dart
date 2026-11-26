import 'dart:io';

import 'package:docs_core/markdown/repo_root.dart';
import 'package:docs_core/markdown/versions.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// Header control linking to archived docs-site snapshots —
/// `docs_core/content/_data/versions.json`, built by
/// `tool/build_version_snapshot.sh`.
///
/// CoUI ships from git tags rather than pub.dev (`publish_to: none`), so a
/// consumer pinned to an older `ref:` has no pub.dev version dropdown to
/// find matching docs for. Each archived snapshot is a full separate
/// `jaspr build` output served under `/versions/{tag}/` — this control is
/// pure navigation between already-built pages, not a runtime toggle, so
/// (unlike `SurfaceStyleSwitcher`/`ThemeToggle`) it needs no inline
/// restore script or `@client` island: a `<details>` menu of `<a href>`
/// links works with zero JavaScript.
///
/// Its look is in `web/docs-shell.css` with the rest of the header's tools —
/// colours there are the kit's variables, so the menu follows the theme.
///
/// Renders nothing when the manifest has no archived versions yet — an
/// empty dropdown reads as a broken control, not an honest "nothing to
/// switch to" (same reasoning `SurfaceStyleSwitcher.offered` uses for its
/// own `length < 2` case).
class VersionSwitcher extends StatelessComponent {
  const VersionSwitcher({super.key});

  /// Reads and sorts the manifest at build time — never a hand-copy, so a
  /// snapshot the build script archived is visible on the very next
  /// deploy without a second place to update.
  ///
  /// Returns `[]` (rather than throwing) if the manifest is missing or
  /// malformed — a version switcher that fails to render is a worse
  /// failure mode for readers than a page that simply omits it.
  static List<VersionSnapshot> _readManifest() {
    try {
      final root = findRepoRoot();
      final file = File('${root.path}/docs_core/content/_data/versions.json');
      if (!file.existsSync()) return const [];
      return sortedNewestFirst(parseVersionManifest(file.readAsStringSync()));
    } on Object {
      return const [];
    }
  }

  @override
  Component build(BuildContext context) {
    final versions = _readManifest();
    if (versions.isEmpty) return const Component.fragment([]);

    return Component.element(
      tag: 'details',
      attributes: {'class': 'version-switcher'},
      children: [
        Component.element(
          tag: 'summary',
          attributes: {'aria-label': 'Docs version'},
          children: [Component.text('버전')],
        ),
        Component.element(
          tag: 'nav',
          attributes: {'aria-label': 'Version history'},
          children: [
            a(href: '/', classes: 'version-switcher-item', [Component.text('현재')]),
            for (final version in versions)
              a(
                href: '/versions/${version.tag}/',
                classes: 'version-switcher-item',
                [
                  Component.text(version.label),
                  span(classes: 'version-switcher-date', [Component.text(version.date)]),
                ],
              ),
          ],
        ),
      ],
    );
  }
}
