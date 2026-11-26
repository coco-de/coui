import 'package:coui_flutter/coui_flutter.dart';

class CardFilledExample extends StatelessWidget {
  const CardFilledExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const Card(
      variant: CoreCardVariant.filled,
      header: Text('채운 카드'),
      body: Text('서피스 컨테이너 색으로 채운 카드예요.'),
    );
  }
}
