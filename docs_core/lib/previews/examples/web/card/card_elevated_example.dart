import 'package:coui_web/coui_web.dart';

class CardElevatedExample extends StatelessComponent {
  const CardElevatedExample({super.key});

  @override
  Component build(BuildContext context) {
    return Card(
      cardStyle: const CoreCardStyle(elevation: CoreCardElevation.medium),
      header: Text('띄운 카드'),
      body: Text('중간 높이의 그림자를 드리운 카드예요.'),
    );
  }
}
