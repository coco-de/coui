import 'package:coui_web/coui_web.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CoreCalendarStyle] slot without constructing the
/// component from scratch.
class CalendarChainExample extends StatelessComponent {
  const CalendarChainExample({super.key});

  @override
  Component build(BuildContext context) {
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
