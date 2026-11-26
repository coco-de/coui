import 'package:coui_flutter/coui_flutter.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CoreCalendarStyle] slot without constructing the widget
/// from scratch.
class CalendarChainExample extends StatelessWidget {
  const CalendarChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Calendar.single().withStyle(
      const CoreCalendarStyle(
        dayCellSize: CoreSpace.space40,
        cellSpacing: CoreSpace.space12,
        endpointPillBorderRadius: CoreBorderRadius.all(CoreRadius.radius8),
        headerTextStyle: CoreTextStyle.token(
          CoreTextStyles.titleSmall,
          color: CoreColor.token(CoreColors.primary),
        ),
      ),
    );
  }
}
