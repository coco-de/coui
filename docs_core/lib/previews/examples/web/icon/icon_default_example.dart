import 'package:coui_web/coui_web.dart';

class IconDefaultExample extends StatelessComponent {
  const IconDefaultExample({super.key});

  @override
  Component build(BuildContext context) {
    return const Icon(LucideIcons.house, iconStyle: CoreIconStyle(size: 28));
  }
}
