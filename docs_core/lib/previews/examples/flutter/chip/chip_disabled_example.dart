import 'package:coui_flutter/coui_flutter.dart';

class ChipDisabledExample extends StatefulWidget {
  const ChipDisabledExample({super.key});

  @override
  State<ChipDisabledExample> createState() => _ChipDisabledExampleState();
}

class _ChipDisabledExampleState extends State<ChipDisabledExample> {
  @override
  Widget build(BuildContext context) {
    return Chip(
      label: '디자인',
      enabled: false,
      onTap: () {
        setState(() {});
      },
    );
  }
}
