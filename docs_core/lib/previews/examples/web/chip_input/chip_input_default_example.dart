import 'package:coui_web/coui_web.dart';

class ChipInputDefaultExample extends StatefulComponent {
  const ChipInputDefaultExample({super.key});

  @override
  State<ChipInputDefaultExample> createState() => _ChipInputDefaultExampleState();
}

class _ChipInputDefaultExampleState extends State<ChipInputDefaultExample> {
  List<String> _chips = const <String>['Flutter', 'Dart'];

  void handleChanged(List<String> chips) {
    setState(() {
      _chips = chips;
    });
  }

  void handleSubmitted(String text) {
    setState(() {
      _chips = [..._chips, text];
    });
  }

  @override
  Component build(BuildContext context) {
    return ChipInput(
      chips: _chips,
      placeholder: '태그를 입력해 주세요',
      onChanged: handleChanged,
      onSubmitted: handleSubmitted,
    );
  }
}
