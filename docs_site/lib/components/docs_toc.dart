import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_content/jaspr_content.dart' show TocEntry;

/// A page's headings as nested lists of anchors.
///
/// Built here rather than with `TableOfContents.build()`, which flattens every
/// level into one `<ul>` and keeps the depth only as an inline `padding-left`
/// on the `<li>`. The reading-position rail pins a marker to each link's own
/// box, so depth has to indent the link's text (`--toc-depth`) instead of
/// moving the link itself, and sub-entries need a class of their own to be set
/// a size smaller. Nesting also tells a screen reader which entries belong to
/// which section.
class DocsTocList extends StatelessComponent {
  const DocsTocList({required this.path, required this.entries, this.includeSubsections = true, super.key});

  /// The page's own path.
  ///
  /// Anchors are `<path>#<id>`: the document sets `<base href="/">`, so a bare
  /// `#<id>` would resolve against the site root and open the home page.
  final String path;

  /// The headings, nested the way `TableOfContentsExtension` found them.
  final List<TocEntry> entries;
  final bool includeSubsections;

  @override
  Component build(BuildContext context) => _list(entries, 0);

  Component _list(List<TocEntry> entries, int depth) {
    return ul(classes: depth == 0 ? 'toc-list' : 'toc-sub', [
      for (final entry in entries)
        li([
          a(
            href: '$path#${entry.id}',
            classes: depth == 0 ? 'toc-link' : 'toc-link toc-link--sub',
            styles: depth == 0 ? null : Styles(raw: {'--toc-depth': '$depth'}),
            [Component.text(entry.text)],
          ),
          if (includeSubsections && entry.children.isNotEmpty) _list(entry.children, depth + 1),
        ]),
    ]);
  }
}
