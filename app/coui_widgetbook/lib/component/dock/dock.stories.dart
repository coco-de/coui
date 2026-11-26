import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'dock.stories.g.dart';

// Dock widgetbook constants.
const _kHomeLabel = 'Home';
const _kSearchLabel = 'Search';
const _kProfileLabel = 'Profile';

/// Interactive demo host for [Dock] stories that tracks the active item.
class DockDemo extends StatefulWidget {
  /// Creates a [DockDemo].
  const DockDemo({
    super.key,
    this.size = CoreDockSize.md,
  });

  /// Dock size preset.
  final CoreDockSize size;

  @override
  State<DockDemo> createState() => _DockDemoState();
}

class _DockDemoState extends State<DockDemo> {
  int _activeIndex = 0;

  void handleItemSelected(int index) {
    setState(() {
      _activeIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dock(
      items: [
        CoreDockItemData<Widget>(
          onPressed: () => handleItemSelected(0),
          icon: const Icon(LucideIcons.house),
          label: _kHomeLabel,
          isActive: _activeIndex == 0,
        ),
        CoreDockItemData<Widget>(
          onPressed: () => handleItemSelected(1),
          icon: const Icon(LucideIcons.search),
          label: _kSearchLabel,
          isActive: _activeIndex == 1,
        ),
        CoreDockItemData<Widget>(
          onPressed: () => handleItemSelected(2),
          icon: const Icon(LucideIcons.user),
          label: _kProfileLabel,
          isActive: _activeIndex == 2,
        ),
      ],
      size: widget.size,
    );
  }
}

/// Navigation metadata for the Dock component.
const kComponentMeta = ComponentMeta(name: 'Dock', path: 'layout');

/// Story metadata for [DockDemo].
const kMeta = Meta(DockDemo.new);

/// Default dock with selectable items and a size knob.
final $Default = _Story();

/// Compact extra-small dock.
final $ExtraSmall = _Story(
  name: 'Extra Small',
  args: _Args(
    size: EnumArg(CoreDockSize.xs, values: CoreDockSize.values),
  ),
);

/// Spacious extra-large dock.
final $ExtraLarge = _Story(
  name: 'Extra Large',
  args: _Args(
    size: EnumArg(CoreDockSize.xl, values: CoreDockSize.values),
  ),
);
