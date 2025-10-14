import 'package:coui_flutter/coui_flutter.dart';

class RepeatedAnimationBuilderExample1 extends StatelessWidget {
  const RepeatedAnimationBuilderExample1({super.key});

  @override
  Widget build(BuildContext context) {
    return RepeatedAnimationBuilder(
      start: const Offset(-100, 0),
      end: const Offset(100, 0),
      duration: const Duration(seconds: 1),
      builder: (context, value, child) {
        return Transform.translate(
          offset: value,
          child: Container(color: Colors.red, width: 100, height: 100),
        );
      },
    );
  }
}
