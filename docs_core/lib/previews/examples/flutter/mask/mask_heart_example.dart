import 'package:coui_flutter/coui_flutter.dart';

/// Heart-shaped [Mask].
class MaskHeartExample extends StatelessWidget {
  /// Creates a [MaskHeartExample].
  const MaskHeartExample({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: CoreSpace.space64,
      height: CoreSpace.space64,
      child: Mask(
        shape: .heart,
        child: Container(color: Theme.of(context).colorScheme.primary.toValue()),
      ),
    );
  }
}
