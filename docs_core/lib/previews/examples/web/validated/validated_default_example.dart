import 'package:coui_web/coui_web.dart';

class ValidatedDefaultExample extends StatelessComponent {
  const ValidatedDefaultExample({super.key});

  @override
  Component build(BuildContext context) {
    return div(
      styles: Styles(raw: {'width': '320px'}),
      [
        Validated(
          state: CoreValidationState.invalid,
          message: Text('필수 항목입니다.'),
          child: TextField(placeholder: Text('이름')),
        ),
      ],
    );
  }
}
