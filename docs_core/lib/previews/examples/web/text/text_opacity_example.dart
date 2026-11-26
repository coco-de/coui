import 'package:coui_web/coui_web.dart';

/// Opacity chain — `.opacity(0..1)` scales the foreground color alpha.
class TextOpacityExample extends StatelessComponent {
  const TextOpacityExample({super.key});

  @override
  Component build(BuildContext context) {
    return div(
      classes: 'flex flex-col gap-${CoreSpace.scale.space8} p-${CoreSpace.scale.space16}',
      [
        Text('opacity 1.0 (default)').bodyMedium,
        Text('opacity 0.7').bodyMedium.opacity(0.7),
        Text('opacity 0.5').bodyMedium.opacity(0.5),
        Text('opacity 0.3').bodyMedium.opacity(0.3),
        Text('primary @ opacity 0.5').bodyMedium.onPrimaryContainer.opacity(0.5),
        Text('error @ opacity 0.7').bodyMedium.onErrorContainer.opacity(0.7),
      ],
    );
  }
}
