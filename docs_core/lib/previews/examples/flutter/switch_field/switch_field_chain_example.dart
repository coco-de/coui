import 'package:coui_flutter/coui_flutter.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CoreSwitchFieldStyle] slot without constructing the
/// widget from scratch. The patch recolours the active track, promotes
/// the label typography and retunes both gaps.
class SwitchFieldChainExample extends StatefulWidget {
  const SwitchFieldChainExample({super.key});

  @override
  State<SwitchFieldChainExample> createState() => _SwitchFieldChainExampleState();
}

class _SwitchFieldChainExampleState extends State<SwitchFieldChainExample> {
  bool _value = false;

  @override
  Widget build(BuildContext context) {
    return SwitchField(
      label: '알림 받기',
      description: '푸시 알림을 받아요.',
      value: _value,
      onChanged: (v) => setState(() => _value = v),
    ).withStyle(
      const CoreSwitchFieldStyle(
        labelToggleGapStyle: CoreGapStyle(size: CoreSpace.space24),
        labelDescriptionGapStyle: CoreGapStyle(size: CoreSpace.space4),
        activeColor: CoreColor.token(CoreColors.success),
        labelTextStyle: CoreTextStyle.token(
          CoreTextStyles.titleSmall,
          color: CoreColor.token(CoreColors.onSurface),
        ),
      ),
    );
  }
}
