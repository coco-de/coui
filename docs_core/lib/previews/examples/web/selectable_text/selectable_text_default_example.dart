import 'package:coui_web/coui_web.dart';

class SelectableTextDefaultExample extends StatelessComponent {
  const SelectableTextDefaultExample({super.key});

  @override
  Component build(BuildContext context) {
    return const SelectableText('이 글자는 선택해서 복사할 수 있어요.');
  }
}
