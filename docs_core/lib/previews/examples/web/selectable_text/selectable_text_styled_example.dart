import 'package:coui_web/coui_web.dart';

class SelectableTextStyledExample extends StatelessComponent {
  const SelectableTextStyledExample({super.key});

  @override
  Component build(BuildContext context) {
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
