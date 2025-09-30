import 'package:coui_flutter/coui_flutter.dart';
import 'package:docs/pages/docs/components_page.dart';

class ButtonTile extends StatelessWidget implements IComponentPage {
  const ButtonTile({super.key});

  @override
  String get title => 'Button';

  @override
  Widget build(BuildContext context) {
    return ComponentCard(
      name: 'button',
      title: 'Button',
      scale: 1.5,
      example: SizedBox(
        width: 250,
        child: Card(
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              PrimaryButton(
                  onPressed: () {
                    // TODOS: will be implemented later.
                  },
                  child: const Text('Primary')),
              SecondaryButton(
                  onPressed: () {
                    // TODOS: will be implemented later.
                  },
                  child: const Text('Secondary')),
              OutlineButton(
                  onPressed: () {
                    // TODOS: will be implemented later.
                  },
                  child: const Text('Outline')),
              GhostButton(
                  onPressed: () {
                    // TODOS: will be implemented later.
                  },
                  child: const Text('Ghost')),
              DestructiveButton(
                child: const Text('Destructive'),
                onPressed: () {
                  // TODOS: will be implemented later.
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
