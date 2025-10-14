import 'package:coui_flutter/coui_flutter.dart';

class LayoutPageExample1 extends StatelessWidget {
  const LayoutPageExample1({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.red,
      child: Container(
        color: Colors.green,
        child: Container(color: Colors.blue, height: 20).withPadding(all: 16),
      ).withPadding(bottom: 12, horizontal: 16, top: 24),
    );
  }
}
