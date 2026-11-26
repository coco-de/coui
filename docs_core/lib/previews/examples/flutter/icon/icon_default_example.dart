import 'package:coui_flutter/coui_flutter.dart';

class IconDefaultExample extends StatelessWidget {
  const IconDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const Icon(LucideIcons.house, iconStyle: CoreIconStyle(size: 28));
  }
}
