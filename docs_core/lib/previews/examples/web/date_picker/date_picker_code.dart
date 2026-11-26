/// Returns a Web code snippet string for the DatePicker component,
/// switched on the `variant` slug used by the registry.
String datePickerCode(String? variant) {
  return switch (variant) {
    'chain' => _chain,
    'dialog' => _dialog,
    'range' => _range,
    'range_dialog' => _rangeDialog,
    _ => _default,
  };
}

const String _chain = '''class DatePickerChainExample extends StatefulComponent {
  const DatePickerChainExample({super.key});

  @override
  State<DatePickerChainExample> createState() => _DatePickerChainExampleState();
}

class _DatePickerChainExampleState extends State<DatePickerChainExample> {
  String? _value;

  @override
  Component build(BuildContext context) {
    return div(
      [
        DatePicker(
          onChanged: (v) => setState(() => _value = v),
          placeholder: '날짜를 선택해 주세요',
          value: _value,
        ).withStyle(
          const CoreDatePickerStyle(
            contentColor: CoreColor.token(CoreColors.primary),
            placeholderColor: CoreColor.token(CoreColors.onSurfaceVariant),
            valueTypography: CoreTextStyle.token(CoreTextStyles.bodyLarge),
            trailingIconStyle: CoreIconStyle(
              size: CoreSize.size20,
              color: CoreColor.token(CoreColors.primary),
            ),
          ),
        ),
      ],
      classes: 'w-\${CoreSpace.scale.space256}',
    );
  }
}''';

const String _default = '''class DatePickerDefaultExample extends StatefulComponent {
  const DatePickerDefaultExample({super.key});

  @override
  State<DatePickerDefaultExample> createState() =>
      _DatePickerDefaultExampleState();
}

class _DatePickerDefaultExampleState extends State<DatePickerDefaultExample> {
  String? _value;

  @override
  Component build(BuildContext context) {
    return div(
      [
        DatePicker(
          onChanged: (v) => setState(() => _value = v),
          placeholder: '날짜를 선택해 주세요',
          value: _value,
        ),
      ],
      classes: 'w-\${CoreSpace.scale.space256}',
    );
  }
}''';

const String _dialog = '''class DatePickerDialogExample extends StatefulComponent {
  const DatePickerDialogExample({super.key});

  @override
  State<DatePickerDialogExample> createState() =>
      _DatePickerDialogExampleState();
}

class _DatePickerDialogExampleState extends State<DatePickerDialogExample> {
  String? _value;

  @override
  Component build(BuildContext context) {
    return div(
      [
        DatePicker(
          onChanged: (v) => setState(() => _value = v),
          value: _value,
          mode: CorePromptMode.dialog,
          placeholder: '날짜를 선택해 주세요',
          dialogTitle: const Text('날짜 선택'),
        ),
      ],
      classes: 'w-\${CoreSpace.scale.space256}',
    );
  }
}''';

const String _range = '''class DatePickerRangeExample extends StatefulComponent {
  const DatePickerRangeExample({super.key});

  @override
  State<DatePickerRangeExample> createState() =>
      _DatePickerRangeExampleState();
}

class _DatePickerRangeExampleState extends State<DatePickerRangeExample> {
  ({String start, String end})? _value;

  @override
  Component build(BuildContext context) {
    return div(
      [
        DateRangePicker(
          onChanged: (v) => setState(() => _value = v),
          value: _value,
          mode: CorePromptMode.popover,
          placeholder: Text('기간을 선택해 주세요'),
        ),
      ],
      classes: 'w-\${CoreSpace.scale.space256}',
    );
  }
}''';

const String _rangeDialog = '''class DatePickerRangeDialogExample extends StatefulComponent {
  const DatePickerRangeDialogExample({super.key});

  @override
  State<DatePickerRangeDialogExample> createState() =>
      _DatePickerRangeDialogExampleState();
}

class _DatePickerRangeDialogExampleState
    extends State<DatePickerRangeDialogExample> {
  ({String start, String end})? _value;

  @override
  Component build(BuildContext context) {
    return div(
      [
        DateRangePicker(
          onChanged: (v) => setState(() => _value = v),
          value: _value,
          placeholder: Text('기간을 선택해 주세요'),
          dialogTitle: const Text('기간 선택'),
        ),
      ],
      classes: 'w-\${CoreSpace.scale.space256}',
    );
  }
}''';
