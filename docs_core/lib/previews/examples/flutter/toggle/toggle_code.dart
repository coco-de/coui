/// Returns a Flutter code snippet string for the Toggle component.
String toggleCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''class ToggleChainExample extends StatefulWidget {
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
}''',
    'on' =>
      '''
class ToggleOnExample extends StatefulWidget {
  const ToggleOnExample({super.key});

  @override
  State<ToggleOnExample> createState() => _ToggleOnExampleState();
}

class _ToggleOnExampleState extends State<ToggleOnExample> {
  bool _value = true;

  @override
  Widget build(BuildContext context) {
    return Toggle(
      value: _value,
      onChanged: (v) => setState(() => _value = v),
      label: '다크 모드',
    );
  }
}''',
    'disabled' =>
      '''
class ToggleDisabledExample extends StatefulWidget {
  const ToggleDisabledExample({super.key});

  @override
  State<ToggleDisabledExample> createState() => _ToggleDisabledExampleState();
}

class _ToggleDisabledExampleState extends State<ToggleDisabledExample> {
  bool _value = false;

  @override
  Widget build(BuildContext context) {
    return Toggle(
      value: _value,
      enabled: false,
      label: '다크 모드',
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
class ToggleDefaultExample extends StatefulWidget {
  const ToggleDefaultExample({super.key});

  @override
  State<ToggleDefaultExample> createState() => _ToggleDefaultExampleState();
}

class _ToggleDefaultExampleState extends State<ToggleDefaultExample> {
  bool _value = false;

  @override
  Widget build(BuildContext context) {
    return Toggle(
      value: _value,
      onChanged: (v) => setState(() => _value = v),
      label: '다크 모드',
    );
  }
}''',
  };
}
