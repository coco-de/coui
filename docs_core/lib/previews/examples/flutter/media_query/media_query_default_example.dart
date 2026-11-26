import 'package:coui_flutter/coui_flutter.dart';

/// Default [MediaQueryVisibility] — hides child below md (768px).
class MediaQueryDefaultExample extends StatelessWidget {
  /// Creates a [MediaQueryDefaultExample].
  const MediaQueryDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final ts = theme.typography;
    return MediaQueryVisibility(
      minBreakpoint: .md,
      alternateChild: Container(
        width: double.infinity,
        padding: const CoreEdgeInsets.all(CoreSpace.space12).toValue(geometry: Theme.of(context).geometry),
        color: cs.surfaceContainer.toValue(),
        child: DefaultTextStyle.merge(
          style: ts.bodyMedium.toValue(theme: Theme.of(context)).copyWith(color: cs.onSurface.toValue()),
          child: const Text('md 미만에서 보여요'),
        ),
      ),
      child: Container(
        width: double.infinity,
        padding: const CoreEdgeInsets.all(CoreSpace.space12).toValue(geometry: Theme.of(context).geometry),
        color: cs.primaryContainer.toValue(),
        child: DefaultTextStyle.merge(
          style: ts.bodyMedium.toValue(theme: Theme.of(context)).copyWith(color: cs.onPrimaryContainer.toValue()),
          child: const Text('md 이상에서 보여요'),
        ),
      ),
    );
  }
}
