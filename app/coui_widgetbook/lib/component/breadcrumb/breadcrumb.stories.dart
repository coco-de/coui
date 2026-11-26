import 'package:coui_flutter/coui_flutter.dart';
import 'package:coui_i10n/coui_i10n.dart';
import 'package:widgetbook/widgetbook.dart';

part 'breadcrumb.stories.g.dart';

const _kDefaultItemCount = 4;

/// Label sets available for the breadcrumb trail.
enum BreadcrumbTrail {
  /// Home > Documents > Projects > Current Folder.
  documents,

  /// Home > Products > Electronics > Smartphones > Current Folder.
  products,
}

/// Interactive demo host for [Breadcrumb] stories.
class BreadcrumbDemo extends StatefulWidget {
  /// Creates a [BreadcrumbDemo].
  const BreadcrumbDemo({
    super.key,
    this.itemCount = _kDefaultItemCount,
    this.trail = BreadcrumbTrail.products,
    this.interactive = false,
  });

  /// Number of breadcrumb items shown.
  final int itemCount;

  /// Which label set the trail renders.
  final BreadcrumbTrail trail;

  /// Whether tapping an item trims the trail to that item.
  final bool interactive;

  @override
  State<BreadcrumbDemo> createState() => _BreadcrumbDemoState();
}

class _BreadcrumbDemoState extends State<BreadcrumbDemo> {
  int? _visibleCount;

  List<String> get _allLabels {
    final labels = t.widgetbook.breadcrumb;

    return switch (widget.trail) {
      .products => [
        labels.home,
        labels.products,
        labels.electronics,
        labels.smartphones,
        labels.current_folder,
      ],
      .documents => [
        labels.home,
        labels.documents,
        labels.projects,
        labels.current_folder,
      ],
    };
  }

  @override
  void didUpdateWidget(BreadcrumbDemo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.itemCount != widget.itemCount ||
        oldWidget.trail != widget.trail ||
        oldWidget.interactive != widget.interactive) {
      _visibleCount = null;
    }
  }

  void handleItemTap(int index) {
    setState(() => _visibleCount = index + 1);
  }

  @override
  Widget build(BuildContext context) {
    final allLabels = _allLabels;
    final requested = _visibleCount ?? widget.itemCount;
    final capped = requested > allLabels.length ? allLabels.length : requested;
    final count = capped < 1 ? 1 : capped;
    final path = allLabels.sublist(0, count);

    final breadcrumb = Breadcrumb(
      items: [
        for (final label in path) CoreBreadcrumbItem(label: label),
      ],
      onItemTap: widget.interactive ? handleItemTap : null,
    );
    if (!widget.interactive) return breadcrumb;

    return Column(
      mainAxisSize: .min,
      crossAxisAlignment: .start,
      spacing: CoreSpace.space16,
      children: [
        breadcrumb,
        Text(
          t.widgetbook.breadcrumb.current_path(path: path.join(' > ')),
        ).bodySmall.onSurface,
      ],
    );
  }
}

/// Navigation metadata for the Breadcrumb component.
const kComponentMeta = ComponentMeta(name: 'Breadcrumb', path: 'navigation');

/// Story metadata for [BreadcrumbDemo].
const kMeta = Meta(BreadcrumbDemo.new);

/// Product trail breadcrumb with editable knobs.
final $Default = _Story();

/// Document trail breadcrumb.
final $Documents = _Story(
  args: _Args(
    trail: EnumArg(
      BreadcrumbTrail.documents,
      values: BreadcrumbTrail.values,
    ),
  ),
);

/// Interactive breadcrumb — tapping an item trims the trail.
final $Interactive = _Story(args: _Args(interactive: BoolArg(true)));
