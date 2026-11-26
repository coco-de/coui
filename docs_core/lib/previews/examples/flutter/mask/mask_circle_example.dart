import 'package:coui_flutter/coui_flutter.dart';

/// Circle-masked colored box.
class MaskCircleExample extends StatelessWidget {
  /// Creates a [MaskCircleExample].
  const MaskCircleExample({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: CoreSpace.space64,
      height: CoreSpace.space64,
      child: Mask(
        shape: .circle,
        child: Container(color: Theme.of(context).colorScheme.primary.toValue()),
      ),
    );
  }
}
