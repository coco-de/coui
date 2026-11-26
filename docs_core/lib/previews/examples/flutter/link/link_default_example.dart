import 'package:coui_flutter/coui_flutter.dart';

/// Default Link example for docs_site Flutter preview.
///
/// `Link` renders tappable link text, recognised by its colour, that
/// navigates to [Link.href] and / or invokes `onPressed`. The underline
/// appears while it is hovered, pressed or focused.
class LinkDefaultExample extends StatelessWidget {
  const LinkDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const Link(
      href: '#',
      child: Text('자세히 보기'),
    );
  }
}
