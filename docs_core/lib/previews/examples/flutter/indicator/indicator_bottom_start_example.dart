import 'package:coui_flutter/coui_flutter.dart';

class IndicatorBottomStartExample extends StatelessWidget {
  const IndicatorBottomStartExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const Indicator(
      horizontalPosition: CoreIndicatorHorizontalPosition.start,
      verticalPosition: CoreIndicatorVerticalPosition.bottom,
      item: Status(
        color: CoreStatusColor.warning,
        size: CoreStatusSize.lg,
      ),
      child: Avatar(initials: 'C'),
    );
  }
}
