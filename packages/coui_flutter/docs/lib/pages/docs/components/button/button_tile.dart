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
      example: SizedBox(
        width: 250,
        child: Card(
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              PrimaryButton(
                child: const Text('Primary'),
                onPressed: () {
                  // TODOS: will be implemented later.
                },
              ),
              SecondaryButton(
                child: const Text('Secondary'),
                onPressed: () {
                  // TODOS: will be implemented later.
                },
              ),
              OutlineButton(
                child: const Text('Outline'),
                onPressed: () {
                  // TODOS: will be implemented later.
                },
              ),
              GhostButton(
                child: const Text('Ghost'),
                onPressed: () {
                  // TODOS: will be implemented later.
                },
              ),
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
      scale: 1.5,
    );
  }
}
