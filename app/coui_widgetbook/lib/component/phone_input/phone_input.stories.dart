import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'phone_input.stories.g.dart';

/// Interactive demo host for [PhoneInput] stories.
class PhoneInputDemo extends StatefulWidget {
  /// Creates a [PhoneInputDemo].
  const PhoneInputDemo({super.key, this.enabled = true});

  /// Whether the input accepts edits.
  final bool enabled;

  @override
  State<PhoneInputDemo> createState() => _PhoneInputDemoState();
}

class _PhoneInputDemoState extends State<PhoneInputDemo> {
  PhoneNumber? _phoneNumber;

  void handleChanged(PhoneNumber value) {
    setState(() => _phoneNumber = value);
  }

  @override
  Widget build(BuildContext context) {
    final phoneNumber = _phoneNumber;

    return Column(
      mainAxisSize: .min,
      spacing: CoreSpace.space16,
      children: [
        PhoneInput(
          onChanged: handleChanged,
          initialCountry: .unitedStates,
          enabled: widget.enabled,
        ),
        if (phoneNumber != null) Text('Full number: ${phoneNumber.fullNumber}'),
      ],
    );
  }
}

/// Navigation metadata for the PhoneInput component.
const kComponentMeta = ComponentMeta(name: 'PhoneInput', path: 'form');

/// Story metadata for [PhoneInputDemo].
const kMeta = Meta(PhoneInputDemo.new);

/// Phone input with country picker and live value read-out.
final $Default = _Story();
