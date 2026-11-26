import 'package:coui_flutter/coui_flutter.dart';

class BottomActionBarHorizontalExample extends StatelessWidget {
  const BottomActionBarHorizontalExample({super.key});

  @override
  Widget build(BuildContext context) {
    return BottomActionBar(
      layout: .horizontal,
      primaryAction: Button(
        variant: .primary,
        size: .xl,
        onPressed: () {},
        child: const Text('등록하기'),
      ),
      secondaryAction: Button(
        variant: .ghost,
        size: .xl,
        onPressed: () {},
        child: const Text('나중에 하기'),
      ),
    );
  }
}
