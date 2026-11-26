import 'package:coui_flutter/coui_flutter.dart';

class AccordionDefaultExample extends StatelessWidget {
  const AccordionDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const Accordion(
      items: [
        AccordionItem(
          title: '환불 정책은 어떻게 되나요?',
          content: Text('구매 후 30일 안에 전액 환불을 요청할 수 있어요.'),
          expanded: true,
        ),
        AccordionItem(
          title: '요금제는 어떻게 해지하나요?',
          content: Text(
            '설정의 결제 메뉴에서 언제든 해지할 수 있어요.',
          ),
        ),
        AccordionItem(
          title: '이메일을 바꿀 수 있나요?',
          content: Text(
            '계정 설정에서 언제든 새 이메일로 바꿀 수 있어요.',
          ),
        ),
      ],
    );
  }
}
