import 'package:coui_web/coui_web.dart';

class FormatterDefaultExample extends StatelessComponent {
  const FormatterDefaultExample({super.key});

  @override
  Component build(BuildContext context) {
    return div(
      styles: Styles(raw: {'width': '280px'}),
      [
        TextField(
          placeholder: Text('숫자만 입력 (0–100)'),
          inputFormatters: [TextInputFormatters.integerOnly(min: 0, max: 100)],
        ),
      ],
    );
  }
}
