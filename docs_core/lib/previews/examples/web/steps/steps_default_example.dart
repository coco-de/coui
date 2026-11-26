import 'package:coui_web/coui_web.dart';

class StepsDefaultExample extends StatelessComponent {
  const StepsDefaultExample({super.key});

  @override
  Component build(BuildContext context) {
    return const Steps(
      currentStep: 2,
      items: [
        CoreStepData(
          title: '계정 만들기',
          description: '이메일로 가입해요',
        ),
        CoreStepData(
          title: '이메일 인증',
          description: '받은편지함을 확인해 주세요',
        ),
        CoreStepData(
          title: '프로필 설정',
          description: '정보를 입력해 주세요',
        ),
        CoreStepData(
          title: '완료',
          description: '시작할 준비가 됐어요',
        ),
      ],
    );
  }
}
