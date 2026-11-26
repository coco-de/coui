import 'package:coui_web/coui_web.dart';

class IndicatorBottomStartExample extends StatelessComponent {
  const IndicatorBottomStartExample({super.key});

  @override
  Component build(BuildContext context) {
    return Indicator(
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
