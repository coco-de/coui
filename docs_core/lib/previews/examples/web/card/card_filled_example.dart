import 'package:coui_web/coui_web.dart';

class CardFilledExample extends StatelessComponent {
  const CardFilledExample({super.key});

  @override
  Component build(BuildContext context) {
    return Card(
      variant: CoreCardVariant.filled,
      header: Text('채운 카드'),
      body: Text('서피스 컨테이너 색으로 채운 카드예요.'),
    );
  }
}
