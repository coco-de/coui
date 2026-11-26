import 'package:coui_flutter/coui_flutter.dart';

class PanelHeaderDefaultExample extends StatelessWidget {
  const PanelHeaderDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    return PanelHeader(
      title: const Text('최근 파일'),
      action: Button(
        variant: .plain,
        size: .sm,
        onPressed: () {},
        child: const Text('모두 보기'),
        trailing: const Icon(
          LucideIcons.chevronRight,
          iconStyle: CoreIconStyle(size: CoreIconSize.size14),
        ),
      ),
    );
  }
}
