import 'package:coui_flutter/coui_flutter.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CorePaginationStyle] slot without constructing the widget
/// from scratch.
class PaginationChainExample extends StatefulWidget {
  const PaginationChainExample({super.key});

  @override
  State<PaginationChainExample> createState() => _PaginationChainExampleState();
}

class _PaginationChainExampleState extends State<PaginationChainExample> {
  int _page = 3;

  @override
  Widget build(BuildContext context) {
    return Pagination(
      page: _page,
      totalPages: 10,
      onPageChanged: (p) => setState(() => _page = p),
    ).withStyle(
      const CorePaginationStyle(
        itemSpacing: CoreSpace.space8,
        buttonSize: CoreSize.size40,
        buttonRadius: CoreBorderRadius.all(CoreRadius.radius16),
        activeBackgroundColor: CoreColor.token(CoreColors.tertiary),
      ),
    );
  }
}
