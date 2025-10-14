import 'package:coui_flutter/coui_flutter.dart';

class NavigationMenuExample1 extends StatelessWidget {
  const NavigationMenuExample1({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return NavigationMenu(
      children: [
        NavigationMenuItem(
          content: NavigationMenuContentList(
            reverse: true,
            children: [
              NavigationMenuContent(
                content: const Text(
                  'Component library for Flutter based on Coui/UI design.',
                ),
                onPressed: () {
                  // TODOS: will be implemented later.
                },
                title: const Text('Introduction'),
              ),
              NavigationMenuContent(
                content: const Text(
                  'How to install this package in your Flutter project.',
                ),
                onPressed: () {
                  // TODOS: will be implemented later.
                },
                title: const Text('Installation'),
              ),
              NavigationMenuContent(
                content: const Text(
                  'Styles and usage of typography in this package.',
                ),
                onPressed: () {
                  // TODOS: will be implemented later.
                },
                title: const Text('Typography'),
              ),
              Clickable(
                mouseCursor: const WidgetStatePropertyAll(
                  SystemMouseCursors.click,
                ),
                child: Card(
                  borderRadius: theme.borderRadiusMd,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const FlutterLogo(size: 32),
                      const Gap(16),
                      const Text('coui_flutter').mono().semiBold().large(),
                      const Gap(8),
                      const Text(
                        'Beautifully designed components from Coui/UI is now available for Flutter',
                      ).muted(),
                    ],
                  ),
                ).constrained(maxWidth: 192),
              ),
            ],
          ),
          child: const Text('Getting started'),
        ),
        NavigationMenuItem(
          content: NavigationMenuContentList(
            children: [
              NavigationMenuContent(
                content: const Text('Accordion component for Flutter.'),
                onPressed: () {
                  // TODOS: will be implemented later.
                },
                title: const Text('Accordion'),
              ),
              NavigationMenuContent(
                content: const Text('Alert component for Flutter.'),
                onPressed: () {
                  // TODOS: will be implemented later.
                },
                title: const Text('Alert'),
              ),
              NavigationMenuContent(
                content: const Text('Alert Dialog component for Flutter.'),
                onPressed: () {
                  // TODOS: will be implemented later.
                },
                title: const Text('Alert Dialog'),
              ),
              NavigationMenuContent(
                content: const Text('Animation component for Flutter.'),
                onPressed: () {
                  // TODOS: will be implemented later.
                },
                title: const Text('Animation'),
              ),
              NavigationMenuContent(
                content: const Text('Avatar component for Flutter.'),
                onPressed: () {
                  // TODOS: will be implemented later.
                },
                title: const Text('Avatar'),
              ),
              NavigationMenuContent(
                content: const Text('Badge component for Flutter.'),
                onPressed: () {
                  // TODOS: will be implemented later.
                },
                title: const Text('Badge'),
              ),
            ],
          ),
          child: const Text('Components'),
        ),
        NavigationMenuItem(
          content: NavigationMenuContentList(
            crossAxisCount: 2,
            children: [
              // latest news
              NavigationMenuContent(
                content: const Text('Stay updated with the latest news.'),
                onPressed: () {
                  // TODOS: will be implemented later.
                },
                title: const Text('Latest news'),
              ),
              NavigationMenuContent(
                content: const Text('View the change log of this package.'),
                onPressed: () {
                  // TODOS: will be implemented later.
                },
                title: const Text('Change log'),
              ),
              NavigationMenuContent(
                content: const Text('List of contributors to this package.'),
                onPressed: () {
                  // TODOS: will be implemented later.
                },
                title: const Text('Contributors'),
              ),
            ],
          ),
          child: const Text('Blog'),
        ),
        NavigationMenuItem(
          child: const Text('Documentation'),
          onPressed: () {
            // TODOS: will be implemented later.
          },
        ),
      ],
    );
  }
}
