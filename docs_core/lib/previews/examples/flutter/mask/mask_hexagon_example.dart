import 'package:coui_flutter/coui_flutter.dart';

/// Hexagon-masked colored box.
class MaskHexagonExample extends StatelessWidget {
  /// Creates a [MaskHexagonExample].
  const MaskHexagonExample({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: CoreSpace.space64,
      height: CoreSpace.space64,
      child: Mask(
        shape: .hexagon,
        child: Container(color: Theme.of(context).colorScheme.primary.toValue()),
      ),
    );
  }
}
