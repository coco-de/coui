import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'scrollview.stories.g.dart';

/// Height of the scrollable viewport in the demo.
const _kViewportHeight = 320.0;

/// Number of list items in the demo.
const _kItemCount = 20;

/// Height of a single list item.
const _kItemHeight = 60.0;

/// Base alpha of the first list item background.
const _kBaseAlpha = 0.1;

/// Alpha increment applied per list item index.
const _kAlphaIncrement = 0.04;

/// Interactive demo host for [ScrollViewInterceptor] stories.
///
/// Wraps a [ListView] so wheel / drag scrolling can be intercepted
/// (or passed through) depending on [enabled].
class ScrollViewInterceptorDemo extends StatelessWidget {
  /// Creates a [ScrollViewInterceptorDemo].
  const ScrollViewInterceptorDemo({super.key, this.enabled = true});

  /// Whether scroll interception is active.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = theme.colorScheme.primary.toValue();

    return SizedBox(
      height: _kViewportHeight,
      child: ScrollViewInterceptor(
        enabled: enabled,
        child: ListView.builder(
          itemBuilder: (context, index) => Container(
            color: base.withValues(
              alpha: _kBaseAlpha + (index * _kAlphaIncrement),
            ),
            height: _kItemHeight,
            margin: const .all(CoreSpace.space8),
            child: Center(
              child: Text('Item ${index + 1}'),
            ),
          ),
          itemCount: _kItemCount,
        ),
      ),
    );
  }
}

/// Navigation metadata for the ScrollViewInterceptor component.
const kComponentMeta = ComponentMeta(
  name: 'ScrollViewInterceptor',
  path: 'infra',
);

/// Story metadata for [ScrollViewInterceptorDemo].
const kMeta = Meta(ScrollViewInterceptorDemo.new);

/// Intercepted list view with an enabled knob.
final $Default = _Story();
