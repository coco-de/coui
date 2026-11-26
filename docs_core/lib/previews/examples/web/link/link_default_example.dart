import 'package:coui_web/coui_web.dart';

/// Default Link example for docs_site Web preview.
///
/// `Link` renders tappable link text, recognised by its colour, that
/// navigates to [Link.href] and / or invokes `onPressed`. The underline
/// appears while it is hovered, pressed or focused.
class LinkDefaultExample extends StatelessComponent {
  const LinkDefaultExample({super.key});

  @override
  Component build(BuildContext context) {
    return Link(
      href: '#',
      child: const Text('자세히 보기'),
    );
  }
}
