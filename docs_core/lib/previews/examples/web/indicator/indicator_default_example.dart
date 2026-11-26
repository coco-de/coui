import 'package:coui_web/coui_web.dart';

class IndicatorDefaultExample extends StatelessComponent {
  const IndicatorDefaultExample({super.key});

  @override
  Component build(BuildContext context) {
    return Indicator(
      item: Status(
        color: CoreStatusColor.success,
        size: CoreStatusSize.lg,
      ),
      child: Avatar(initials: 'C'),
    );
  }
}
