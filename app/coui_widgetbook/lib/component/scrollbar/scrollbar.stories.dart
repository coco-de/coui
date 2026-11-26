import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'scrollbar.stories.g.dart';

/// Width of the scrollable preview area.
const _kPreviewWidth = 240.0;

/// Height of the scrollable preview area.
const _kPreviewHeight = 160.0;

/// Default number of scrollable list items.
const _kItemCount = 20;

/// Interactive demo host for [Scrollbar] stories.
///
/// Hosts a scroll controller shared between the [Scrollbar] and its
/// scroll view so the thumb tracks the content position.
class ScrollbarDemo extends StatefulWidget {
  /// Creates a [ScrollbarDemo].
  const ScrollbarDemo({
    super.key,
    this.visibility = CoreScrollbarVisibility.defaultVisibility,
    this.itemCount = _kItemCount,
  });

  /// Scrollbar thumb visibility mode.
  final CoreScrollbarVisibility visibility;

  /// Number of scrollable list items.
  final int itemCount;

  @override
  State<ScrollbarDemo> createState() => _ScrollbarDemoState();
}

class _ScrollbarDemoState extends State<ScrollbarDemo> {
  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _kPreviewWidth,
      height: _kPreviewHeight,
      child: Scrollbar(
        visibility: widget.visibility,
        controller: _controller,
        child: SingleChildScrollView(
          controller: _controller,
          child: Column(
            crossAxisAlignment: .start,
            spacing: CoreSpace.space8,
            children: [
              for (int i = 1; i <= widget.itemCount; i += 1)
                Text('Scroll item $i').bodyMedium,
            ],
          ),
        ),
      ),
    );
  }
}

/// Navigation metadata for the Scrollbar component.
const kComponentMeta = ComponentMeta(name: 'Scrollbar', path: 'infra');

/// Story metadata for [ScrollbarDemo].
const kMeta = Meta(ScrollbarDemo.new);

/// Scrollbar with the default (auto) visibility.
final $Default = _Story();

/// Scrollbar with an always-visible thumb.
final $Visibility = _Story(
  args: _Args(
    visibility: EnumArg(
      CoreScrollbarVisibility.always,
      values: CoreScrollbarVisibility.values,
    ),
  ),
);
