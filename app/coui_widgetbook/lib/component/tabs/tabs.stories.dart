import 'package:coui_flutter/coui_flutter.dart';
import 'package:coui_i10n/coui_i10n.dart';
import 'package:widgetbook/widgetbook.dart';

part 'tabs.stories.g.dart';

const _kContentWidth = 400.0;
const _kContentHeight = 200.0;

/// Interactive demo host for [Tabs] stories.
///
/// Owns the selected index and optionally renders an [IndexedStack]
/// content panel below the tab bar.
class TabsDemo extends StatefulWidget {
  /// Creates a [TabsDemo].
  const TabsDemo({
    super.key,
    this.initialIndex = 0,
    this.variant = CoreTabVariant.pill,
    this.showContent = false,
  });

  /// Initially selected tab index.
  final int initialIndex;

  /// Visual variant of the tab bar.
  final CoreTabVariant variant;

  /// Whether a content panel is rendered below the tab bar.
  final bool showContent;

  @override
  State<TabsDemo> createState() => _TabsDemoState();
}

class _TabsDemoState extends State<TabsDemo> {
  int? _selectedIndex;

  int get _effectiveIndex => _selectedIndex ?? widget.initialIndex;

  static Widget _buildContentCard(String title, String body) {
    return Card(
      child: Center(
        child: Column(
          mainAxisSize: .min,
          spacing: CoreSpace.space8,
          children: [
            Text(title).bodyLarge().semiBold(),
            Text(body).bodySmall().onSurface(),
          ],
        ),
      ),
    );
  }

  @override
  void didUpdateWidget(TabsDemo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialIndex != widget.initialIndex) {
      _selectedIndex = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabsLabels = t.widgetbook.tabs;

    final tabBar = Tabs(
      onChanged: (index) => setState(() => _selectedIndex = index),
      tabs: widget.showContent
          ? [
              CoreTabItem(label: tabsLabels.overview),
              CoreTabItem(label: tabsLabels.details),
              CoreTabItem(label: tabsLabels.history),
            ]
          : [
              CoreTabItem(label: tabsLabels.home),
              CoreTabItem(label: tabsLabels.profile),
              CoreTabItem(label: tabsLabels.settings),
            ],
      selectedIndex: _effectiveIndex,
      variant: widget.variant,
    );

    return Center(
      child: SizedBox(
        width: _kContentWidth,
        child: Column(
          mainAxisSize: .min,
          spacing: CoreSpace.space16,
          children: [
            tabBar,
            if (widget.showContent)
              SizedBox(
                height: _kContentHeight,
                child: IndexedStack(
                  index: _effectiveIndex,
                  children: [
                    _buildContentCard(
                      tabsLabels.overview_content,
                      tabsLabels.general_info,
                    ),
                    _buildContentCard(
                      tabsLabels.details_content,
                      tabsLabels.specifications,
                    ),
                    _buildContentCard(
                      tabsLabels.history_content,
                      tabsLabels.timeline,
                    ),
                  ],
                ),
              )
            else
              Text(
                t.widgetbook.common.selected_tab(
                  index: _effectiveIndex.toString(),
                ),
              ).medium().onSurface(),
          ],
        ),
      ),
    );
  }
}

/// Navigation metadata for the Tabs component.
const kComponentMeta = ComponentMeta(name: 'Tabs', path: 'navigation');

/// Story metadata for [TabsDemo].
const kMeta = Meta(TabsDemo.new);

/// Pill tabs with a selected-index readout.
final $Default = _Story();

/// Tabs driving an [IndexedStack] content panel.
final $WithContent = _Story(
  name: 'With Content',
  args: _Args(showContent: BoolArg(true)),
);

/// Underline (line) variant of the tab bar.
final $Line = _Story(
  args: _Args(
    variant: EnumArg(CoreTabVariant.underline, values: CoreTabVariant.values),
  ),
);
