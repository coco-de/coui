import 'package:coui_web/coui_web.dart';

class BasicDefaultExample extends StatelessComponent {
  const BasicDefaultExample({super.key});

  @override
  Component build(BuildContext context) {
    return Basic(
      leading: const Icon(LucideIcons.user),
      title: Text('사용자 프로필'),
      subtitle: Text('계정 설정을 관리해요'),
      content: Text('alice@example.com 계정으로 로그인했어요'),
      trailing: const Icon(LucideIcons.chevronRight),
    );
  }
}
