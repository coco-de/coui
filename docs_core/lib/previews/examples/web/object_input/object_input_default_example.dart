import 'package:coui_web/coui_web.dart';

class ObjectInputDefaultExample extends StatelessComponent {
  const ObjectInputDefaultExample({super.key});

  @override
  Component build(BuildContext context) {
    return ObjectInput(
      fields: const [
        CoreObjectInputField(key: 'year', placeholder: 'YYYY', maxLength: 4, pattern: r'\d'),
        CoreObjectInputField(key: 'month', placeholder: 'MM', maxLength: 2, pattern: r'\d'),
        CoreObjectInputField(key: 'day', placeholder: 'DD', maxLength: 2, pattern: r'\d'),
      ],
      separator: '/',
      onChanged: (values) => print('$values'),
    );
  }
}
