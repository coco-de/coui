import 'package:coui_web/coui_web.dart';

/// Always-underlined Link example for docs_site Web preview.
///
/// Setting `underline: true` keeps the underline permanent — for a link
/// that sits where colour alone cannot carry the recognition.
class LinkUnderlineExample extends StatelessComponent {
  const LinkUnderlineExample({super.key});

  @override
  Component build(BuildContext context) {
    return Link(
      href: '#',
      underline: true,
      child: const Text('항상 밑줄 표시'),
    );
  }
}
