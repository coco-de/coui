import 'package:coui_flutter/coui_flutter.dart';
import 'package:docs/pages/docs/components_page.dart';

class CheckboxTile extends StatelessWidget implements IComponentPage {
  const CheckboxTile({super.key});

  @override
  String get title => 'Checkbox';

  @override
  Widget build(BuildContext context) {
    return ComponentCard(
      name: 'checkbox',
      title: 'Checkbox',
      example: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              onChanged: (value) {},
              state: CheckboxState.checked,
              trailing: const Text('Checked'),
            ),
            Checkbox(
              onChanged: (value) {},
              state: CheckboxState.indeterminate,
              trailing: const Text('Indeterminate'),
            ),
            Checkbox(
              onChanged: (value) {},
              state: CheckboxState.unchecked,
              trailing: const Text('Unchecked'),
            ),
          ],
        ).gap(4).sized(width: 300),
      ),
      scale: 1.8,
    );
  }
}
