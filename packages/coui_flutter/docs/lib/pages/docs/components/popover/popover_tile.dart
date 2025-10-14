import 'package:docs/pages/docs/components_page.dart';
import 'package:coui_flutter/coui_flutter.dart';
import 'package:docs/pages/docs/components/calendar/calendar_example_2.dart';

class PopoverTile extends StatelessWidget implements IComponentPage {
  const PopoverTile({super.key});

  @override
  String get title => 'Popover';

  @override
  Widget build(BuildContext context) {
    return ComponentCard(
      name: 'popover',
      title: 'Popover',
      example: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DatePicker(
              mode: PromptMode.popover,
              onChanged: (value) {},
              stateBuilder: (date) {
                if (date.isAfter(DateTime.now())) {
                  return DateState.disabled;
                }
                return DateState.enabled;
              },
              value: DateTime.now(),
            ),
            const Gap(4),
            const CalendarExample2(),
          ],
        ),
      ),
      scale: 1,
    );
  }
}
