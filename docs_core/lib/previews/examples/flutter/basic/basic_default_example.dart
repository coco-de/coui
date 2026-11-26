import 'package:coui_flutter/coui_flutter.dart';

class BasicDefaultExample extends StatelessWidget {
  const BasicDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Basic(
      leading: const Icon(LucideIcons.user),
      title: const Text('사용자 프로필'),
      subtitle: const Text('계정 설정을 관리해요'),
      content: const Text('alice@example.com 계정으로 로그인했어요'),
      trailing: const Icon(LucideIcons.chevronRight),
    );
  }
}
