import 'package:coui_web/coui_web.dart';

// The field's width in the strip.
const String _kFieldWidth = '200px';

class JoinInputExample extends StatelessComponent {
  const JoinInputExample({super.key});

  @override
  Component build(BuildContext context) {
    return Join(
      children: [
        div(
          [TextField(placeholder: const Text('이메일 주소'))],
          styles: const Styles(raw: {'width': _kFieldWidth}),
        ),
        Button(onPressed: () {}, child: Text('구독하기')),
      ],
    );
  }
}
