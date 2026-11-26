import 'package:coui_flutter/coui_flutter.dart';

/// Always-underlined Link example for docs_site Flutter preview.
///
/// Setting `underline: true` keeps the underline permanent — for a link
/// that sits where colour alone cannot carry the recognition.
class LinkUnderlineExample extends StatelessWidget {
  const LinkUnderlineExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const Link(
      href: '#',
      underline: true,
      child: Text('항상 밑줄 표시'),
    );
  }
}
