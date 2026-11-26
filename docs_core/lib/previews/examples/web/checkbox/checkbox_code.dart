/// Returns a Web code snippet string for the Checkbox component.
String checkboxCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
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
}''',
    'checked' =>
      '''
class CheckboxCheckedExample extends StatefulComponent {
  const CheckboxCheckedExample({super.key});

  @override
  State<CheckboxCheckedExample> createState() => _CheckboxCheckedExampleState();
}

class _CheckboxCheckedExampleState extends State<CheckboxCheckedExample> {
  bool? _checked = true;

  @override
  Component build(BuildContext context) {
    return Checkbox(
      checked: _checked,
      label: '선택됨',
      onChanged: (value) => setState(() => _checked = value),
    );
  }
}''',
    'indeterminate' =>
      '''
class CheckboxIndeterminateExample extends StatefulComponent {
  const CheckboxIndeterminateExample({super.key});

  @override
  State<CheckboxIndeterminateExample> createState() => _CheckboxIndeterminateExampleState();
}

class _CheckboxIndeterminateExampleState extends State<CheckboxIndeterminateExample> {
  bool? _checked;

  @override
  Component build(BuildContext context) {
    return Checkbox(
      checked: _checked,
      label: '일부 선택',
      tristate: true,
      onChanged: (value) => setState(() => _checked = value),
    );
  }
}''',
    'disabled' =>
      '''
class CheckboxDisabledExample extends StatefulComponent {
  const CheckboxDisabledExample({super.key});

  @override
  State<CheckboxDisabledExample> createState() => _CheckboxDisabledExampleState();
}

class _CheckboxDisabledExampleState extends State<CheckboxDisabledExample> {
  bool? _checked = false;

  @override
  Component build(BuildContext context) {
    return Checkbox(
      checked: _checked,
      label: '비활성',
      enabled: false,
      onChanged: (value) => setState(() => _checked = value),
    );
  }
}''',
    _ =>
      '''
class CheckboxDefaultExample extends StatefulComponent {
  const CheckboxDefaultExample({super.key});

  @override
  State<CheckboxDefaultExample> createState() => _CheckboxDefaultExampleState();
}

class _CheckboxDefaultExampleState extends State<CheckboxDefaultExample> {
  bool? _checked = false;

  @override
  Component build(BuildContext context) {
    return Checkbox(
      checked: _checked,
      label: '약관 동의',
      onChanged: (value) => setState(() => _checked = value),
    );
  }
}''',
  };
}
