import 'package:coui_web/coui_web.dart';

/// Circle-masked colored box.
class MaskCircleExample extends StatelessComponent {
  /// Creates a [MaskCircleExample].
  const MaskCircleExample({super.key});

  @override
  Component build(BuildContext context) {
    final cs = context.theme.colorScheme;
    return Mask(
      shape: .circle,
      child: div(
        classes:
            'w-${CoreSpace.scale.space64} h-${CoreSpace.scale.space64} '
            'bg-${cs.primary}',
        [],
      ),
    );
  }
}
