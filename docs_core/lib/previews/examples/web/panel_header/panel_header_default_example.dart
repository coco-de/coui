import 'package:coui_web/coui_web.dart';

class PanelHeaderDefaultExample extends StatelessComponent {
  const PanelHeaderDefaultExample({super.key});

  @override
  Component build(BuildContext context) {
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
