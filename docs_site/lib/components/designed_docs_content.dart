import 'package:jaspr_content/jaspr_content.dart';

/// Publishes the site-only designed pages (`content/<name>.md` under
/// `docs_site`) at their shared document routes, in place of the shared body.
class DesignedDocsContent implements PageExtension {
  const DesignedDocsContent();

  static const _paths = {
    '/components-overview': 'components/overview',
  };

  @override
  Future<List<Node>> apply(Page page, List<Node> nodes) async {
    final name = _paths[page.url];
    if (name == null) return nodes;

    final design = page.copy()..apply(content: await page.readPartial('content/$name.md'));
    design.parseFrontmatter();
    await design.renderTemplate(const []);
    page.apply(data: {'page': design.data.page, 'docsDesign': true});
    return design.parseNodes();
  }
}
