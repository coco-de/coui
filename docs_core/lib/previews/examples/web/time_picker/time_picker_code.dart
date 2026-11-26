/// Returns a Web code snippet string for the TimePicker component,
/// switched on the `variant` slug used by the registry.
String timePickerCode(String? variant) {
  return switch (variant) {
    'chain' => _chain,
    'dialog' => _dialog,
    'seconds' => _seconds,
    'error' => _error,
    _ => _default,
  };
}

const String _chain = '''class TimePickerChainExample extends StatefulComponent {
  const TimePickerChainExample({super.key});

  @override
  State<TimePickerChainExample> createState() => _TimePickerChainExampleState();
}

class _TimePickerChainExampleState extends State<TimePickerChainExample> {
  String? _value;

  @override
  Component build(BuildContext context) {
    return div(
      [
        TimePicker(
          value: _value,
          placeholder: '시간을 선택해 주세요',
          onChanged: (value) => setState(() => _value = value),
        ).withStyle(
          const CoreTimePickerStyle(
            segmentBorderRadius: CoreBorderRadius.all(CoreRadius.radius8),
            segmentBorderColor: CoreColor.token(CoreColors.primary),
            contentColor: CoreColor.token(CoreColors.primary),
            triggerHeight: CoreSpace.space48,
            triggerBorderWidth: CoreStrokeWidth.stroke2,
            trailingIconStyle: CoreIconStyle(
              size: CoreIconSize.size20,
              color: CoreColor.token(CoreColors.primary),
            ),
          ),
        ),
      ],
      classes: 'w-\${CoreSpace.scale.space256}',
    );
  }
}''';

const String _default = '''class TimePickerDefaultExample extends StatefulComponent {
  const TimePickerDefaultExample({super.key});

  @override
  State<TimePickerDefaultExample> createState() =>
      _TimePickerDefaultExampleState();
}

class _TimePickerDefaultExampleState extends State<TimePickerDefaultExample> {
  String? _value;

  @override
  Component build(BuildContext context) {
    return div(
      [
        TimePicker(
          value: _value,
          placeholder: '시간을 선택해 주세요',
          onChanged: (value) => setState(() => _value = value),
        ),
      ],
      classes: 'w-\${CoreSpace.scale.space256}',
    );
  }
}''';

const String _dialog = '''class TimePickerDialogExample extends StatefulComponent {
  const TimePickerDialogExample({super.key});

  @override
  State<TimePickerDialogExample> createState() =>
      _TimePickerDialogExampleState();
}

class _TimePickerDialogExampleState extends State<TimePickerDialogExample> {
  String? _value;

  @override
  Component build(BuildContext context) {
    return div(
      [
        TimePicker(
          value: _value,
          placeholder: '시간을 선택해 주세요',
          mode: CorePromptMode.dialog,
          dialogTitle: Text('시간 선택'),
          onChanged: (value) => setState(() => _value = value),
        ),
      ],
      classes: 'w-\${CoreSpace.scale.space256}',
    );
  }
}''';

const String _seconds = '''class TimePickerSecondsExample extends StatefulComponent {
  const TimePickerSecondsExample({super.key});

  @override
  State<TimePickerSecondsExample> createState() =>
      _TimePickerSecondsExampleState();
}

class _TimePickerSecondsExampleState extends State<TimePickerSecondsExample> {
  String? _value;

  @override
  Component build(BuildContext context) {
    return div(
      [
        TimePicker(
          value: _value,
          placeholder: '시간을 선택해 주세요',
          showSeconds: true,
          onChanged: (value) => setState(() => _value = value),
        ),
      ],
      classes: 'w-\${CoreSpace.scale.space256}',
    );
  }
}''';

const String _error = '''class TimePickerErrorExample extends StatefulComponent {
  const TimePickerErrorExample({super.key});

  @override
  State<TimePickerErrorExample> createState() =>
      _TimePickerErrorExampleState();
}

class _TimePickerErrorExampleState extends State<TimePickerErrorExample> {
  String? _value;

  @override
  Component build(BuildContext context) {
    return div(
      [
        TimePicker(
          value: _value,
          placeholder: '시간을 선택해 주세요',
          errorText: '시간을 선택해야 해요',
          onChanged: (value) => setState(() => _value = value),
        ),
      ],
      classes: 'w-\${CoreSpace.scale.space256}',
    );
  }
}''';
