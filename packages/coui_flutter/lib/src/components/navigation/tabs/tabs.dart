import 'package:coui_flutter/coui_flutter.dart';

/// Theme data for customizing [Tabs] widget appearance.
///
/// This class defines the visual properties that can be applied to
/// [Tabs] widgets, including padding for the container and individual tabs,
/// background colors, and border radius styling. These properties can be
/// set at the theme level to provide consistent styling across the application.
class TabsTheme {
  const TabsTheme({
    this.backgroundColor,
    this.borderRadius,
    this.containerPadding,
    this.tabPadding,
  });

  final EdgeInsetsGeometry? containerPadding;
  final EdgeInsetsGeometry? tabPadding;
  final Color? backgroundColor;

  final BorderRadiusGeometry? borderRadius;

  TabsTheme copyWith({
    ValueGetter<Color?>? backgroundColor,
    ValueGetter<BorderRadiusGeometry?>? borderRadius,
    ValueGetter<EdgeInsetsGeometry?>? containerPadding,
    ValueGetter<EdgeInsetsGeometry?>? tabPadding,
  }) {
    return TabsTheme(
      backgroundColor:
          backgroundColor == null ? this.backgroundColor : backgroundColor(),
      borderRadius: borderRadius == null ? this.borderRadius : borderRadius(),
      containerPadding:
          containerPadding == null ? this.containerPadding : containerPadding(),
      tabPadding: tabPadding == null ? this.tabPadding : tabPadding(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is TabsTheme &&
        other.containerPadding == containerPadding &&
        other.tabPadding == tabPadding &&
        other.backgroundColor == backgroundColor &&
        other.borderRadius == borderRadius;
  }

  @override
  int get hashCode =>
      Object.hash(containerPadding, tabPadding, backgroundColor, borderRadius);
}

/// A tabbed interface widget for organizing content into switchable panels.
///
/// [Tabs] provides a clean and intuitive way to organize related content into
/// separate panels that users can switch between by tapping tab headers. It manages
/// the selection state and provides visual feedback for the active tab while
/// handling the display of corresponding content.
///
/// Key features:
/// - Tab-based content organization with header and panel areas
/// - Active tab highlighting with smooth transitions
/// - Customizable tab styling through theming
/// - Gesture-based tab switching with tap support
/// - Flexible content management through TabChild system
/// - Integration with the coui_flutter design system
/// - Responsive layout adaptation
/// - Keyboard navigation support
///
/// The widget works with [TabChild] elements that define both the tab header
/// and the associated content panel. Each tab can contain any widget content,
/// from simple text to complex layouts.
///
/// Tab organization:
/// - Headers: Displayed in a horizontal row for tab selection
/// - Content: The active tab's content is shown in the main area
/// - Selection: Visual indication of the currently active tab
/// - Transitions: Smooth animations between tab switches
///
/// Example:
/// ```dart
/// Tabs(
///   index: currentTabIndex,
///   onChanged: (index) => setState(() => currentTabIndex = index),
///   children: [
///     TabChild(
///       tab: Text('Overview'),
///       child: Center(child: Text('Overview content')),
///     ),
///     TabChild(
///       tab: Text('Details'),
///       child: Center(child: Text('Details content')),
///     ),
///     TabChild(
///       tab: Text('Settings'),
///       child: Center(child: Text('Settings content')),
///     ),
///   ],
/// );
/// ```
class Tabs extends StatelessWidget {
  const Tabs({
    required this.children,
    required this.index,
    super.key,
    required this.onChanged,
    this.padding,
  });

  final int index;
  final ValueChanged<int> onChanged;
  final List<TabChild> children;

  final EdgeInsetsGeometry? padding;

  Widget _childBuilder(
    BuildContext context,
    TabContainerData data,
    Widget child,
  ) {
    final theme = Theme.of(context);
    final scaling = theme.scaling;
    final compTheme = ComponentTheme.maybeOf<TabsTheme>(context);
    final tabPadding = styleValue(
      defaultValue:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4) * scaling,
      themeValue: compTheme?.tabPadding,
      widgetValue: padding,
    );
    final i = data.index;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        onChanged(i);
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        hitTestBehavior: HitTestBehavior.translucent,
        child: AnimatedContainer(
          // slightly faster than kDefaultDuration
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(theme.radiusMd),
            color: i == index ? theme.colorScheme.background : null,
          ),
          duration: const Duration(milliseconds: 50),
          padding: tabPadding,
          child: (i == index ? child.foreground() : child.muted())
              .small()
              .medium(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scaling = theme.scaling;
    final compTheme = ComponentTheme.maybeOf<TabsTheme>(context);
    final containerPadding = styleValue(
      defaultValue: const EdgeInsets.all(4) * scaling,
      themeValue: compTheme?.containerPadding,
    );
    final backgroundColor = styleValue(
      defaultValue: theme.colorScheme.muted,
      themeValue: compTheme?.backgroundColor,
    );
    final borderRadius = styleValue(
      defaultValue: BorderRadius.circular(theme.radiusLg),
      themeValue: compTheme?.borderRadius,
    );

    return TabContainer(
      builder: (context, children) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: borderRadius is BorderRadius
                ? borderRadius
                : borderRadius.resolve(Directionality.of(context)),
            color: backgroundColor,
          ),
          padding: containerPadding,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: children,
            ).muted(),
          ),
        );
      },
      childBuilder: _childBuilder,
      onSelect: onChanged,
      selected: index,
      children: children,
    );
  }
}
