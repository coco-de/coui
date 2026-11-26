import 'package:coui_web/coui_web.dart';

class IconSearchExample extends StatelessComponent {
  const IconSearchExample({super.key});

  @override
  Component build(BuildContext context) {
    return const Icon(LucideIcons.search, iconStyle: CoreIconStyle(size: 28));
  }
}
