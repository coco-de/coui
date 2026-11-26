import 'package:coui_flutter/coui_flutter.dart';

/// Vertical [Divider] showcased inside a fixed-height container.
class DividerVerticalExample extends StatelessWidget {
  /// Creates a [DividerVerticalExample].
  const DividerVerticalExample({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: CoreSpace.space32,
      child: const Divider(orientation: .vertical),
    );
  }
}
