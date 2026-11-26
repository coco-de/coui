import 'package:coui_flutter/coui_flutter.dart';

class ProgressLabelledExample extends StatelessWidget {
  const ProgressLabelledExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: double.infinity,
      child: Progress(
        value: 0.62,
        label: Text('팀 요금제'),
        valueLabel: Text('62%'),
        caption: Text('AI 사용량 · 18일 남음'),
      ),
    );
  }
}
