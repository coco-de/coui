import 'package:coui_web/coui_web.dart';

/// Muted Link example for docs_site Web preview.
///
/// `variant: CoreLinkVariant.muted` reads the secondary text colour, for a
/// link in a supporting position — a footer row, a caption.
class LinkMutedExample extends StatelessComponent {
  const LinkMutedExample({super.key});

  @override
  Component build(BuildContext context) {
    return Link(
      href: '#',
      variant: CoreLinkVariant.muted,
      child: const Text('이용약관'),
    );
  }
}
