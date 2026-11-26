import 'package:coui_flutter/coui_flutter.dart';

class CardElevatedExample extends StatelessWidget {
  const CardElevatedExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const Card(
      cardStyle: CoreCardStyle(elevation: CoreCardElevation.medium),
      header: Text('띄운 카드'),
      body: Text('중간 높이의 그림자를 드리운 카드예요.'),
    );
  }
}
