import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';

/// Animated skeleton loader shown while Flutter engine initializes.
///
/// Uses min-height to match the component constraint size rather than
/// a fixed height, preventing layout shift when Flutter content loads.
class PreviewSkeleton extends StatelessComponent {
  const PreviewSkeleton({super.key});

  @override
  Component build(BuildContext context) {
    return div(classes: 'preview-skeleton', [
      div(classes: 'preview-skeleton-shimmer', []),
      span(classes: 'preview-skeleton-text', [
        Component.text('Loading Flutter...'),
      ]),
    ]);
  }
}
