import 'package:coui_flutter/coui_flutter.dart';

class OptionItemChainExample extends StatelessWidget {
  const OptionItemChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    // withStyle full-control — a roomier row on the same label.
    return OptionItem(
      label: const Text('최신순'),
      selected: true,
      onPressed: () {},
    ).withStyle(
      const CoreOptionItemStyle(
        padding: CoreEdgeInsets.symmetric(
          horizontal: CoreSpace.space20,
          vertical: CoreSpace.space12,
        ),
      ),
    );
  }
}
