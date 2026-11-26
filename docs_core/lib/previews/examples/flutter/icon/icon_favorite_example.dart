import 'package:coui_flutter/coui_flutter.dart';

class IconFavoriteExample extends StatelessWidget {
  const IconFavoriteExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Icon(
      LucideIcons.heart,
      iconStyle: CoreIconStyle(
        size: 28,
        color: context.theme.colorScheme.tertiary,
      ),
    );
  }
}
