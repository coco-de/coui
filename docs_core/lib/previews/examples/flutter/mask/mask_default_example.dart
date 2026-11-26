import 'package:coui_flutter/coui_flutter.dart';

/// Default [Mask] showcasing the squircle shape.
class MaskDefaultExample extends StatelessWidget {
  /// Creates a [MaskDefaultExample].
  const MaskDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: CoreSpace.space64,
      height: CoreSpace.space64,
      child: Mask(
        child: Container(color: Theme.of(context).colorScheme.primary.toValue()),
      ),
    );
  }
}
