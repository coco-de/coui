import 'package:coui_web/coui_web.dart';

class DisclosureGroupExample extends StatelessComponent {
  const DisclosureGroupExample({super.key});

  @override
  Component build(BuildContext context) {
    return const DisclosureGroup(
      items: [
        Disclosure(
          title: 'JavaScript 없이도 동작하나요?',
          open: true,
          content: Text(
            '웹에서는 <details>로 그려서 브라우저가 열어 줘요.',
          ),
        ),
        Disclosure(
          title: '하나를 열면 나머지가 닫히나요?',
          content: Text('아니요. 그렇게 하려면 Accordion을 쓰세요.'),
        ),
        Disclosure(
          title: '머리글에 글자 말고 다른 것도 넣을 수 있나요?',
          content: Text('네. title 대신 trigger 위젯을 넘기면 돼요.'),
        ),
      ],
    );
  }
}
