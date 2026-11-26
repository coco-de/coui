import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'object_input.stories.g.dart';

const _kDateFields = [
  CoreObjectInputField(key: 'year', placeholder: 'YYYY', maxLength: 4),
  CoreObjectInputField(key: 'month', placeholder: 'MM', maxLength: 2),
  CoreObjectInputField(key: 'day', placeholder: 'DD', maxLength: 2),
];

/// Interactive demo host for [ObjectInput] stories.
class ObjectInputDemo extends StatefulWidget {
  /// Creates an [ObjectInputDemo].
  const ObjectInputDemo({
    super.key,
    this.separator = '/',
    this.enabled = true,
    this.showLeadingIcon = false,
  });

  /// Separator drawn between the fields.
  final String separator;

  /// Whether the input accepts edits.
  final bool enabled;

  /// Whether a leading calendar icon is shown.
  final bool showLeadingIcon;

  @override
  State<ObjectInputDemo> createState() => _ObjectInputDemoState();
}

class _ObjectInputDemoState extends State<ObjectInputDemo> {
  Map<String, String> _values = const {};

  void handleValuesChanged(Map<String, String> values) {
    setState(() => _values = values);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: .min,
      spacing: CoreSpace.space16,
      children: [
        ObjectInput(
          onChanged: handleValuesChanged,
          fields: _kDateFields,
          separator: widget.separator,
          enabled: widget.enabled,
          leading: widget.showLeadingIcon
              ? const Icon(
                  LucideIcons.calendar,
                  iconStyle: CoreIconStyle(size: CoreSpace.space16),
                )
              : null,
        ),
        Text('Values: $_values').bodySmall().onSurface(),
      ],
    );
  }
}

/// Navigation metadata for the ObjectInput component.
const kComponentMeta = ComponentMeta(name: 'ObjectInput', path: 'form');

/// Story metadata for [ObjectInputDemo].
const kMeta = Meta(ObjectInputDemo.new);

/// Date-style segmented input with editable knobs.
final $Default = _Story();

/// Segmented input with a leading calendar icon.
final $WithLeadingIcon = _Story(
  name: 'With Leading Icon',
  args: _Args(showLeadingIcon: BoolArg(true)),
);
