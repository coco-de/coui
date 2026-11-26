import 'package:coui_flutter/coui_flutter.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CoreSelectStyle] slot without constructing the widget
/// from scratch. The patch recolours the trigger content, the
/// placeholder and the trailing chevron, and loosens the option rows.
class SelectChainExample extends StatefulWidget {
  const SelectChainExample({super.key});

  @override
  State<SelectChainExample> createState() => _SelectChainExampleState();
}

class _SelectChainExampleState extends State<SelectChainExample> {
  String? _value = 'apple';

  void handleChanged(String value) {
    setState(() => _value = value);
  }

  @override
  Widget build(BuildContext context) {
    return Select<String>(
      items: const [
        CoreSelectItem(value: 'apple', label: '사과'),
        CoreSelectItem(value: 'banana', label: '바나나'),
        CoreSelectItem(value: 'orange', label: '오렌지'),
      ],
      value: _value,
      placeholder: '과일을 선택해 주세요',
      onChanged: handleChanged,
    ).withStyle(
      const CoreSelectStyle(
        optionSpacing: CoreSpace.space4,
        trailingIconStyle: CoreIconStyle(
          size: CoreSize.size20,
          color: CoreColor.token(CoreColors.primary),
        ),
        placeholderColor: CoreColor.token(CoreColors.onSurfaceVariant),
        contentColor: CoreColor.token(CoreColors.primary),
      ),
    );
  }
}
