// ignore_for_file: avoid_print
import 'package:coui_flutter/coui_flutter.dart';

class FormattedInputExample1 extends StatelessWidget {
  const FormattedInputExample1({super.key});

  @override
  Widget build(BuildContext context) {
    return FormattedInput(
      initialValue: FormattedValue([
        const InputPart.editable(
          length: 2,
          placeholder: Text('MM'),
          width: 40,
        ).withValue('01'),
        const InputPart.static('/'),
        const InputPart.editable(
          length: 2,
          placeholder: Text('DD'),
          width: 40,
        ).withValue('02'),
        const InputPart.static('/'),
        const InputPart.editable(
          length: 4,
          placeholder: Text('YYYY'),
          width: 60,
        ).withValue('2021'),
      ]),
      onChanged: (value) {
        List<String> parts = [];
        for (FormattedValuePart part in value.values) {
          parts.add(part.value ?? '');
        }
        print(parts.join('/'));
      },
    );
  }
}
