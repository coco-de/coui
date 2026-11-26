import 'package:coui_flutter/coui_flutter.dart';

class CardDefaultExample extends StatelessWidget {
  const CardDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      header: const Text('프로젝트 요약'),
      body: const Text('이번 주 진행 상황을 확인해 보세요.'),
      footer: Button(
        variant: CoreButtonVariant.primary,
        onPressed: () {},
        child: const Text('자세히 보기'),
      ),
    );
  }
}
