import 'package:coui_flutter/coui_flutter.dart';

// The field's width in the strip — a `Row` gives its children unbounded
// width, so the field is told how wide to be.
const double _kFieldWidth = 200;

class JoinInputExample extends StatelessWidget {
  const JoinInputExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Join(
      children: [
        SizedBox(
          width: _kFieldWidth,
          child: TextField(placeholder: const Text('이메일 주소')),
        ),
        Button(onPressed: () {}, child: const Text('구독하기')),
      ],
    );
  }
}
