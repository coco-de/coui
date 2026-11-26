import 'package:coui_web/coui_web.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CoreSelectableTextStyle] slot without constructing the
/// widget from scratch. The patch drives the prose typography plus the
/// caret and selection chrome in one instance.
class SelectableTextChainExample extends StatelessComponent {
  const SelectableTextChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return const SelectableText(
      '이 글자는 선택해서 복사할 수 있어요.',
    ).withStyle(
      const CoreSelectableTextStyle(
        textStyle: CoreTextStyle.token(
          CoreTextStyles.bodyLarge,
          color: CoreColor.token(CoreColors.primary),
        ),
        cursorColor: CoreColor.token(CoreColors.primary),
        cursorWidth: CoreStrokeWidth.stroke3,
        cursorRadius: CoreBorderRadius.all(CoreRadius.radius4),
        selectionColor: CoreColor.token(
          CoreColors.primary,
          opacity: CoreOpacity.opacity25,
        ),
      ),
    );
  }
}
