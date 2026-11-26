import 'package:coui_flutter/coui_flutter.dart';

class BottomActionBarDefaultExample extends StatelessWidget {
  const BottomActionBarDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    return BottomActionBar(
      description: const Text('계속하면 이용약관에 동의한 것으로 봐요'),
      primaryAction: Button(
        variant: .primary,
        size: .xl,
        onPressed: () {},
        child: const Text('등록하기'),
      ),
      secondaryAction: Button(
        variant: .ghost,
        size: .lg,
        onPressed: () {},
        child: const Text('나중에 하기'),
      ),
    );
  }
}
