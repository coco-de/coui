import 'package:coui_flutter/coui_flutter.dart';

/// Star-shaped [Mask].
class MaskStarExample extends StatelessWidget {
  /// Creates a [MaskStarExample].
  const MaskStarExample({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: CoreSpace.space64,
      height: CoreSpace.space64,
      child: Mask(
        shape: .star,
        child: Container(color: Theme.of(context).colorScheme.primary.toValue()),
      ),
    );
  }
}
