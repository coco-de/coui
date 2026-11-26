import 'package:coui_flutter/coui_flutter.dart';

/// External Link example for docs_site Flutter preview.
///
/// Setting `external: true` marks the link as opening in a new
/// browsing context.
class LinkExternalExample extends StatelessWidget {
  const LinkExternalExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const Link(
      href: 'https://example.com',
      external: true,
      child: Text('외부 링크'),
    );
  }
}
