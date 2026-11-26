import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'navigation_menu.stories.g.dart';

/// Interactive demo host for [NavigationMenu] stories.
class NavigationMenuDemo extends StatelessWidget {
  /// Creates a [NavigationMenuDemo].
  const NavigationMenuDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return const NavigationMenu(
      items: [
        CoreNavigationMenuItem(label: 'Home'),
        CoreNavigationMenuItem(
          label: 'Products',
          content: Text('Latest gadgets, fashion and more'),
        ),
        CoreNavigationMenuItem(label: 'About'),
        CoreNavigationMenuItem(label: 'Contact'),
      ],
    );
  }
}

/// Navigation metadata for the NavigationMenu component.
const kComponentMeta = ComponentMeta(name: 'NavigationMenu', path: 'menu');

/// Story metadata for [NavigationMenuDemo].
const kMeta = Meta(NavigationMenuDemo.new);

/// Menu bar with one item exposing hover content.
final $Default = _Story();
