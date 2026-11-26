import 'dart:io';

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_content/jaspr_content.dart' show CustomComponentBase;

import 'changelog.dart';
import 'repo_root.dart';

/// `<ChangelogPreview package="coui_flutter" count="5" />`.
///
/// Renders the most recent [count] release entries straight out of
/// `packages/{package}/CHANGELOG.md` at doc-build time — never a hand
/// copy, so it cannot drift the way a pasted excerpt would (the exact
/// failure mode #3585 exists to close: the root `CHANGELOG.md` was linked
/// nowhere and nobody noticed it had stopped tracking real releases).
///
/// `package` must be a directory under `packages/` with a `CHANGELOG.md`
/// (`coui_flutter` / `coui_web` / `coui_core` today). A missing or
/// unreadable file renders a single-line notice instead of throwing — a
/// doc page should degrade, not 500, if a package is renamed.
class ChangelogPreview extends CustomComponentBase {
  @override
  Pattern get pattern => 'ChangelogPreview';

  @override
  Component apply(String name, Map<String, String> attributes, Component? child) {
    // What the tag says is decided by `changelogPreviewView` — the native
    // app reads the same function, so the two surfaces cannot show different
    // entries from one CHANGELOG. Only the file read below is Web's own.
    final package = changelogPreviewPackage(attributes);
    if (package == null) return _render(kChangelogPreviewMissingPackageNotice);

    final String source;
    try {
      final root = findRepoRoot();
      final file = File('${root.path}/packages/$package/CHANGELOG.md');
      if (!file.existsSync()) {
        return _render(changelogPreviewMissingNotice(package));
      }
      source = file.readAsStringSync();
    } on Object catch (e) {
      return _render(changelogPreviewUnreadableNotice(package, e));
    }

    return _render(
      changelogPreviewView(package: package, attributes: attributes, changelogSource: source),
    );
  }

  Component _render(ChangelogPreviewView view) => switch (view) {
    ChangelogPreviewNotice(:final message) => _notice(message),
    ChangelogPreviewEntries(:final entries) => div(classes: 'changelog-preview', [
      Component.element(tag: 'style', children: [RawText(_css)]),
      for (final entry in entries) _entry(entry),
    ]),
  };

  Component _entry(ChangelogEntry entry) {
    return article(classes: 'cp-entry', [
      header(classes: 'cp-entry-header', [
        span(classes: 'cp-version', [Component.text(entry.version)]),
        span(classes: 'cp-date', [Component.text(entry.date)]),
      ]),
      for (final section in entry.sections.entries)
        if (section.value.isNotEmpty)
          div(classes: 'cp-section', [
            h4([Component.text(section.key)]),
            ul([
              for (final bullet in section.value)
                li([
                  for (final span in changelogBulletSpans(bullet))
                    switch (span.kind) {
                      ChangelogSpanKind.text => Component.text(span.text),
                      ChangelogSpanKind.strong => strong([Component.text(span.text)]),
                      ChangelogSpanKind.code => code([Component.text(span.text)]),
                    },
                ]),
            ]),
          ]),
    ]);
  }

  Component _notice(String message) {
    return p(classes: 'changelog-preview-notice', [Component.text(message)]);
  }
}

const _css = '''
.changelog-preview { margin: 1rem 0; display: flex; flex-direction: column; gap: 1.25rem; }
.cp-entry { padding-bottom: 1rem; border-bottom: 1px solid var(--coui-outline-variant, #e5e7eb); }
.cp-entry:last-child { border-bottom: none; padding-bottom: 0; }
.cp-entry-header { display: flex; align-items: baseline; gap: 0.6rem; margin-bottom: 0.5rem; }
.cp-version { font-weight: 600; font-family: monospace; color: var(--coui-on-surface, #1a1a1a); }
.cp-date { font-size: 0.8rem; color: var(--coui-on-surface-variant, #6b7280); }
.cp-section h4 { font-size: 0.8rem; margin: 0.5rem 0 0.25rem; color: var(--coui-on-surface-variant, #6b7280); }
.cp-section ul { margin: 0; padding-left: 1.25rem; }
.cp-section li { font-size: 0.9rem; margin: 0.15rem 0; color: var(--coui-on-surface, #1a1a1a); }
.changelog-preview-notice { font-size: 0.85rem; color: var(--coui-on-surface-variant, #6b7280); font-style: italic; }
''';
