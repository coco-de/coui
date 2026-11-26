/// Returns a Web code snippet string for the SelectableText component.
String selectableTextCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
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
}''',
    'styled' =>
      '''
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
}''',
    _ =>
      '''
class SelectableTextDefaultExample extends StatelessComponent {
  const SelectableTextDefaultExample({super.key});

  @override
  Component build(BuildContext context) {
    return const SelectableText('이 글자는 선택해서 복사할 수 있어요.');
  }
}''',
  };
}
