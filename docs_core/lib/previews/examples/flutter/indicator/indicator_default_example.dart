import 'package:coui_flutter/coui_flutter.dart';

class IndicatorDefaultExample extends StatelessWidget {
  const IndicatorDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const Indicator(
      item: Status(
        color: CoreStatusColor.success,
        size: CoreStatusSize.lg,
      ),
      child: Avatar(initials: 'C'),
    );
  }
}
