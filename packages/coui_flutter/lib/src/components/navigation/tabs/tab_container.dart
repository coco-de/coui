import 'package:coui_flutter/coui_flutter.dart';

/// {@template tab_container_theme}
/// Theme data for [TabContainer] providing default builders.
/// {@endtemplate}
class TabContainerTheme {
  /// {@macro tab_container_theme}
  const TabContainerTheme({this.builder, this.childBuilder});

  /// Default builder for laying out tab children.
  final TabBuilder? builder;

  /// Default builder for wrapping each tab child.
  final TabChildBuilder? childBuilder;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is TabContainerTheme &&
        other.builder == builder &&
        other.childBuilder == childBuilder;
  }

  @override
  String toString() {
    return 'TabContainerTheme(builder: ${builder()}, childBuilder: ${childBuilder()})';
  }

  @override
  int get hashCode => Object.hash(builder, childBuilder);
}

class TabContainerData {
  const TabContainerData({
    required this.childBuilder,
    required this.index,
    required this.onSelect,
    required this.selected,
  });

  final int index;
  final int selected;
  final ValueChanged<int>? onSelect;
  final TabChildBuilder childBuilder;

  static TabContainerData of(BuildContext context) {
    final data = Data.maybeOf<TabContainerData>(context);
    assert(data != null, 'TabChild must be a descendant of TabContainer');

    return data!;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is TabContainerData &&
        other.selected == selected &&
        other.onSelect == onSelect &&
        other.index == index &&
        other.childBuilder == childBuilder;
  }

  @override
  int get hashCode => Object.hash(index, selected, onSelect, childBuilder);
}

mixin TabChild on Widget {
  bool get indexed;
}

mixin KeyedTabChild<T> on TabChild {
  T get tabKey;
}

class TabChildWidget extends StatelessWidget with TabChild {
  const TabChildWidget({
    required this.child,
    this.indexed = false,
    super.key,
  });

  final Widget child;

  @override
  final bool indexed;

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

class TabItem extends StatelessWidget with TabChild {
  const TabItem({required this.child, super.key});

  final Widget child;

  @override
  bool get indexed => true;

  @override
  Widget build(BuildContext context) {
    final data = TabContainerData.of(context);

    return data.childBuilder(context, data, child);
  }
}

typedef TabBuilder =
    Widget Function(BuildContext context, List<Widget> children);
typedef TabChildBuilder =
    Widget Function(BuildContext context, TabContainerData data, Widget child);

class TabContainer extends StatelessWidget {
  const TabContainer({
    this.builder,
    this.childBuilder,
    required this.children,
    super.key,
    required this.onSelect,
    required this.selected,
  });

  final int selected;
  final ValueChanged<int>? onSelect;
  final List<TabChild> children;
  final TabBuilder? builder;

  final TabChildBuilder? childBuilder;

  @override
  Widget build(BuildContext context) {
    final compTheme = ComponentTheme.maybeOf<TabContainerTheme>(context);
    final tabBuilder =
        builder ??
        compTheme?.builder ??
        (context, children) => Column(children: children);
    final tabChildBuilder =
        childBuilder ?? compTheme?.childBuilder ?? ((_, __, child) => child);

    final wrappedChildren = <Widget>[];
    int index = 0;
    for (final child in children) {
      if (child.indexed) {
        wrappedChildren.add(
          Data.inherit(
            key: ValueKey(child),
            data: TabContainerData(
              childBuilder: tabChildBuilder,
              index: index,
              onSelect: onSelect,
              selected: selected,
            ),
            child: child,
          ),
        );
        index += 1;
      } else {
        wrappedChildren.add(child);
      }
    }

    return tabBuilder(context, wrappedChildren);
  }
}
