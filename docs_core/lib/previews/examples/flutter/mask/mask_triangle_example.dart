import 'package:coui_flutter/coui_flutter.dart';

/// Triangle-shaped [Mask].
class MaskTriangleExample extends StatelessWidget {
  /// Creates a [MaskTriangleExample].
  const MaskTriangleExample({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: CoreSpace.space64,
      height: CoreSpace.space64,
      child: Mask(
        shape: .triangle,
        child: Container(color: Theme.of(context).colorScheme.primary.toValue()),
      ),
    );
  }
}
