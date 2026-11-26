import 'package:coui_web/coui_web.dart';

class ProgressLabelledExample extends StatelessComponent {
  const ProgressLabelledExample({super.key});

  @override
  Component build(BuildContext context) {
    return const Progress(
      value: 0.62,
      label: Text('팀 요금제'),
      valueLabel: Text('62%'),
      caption: Text('AI 사용량 · 18일 남음'),
    );
  }
}
