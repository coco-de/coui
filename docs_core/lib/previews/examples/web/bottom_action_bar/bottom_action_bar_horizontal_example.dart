import 'package:coui_web/coui_web.dart';

class BottomActionBarHorizontalExample extends StatelessComponent {
  const BottomActionBarHorizontalExample({super.key});

  @override
  Component build(BuildContext context) {
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
