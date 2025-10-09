import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

/// Builds the default Switch use case for Widgetbook.
// Using deprecated Switch type in annotation for backwards compatibility
// showcase
// ignore: deprecated_member_use
@UseCase(name: 'Switch Default', type: Switch)
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
    // Using deprecated Switch widget for backwards compatibility showcase
    // ignore: deprecated_member_use
    return Switch(
      onChanged: (v) => setState(() => _value = v),
      trailing: const Text('Switch'),
      value: _value,
    );
  }
}
