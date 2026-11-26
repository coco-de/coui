import 'package:coui_flutter/coui_flutter.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CoreCheckboxStyle] slot without constructing the widget
/// from scratch.
class CheckboxChainExample extends StatefulWidget {
  const CheckboxChainExample({super.key});

  @override
  State<CheckboxChainExample> createState() => _CheckboxChainExampleState();
}

class _CheckboxChainExampleState extends State<CheckboxChainExample> {
  bool? _checked = false;

  @override
  Widget build(BuildContext context) {
    return Checkbox(
      checked: _checked,
      label: '약관 동의',
      onChanged: (value) => setState(() => _checked = value),
    ).withStyle(
      const CoreCheckboxStyle(
        boxBorderColor: CoreColor.token(CoreColors.primary),
        boxBorderWidth: CoreStrokeWidth.stroke2,
        boxBorderRadius: CoreBorderRadius.all(CoreRadius.radius8),
        boxSize: CoreSize.size24,
        indicatorLabelGapStyle: CoreGapStyle(size: CoreSpace.space12),
      ),
    );
  }
}
