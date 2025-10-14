import 'package:coui_flutter/coui_flutter.dart';

class TrackerExample1 extends StatefulWidget {
  const TrackerExample1({super.key});

  @override
  State<TrackerExample1> createState() => _TrackerExample1State();
}

class _TrackerExample1State extends State<TrackerExample1> {
  @override
  Widget build(BuildContext context) {
    List<TrackerData> data = [];
    for (int i = 0; i < 80; i++) {
      data.add(
        const TrackerData(
          level: TrackerLevel.fine,
          tooltip: Text('Tracker Fine'),
        ),
      );
    }
    data[40] = data[35] = const TrackerData(
      level: TrackerLevel.warning,
      tooltip: Text('Tracker Warning'),
    );
    data[60] = data[68] = data[72] = const TrackerData(
      level: TrackerLevel.critical,
      tooltip: Text('Tracker Critical'),
    );
    for (int i = 8; i < 16; i++) {
      data[i] = const TrackerData(
        level: TrackerLevel.unknown,
        tooltip: Text('Tracker Unknown'),
      );
    }
    return Tracker(data: data);
  }
}
