import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'fade_scroll.stories.g.dart';

const _kViewportWidth = 300.0;
const _kViewportHeight = 200.0;
const _kDefaultItemCount = 20;

/// Interactive demo host for [FadeScroll] stories.
class FadeScrollDemo extends StatefulWidget {
  /// Creates a [FadeScrollDemo].
  const FadeScrollDemo({
    super.key,
    this.itemCount = _kDefaultItemCount,
    this.showScrollbar = false,
  });

  /// Number of list items inside the scrollable viewport.
  final int itemCount;

  /// Whether the scrollbar is shown.
  final bool showScrollbar;

  @override
  State<FadeScrollDemo> createState() => _FadeScrollDemoState();
}

class _FadeScrollDemoState extends State<FadeScrollDemo> {
  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _kViewportWidth,
      height: _kViewportHeight,
      child: FadeScroll(
        controller: _controller,
        showScrollbar: widget.showScrollbar,
        // FadeScroll owns the viewport; its content must not attach the same
        // controller to a second scroll view.
        child: Column(
          crossAxisAlignment: .stretch,
          children: [
            for (var index = 0; index < widget.itemCount; index++)
              Padding(
                padding: const .all(CoreSpace.space12),
                child: Text('Item ${index + 1}'),
              ),
          ],
        ),
      ),
    );
  }
}

/// Navigation metadata for the FadeScroll component.
const kComponentMeta = ComponentMeta(name: 'FadeScroll', path: 'layout');

/// Story metadata for [FadeScrollDemo].
const kMeta = Meta(FadeScrollDemo.new);

/// Fading scroll viewport with editable knobs.
final $Default = _Story();
