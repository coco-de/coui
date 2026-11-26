import 'package:coui_web/coui_web.dart';

/// Default [Mask] showcasing the squircle shape.
class MaskDefaultExample extends StatelessComponent {
  /// Creates a [MaskDefaultExample].
  const MaskDefaultExample({super.key});

  @override
  Component build(BuildContext context) {
    final cs = context.theme.colorScheme;
    return Mask(
      child: div(
        classes:
            'w-${CoreSpace.scale.space64} h-${CoreSpace.scale.space64} '
            'bg-${cs.primary}',
        [],
      ),
    );
  }
}
