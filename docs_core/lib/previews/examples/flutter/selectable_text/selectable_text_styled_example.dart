import 'package:coui_flutter/coui_flutter.dart';

class SelectableTextStyledExample extends StatelessWidget {
  const SelectableTextStyledExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const SelectableText(
      '스타일을 바꾼 선택 가능한 글자예요.',
      selectableTextStyle: CoreSelectableTextStyle(
        textStyle: CoreTextStyle(
          fontSize: CoreFontSize.s18,
          fontWeight: CoreFontWeight.semiBold,
        ),
      ),
    );
  }
}
