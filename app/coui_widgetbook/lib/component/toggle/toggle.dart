import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

@UseCase(name: 'Default', type: Toggle)
material.Widget buildToggleUseCase(material.BuildContext context) {
  return const _ToggleExample();
}

class _ToggleExample extends material.StatefulWidget {
  const _ToggleExample();

  @override
  material.State<_ToggleExample> createState() => _ToggleExampleState();
}

class _ToggleExampleState extends material.State<_ToggleExample> {
  bool _value = false;

  void _handleChanged(bool v) {
    setState(() {
      _value = v;
    });
  }

  @override
  material.Widget build(material.BuildContext context) {
    return Toggle(
      onChanged: _handleChanged,
      trailing: const Text('Toggle'),
      value: _value,
    );
  }
}
