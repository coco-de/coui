import 'package:coui_web/coui_web.dart';

/// External Link example for docs_site Web preview.
///
/// Setting `external: true` opens the link in a new browsing context
/// (`target="_blank"` + `rel="noopener noreferrer"`).
class LinkExternalExample extends StatelessComponent {
  const LinkExternalExample({super.key});

  @override
  Component build(BuildContext context) {
    return Link(
      href: 'https://example.com',
      external: true,
      child: const Text('외부 링크'),
    );
  }
}
