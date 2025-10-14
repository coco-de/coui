import 'package:coui_flutter/coui_flutter.dart';

class LayoutPageExample2 extends StatelessWidget {
  const LayoutPageExample2({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.red,
      child: Container(
        color: Colors.green,
        child: Container(color: Colors.blue, height: 20).withMargin(all: 16),
      ).withMargin(bottom: 12, horizontal: 16, top: 24),
    );
  }
}
