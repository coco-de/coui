import 'package:coui_flutter/coui_flutter.dart';

class TextAreaExample2 extends StatelessWidget {
  const TextAreaExample2({super.key});

  @override
  Widget build(BuildContext context) {
    return const TextArea(
      expandableWidth: true,
      initialValue: 'Hello, World!',
      initialWidth: 500,
    );
  }
}
