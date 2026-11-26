/// Returns a Flutter code snippet string for the DefinitionList component.
String definitionListCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''class DefinitionListChainExample extends StatelessWidget {
  const DefinitionListChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const DefinitionList(
      items: [
        CoreDefinitionEntry(term: '상호', description: '주식회사 코코드'),
        CoreDefinitionEntry(term: '대표', description: '한동우'),
        CoreDefinitionEntry(term: '사업자등록번호', description: '000-00-00000'),
      ],
      layout: CoreDefinitionLayout.columns,
      numeric: true,
    ).withStyle(
      const CoreDefinitionListStyle(
        entrySpacing: CoreSpace.space24,
        pairSpacing: CoreSpace.space16,
        termTextStyle: CoreTextStyle.token(
          CoreTextStyles.labelMedium,
          color: CoreColor.token(CoreColors.primary),
        ),
        descriptionTextStyle: CoreTextStyle.token(
          CoreTextStyles.bodyLarge,
          color: CoreColor.token(CoreColors.onSurface),
        ),
      ),
    );
  }
}''',
    'columns' =>
      '''
class DefinitionListColumnsExample extends StatelessWidget {
  const DefinitionListColumnsExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const DefinitionList(
      items: [
        CoreDefinitionEntry(term: '상호', description: '주식회사 코코드'),
        CoreDefinitionEntry(term: '대표', description: '한동우'),
        CoreDefinitionEntry(term: '사업자등록번호', description: '000-00-00000'),
      ],
      layout: CoreDefinitionLayout.columns,
      numeric: true,
    );
  }
}''',
    'inline' =>
      '''
class DefinitionListInlineExample extends StatelessWidget {
  const DefinitionListInlineExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const DefinitionList(
      items: [
        CoreDefinitionEntry(term: '상호', description: '주식회사 코코드'),
        CoreDefinitionEntry(term: '대표', description: '한동우'),
        CoreDefinitionEntry(term: '사업자등록번호', description: '000-00-00000'),
      ],
      layout: CoreDefinitionLayout.inline,
    );
  }
}''',
    _ =>
      '''
class DefinitionListDefaultExample extends StatelessWidget {
  const DefinitionListDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const DefinitionList(
      items: [
        CoreDefinitionEntry(term: '상호', description: '주식회사 코코드'),
        CoreDefinitionEntry(term: '대표', description: '한동우'),
        CoreDefinitionEntry(term: '사업자등록번호', description: '000-00-00000'),
      ],
    );
  }
}''',
  };
}
