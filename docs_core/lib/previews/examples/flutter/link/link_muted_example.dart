import 'package:coui_flutter/coui_flutter.dart';

/// Muted Link example for docs_site Flutter preview.
///
/// `variant: CoreLinkVariant.muted` reads the secondary text colour, for a
/// link in a supporting position — a footer row, a caption.
class LinkMutedExample extends StatelessWidget {
  const LinkMutedExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const Link(
      href: '#',
      variant: CoreLinkVariant.muted,
      child: Text('이용약관'),
    );
  }
}
