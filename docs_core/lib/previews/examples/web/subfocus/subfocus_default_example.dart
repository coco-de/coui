import 'package:coui_web/coui_web.dart';

class SubfocusScopeDefaultExample extends StatelessComponent {
  const SubfocusScopeDefaultExample({super.key});

  @override
  Component build(BuildContext context) {
    return SubfocusScope(
      child: div(
        classes: 'flex flex-col items-center gap-${CoreSpace.scale.space8}',
        [
          Subfocus(
            focusId: 'a',
            child: Card(child: Text('항목 A (↑↓ 키로 이동)').bodyMedium),
          ),
          Subfocus(
            focusId: 'b',
            child: Card(child: Text('항목 B').bodyMedium),
          ),
          Subfocus(
            focusId: 'c',
            child: Card(child: Text('항목 C').bodyMedium),
          ),
        ],
      ),
    );
  }
}
