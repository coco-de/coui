import 'package:coui_flutter/coui_flutter.dart';

class TimelineDefaultExample extends StatelessWidget {
  const TimelineDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Timeline(
      items: [
        CoreTimelineItem(title: '주문 접수', timestamp: '오전 10:00'),
        CoreTimelineItem(title: '처리 중', timestamp: '오전 11:30'),
        CoreTimelineItem(title: '발송 완료', timestamp: '오후 2:00'),
      ],
    );
  }
}
