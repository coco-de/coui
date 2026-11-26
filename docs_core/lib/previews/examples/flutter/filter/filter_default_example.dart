import 'package:coui_flutter/coui_flutter.dart';

class FilterDefaultExample extends StatefulWidget {
  const FilterDefaultExample({super.key});

  @override
  State<FilterDefaultExample> createState() => _FilterDefaultExampleState();
}

class _FilterDefaultExampleState extends State<FilterDefaultExample> {
  String? _selected = 'svelte';

  void handleValueChanged(String value) {
    setState(() => _selected = value);
  }

  void handleReset() {
    setState(() => _selected = null);
  }

  @override
  Widget build(BuildContext context) {
    return Filter<String>(
      groupValue: _selected,
      onValueChanged: handleValueChanged,
      onReset: handleReset,
      showResetButton: true,
      items: const [
        CoreFilterItem(value: 'svelte', label: 'Svelte'),
        CoreFilterItem(value: 'vue', label: 'Vue'),
        CoreFilterItem(value: 'react', label: 'React'),
      ],
    );
  }
}
