/// Returns a Flutter code snippet string for the DatePicker
/// component, switched on the `variant` slug used by the registry.
String datePickerCode(String? variant) {
  return switch (variant) {
    'chain' => _chain,
    'dialog' => _dialog,
    'range' => _range,
    'range_dialog' => _rangeDialog,
    _ => _default,
  };
}

const String _chain = '''class DatePickerChainExample extends StatefulWidget {
  const DatePickerChainExample({super.key});

  @override
  State<DatePickerChainExample> createState() => _DatePickerChainExampleState();
}

class _DatePickerChainExampleState extends State<DatePickerChainExample> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: CoreSpace.space256,
      child:
          ControlledDatePicker(
            placeholder: '날짜를 선택해 주세요',
            onChanged: (_) {},
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
    );
  }
}''';

const String _default = '''class DatePickerDefaultExample extends StatefulWidget {
  const DatePickerDefaultExample({super.key});

  @override
  State<DatePickerDefaultExample> createState() =>
      _DatePickerDefaultExampleState();
}

class _DatePickerDefaultExampleState extends State<DatePickerDefaultExample> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: CoreSpace.space256,
      child: DatePicker.simple(
        placeholder: '날짜를 선택해 주세요',
        onChanged: (_) {},
      ),
    );
  }
}''';

const String _dialog = '''class DatePickerDialogExample extends StatefulWidget {
  const DatePickerDialogExample({super.key});

  @override
  State<DatePickerDialogExample> createState() =>
      _DatePickerDialogExampleState();
}

class _DatePickerDialogExampleState extends State<DatePickerDialogExample> {
  DateTime? _value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: CoreSpace.space256,
      child: DatePicker(
        onChanged: (v) => setState(() => _value = v),
        value: _value,
        mode: CorePromptMode.dialog,
        placeholder: '날짜를 선택해 주세요',
        dialogTitle: const Text('날짜 선택'),
      ),
    );
  }
}''';

const String _range = '''class DatePickerRangeExample extends StatefulWidget {
  const DatePickerRangeExample({super.key});

  @override
  State<DatePickerRangeExample> createState() =>
      _DatePickerRangeExampleState();
}

class _DatePickerRangeExampleState extends State<DatePickerRangeExample> {
  DateTimeRange? _value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: CoreSpace.space256,
      child: DateRangePicker(
        onChanged: (v) => setState(() => _value = v),
        value: _value,
        mode: CorePromptMode.popover,
        placeholder: const Text('기간을 선택해 주세요'),
      ),
    );
  }
}''';

const String _rangeDialog = '''class DatePickerRangeDialogExample extends StatefulWidget {
  const DatePickerRangeDialogExample({super.key});

  @override
  State<DatePickerRangeDialogExample> createState() =>
      _DatePickerRangeDialogExampleState();
}

class _DatePickerRangeDialogExampleState
    extends State<DatePickerRangeDialogExample> {
  DateTimeRange? _value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: CoreSpace.space256,
      child: DateRangePicker(
        onChanged: (v) => setState(() => _value = v),
        value: _value,
        placeholder: const Text('기간을 선택해 주세요'),
        dialogTitle: const Text('기간 선택'),
      ),
    );
  }
}''';
