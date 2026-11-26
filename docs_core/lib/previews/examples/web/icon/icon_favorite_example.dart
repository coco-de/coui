import 'package:coui_web/coui_web.dart';

class IconFavoriteExample extends StatelessComponent {
  const IconFavoriteExample({super.key});

  @override
  Component build(BuildContext context) {
    return Icon(
      LucideIcons.heart,
      iconStyle: const CoreIconStyle(
        size: 28,
        color: CoreColor.token(CoreColors.tertiary),
      ),
    );
  }
}
