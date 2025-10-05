import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

@UseCase(name: 'Default', type: Toggle)
material.Widget buildSwitchUseCase(material.BuildContext context) {
  return const _SwitchExample();
}

class _SwitchExample extends material.StatefulWidget {
  const _SwitchExample();

  @override
  material.State<_SwitchExample> createState() => _SwitchExampleState();
}

class _SwitchExampleState extends material.State<_SwitchExample> {
  bool _value = false;

  @override
  material.Widget build(material.BuildContext context) {
    return Toggle(
      onChanged: (v) => setState(() => _value = v),
      trailing: const Text('Switch'),
      value: _value,
    );
  }
}
