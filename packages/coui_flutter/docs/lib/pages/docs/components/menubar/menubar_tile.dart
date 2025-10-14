import 'package:docs/pages/docs/components_page.dart';
import 'package:flutter/services.dart';
import 'package:coui_flutter/coui_flutter.dart';

class MenubarTile extends StatelessWidget implements IComponentPage {
  const MenubarTile({super.key});

  @override
  String get title => 'Menubar';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ComponentCard(
      name: 'menubar',
      title: 'Menubar',
      example: Card(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            OutlinedContainer(
              backgroundColor: theme.colorScheme.background,
              borderColor: theme.colorScheme.border,
              borderRadius: theme.borderRadiusMd,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: IntrinsicHeight(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Button(
                        style: const ButtonStyle.menubar(),
                        onPressed: () {
                          // TODOS: will be implemented later.
                        },
                        child: const Text('File'),
                      ),
                      Button(
                        style: const ButtonStyle.menubar().copyWith(
                          decoration: (context, states, value) {
                            return (value as BoxDecoration).copyWith(
                              color: theme.colorScheme.accent,
                              borderRadius: BorderRadius.circular(
                                theme.radiusSm,
                              ),
                            );
                          },
                        ),
                        onPressed: () {
                          // TODOS: will be implemented later.
                        },
                        child: const Text('Edit'),
                      ),
                      Button(
                        style: const ButtonStyle.menubar(),
                        onPressed: () {
                          // TODOS: will be implemented later.
                        },
                        child: const Text('View'),
                      ),
                      Button(
                        style: const ButtonStyle.menubar(),
                        onPressed: () {
                          // TODOS: will be implemented later.
                        },
                        child: const Text('Help'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Gap(4),
            Container(
              width: 192,
              margin: const EdgeInsets.only(left: 48),
              child: MenuPopup(
                children: [
                  Button(
                    style: const ButtonStyle.menu(),
                    trailing: const MenuShortcut(
                      activator: SingleActivator(
                        LogicalKeyboardKey.keyZ,
                        control: true,
                      ),
                    ),
                    onPressed: () {
                      // TODOS: will be implemented later.
                    },
                    child: const Text('Undo'),
                  ),
                  Button(
                    style: const ButtonStyle.menu().copyWith(
                      decoration: (context, states, value) {
                        return (value as BoxDecoration).copyWith(
                          color: theme.colorScheme.accent,
                          borderRadius: BorderRadius.circular(theme.radiusSm),
                        );
                      },
                    ),
                    trailing: const MenuShortcut(
                      activator: SingleActivator(
                        LogicalKeyboardKey.keyY,
                        control: true,
                      ),
                    ),
                    onPressed: () {
                      // TODOS: will be implemented later.
                    },
                    child: const Text('Redo'),
                  ),
                  const MenuDivider(),
                  Button(
                    style: const ButtonStyle.menu(),
                    trailing: const MenuShortcut(
                      activator: SingleActivator(
                        LogicalKeyboardKey.keyX,
                        control: true,
                      ),
                    ),
                    onPressed: () {
                      // TODOS: will be implemented later.
                    },
                    child: const Text('Cut'),
                  ),
                  Button(
                    style: const ButtonStyle.menu(),
                    trailing: const MenuShortcut(
                      activator: SingleActivator(
                        LogicalKeyboardKey.keyC,
                        control: true,
                      ),
                    ),
                    onPressed: () {
                      // TODOS: will be implemented later.
                    },
                    child: const Text('Copy'),
                  ),
                  Button(
                    style: const ButtonStyle.menu(),
                    trailing: const MenuShortcut(
                      activator: SingleActivator(
                        LogicalKeyboardKey.keyV,
                        control: true,
                      ),
                    ),
                    onPressed: () {
                      // TODOS: will be implemented later.
                    },
                    child: const Text('Paste'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      scale: 1,
    );
  }
}
