import 'package:coui_web/coui_web.dart';

/// Link with a trailing icon for docs_site Web preview.
///
/// The external-link glyph after the label says the link leaves the site;
/// it takes the link's text colour and sits a gap away from the label.
class LinkIconsExample extends StatelessComponent {
  const LinkIconsExample({super.key});

  @override
  Component build(BuildContext context) {
    return const Link(
      href: 'https://github.com/coco-de/coui',
      external: true,
      trailing: Icon(LucideIcons.externalLink),
      child: Text('GitHub에서 보기'),
    );
  }
}
