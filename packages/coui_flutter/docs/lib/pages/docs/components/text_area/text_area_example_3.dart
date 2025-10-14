import 'package:coui_flutter/coui_flutter.dart';

class TextAreaExample3 extends StatelessWidget {
  const TextAreaExample3({super.key});

  @override
  Widget build(BuildContext context) {
    return const TextArea(
      expandableHeight: true,
      expandableWidth: true,
      initialHeight: 300,
      initialValue: 'Hello, World!',
      initialWidth: 500,
    );
  }
}
