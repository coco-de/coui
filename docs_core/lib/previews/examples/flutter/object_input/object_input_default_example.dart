import 'package:coui_flutter/coui_flutter.dart';

class ObjectInputDefaultExample extends StatelessWidget {
  const ObjectInputDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    return ObjectInput(
      fields: const [
        CoreObjectInputField(key: 'year', placeholder: 'YYYY', maxLength: 4, pattern: r'\d'),
        CoreObjectInputField(key: 'month', placeholder: 'MM', maxLength: 2, pattern: r'\d'),
        CoreObjectInputField(key: 'day', placeholder: 'DD', maxLength: 2, pattern: r'\d'),
      ],
      separator: '/',
      onChanged: (values) => debugPrint('$values'),
    );
  }
}
