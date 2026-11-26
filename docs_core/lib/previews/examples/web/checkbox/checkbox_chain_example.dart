import 'package:coui_web/coui_web.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CoreCheckboxStyle] slot without constructing the
/// component from scratch.
class CheckboxChainExample extends StatefulComponent {
  const CheckboxChainExample({super.key});

  @override
  State<CheckboxChainExample> createState() => _CheckboxChainExampleState();
}

class _CheckboxChainExampleState extends State<CheckboxChainExample> {
  bool? _checked = false;

  @override
  Component build(BuildContext context) {
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
