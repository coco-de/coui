import 'package:coui_flutter/coui_flutter.dart';

class RadioGroupExample1 extends StatefulWidget {
  const RadioGroupExample1({super.key});

  @override
  State<RadioGroupExample1> createState() => _RadioGroupExample1State();
}

class _RadioGroupExample1State extends State<RadioGroupExample1> {
  int? selectedValue;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RadioGroup<int>(
          onChanged: (value) {
            setState(() {
              selectedValue = value;
            });
          },
          value: selectedValue,
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RadioItem(trailing: Text('Option 1'), value: 1),
              RadioItem(trailing: Text('Option 2'), value: 2),
              RadioItem(trailing: Text('Option 3'), value: 3),
            ],
          ),
        ),
        const Gap(16),
        Text('Selected: $selectedValue'),
      ],
    );
  }
}
