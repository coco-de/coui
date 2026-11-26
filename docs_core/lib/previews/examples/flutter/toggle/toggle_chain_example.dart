import 'package:coui_flutter/coui_flutter.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CoreToggleStyle] slot without constructing the widget
/// from scratch.
class ToggleChainExample extends StatefulWidget {
  const ToggleChainExample({super.key});

  @override
  State<ToggleChainExample> createState() => _ToggleChainExampleState();
}

class _ToggleChainExampleState extends State<ToggleChainExample> {
  bool _value = false;

  @override
  Widget build(BuildContext context) {
    return Toggle(
      value: _value,
      onChanged: (v) => setState(() => _value = v),
      label: '다크 모드',
    ).withStyle(
      const CoreToggleStyle(
        trackActiveColor: CoreColor.token(CoreColors.success),
        trackInactiveColor: CoreColor.token(CoreColors.outlineVariant),
        trackBorderRadius: CoreBorderRadius.all(CoreRadius.radius4),
        thumbBorderRadius: CoreBorderRadius.all(CoreRadius.radius2),
        thumbShadow: CoreShadow.sm,
        iconLabelGapStyle: CoreGapStyle(size: CoreSpace.space12),
      ),
    );
  }
}
