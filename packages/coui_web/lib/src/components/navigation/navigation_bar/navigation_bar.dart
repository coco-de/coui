import 'package:coui_web/src/base/ui_component.dart';
import 'package:jaspr/jaspr.dart';

/// Callback signature for navigation item selection.
typedef NavigationCallback = void Function(int index);

/// A navigation bar component following shadcn-ui design patterns.
///
/// Example:
/// ```dart
/// NavigationBar(
///   currentIndex: 0,
///   onIndexChanged: (index) => print('Selected: $index'),
///   items: [
///     NavigationItem(icon: Icon.home, label: 'Home'),
///     NavigationItem(icon: Icon.search, label: 'Search'),
///   ],
/// )
/// ```
class NavigationBar extends UiComponent {
  /// Creates a NavigationBar component.
  ///
  /// Parameters:
  /// - [items]: Navigation items
  /// - [currentIndex]: Currently selected index
  /// - [onIndexChanged]: Callback when selection changes
  const NavigationBar({
    super.key,
    required this.items,
    this.currentIndex = 0,
    this.onIndexChanged,
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.tag = _navValue,
  }) : super(null);

  /// Navigation items.
  final List<NavigationItem> items;

  /// Currently selected index.
  final int currentIndex;

  /// Callback when selection changes.
  final NavigationCallback? onIndexChanged;

  static const _navValue = 'nav';

  @override
  NavigationBar copyWith({
    int? currentIndex,
    Key? key,
    List<NavigationItem>? items,
    Map<String, String>? attributes,
    NavigationCallback? onIndexChanged,
    String? classes,
    String? id,
    String? tag,
    Styles? css,
  }) {
    return NavigationBar(
      attributes: attributes ?? this.componentAttributes,
      classes: mergeClasses(classes, this.classes),
      css: css ?? this.css,
      currentIndex: currentIndex ?? this.currentIndex,
      id: id ?? this.id,
      items: items ?? this.items,
      key: key ?? this.key,
      onIndexChanged: onIndexChanged ?? this.onIndexChanged,
      tag: tag ?? this.tag,
    );
  }

  @override
  Component build(BuildContext context) {
    final navItems = <Component>[];

    for (int i = 0; i < items.length; i += 1) {
      final item = items[i];
      final isActive = i == currentIndex;

      navItems.add(
        button(
          classes: _buildItemClasses(isActive),
          attributes: {
            'type': 'button',
            if (isActive) 'aria-current': 'page',
          },
          events: _buildItemEvents(i),
          children: [
            if (item.icon != null) item.icon!,
            if (item.label != null)
              span(
                classes: 'text-xs',
                child: text(item.label!),
              ),
          ],
        ),
      );
    }

    return nav(
      id: id,
      classes: _buildClasses(),
      styles: css,
      attributes: {
        ...this.componentAttributes,
        'aria-label': 'Main navigation',
      },
      events: this.events,
      children: navItems,
    );
  }

  @override
  String get baseClass =>
      'flex items-center justify-around border-t bg-background p-2';

  String _buildClasses() {
    final classList = [baseClass];

    if (classes != null && classes!.isNotEmpty) {
      classList.add(classes!);
    }

    return classList.join(' ');
  }

  static String _buildItemClasses(bool isActive) {
    const base =
        'flex flex-col items-center justify-center gap-1 rounded-md p-2 transition-colors';
    final state = isActive
        ? 'bg-accent text-accent-foreground'
        : 'text-muted-foreground hover:bg-accent hover:text-accent-foreground';

    return '$base $state';
  }

  Map<String, List<dynamic>> _buildItemEvents(int index) {
    final currentCallback = onIndexChanged;

    return currentCallback == null
        ? {}
        : {
            'click': [
              (event) => currentCallback(index),
            ],
          };
  }
}

/// A navigation bar item.
class NavigationItem {
  /// Creates a NavigationItem.
  const NavigationItem({
    this.icon,
    this.label,
  }) : assert(
         icon != null || label != null,
         'Either icon or label must be provided',
       );

  /// Item icon.
  final Component? icon;

  /// Item label.
  final String? label;
}
