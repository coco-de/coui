import 'package:coui_web/coui_web.dart';

class ChipDisabledExample extends StatefulComponent {
  const ChipDisabledExample({super.key});

  @override
  State<ChipDisabledExample> createState() => _ChipDisabledExampleState();
}

class _ChipDisabledExampleState extends State<ChipDisabledExample> {
  @override
  Component build(BuildContext context) {
    return Chip(
      label: '디자인',
      enabled: false,
      onTap: () {
        setState(() {});
      },
    );
  }
}
