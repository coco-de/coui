import 'package:coui_flutter/coui_flutter.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CoreMultipleChoiceStyle] slot without constructing the
/// widget from scratch.
class MultipleChoiceChainExample extends StatefulWidget {
  const MultipleChoiceChainExample({super.key});

  @override
  State<MultipleChoiceChainExample> createState() => _MultipleChoiceChainExampleState();
}

class _MultipleChoiceChainExampleState extends State<MultipleChoiceChainExample> {
  String? _value = 'md';

  @override
  Widget build(BuildContext context) {
    return MultipleChoice<String>(
      options: const [
        (value: 'sm', label: '작음'),
        (value: 'md', label: '보통'),
        (value: 'lg', label: '큼'),
      ],
      value: _value,
      onChanged: (v) => setState(() => _value = v),
    ).withStyle(
      const CoreMultipleChoiceStyle(
        optionSpacing: CoreSpace.space12,
        chipStyle: CoreChipStyle(
          padding: CoreEdgeInsets.symmetric(
            horizontal: CoreSpace.space20,
            vertical: CoreSpace.space12,
          ),
          borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
        ),
      ),
    );
  }
}
