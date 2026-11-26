import 'package:coui_flutter/coui_flutter.dart';
import 'package:coui_i10n/coui_i10n.dart';
import 'package:widgetbook/widgetbook.dart';

part 'tab_pane.stories.g.dart';

const _kPaneWidth = 400.0;

/// Interactive demo host for [TabPane] stories.
///
/// Owns the selected index and the (re-orderable) tab list.
class TabPaneDemo extends StatefulWidget {
  /// Creates a [TabPaneDemo].
  const TabPaneDemo({
    super.key,
    this.initialIndex = 0,
    this.reorderable = false,
    this.editorStrip = false,
  });

  /// Initially selected tab index.
  final int initialIndex;

  /// Whether tabs can be re-ordered by dragging.
  final bool reorderable;

  /// Whether to render the IDE editor-strip path.
  final bool editorStrip;

  @override
  State<TabPaneDemo> createState() => _TabPaneDemoState();
}

class _TabPaneDemoState extends State<TabPaneDemo> {
  int? _selectedIndex;
  List<CoreTabItem<Widget>>? _tabs;

  int get _effectiveIndex => (_selectedIndex ?? widget.initialIndex).clamp(
    0,
    (_tabs ?? _buildTabs).length - 1,
  );

  void handleReorder(List<CoreTabItem<Widget>> reordered) {
    final selected = (_tabs ?? _buildTabs)[_effectiveIndex];
    setState(() {
      _tabs = reordered;
      _selectedIndex = reordered.indexOf(selected);
    });
  }

  void handleClose(int index) {
    final current = List<CoreTabItem<Widget>>.of(_tabs ?? _buildTabs);
    if (current.length <= 1) return;
    final selectedLabel = current[_effectiveIndex].label;
    current.removeAt(index);
    setState(() {
      _tabs = [
        for (var i = 0; i < current.length; i++)
          CoreTabItem(
            label: current[i].label,
            leading: current[i].leading,
            onClose: () => handleClose(i),
          ),
      ];
      final nextIndex = current.indexWhere((t) => t.label == selectedLabel);
      _selectedIndex = nextIndex >= 0 ? nextIndex : current.length - 1;
    });
  }

  static Widget _panel(String text) {
    return Padding(
      padding: const .all(CoreSpace.space16),
      child: Text(text).bodyLarge().semiBold(),
    );
  }

  @override
  void didUpdateWidget(TabPaneDemo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialIndex != widget.initialIndex ||
        oldWidget.editorStrip != widget.editorStrip) {
      _selectedIndex = null;
      _tabs = null;
    }
  }

  List<CoreTabItem<Widget>> get _buildTabs {
    final tabsLabels = t.widgetbook.tabs;

    if (widget.editorStrip) {
      return [
        CoreTabItem(
          label: 'main.dart',
          leading: const Icon(LucideIcons.fileCode),
          onClose: () => handleClose(0),
        ),
        CoreTabItem(
          label: 'tab_pane.dart',
          leading: const Icon(LucideIcons.fileCode),
          onClose: () => handleClose(1),
        ),
        CoreTabItem(
          label: 'pubspec.yaml',
          leading: const Icon(LucideIcons.file),
          onClose: () => handleClose(2),
        ),
      ];
    }

    return [
      CoreTabItem(
        label: tabsLabels.overview,
        content: _panel(tabsLabels.overview_content),
      ),
      CoreTabItem(
        label: tabsLabels.details,
        content: _panel(tabsLabels.details_content),
      ),
      CoreTabItem(
        label: tabsLabels.history,
        content: _panel(tabsLabels.history_content),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final tabs = _tabs ?? _buildTabs;
    _tabs ??= tabs;

    return Center(
      child: SizedBox(
        width: _kPaneWidth,
        child: TabPane(
          onChanged: (index) => setState(() => _selectedIndex = index),
          tabs: tabs,
          selectedIndex: _effectiveIndex,
          reorderable: widget.reorderable,
          variant: widget.editorStrip ? .editorStrip : .boxed,
          onReorder: widget.reorderable ? handleReorder : null,
        ),
      ),
    );
  }
}

/// Navigation metadata for the TabPane component.
const kComponentMeta = ComponentMeta(name: 'TabPane', path: 'navigation');

/// Story metadata for [TabPaneDemo].
const kMeta = Meta(TabPaneDemo.new);

/// Boxed tab pane with per-tab content panels.
final $Default = _Story();

/// Tab pane whose tabs can be re-ordered by dragging.
final $Reorderable = _Story(args: _Args(reorderable: BoolArg(true)));

/// IDE editor-tab strip (no content panel / T-junction).
final $EditorStrip = _Story(args: _Args(editorStrip: BoolArg(true)));
