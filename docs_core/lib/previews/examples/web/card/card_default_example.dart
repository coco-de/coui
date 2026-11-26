import 'package:coui_web/coui_web.dart';

class CardDefaultExample extends StatelessComponent {
  const CardDefaultExample({super.key});

  @override
  Component build(BuildContext context) {
    return Card(
      header: Text('프로젝트 요약'),
      body: Text('이번 주 진행 상황을 확인해 보세요.'),
      footer: Button(
        variant: CoreButtonVariant.primary,
        onPressed: () {},
        child: Text('자세히 보기'),
      ),
    );
  }
}
