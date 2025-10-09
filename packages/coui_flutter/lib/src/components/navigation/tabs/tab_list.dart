import 'package:coui_flutter/coui_flutter.dart';

/// Theme configuration for [TabList] appearance and behavior.
///
/// TabListTheme defines the visual styling for tab list components including
/// border colors, indicator styling, and dimensional properties. All properties
/// are optional and fall back to theme defaults when not specified.
///
/// Example:
/// ```dart
/// ComponentTheme<TabListTheme>(
///   data: TabListTheme(
///     borderColor: Colors.grey,
///     borderWidth: 2.0,
///     indicatorColor: Colors.blue,
///     indicatorHeight: 3.0,
///   ),
///   child: TabList(...),
/// )
/// ```
class TabListTheme {
  const TabListTheme({
    this.borderColor,
    this.borderWidth,
    this.indicatorColor,
    this.indicatorHeight,
  });

  /// Color of the bottom border line separating tabs from content.
  ///
  /// Type: `Color?`. If null, uses the theme's border color. This creates
  /// visual separation between the tab bar and the content area.
  final Color? borderColor;

  /// Width of the bottom border line in logical pixels.
  ///
  /// Type: `double?`. If null, uses 1 logical pixel scaled by theme scaling.
  /// The border provides structure and visual hierarchy to the tab interface.
  final double? borderWidth;

  /// Color of the active tab indicator line.
  ///
  /// Type: `Color?`. If null, uses the theme's primary color. The indicator
  /// clearly shows which tab is currently active.
  final Color? indicatorColor;

  /// Height of the active tab indicator line in logical pixels.
  ///
  /// Type: `double?`. If null, uses 2 logical pixels scaled by theme scaling.
  /// The indicator appears at the bottom of the active tab.
  final double? indicatorHeight;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is TabListTheme &&
        other.borderColor == borderColor &&
        other.borderWidth == borderWidth &&
        other.indicatorColor == indicatorColor &&
        other.indicatorHeight == indicatorHeight;
  }

  @override
  int get hashCode =>
      Object.hash(borderColor, borderWidth, indicatorColor, indicatorHeight);
}

/// A horizontal tab list widget for selecting between multiple tab content areas.
///
/// TabList provides a classic tab interface with a horizontal row of tab buttons
/// and an active tab indicator. It handles tab selection state and provides visual
/// feedback for the currently active tab through styling and an indicator line.
///
/// The widget automatically manages the appearance of tab buttons, applying
/// appropriate styling for active and inactive states. The active tab is
/// highlighted with foreground styling and an indicator line at the bottom.
///
/// Features:
/// - Horizontal row of selectable tab buttons
/// - Visual active tab indicator with customizable styling
/// - Automatic tab button state management (active/inactive)
/// - Theme-aware styling with customizable colors and dimensions
/// - Integration with TabContainer for coordinated tab management
///
/// The TabList works as part of a complete tab system, typically used with
/// corresponding content areas that show/hide based on the selected tab.
///
/// Example:
/// ```dart
/// TabList(
///   index: currentTabIndex,
///   onChanged: (index) => setState(() => currentTabIndex = index),
///   children: [
///     TabChild(child: Text('Tab 1')),
///     TabChild(child: Text('Tab 2')),
///     TabChild(child: Text('Tab 3')),
///   ],
/// )
/// ```
class TabList extends StatelessWidget {
  /// Creates a [TabList] with horizontal tab selection.
  ///
  /// Configures a tab list widget that displays a horizontal row of selectable
  /// tab buttons with visual feedback for the active tab.
  ///
  /// Parameters:
  /// - [key] (Key?): Widget identifier for the widget tree
  /// - [children] (List<TabChild>, required): List of tab items to display
  /// - [index] (int, required): Index of the currently active tab
  /// - [onChanged] (ValueChanged<int>?, required): Callback for tab selection
  ///
  /// Example:
  /// ```dart
  /// TabList(
  ///   index: selectedIndex,
  ///   onChanged: (newIndex) {
  ///     setState(() {
  ///       selectedIndex = newIndex;
  ///       // Update content based on new tab selection
  ///     });
  ///   },
  ///   children: [
  ///     TabChild(child: Text('Overview')),
  ///     TabChild(child: Text('Details')),
  ///     TabChild(child: Text('Settings')),
  ///   ],
  /// )
  /// ```
  const TabList({
    required this.children,
    required this.index,
    super.key,
    required this.onChanged,
  });

  /// List of tab child widgets to display in the tab list.
  ///
  /// Type: `List<TabChild>`. Each TabChild represents one selectable tab
  /// with its own label and optional content. The tabs are displayed in
  /// the order provided in the list.
  final List<TabChild> children;

  /// Index of the currently active/selected tab.
  ///
  /// Type: `int`. Zero-based index indicating which tab is currently active.
  /// Must be within the bounds of the [children] list. The active tab
  /// receives special styling and the indicator line.
  final int index;

  /// Callback invoked when a tab is selected.
  ///
  /// Type: `ValueChanged<int>?`. Called with the index of the newly selected
  /// tab when the user taps on a tab button. If null, tabs are not interactive.
  final ValueChanged<int>? onChanged;

  Widget _childBuilder(
    BuildContext context,
    TabContainerData data,
    Widget child,
  ) {
    final theme = Theme.of(context);
    final compTheme = ComponentTheme.maybeOf<TabListTheme>(context);
    final indicatorColor = styleValue(
      themeValue: compTheme?.indicatorColor,
      defaultValue: theme.colorScheme.primary,
    );
    final indicatorHeight = styleValue(
      themeValue: compTheme?.indicatorHeight,
      defaultValue: theme.scaling * 2,
    );
    child = TabButton(
      onPressed: () {
        data.onSelect?.call(data.index);
      },
      enabled: data.onSelect != null,
      child: child,
    );

    return Stack(
      fit: StackFit.passthrough,
      children: [
        if (data.index == index) child.foreground() else child.muted(),
        if (data.index == index)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(color: indicatorColor, height: indicatorHeight),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scaling = theme.scaling;
    final compTheme = ComponentTheme.maybeOf<TabListTheme>(context);
    final borderColor = styleValue(
      themeValue: compTheme?.borderColor,
      defaultValue: theme.colorScheme.border,
    );
    final borderWidth = styleValue(
      themeValue: compTheme?.borderWidth,
      defaultValue: scaling * 1,
    );

    return TabContainer(
      builder: (context, children) {
        return Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: borderColor, width: borderWidth),
            ),
          ),
          child: Row(children: children),
        );
      },
      childBuilder: _childBuilder,
      onSelect: onChanged,
      selected: index,
      children: children,
    );
  }
}
