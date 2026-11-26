import 'package:coui_web/coui_web.dart';

class DisclosureDefaultExample extends StatelessComponent {
  const DisclosureDefaultExample({super.key});

  @override
  Component build(BuildContext context) {
    return const Disclosure(
      title: 'CoUI는 무엇인가요?',
      open: true,
      content: Text(
        'Flutter와 웹에서 똑같이 보이는 디자인 시스템이에요.',
      ),
    );
  }
}
