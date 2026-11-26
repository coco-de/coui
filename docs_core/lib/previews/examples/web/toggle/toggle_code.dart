/// Returns a Web code snippet string for the Toggle component.
String toggleCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''class ToggleChainExample extends StatefulComponent {
  const ToggleChainExample({super.key});

  @override
  State<ToggleChainExample> createState() => _ToggleChainExampleState();
}

class _ToggleChainExampleState extends State<ToggleChainExample> {
  bool _value = false;

  @override
  Component build(BuildContext context) {
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
}''',
    'on' =>
      '''
class ToggleOnExample extends StatefulComponent {
  const ToggleOnExample({super.key});

  @override
  State<ToggleOnExample> createState() => _ToggleOnExampleState();
}

class _ToggleOnExampleState extends State<ToggleOnExample> {
  bool _value = true;

  @override
  Component build(BuildContext context) {
    return Toggle(
      value: _value,
      label: '다크 모드',
      onChanged: (v) => setState(() => _value = v),
    );
  }
}''',
    'disabled' =>
      '''
class ToggleDisabledExample extends StatefulComponent {
  const ToggleDisabledExample({super.key});

  @override
  State<ToggleDisabledExample> createState() => _ToggleDisabledExampleState();
}

class _ToggleDisabledExampleState extends State<ToggleDisabledExample> {
  bool _value = false;

  @override
  Component build(BuildContext context) {
    return Toggle(
      value: _value,
      label: '다크 모드',
      enabled: false,
      onChanged: (value) {
        setState(() {
          _value = value;
        });
      },
    );
  }
}''',
    _ =>
      '''
class ToggleDefaultExample extends StatefulComponent {
  const ToggleDefaultExample({super.key});

  @override
  State<ToggleDefaultExample> createState() => _ToggleDefaultExampleState();
}

class _ToggleDefaultExampleState extends State<ToggleDefaultExample> {
  bool _value = false;

  @override
  Component build(BuildContext context) {
    return Toggle(
      value: _value,
      label: '다크 모드',
      onChanged: (v) => setState(() => _value = v),
    );
  }
}''',
  };
}
