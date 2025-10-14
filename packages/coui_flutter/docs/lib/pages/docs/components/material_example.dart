import 'package:docs/pages/docs/component_page.dart';
import 'package:docs/pages/docs/components/material/material_example_1.dart';
import 'package:docs/pages/widget_usage_example.dart';
import 'package:go_router/go_router.dart';
import 'package:coui_flutter/coui_flutter.dart';

import 'material/cupertino_example_1.dart';

class MaterialExample extends StatelessWidget {
  const MaterialExample({super.key});

  @override
  Widget build(BuildContext context) {
    return ComponentPage(
      name: 'external',
      description: 'You can use Material/Cupertino Widgets with coui_flutter.',
      displayName: 'Material/Cupertino Widgets',
      component: false,
      children: [
        const Gap(24),
        Alert(
          content: const Text(
            'By default, Material/Cupertino Theme will follow coui_flutter theme. ',
          ).thenButton(
            child: const Text(
              'Try changing the coui_flutter theme right here!',
            ),
            onPressed: () {
              context.goNamed('theme');
            },
          ),
          leading: const Icon(Icons.info_outline),
          title: const Text('Note'),
        ),
        WidgetUsageExample(
          title: 'Material Example',
          path: 'lib/pages/docs/components/material/material_example_1.dart',
          summarize: false,
          child: const MaterialExample1().sized(height: 900, width: 500),
        ),
        WidgetUsageExample(
          title: 'Cupertino Example',
          path: 'lib/pages/docs/components/material/cupertino_example_1.dart',
          summarize: false,
          child: const CupertinoExample1().sized(height: 900, width: 500),
        ),
      ],
    );
  }
}
