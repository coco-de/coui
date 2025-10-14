import 'package:docs/pages/docs/components_page.dart';
import 'package:coui_flutter/coui_flutter.dart';

class FormattedInputTile extends StatelessWidget implements IComponentPage {
  const FormattedInputTile({super.key});

  @override
  String get title => 'Formatted Input';

  @override
  Widget build(BuildContext context) {
    return ComponentCard(
      name: 'formatted_input',
      title: 'Formatted Input',
      example: Card(
        child: const Column(
          children: [
            TextField(
              initialValue: '1234567890',
              placeholder: Text('(123) 456-7890'),
            ),
            Gap(16),
            TextField(
              initialValue: '1234567890123456',
              placeholder: Text('1234 5678 9012 3456'),
            ),
            Gap(16),
            TextField(
              initialValue: '12/25/2024',
              placeholder: Text('MM/DD/YYYY'),
            ),
          ],
        ).withPadding(all: 16),
      ),
      scale: 1.2,
    );
  }
}
