import 'package:coui_flutter/coui_flutter.dart';

class PaginationDefaultExample extends StatefulWidget {
  const PaginationDefaultExample({super.key});

  @override
  State<PaginationDefaultExample> createState() => _PaginationDefaultExampleState();
}

class _PaginationDefaultExampleState extends State<PaginationDefaultExample> {
  int _page = 3;

  @override
  Widget build(BuildContext context) {
    return Pagination(
      page: _page,
      totalPages: 10,
      onPageChanged: (p) => setState(() => _page = p),
    );
  }
}
