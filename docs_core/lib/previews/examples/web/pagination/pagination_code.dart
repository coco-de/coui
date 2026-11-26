/// Returns a Web code snippet string for the Pagination component.
String paginationCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
class PaginationChainExample extends StatefulComponent {
  const PaginationChainExample({super.key});

  @override
  State<PaginationChainExample> createState() => _PaginationChainExampleState();
}

class _PaginationChainExampleState extends State<PaginationChainExample> {
  int _page = 3;

  @override
  Component build(BuildContext context) {
    return Pagination(
      page: _page,
      totalPages: 10,
      onPageChanged: (value) => setState(() => _page = value),
    ).withStyle(
      const CorePaginationStyle(
        itemSpacing: CoreSpace.space8,
        buttonSize: CoreSize.size40,
        buttonRadius: CoreBorderRadius.all(CoreRadius.radius16),
        activeBackgroundColor: CoreColor.token(CoreColors.tertiary),
      ),
    );
  }
}''',
    _ =>
      '''
class PaginationDefaultExample extends StatefulComponent {
  const PaginationDefaultExample({super.key});

  @override
  State<PaginationDefaultExample> createState() =>
      _PaginationDefaultExampleState();
}

class _PaginationDefaultExampleState extends State<PaginationDefaultExample> {
  int _page = 3;

  @override
  Component build(BuildContext context) {
    return Pagination(
      page: _page,
      totalPages: 10,
      onPageChanged: (value) => setState(() => _page = value),
    );
  }
}''',
  };
}
